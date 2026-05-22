---
phase: 105-xclient-lookup-service
plan: "01"
subsystem: service
tags: [xclient, api, minitest, tdd]
dependency_graph:
  requires: []
  provides: [XClient#lookup_user_by_username, XClient#parse_lookup_response]
  affects: [app/services/x_client.rb, test/services/x_client_test.rb]
tech_stack:
  added: []
  patterns: [Faraday :test adapter injection, case res.status parser, normalize_following_row reuse]
key_files:
  modified:
    - app/services/x_client.rb
    - test/services/x_client_test.rb
decisions:
  - "lookup_user_by_username routes through following_connection(user) not connection_for(user) to honour injected test stubs"
  - "parse_lookup_response uses item: (singular) key to match Phase 106 result[:item] read contract"
  - "HTTP 400 treated same as 404 — maps to :not_found (bad handle format = not found)"
  - "Faraday::TimeoutError and ConnectionFailed both map to :api_error (not :timeout/:network as in fetch_following)"
metrics:
  duration_minutes: 3
  completed_date: "2026-05-22"
  tasks_completed: 3
  files_modified: 2
requirements_completed: [XSVC-01, XSVC-02]
---

# Phase 105 Plan 01: XClient Lookup Service Summary

**One-liner:** `XClient#lookup_user_by_username` with `parse_lookup_response` private parser — 7-symbol error contract via Faraday :test adapter, 8 new Minitest cases.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1+2 | Add lookup_user_by_username + parse_lookup_response | f864188 | app/services/x_client.rb |
| 3 | Add 8 Minitest cases for lookup_user_by_username | 63d12fd | test/services/x_client_test.rb |

## What Was Built

### Public method: `XClient#lookup_user_by_username(user:, username:)`

- Strips leading `@` from `username` via `sub(/\A@/, '').presence`; returns `{ success: false, error: :not_found }` for blank handle without making an HTTP call
- Issues `GET /2/users/by/username/{handle}` via `following_connection(user)` (consults `@forced_connection` for test stub injection)
- Sets `user.fields=id,name,username,profile_image_url,protected` query param
- Delegates to `parse_lookup_response(res)` and returns its result
- Rescue chain: `Faraday::TimeoutError, Faraday::ConnectionFailed` first → `:api_error`; then `Faraday::Error` → `:api_error`

### Private method: `XClient#parse_lookup_response(res)`

| Status | Return |
|--------|--------|
| 200 + valid Hash body + Hash data | `{ success: true, item: normalize_following_row(body['data']) }` |
| 200 + non-Hash body | `{ success: false, error: :parse_error }` |
| 200 + missing/non-Hash data | `{ success: false, error: :not_found }` |
| 400, 404 | `{ success: false, error: :not_found }` |
| 403 | `{ success: false, error: :suspended }` |
| 429 | `{ success: false, error: :rate_limited }` |
| else | `{ success: false, error: :api_error }` |

### Tests: 8 new Minitest cases

All use Faraday `:test` adapter injected via `XClient.new(connection: conn)` and fixture `users(:twitter_user)`:

1. `test_lookup_user_returns_item_on_200` — 200 success; asserts `item[:username]` and `item[:id]` from API body
2. `test_lookup_user_strips_at_prefix` — stub path regex without `@`; input `'@foobar'` still succeeds
3. `test_lookup_user_404_returns_not_found`
4. `test_lookup_user_400_returns_not_found`
5. `test_lookup_user_403_returns_suspended`
6. `test_lookup_user_429_returns_rate_limited`
7. `test_lookup_user_timeout_returns_api_error`
8. `test_lookup_user_connection_failed_returns_api_error`

## Verification

- `bin/rails test test/services/x_client_test.rb` — 15 runs, 30 assertions, 0 failures, 0 errors
- `bin/rails test` — 540 runs, 2372 assertions, 0 failures, 0 errors, 0 skips
- `yarn run lint` — green (no JS changes)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes. Threat register T-105-01 through T-105-SC applied as designed:
- `parse_json_safe` returns nil on malformed JSON
- `body['data']` is type-guarded with `is_a?(Hash)` before `normalize_following_row`
- `normalize_following_row` coerces all fields with `.to_s` / boolean cast

## Self-Check: PASSED

- `app/services/x_client.rb` contains `def lookup_user_by_username` — FOUND
- `app/services/x_client.rb` contains `def parse_lookup_response` — FOUND
- `test/services/x_client_test.rb` contains 8 `test_lookup_user*` methods — FOUND (grep -c returns 8)
- Commit f864188 exists — FOUND
- Commit 63d12fd exists — FOUND
