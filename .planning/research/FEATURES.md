# Feature Research — v1.31 X Account Manual Add by Handle

**Project:** Bookmarks v1.31
**Domain:** Add-by-handle account discovery on an existing Rails social dashboard
**Researched:** 2026-05-22
**Confidence:** HIGH (codebase read directly; X API v2 docs confirmed via official sources; UX patterns from established app conventions)

---

## Context: What Already Exists

The `/x_accounts` index page shows every XAccount row for the current user (fetched from their X following list), each rendered as a card with a selection checkbox. The controller already handles:

- `GET /x_accounts` — renders the account list (ordered by username, excludes soft-deleted)
- `POST /x_accounts/refresh` — calls `XClient#fetch_following`, diffs, upserts
- `PATCH /x_accounts/:id` — saves selection state + display_count per row

The `x_accounts` table has a composite unique index on `(user_id, x_user_id)`, so adding a second row for the same account is a uniqueness violation — the system must detect this case and re-use the existing row or show a "already in your list" message.

**XClient already provides the right API surface:** The `bearer_faraday` method authenticates with `user.oauth2_token` (Bearer token, OAuth2). The X API v2 endpoint `GET /2/users/by/username/:username` uses the same Bearer token. Rate limit is 300 requests per 15-minute window per app — generously large compared to what this personal app will consume. The endpoint returns `id`, `name`, `username`, `protected`, `profile_image_url` by default.

**The `manually_added` boolean flag** (to be added to `x_accounts`) distinguishes origin (manual vs follow-sync) but has no effect on selection, display, or any other behavior — it is metadata only.

---

## Feature Landscape

### Table Stakes — Required for the Milestone to Deliver Value

If any of these are absent, the "add by handle" flow is broken or confusing.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Handle input field on `/x_accounts` screen** | The entry point is the existing management screen. Users expect the add form to live where accounts are managed, not on a separate page. Inline inline placement (above or below the account list) is the standard pattern for "add item to a managed list." | LOW | A single `<form>` with a text input and a submit button. No JS required for the initial implementation — a standard POST round-trip is sufficient. |
| **Strip leading `@` before lookup** | Users type `@username` (with the `@`) because that is how X handles are conventionally written. Stripping the `@` before sending to the API is expected UX hygiene. Without it, the API returns 404 for `@username` even though `username` resolves. | LOW | `params[:username].to_s.lstrip.delete_prefix('@').strip` in the controller. One line. |
| **API lookup before insert — confirm account exists** | The app must not allow adding a handle that does not exist. The X API `GET /2/users/by/username/:username` returns 404 if the account does not exist. This must be surfaced to the user as an error state, not silently ignored. | LOW | Call `XClient#fetch_user_by_username(user:, username:)` (new method) in the controller. On 404, flash `:alert`. |
| **"Account not found" error state** | User types a nonexistent or suspended handle and clicks Add. The form re-renders with a clear message: "Account @foo was not found." Without this, users assume the button is broken. | LOW | Flash alert. No inline partial needed. |
| **"Already in your list" guard** | The `(user_id, x_user_id)` unique index means inserting a duplicate raises `ActiveRecord::RecordNotUnique`. More importantly, if the account is already in the list (even soft-deleted), the user should get a clear message — not a 500, and not silently re-adding. Three sub-cases: (a) active row exists (not deleted), (b) soft-deleted row exists (it was previously removed by a follow-sync diff). Case (a): flash "already added". Case (b): un-delete and re-activate, then redirect. | LOW-MEDIUM | Model-level check before insert. `XAccount.where(user_id:, x_user_id:).first` — if found and not deleted, flash "already added" and redirect. If found and deleted, reset `deleted: false, manually_added: true` and redirect with success. If not found, insert new row. |
| **Protected account warning on add** | The existing selection flow already shows a "protected account" acknowledgement checkbox before the user can select a protected account. An account added via manual add must also carry the `protected` field. If `protected: true`, the account is added but selection requires acknowledgement — same as the existing flow. The user should not be able to accidentally select a protected account they just added without acknowledging. | LOW | The API response includes `protected`. Store it in the row. No new UX needed — the existing `protected_acknowledged` validation and card UI handle it from here. |
| **`manually_added boolean NOT NULL DEFAULT false` migration** | Adds the origin flag. Does not change any behavior. Required as a tracking field so the refresh diff does not delete manually-added accounts that are not in the following list. | LOW | One migration. One column. The `refresh_cache_from_items!` method must skip (or handle carefully) rows with `manually_added: true` when soft-deleting missing rows. |
| **Refresh diff protection for manually-added rows** | `XAccount.refresh_cache_from_items!` currently soft-deletes every row not in the API response. Manually-added accounts are not in the following list by definition — so every refresh would soft-delete them. This must be fixed: `manually_added: true` rows must be excluded from the soft-delete sweep. | MEDIUM | In `refresh_cache_from_items!`, change the soft-delete sweep to: `where(manually_added: false).find_each { |acc| acc.update!(deleted: true) unless seen[acc.x_user_id] }`. This is a critical correctness fix, not optional. |
| **Ja/en locale strings for the new form** | All UI strings must exist in both `ja.yml` and `en.yml`. The input label, placeholder, button text, and all error/success flash messages need keys. This is a project-wide requirement. | LOW | Six to eight new locale keys. Same pattern as every other form in the app. |
| **Success feedback after add** | When the account is successfully added, the user is redirected to `/x_accounts` with a flash notice: "Account @foo has been added." Without feedback, the user may click Add multiple times wondering if it worked. | LOW | `flash[:notice] = t('x_accounts.add.success', username: '@' + username)` and redirect. |
| **XApiCall instrumentation for the new lookup** | `XAccountsController#refresh` and `#show` already call `record_x_api_call`. The new lookup action must do the same. This is required for consistent API usage reporting that v1.29 introduced. | LOW | Call `record_x_api_call(endpoint: 'fetch_user_by_username', result: result)` in the new controller action. One line. |

---

### Differentiators — Useful but Not Required for MVP

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Inline profile preview before confirming add** | After the user types a handle and clicks "Look Up", the form shows the account's display name and avatar inline, then a "Confirm Add" button. Reduces the chance of adding the wrong account (common username collisions). Pattern: Twitter's "follow" confirmation shows a profile card before the follow button. | MEDIUM | Requires a two-step flow: POST to a `preview` action renders the profile card inline (or as a partial replaced by JS). A second POST to `create` confirms. Alternatively, a single POST shows the preview page with a confirmation form. Without JS, this is a two-request round-trip — workable in server-rendered Rails but adds one more controller action and one view partial. Not needed for correctness; the account name/handle shown in the success flash is sufficient confirmation. |
| **Case-insensitive handle input** | X usernames are case-insensitive but the API accepts any case. Normalizing to lowercase before lookup prevents duplicate rows if the user types `@HANDLE` once and `@handle` another time. The unique index is on `x_user_id` (not `username`), so the API is the source of truth — but normalized storage is cleaner. | LOW | `.downcase` on the username before lookup. Almost zero cost but depends on whether the X API always returns the canonical casing (it does — the API response `username` field is the canonical form). |
| **Remove / soft-delete for manually-added accounts** | A user who added an account manually may want to remove it without triggering a refresh. A "Remove" button per card (only shown for `manually_added: true` accounts) sets `deleted: true`. The follow-synced accounts continue to be managed by refresh. | MEDIUM | Adds a `DELETE /x_accounts/:id` route. A confirm dialog (JS confirm or a separate confirmation page). The existing `preload_account` before_action already handles authorization. Low-risk addition but adds surface area. |
| **Handle validation in the browser before submit** | A pattern attribute on the input (`[A-Za-z0-9_]{1,15}`) prevents submitting clearly invalid handles (too long, invalid characters). Reduces round-trips for typos. | LOW | One `pattern` attribute on the `<input>`. Zero JS required; browser native validation. |

---

### Anti-Features — Explicitly Not This Milestone

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Modal/popup for the add form** | A modal requires JS to open/close, focus trapping, and ARIA management. The existing app has no modal component. Adding one for a simple text input adds JS complexity that violates the "no new JS complexity" standing constraint. | Inline form above or below the existing account list. Same page, no overlay. |
| **Autocomplete / handle suggestions while typing** | Requires debounced XHR calls to a lookup endpoint on every keystroke. X API rate limits (300/15min for user lookup) are not a hard constraint, but adding live search creates a new AJAX endpoint, a new JS event handler, and new failure states. The app avoids AJAX complexity where server-rendered round-trips suffice. | Submit-on-click lookup. User types the full handle and clicks Add. |
| **Importing multiple handles at once (bulk add)** | A textarea where the user pastes a list of handles and adds them all. More complex error reporting (per-line errors), a loop in the controller, and a transaction that may partially succeed. The single-add pattern is sufficient for personal use. | One handle at a time. The form is on the same page; adding several accounts is fast even one at a time. |
| **Searching across all X accounts (not just the user's)** | A search box that queries X's full user directory. This is a different feature (discovery) from "add a specific account you already know the handle of." The milestone specifically calls for "type a handle to add." | Direct handle entry only. No query-against-all-users search. |
| **Show tweet preview of the added account on the add page** | Fetching tweets for a just-added account and showing them inline during the add flow is a cross-feature scope expansion. The dashboard gadget handles tweet display. | The user can see tweets on the dashboard after selecting the account. |
| **OmniAuth / OAuth "follow user" via the API** | Using the X API to programmatically follow the added account on behalf of the user. This app is read-only; it displays tweets, it does not write to X. | Read-only: add to local display list only. |

---

## Feature Dependencies

```
[manually_added boolean migration]
    └──required by──> [refresh diff protection logic]
    └──required by──> [new XAccount row insert]

[XClient#fetch_user_by_username (new method)]
    └──required by──> [controller lookup action]
    └──uses──> [existing bearer_faraday connection]
    └──mirrors──> [fetch_following structure: success/error contract]

[Controller: POST /x_accounts/add_by_handle (or POST /x_accounts)]
    └──calls──> [XClient#fetch_user_by_username]
    └──calls──> [XApiCall.record!]
    └──checks──> [existing row by x_user_id]
    └──writes──> [XAccount row with manually_added: true]
    └──redirects to──> [x_accounts_path with flash]

[refresh_cache_from_items! soft-delete sweep fix]
    └──requires──> [manually_added column to exist]
    └──protects──> [manually_added: true rows from being deleted on refresh]

[Add form on index view]
    └──renders on──> [existing x_accounts/index.html.erb]
    └──posts to──> [new controller action]

[Ja/en locale strings]
    └──required by──> [add form view + flash messages]
    └──keys in──> [config/locales/ja.yml + en.yml]
```

### Dependency Notes

- **`manually_added` column must precede all else.** The refresh diff fix and the new insert both depend on this column being present.
- **The refresh diff fix is load-bearing.** Without it, a user who adds an account manually and then clicks Refresh will lose the account. This must ship in the same milestone.
- **`XClient#fetch_user_by_username` is a new method, not a modification.** The existing `fetch_following` and `fetch_recent_tweets` are untouched. The new method follows the same `{ success:, items: }` contract.
- **Authorization:** The new add action uses `before_action :require_twitter_linked` (already present), so it is already gated behind the OAuth2 link requirement. No new auth surface.
- **Uniqueness:** The DB unique index on `(user_id, x_user_id)` is the canonical guard. The controller must handle the "already exists" case before the DB raises, to give a user-friendly error rather than a 500.

---

## X API Endpoint Details for `fetch_user_by_username`

**Endpoint:** `GET /2/users/by/username/:username`

**Auth:** Bearer token (same as existing `bearer_faraday` setup)

**Required fields to request:** `user.fields=id,name,username,profile_image_url,protected`

**Rate limit:** 300 requests per 15-minute window per app — well within any personal-use scenario.

**Error codes to handle (mirrors existing XClient contract):**

| HTTP Status | Meaning | Error Symbol |
|-------------|---------|--------------|
| 200 | Account found | success |
| 404 | Account does not exist or is suspended | `:not_found` |
| 401 | OAuth2 token expired/invalid | `:unauthorized` |
| 429 | Rate limited (300/15min would require hammering) | `:rate_limited` |
| 5xx / network | X API down | `:api_error` / `:timeout` / `:network` |

**Response shape (same as following items):**

```json
{
  "data": {
    "id": "12345",
    "name": "Display Name",
    "username": "handle",
    "protected": false,
    "profile_image_url": "https://pbs.twimg.com/..."
  }
}
```

The normalized row returned from `fetch_user_by_username` can use the same `normalize_following_row` format (`{ id:, username:, name:, profile_image_url:, protected: }`) so `XAccount.new(...)` assignment is identical to the refresh path.

---

## Error States to Handle

All error states must have a flash message (alert) in both ja and en.

| State | User-Visible Message | How to Produce in Tests |
|-------|---------------------|------------------------|
| Account not found (404) | "アカウント @foo が見つかりませんでした" / "Account @foo was not found." | WebMock stub returning 404 |
| Already in active list | "アカウント @foo はすでに追加されています" / "Account @foo is already in your list." | Pre-existing XAccount row with deleted: false |
| Previously deleted, now restored | (success flash) "アカウント @foo を追加しました" / "Account @foo has been added." | XAccount row with deleted: true — re-activate |
| Protected account added | (success flash) "アカウント @foo を追加しました（非公開アカウントは選択時に確認が必要です）" / "Account @foo was added. Protected accounts require acknowledgement before selection." | API response with protected: true |
| Input blank or invalid pattern | Form-level validation before API call | Empty string or `<input>` pattern rejection |
| Rate limited | "X API の利用制限に達しました" / "X API rate limit reached." | WebMock stub returning 429 |
| Network error / timeout | "X API に接続できませんでした" / "Could not reach the X API." | WebMock to raise Faraday::TimeoutError |
| Unauthorized (token expired) | Existing `:unauthorized` locale key | WebMock stub returning 401 |

---

## MVP Definition

### Build in v1.31

1. **Schema:** `manually_added boolean NOT NULL DEFAULT false` migration on `x_accounts`
2. **Model:** `XAccount` — permit `manually_added` as attr; update `refresh_cache_from_items!` soft-delete to exclude `manually_added: true` rows
3. **XClient:** Add `fetch_user_by_username(user:, username:)` method returning `{ success: true, item: {...} }` or `{ success: false, error: Symbol }` + `rate_limit_remaining`
4. **Controller:** New action (e.g., `POST /x_accounts/add` or a `create` action) that: strips `@`, calls `fetch_user_by_username`, handles all error states, upserts the row with `manually_added: true`, calls `record_x_api_call`, redirects
5. **View:** Inline add form on `x_accounts/index.html.erb` — text input, submit button, locale keys for label/placeholder/button
6. **Locales:** All error + success flash strings in ja.yml and en.yml
7. **Tests:** Minitest for `XClient#fetch_user_by_username` (success, 404, 401, 429, timeout), controller action (all error states + success + already-added + soft-deleted restore), model `refresh_cache_from_items!` protection for manually_added rows; Cucumber E2E scenario: user types handle, account added, appears in list

### Explicitly Defer

- Two-step confirmation/preview before insert — not needed for correctness at this scale
- Remove / soft-delete for manually-added accounts — add-only is correct for v1.31
- CSS badge distinguishing manually-added vs follow-synced on the card — origin is metadata, not a display concern
- Bulk add — single-add form is sufficient

---

## Complexity Assessment

| Component | Effort | Risk | Notes |
|-----------|--------|------|-------|
| Migration (`manually_added`) | 0.5 phases | LOW | One column, one migration |
| `refresh_cache_from_items!` fix | 0.5 phases | MEDIUM | Correctness-critical; must not break existing refresh behavior; good test coverage required |
| `XClient#fetch_user_by_username` | 0.5 phases | LOW | Mirrors existing `fetch_following` structure; new Faraday call, same auth |
| Controller action + route | 1 phase | LOW | 6–8 error states, but all follow the same flash-and-redirect pattern |
| View (inline form) | 0.5 phases | LOW | One `<form>` block added to existing index view |
| Locales (ja/en) | Folded in | LOW | 8–12 keys |
| Minitest coverage | 1 phase | LOW | Service + model + controller tests; WebMock for HTTP stubs |
| Cucumber E2E | 0.5 phases | LOW | One happy-path scenario + one "not found" scenario |

**Total: 4–5 phases.** Smaller than v1.29 (5–6 phases). The heaviest risk is the `refresh_cache_from_items!` fix — existing refresh tests must be extended to cover the manually_added exclusion.

---

## Sources

- Codebase read directly: `app/services/x_client.rb`, `app/controllers/x_accounts_controller.rb`, `app/models/x_account.rb`, `app/views/x_accounts/index.html.erb`, `db/schema.rb`
- [X API v2: GET /2/users/by/username/:username — docs.x.com](https://docs.x.com/x-api/users/get-user-by-username) — endpoint fields and auth confirmed
- [X API v2: Rate Limits — docs.x.com](https://docs.x.com/x-api/fundamentals/rate-limits) — 300/15min for user lookup endpoints confirmed
- [X API v2: User lookup by usernames — docs.x.com](https://docs.x.com/x-api/users/user-lookup-by-usernames) — batch variant confirmed; single-username variant used here

---

*Feature research for: manual add-by-handle on X accounts management screen in Rails personal dashboard*
*Researched: 2026-05-22*
