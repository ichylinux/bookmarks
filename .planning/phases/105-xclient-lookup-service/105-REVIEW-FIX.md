---
phase: 105-xclient-lookup-service
fixed_at: 2026-05-22T00:00:00Z
review_path: .planning/phases/105-xclient-lookup-service/105-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 105: Code Review Fix Report

**Fixed at:** 2026-05-22
**Source review:** .planning/phases/105-xclient-lookup-service/105-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (CR-01, WR-01, WR-02, WR-03)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Username interpolated into URL path without format validation

**Files modified:** `app/services/x_client.rb`
**Commit:** c4dfdc1
**Applied fix:** Added `return { success: false, error: :not_found } unless handle.match?(/\A\w{1,15}\z/)` guard after the blank check in `lookup_user_by_username`, with an explanatory comment. Prevents path-traversal and query-string injection via crafted username values.

### WR-01: `test_bearer_header_used_when_oauth2_token_present` tests its own setup, not XClient

**Files modified:** `test/services/x_client_test.rb`
**Commit:** 5e16e9e
**Applied fix:** Replaced the test (renamed to `test_bearer_header_sent_by_xclient`) so it routes through `XClient.new(connection: conn).fetch_following` rather than calling `conn.get` directly. The assertion now fires on the header that XClient actually sets, not one the test injected itself. Also added `assert_no_match(/oauth_consumer_key/, ...)` to preserve the intent of the original secondary assertion.

### WR-02: `parse_lookup_response` silently maps HTTP 401 to `:api_error` instead of `:unauthorized`

**Files modified:** `app/services/x_client.rb`
**Commit:** 7352b78
**Applied fix:** Added `when 401 then { success: false, error: :unauthorized }` branch to `parse_lookup_response`, placed between `when 400, 404` and `when 403`, consistent with the sibling parsers `parse_following_response` and `parse_tweets_response`.

### WR-03: `lookup_user_by_username` rescue maps network errors to `:api_error`, inconsistent with other public methods

**Files modified:** `app/services/x_client.rb`, `test/services/x_client_test.rb`
**Commit:** c4f8651
**Applied fix:** Split the rescue block to mirror `fetch_following`: `Faraday::TimeoutError, Faraday::ConnectionFailed` → `:timeout`; generic `Faraday::Error` → `:network`. Updated doc comment to list `:timeout` and `:network` alongside the other error symbols. Updated `test_lookup_user_timeout_returns_api_error` (renamed to `test_lookup_user_timeout_returns_timeout`) and `test_lookup_user_connection_failed_returns_api_error` (renamed to `test_lookup_user_connection_failed_returns_timeout`) to assert `:timeout` instead of `:api_error`.

**Verification:** `bin/rails test test/services/x_client_test.rb` — 15 runs, 31 assertions, 0 failures after all fixes applied.

---

_Fixed: 2026-05-22_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
