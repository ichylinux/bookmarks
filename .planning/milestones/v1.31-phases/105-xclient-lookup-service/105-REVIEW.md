---
phase: 105-xclient-lookup-service
reviewed: 2026-05-22T14:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - app/services/x_client.rb
  - test/services/x_client_test.rb
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: clean
---

# Phase 105: Code Review Report (Final — after fix iterations)

**Reviewed:** 2026-05-22
**Depth:** standard
**Files Reviewed:** 2
**Status:** clean

## Summary

All Critical and Warning findings introduced by phase 105 are resolved. Two informational items remain (pre-existing or advisory — not introduced by this phase). One pre-existing test (`test_fetch_following_uses_bearer_when_oauth2_token_present`) has a structural flaw where the forced-connection injection bypasses `bearer_faraday`; this predates phase 105 and is noted as advisory only.

---

## Info

### IN-01: Redundant `[x, 5].max` before `.clamp(5, 100)` (pre-existing)

**File:** `app/services/x_client.rb:17`
`[max_results.to_i, 5].max.clamp(5, 100)` — `.clamp(5, 100)` already enforces the lower bound of 5. The `Array#max` call is dead. Pre-existing, out of fix scope.

### IN-02: Pre-existing forced-connection test pattern limits `bearer_faraday` coverage

**File:** `test/services/x_client_test.rb:75`
`test_fetch_following_uses_bearer_when_oauth2_token_present` injects a forced connection that bypasses `bearer_faraday`. The Authorization header asserted is the one injected by the test. Pre-existing pattern — advisory only, not introduced by phase 105.

---

## Resolved Findings

The following findings are confirmed resolved across iterations 1 and 2:

- **CR-01** (resolved in iteration 1): Username format validation `handle.match?(/\A\w{1,15}\z/)` is in place at `app/services/x_client.rb:85`, preventing path-traversal and injection.
- **WR-02** (resolved in iteration 1): `parse_lookup_response` contains a `when 401` branch returning `:unauthorized` at `app/services/x_client.rb:209-210`.
- **WR-03** (resolved in iteration 1): `lookup_user_by_username` rescue chain correctly distinguishes `:timeout` from `:network`; doc comment at line 80 lists both symbols; test assertions are consistent.

---

_Reviewed: 2026-05-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
