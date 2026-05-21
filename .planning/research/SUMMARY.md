# Project Research Summary

**Project:** Bookmarks v1.31 — X Account Manual Add (Non-Following)
**Domain:** Incremental feature on existing Rails X accounts management screen
**Researched:** 2026-05-22
**Confidence:** HIGH

## Executive Summary

v1.31 is a focused, low-risk feature addition to an existing, well-understood system. The goal is to let users type an X handle and add that account to their management screen even if they do not follow it on X. All infrastructure required — Faraday HTTP client, OAuth2 Bearer token auth, upsert patterns, flash error handling, API call instrumentation — already exists. The milestone requires one new XClient method, one migration, one controller action, one view form, and a targeted fix to the refresh soft-delete loop. No new gems, no new authentication flows, no background jobs.

The single highest-risk item is the `refresh_cache_from_items!` soft-delete loop. Without a one-line guard (`next if acc.manually_added?`), every Refresh click silently destroys manually-added accounts. This fix is load-bearing and must ship in the same phase as the migration — nothing else should be built until this behavior is covered by a passing Minitest. A second related risk is that the `assign_attributes` call inside the same refresh method must never include `manually_added: false`, or accounts that the user both follows and manually-added will lose their flag the next time refresh runs.

Beyond the refresh interaction, all remaining work follows established patterns already present in the codebase: `first_or_initialize` for upsert, existing error symbols for API failures, `record_x_api_call` for instrumentation, and locale keys in both `ja.yml` and `en.yml`. The milestone is estimated at 4-5 phases of work, smaller than v1.29.

---

## Key Findings

### Recommended Stack

Zero new gems required. The existing `XClient` Faraday service already authenticates with `user.oauth2_token` (OAuth2 User Context Bearer token), which is confirmed as sufficient for `GET /2/users/by/username/{username}`. The new method is approximately 25 lines following the identical pattern as `fetch_following` and `fetch_recent_tweets`. WebMock and the Faraday `:test` adapter already in place cover test stubbing with no additions.

**Core technologies:**
- `XClient` (Faraday, existing): New `lookup_user_by_username` method — mirrors `fetch_following` structure, reuses `normalize_following_row` and `connection_for`
- `users.oauth2_token` Bearer auth (existing): Confirmed sufficient for the user lookup endpoint; no new OAuth scopes required
- `x_accounts` migration: Add `manually_added boolean NOT NULL DEFAULT false` — safe backfill-free column; existing rows default to `false`
- WebMock + Faraday `:test` adapter (existing): No changes needed to test infrastructure; new stubs follow `stub_request(:get, /users\/by\/username/)` pattern

### Expected Features

**Must have (table stakes):**
- Handle input form on `/x_accounts` index page — inline, no modal, no JS required
- Strip leading `@` before API call — users type `@handle`; the X API rejects it
- API lookup before insert — reject nonexistent/suspended handles with a flash error
- "Already in your list" guard — `first_or_initialize` prevents `RecordNotUnique` 500s; handles both active and soft-deleted existing rows
- `refresh_cache_from_items!` protection — manually-added rows must survive every Refresh click
- `manually_added` migration — prerequisite for all of the above
- `protected` field stored on add — existing acknowledgement gate handles selection gate
- Success and error flash messages in `ja.yml` and `en.yml`
- `record_x_api_call` instrumentation on the new action

**Should have (not required for v1.31):**
- Case-insensitive handle normalization (downcase before lookup) — prevents duplicate rows from casing variants
- Browser `pattern` attribute on input — reduces round-trips for obviously invalid handles; one HTML attribute

**Defer to v2+:**
- Two-step preview before confirming add — not needed for correctness
- Remove/soft-delete for manually-added accounts — add-only is correct for v1.31
- Visual badge distinguishing manually-added vs follow-synced — origin is metadata, not a v1.31 display concern
- Bulk add or CSV import — single handle at a time is sufficient

### Architecture Approach

The feature is layered strictly on top of the existing `XAccountsController` / `XClient` / `XAccount` triptych without modifying any existing public interfaces. A new collection route `POST /x_accounts/lookup_and_add` dispatches to a new controller action that normalizes input, calls `XClient#lookup_user_by_username`, records the API call, then delegates to `XAccount.upsert_manual!` (new class method) which uses `first_or_initialize` to handle create/resurrect idempotently. The existing redirect-after-POST pattern, flash conventions, and `require_twitter_linked` before_action all apply unchanged.

**Major components:**
1. `XClient#lookup_user_by_username` — calls `GET /2/users/by/username/{username}`, returns `{ success: true, item: {...} }` or `{ success: false, error: Symbol }`; reuses `normalize_following_row`, `connection_for`, and the existing error symbol contract
2. `XAccount.upsert_manual!` — new class method; `first_or_initialize` on `(user_id, x_user_id)`; unconditionally sets `manually_added: true, deleted: false`; raises `RecordInvalid` for invalid state (controller rescues)
3. `refresh_cache_from_items!` (modified) — soft-delete loop gains `next if acc.manually_added?`; the `assign_attributes` call is left unchanged (must NOT include `manually_added`)
4. `XAccountsController#lookup_and_add` — new action; handle format validation; calls XClient, calls `record_x_api_call`, calls `upsert_manual!`, redirects with flash
5. Index view form — `form_with url: lookup_and_add_x_accounts_path`, text input, submit; synchronous POST, no JS

### Critical Pitfalls

1. **`refresh_cache_from_items!` silently deletes manually-added accounts on every Refresh** — Add `next if acc.manually_added?` to the soft-delete loop. Write the Minitest case before any controller work. This is the single most important change in the milestone.
2. **`assign_attributes` in refresh must never include `manually_added: false`** — The following payload has no `manually_added` field; do not add it to the attributes hash. Test that a `manually_added: true` row that also appears in the following payload retains its flag after refresh runs.
3. **`RecordNotUnique` on duplicate add raises a 500** — Use `first_or_initialize` on `(user_id, x_user_id)`; detect active vs. soft-deleted rows and respond with a flash. Rescue `ActiveRecord::RecordNotUnique` as a safety net.
4. **Resurrection path must unconditionally set `manually_added: true`** — Do not branch on `new_record?`; always assign `manually_added: true, deleted: false` in `upsert_manual!` regardless of whether the row is new or existing.
5. **WebMock does not cover `/2/users/by/username/` in Cucumber** — Register `WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/by\/username\//)` in the relevant Cucumber `Before` hook; without it scenarios fail with an opaque `NetConnectNotAllowedError`.

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Schema + Model (Migration and Refresh Fix)

**Rationale:** The `manually_added` column is a hard prerequisite for every other change. The `refresh_cache_from_items!` fix is load-bearing correctness work that must ship before any manually-added row can be created safely.
**Delivers:** `x_accounts.manually_added` column; `XAccount.upsert_manual!` class method; `refresh_cache_from_items!` guarded soft-delete loop; model validations
**Addresses:** Migration and refresh diff protection (FEATURES.md table stakes items)
**Avoids:** Pitfalls 1, 2, 7 (the three refresh-interaction bugs)

### Phase 2: XClient Service Method

**Rationale:** The controller action depends on `XClient#lookup_user_by_username` existing. Build and fully test the service method in isolation before wiring it into the controller.
**Delivers:** `XClient#lookup_user_by_username` public method; `parse_lookup_response` private method; full Minitest coverage (200, 404, 401, 429, 403, timeout, network, parse error)
**Uses:** Existing `connection_for`, `bearer_faraday`, `normalize_following_row`
**Avoids:** Pitfalls 4 (`@` stripping before URL path), 5 (exhaustive HTTP status handling including 403 for suspended accounts), 6 (store API-returned canonical username not raw input)

### Phase 3: Controller Action + Route + Locales

**Rationale:** Controller wires the service method to the web layer. Locale strings are included here because controller flash messages directly depend on them.
**Delivers:** `POST /x_accounts/lookup_and_add` route and action; all flash error/success states; `record_x_api_call` instrumentation; `ja.yml` and `en.yml` keys; controller integration tests covering all error states
**Implements:** `XAccountsController#lookup_and_add`
**Avoids:** Pitfalls 3 (duplicate add rescue), 7 (unconditional `manually_added: true` in upsert path), 8 (missing API call instrumentation)

### Phase 4: View Form

**Rationale:** The inline form is purely additive to the existing index view. Kept separate from Phase 3 so controller tests run independently of view rendering.
**Delivers:** Handle input form on `x_accounts/index.html.erb`; HTML `pattern` attribute for client-side UX; no JS; locale keys from Phase 3 rendered in the view
**Implements:** Architecture view component

### Phase 5: Cucumber E2E + Tri-suite Gate

**Rationale:** E2E scenarios depend on all previous phases. WebMock stub registration must be in place before the scenario runs.
**Delivers:** Happy-path Cucumber scenario (submit handle, account appears in list); "not found" error-state scenario; tri-suite green gate (lint + Minitest + Cucumber)
**Avoids:** Pitfall 9 (WebMock gap for new URL path)

### Phase Ordering Rationale

- Schema first: both the model class method and the refresh fix reference `manually_added?` — Rails raises `NoMethodError` if the column does not exist
- Service before controller: controller integration tests stub `XClient`; having the real method prevents stub drift
- View after controller: controller can be tested headlessly; the view adds the entry point
- Cucumber last: exercises the full stack end-to-end and catches any integration gaps from prior phases

### Research Flags

All phases use well-documented, established patterns. No phase requires additional research during planning.

- **Phase 1:** Standard Rails migration + `first_or_initialize` upsert; pattern already in codebase
- **Phase 2:** `XClient` method pattern established by `fetch_following`; Faraday `:test` adapter pattern established by existing service tests
- **Phase 3:** Controller action follows existing `refresh` action pattern exactly; all error symbols already have locale keys
- **Phase 4:** Standard `form_with` inline form; no JS; existing view structure is clear
- **Phase 5:** Cucumber Before hook stub pattern already exists for other X API paths

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Endpoint URL verified from official X docs; user OAuth2 token confirmed sufficient; zero new gems confirmed by codebase inspection |
| Features | HIGH | Must-haves derived from direct codebase read and X API v2 docs; no speculative features |
| Architecture | HIGH | Direct inspection of all modified files: `x_client.rb`, `x_account.rb`, `x_accounts_controller.rb`, `schema.rb`, routes, views, tests |
| Pitfalls | HIGH (critical 3) / MEDIUM (403 suspended accounts) | Refresh interaction pitfalls confirmed by direct code inspection; HTTP 403 for suspended accounts from community sources, not official API reference |

**Overall confidence:** HIGH

### Gaps to Address

- **HTTP 403 for suspended accounts:** Confirmed from X Developer Community forum threads, not the official API reference. Safe mitigation: map 403 to `:forbidden` in `parse_lookup_response` and add a locale key. If 403 is never returned in practice, the branch is harmless.
- **Rate limit figure (300 vs 900/15 min):** FEATURES.md cites 300; STACK.md cites 900. Both are secondary sources. At personal-use scale the exact figure is irrelevant — the `:rate_limited` path handles it regardless. No action needed during planning.
- **Total `x_accounts` row cap:** PITFALLS.md raises whether a per-user row cap is needed. Recommendation: no cap for v1.31 (personal app, low volume). Decide explicitly during Phase 1 planning and document the decision.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `app/services/x_client.rb`, `app/models/x_account.rb`, `app/controllers/x_accounts_controller.rb`, `db/schema.rb`, `config/routes.rb`, `test/` suite
- [X API v2: GET /2/users/by/username/{username}](https://docs.x.com/x-api/users/get-user-by-username) — endpoint URL, fields, auth types, response shape confirmed
- [X API v2: Rate Limits](https://docs.x.com/x-api/fundamentals/rate-limits) — user lookup rate limit window confirmed

### Secondary (MEDIUM confidence)
- [9meters.com X API rate limits reference](https://9meters.com/entertainment/social-media/x-api-rate-limits-formerly-twitter) — rate limit figure (900/15 min per STACK.md); independent source
- X Developer Community forum threads — HTTP 403 behavior for suspended accounts; not in official API reference excerpt retrieved

---

*Research completed: 2026-05-22*
*Ready for roadmap: yes*
