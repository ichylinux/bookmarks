# Domain Pitfalls: v1.31 X Account Manual Add (Non-Following)

**Domain:** Adding manual X account lookup-by-handle to an existing Rails diff-upsert refresh system
**Researched:** 2026-05-22
**Scope:** Pitfalls specific to adding `XClient#lookup_user_by_username`, a `manually_added` flag, and a controller add action to the existing `x_accounts` / `refresh_cache_from_items!` system

---

## Critical Pitfalls

### Pitfall 1: `refresh_cache_from_items!` blindly soft-deletes manually-added accounts on every refresh

**What goes wrong:**
`XAccount.refresh_cache_from_items!` builds a `seen` hash from the X following-API payload, then iterates every `x_accounts` row for the user and calls `acc.update!(deleted: true)` on any row whose `x_user_id` is absent from that hash. A manually-added account the user does not follow will always be absent from the following payload. Every call to Refresh silently soft-deletes all manually-added accounts.

**Why it happens:**
The method was written when the only source of accounts was the following API. The soft-delete loop at lines 51–55 of `app/models/x_account.rb` has no concept of origin. Any row not seen in the following payload is a candidate for deletion — there is no exemption path.

**Consequences:**
- User adds @handle manually, it appears on the dashboard. User clicks Refresh. The account vanishes. This repeats on every refresh, forever.
- `selected: true` state persists on the soft-deleted row but the `not_deleted` scope excludes it from gadget queries, so the tweet feed also disappears silently.
- No data is hard-deleted, so recovery is possible, but the user-visible experience is broken on every refresh cycle.

**Prevention:**
Add a single guard line inside the soft-delete loop in `refresh_cache_from_items!`:

```ruby
XAccount.where(user_id: user.id).find_each do |acc|
  next if seen[acc.x_user_id]
  next if acc.manually_added?   # guard: manually-added accounts survive refresh

  acc.update!(deleted: true)
end
```

This is the single most important change in the milestone. Write it and its Minitest case before any controller work.

**Detection:**
Minitest:
1. Create `XAccount` with `manually_added: true`, `deleted: false`.
2. Call `XAccount.refresh_cache_from_items!(user, [])` (empty payload — row not in following list).
3. Assert `acc.reload.deleted?` returns `false`.

The existing tests `test_refresh_cache_soft_deletes_unselected_row_missing_from_payload` and `test_refresh_cache_soft_deletes_selected_row_missing_from_payload` show the correct pattern; add an equivalent "does NOT soft-delete manually-added row" test alongside them.

**Phase:** Migration + model phase (Phase 1). Do not merge any controller work until this test is green.

---

### Pitfall 2: `assign_attributes` in `refresh_cache_from_items!` must never include `manually_added: false`

**What goes wrong:**
When a manually-added account also appears in the following payload (the user follows someone they manually added), `refresh_cache_from_items!` upserts that row via `assign_attributes` and `save!`. Developers adding the `manually_added` column may be tempted to include `manually_added: false` in the `assign_attributes` call to ensure a "clean" follow-synced state. This silently clears the flag: the account is now treated as follow-synced and will be correctly soft-deleted on the next refresh if the user unfollows.

**Why it happens:**
The following-API payload has no `manually_added` field. Developers reasoning about "state reset on upsert" may add the column to the attributes hash as a form of bookkeeping. The mistake is invisible until the user unfollows and refreshes.

**Consequences:**
- Manually-added account survives one refresh (because the follow lookup finds it), then disappears the next time the user unfollows — which was not the intent.
- Root cause is one extra line in `assign_attributes`; very easy to introduce, hard to notice.

**Prevention:**
Do NOT add `manually_added` to the `assign_attributes` call inside `refresh_cache_from_items!`. Let the column's DB default (`false`) apply only at row creation. Only the manual-add action should set `manually_added: true`.

**Detection:**
Minitest:
1. Create a `manually_added: true` row with a `x_user_id` that IS present in the refresh payload.
2. Call `refresh_cache_from_items!` with that row in the payload.
3. Assert `acc.reload.manually_added?` is still `true`.

**Phase:** Migration + model phase (Phase 1). Part of the same test suite as Pitfall 1.

---

### Pitfall 3: Unique index on `(user_id, x_user_id)` raises `RecordNotUnique` on duplicate manual add

**What goes wrong:**
`x_accounts` has `UNIQUE KEY index_x_accounts_on_user_id_and_x_user_id (user_id, x_user_id)`. If a user tries to add a handle that is already present in `x_accounts` (either as a follow-synced account, an earlier manual add, or a soft-deleted row), an INSERT raises `ActiveRecord::RecordNotUnique`. Two cases:

1. Row exists with `deleted: false` — attempting a new create raises the constraint.
2. Row exists with `deleted: true` — the soft-deleted row still holds the unique slot; inserting a new row raises the same constraint.

**Consequences:**
- Unrescued `RecordNotUnique` surfaces as a 500 to the user.
- Case 2 is subtle: a user who previously had a follow-synced account, ran refresh after unfollowing (soft-delete), then tries to manually re-add sees a 500 rather than a clean re-activation.

**Prevention:**
Use `XAccount.where(user_id: current_user.id, x_user_id: looked_up_id).first_or_initialize` — the same pattern already used in `refresh_cache_from_items!`. When the record already exists with `deleted: false`, return a flash indicating the account is already added. When it exists with `deleted: true`, un-delete it and set `manually_added: true` (resurrect rather than insert).

If `save!` is used downstream, also rescue `ActiveRecord::RecordNotUnique` as a safety net, following the precedent set in `Users::EmailRegistrationsController`.

**Detection:**
Minitest: attempt to add the same handle twice; assert the second request returns a 302 with a flash message, not a 500. Add a separate test for the `deleted: true` resurrection path.

**Phase:** Controller/service phase. Pair the rescue with the integration test.

---

## Moderate Pitfalls

### Pitfall 4: Raw `@handle` input passed to the API path without stripping the `@` prefix

**What goes wrong:**
Users naturally type `@handle` (with `@` prefix) or paste it from a mention. If the raw input is passed directly to `GET /2/users/by/username/{username}`, the API receives `@handle` as the literal username segment. X usernames do not include `@`; the API returns HTTP 404.

**Prevention:**
Strip leading `@` characters and surrounding whitespace before building the request path:

```ruby
username = params[:username].to_s.strip.delete_prefix('@')
return redirect with flash if username.blank?
```

Additionally, validate the username matches the allowed character set (alphanumeric + underscore, 1–50 characters) before making the API call. Return a validation flash for invalid input rather than consuming a rate-limited API request.

**Detection:**
Minitest: pass `@testuser` to the lookup action; assert the Faraday stub receives `/2/users/by/username/testuser` (no `@`). Also test all-whitespace input returns a redirect with a validation flash, not an API call.

**Phase:** Service phase when `XClient#lookup_user_by_username` is first implemented.

---

### Pitfall 5: New `lookup_user_by_username` method missing HTTP error status handling — especially 403 for suspended accounts

**What goes wrong:**
`parse_following_response` and `parse_tweets_response` both map 401 → `:unauthorized`, 404 → `:not_found`, 429 → `:rate_limited`, else → `:api_error`. The new lookup method needs the same exhaustive handling. Two gaps are most likely:

- **429 mapped to `:api_error` instead of `:rate_limited`**: losing the specific signal breaks the admin usage report error_code column and renders the wrong flash message.
- **403 not handled**: the X API v2 returns HTTP 403 with a user-suspension error when looking up a suspended account. An unhandled 403 falls through to `:api_error` instead of a meaningful `:suspended` or `:forbidden` symbol. Users see a generic error rather than "that account is suspended."

**Rate limit context (MEDIUM confidence):**
`GET /2/users/by/username/{username}` has a per-app (bearer token) limit of 300 requests per 15 minutes per the X API rate limits documentation. This is generous for a personal app with infrequent manual adds, but the 429 path must still be handled correctly.

**Prevention:**
Copy the full `case res.status` block from `parse_following_response` as the starting point for the new response parser. Add a `when 403` branch returning a distinct error symbol (`:forbidden` or `:suspended`). Ensure 429 maps to `:rate_limited`.

**Detection:**
Service unit tests using Faraday `:test` adapter:
- Stub 429 → assert `result[:error] == :rate_limited`
- Stub 403 → assert `result[:error] == :forbidden` (or `:suspended`)
- Stub 404 → assert `result[:error] == :not_found`

**Phase:** Service phase (`XClient#lookup_user_by_username`).

---

### Pitfall 6: Storing user-input username instead of the API-returned canonical username

**What goes wrong:**
X usernames are case-insensitive at the URL level but the API returns canonical casing (e.g., user types `ELONMUSK`, API returns `"username": "elonmusk"`). If the controller stores `params[:username]` directly rather than `result[:username]` from the API response body, `x_accounts.username` has wrong casing from creation, breaking `XAccount#profile_url` display and creating inconsistency with the refresh flow which always uses API-sourced values.

A second scenario: the handle the user typed is an old handle that was renamed. The API returns `"username": "NewHandle"` but the controller stores `"OldHandle"`. The stored row is stale from the start.

**Prevention:**
Always assign `username` from the API response, not the input parameter. The input is used only to form the lookup URL path.

**Detection:**
Minitest: stub the API to return `"username": "canonical_user"` when queried for `CANONICAL_USER`. Assert the persisted `XAccount#username` is `"canonical_user"`, not `"CANONICAL_USER"`.

**Phase:** Service phase. One-line discipline issue, easy to miss.

---

### Pitfall 7: Manually-added account resurrection does not unconditionally set `manually_added: true`

**What goes wrong:**
`first_or_initialize` finds an existing row (e.g., `deleted: true` from a prior soft-delete). The developer sets `deleted: false` to resurrect it but branches on `new_record?` to set `manually_added: true` — only new rows get the flag. An existing soft-deleted row is resurrected without the flag. On the next refresh the row is soft-deleted again because `manually_added?` is false.

**Prevention:**
In the manual-add code path, after `first_or_initialize`, unconditionally assign `manually_added: true, deleted: false` before save — do not branch on `new_record?`.

**Detection:**
Minitest: create a `deleted: true, manually_added: false` row with the target `x_user_id`. Run the add action. Assert `acc.reload.manually_added?` is `true` and `acc.reload.deleted?` is `false`.

**Phase:** Controller/service phase.

---

### Pitfall 8: Missing `XApiCall.record!` instrumentation for the new lookup action

**What goes wrong:**
`XAccountsController#refresh` and `#show` both call the private `record_x_api_call(endpoint:, result:)` helper. A new controller action that calls `XClient#lookup_user_by_username` may skip this instrumentation. The admin X API usage report at `/admin/x_api_usages` then undercounts API usage.

**Prevention:**
Call `record_x_api_call(endpoint: 'lookup_user_by_username', result: result)` in the new action, using the same private helper already on `XAccountsController`. The helper already rescues `StandardError` so a logging failure will not break the main flow.

**Phase:** Controller phase.

---

## Minor Pitfalls

### Pitfall 9: WebMock stubs in Cucumber `Before` hooks do not cover the new `/2/users/by/username/` path

**What goes wrong:**
`test/support/webmock.rb` applies `disable_net_connect!(allow_localhost: true)` globally. Cucumber scenarios that exercise the manual-add form trigger a real HTTP request to `api.twitter.com/2/users/by/username/...`. Without a WebMock stub registered for this path, WebMock raises `WebMock::NetConnectNotAllowedError` and the scenario fails with an opaque connection error rather than a meaningful assertion.

**Prevention:**
Register `WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/by\/username\//)` in the relevant Cucumber `Before` hook or scenario step, mirroring the pattern used for `@x_gadget` in the existing feature support files.

**Detection:**
Run the new Cucumber scenario without the stub. The `WebMock::NetConnectNotAllowedError` message will name the unmatched URL.

**Phase:** Cucumber/E2E phase.

---

### Pitfall 10: No explicit decision on total account count cap (selected vs. all rows)

**What goes wrong:**
The selection cap (12) limits `selected: true` accounts. The `manually_added` flag adds accounts to the `x_accounts` pool without selecting them. There is currently no limit on total rows per user (selected + unselected + manually added). A user could add 200 accounts manually, cluttering the management screen and creating an unbounded table growth scenario.

**Prevention:**
Decide explicitly whether the 12-account selection cap is sufficient, or whether a separate cap on total `x_accounts` rows is needed. Document the decision in the roadmap. If a cap is added, enforce it both at the model level (validation) and return a clear flash from the controller when the cap is hit.

**Phase:** Model/migration phase. This is a product decision; raise it explicitly rather than inheriting silence.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Migration: add `manually_added` column | Pitfall 2 — `assign_attributes` reset | Audit every `assign_attributes` call in `refresh_cache_from_items!`; do not include the new column |
| Model: guard in `refresh_cache_from_items!` | Pitfall 1 (critical) | Add `next if acc.manually_added?` to the soft-delete loop; write the Minitest case before marking phase complete |
| Model tests for refresh behavior | Pitfalls 1, 2 | Two new Minitest cases: (a) manually-added row survives empty refresh; (b) manually-added flag not cleared when row appears in following payload |
| Service: `XClient#lookup_user_by_username` | Pitfalls 4, 5, 6 | Strip `@` before URL path; copy full status-code parser from existing methods; use API-returned `username` |
| Controller: new add action | Pitfalls 3, 7, 8 | Use `first_or_initialize`; unconditionally set `manually_added: true`; rescue `RecordNotUnique`; call `record_x_api_call` |
| Cucumber E2E | Pitfall 9 | Register WebMock stub for `/2/users/by/username/` in the relevant Before hook |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| refresh/manually_added interaction (Pitfalls 1–3) | HIGH | Direct code inspection of `refresh_cache_from_items!` lines 51–55; logic is unambiguous; existing Minitest cases confirm soft-delete behavior |
| Unique index / duplicate add (Pitfall 3) | HIGH | `db/schema.rb` confirms `UNIQUE KEY index_x_accounts_on_user_id_and_x_user_id`; `first_or_initialize` pattern confirmed in model |
| Username sanitization (Pitfall 4) | HIGH | X API documented behavior; `@` is not part of the username in the URL path segment |
| Rate limits (Pitfall 5) | MEDIUM | 300/15 min per-app confirmed from docs.x.com rate limits page; tier-specific caps may apply |
| HTTP 403 for suspended accounts (Pitfall 5) | MEDIUM | Confirmed from X Developer Community forum threads; not in official API reference excerpt retrieved |
| Username casing from API (Pitfall 6) | HIGH | X API v2 always returns canonical `username` in response body; storing input vs. response is a code-level decision |
| WebMock gap (Pitfall 9) | HIGH | Direct inspection of `test/support/webmock.rb`; `disable_net_connect!` is global; new URL path will not be covered by existing stubs |
