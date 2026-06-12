---
phase: 119-custom-omniauth-mastodon-strategy
fixed: 2026-06-12T18:55:00Z
iteration: 1
findings_addressed:
  critical: 0
  warning: 3
  info: 1
  skipped: 1
status: fixed
---

# Phase 119: Code Review Fix Report

**Fixed:** 2026-06-12T18:55:00Z
**Iteration:** 1

## Fixes Applied

### WR-01 + WR-02: Idempotent registration with instance-scoped cache

**File:** `lib/omniauth/strategies/mastodon.rb`

- Added `oauth_credentials_cached_for_current_instance?` guard to skip `/api/v1/apps` when credentials exist for the current instance
- Store `session[:mastodon_oauth_instance]` alongside client credentials; re-register when instance changes

### WR-03: Registration response validation

**File:** `lib/omniauth/strategies/mastodon.rb`

- Extracted `parse_registration_response!` with `JSON::ParserError` rescue and missing-field validation via `fail!(:invalid_credentials, ...)`

### IN-02: Comment indentation

**File:** `lib/omniauth/strategies/mastodon.rb`

- Moved class comment to proper indentation inside `module Strategies`

## Tests Added

**File:** `test/lib/omniauth/strategies/mastodon_test.rb`

- `test_request_phase_skips_registration_when_credentials_cached_for_same_instance`
- `test_request_phase_reregisters_when_instance_changes`
- Assertion for `mastodon_oauth_instance` in registration test

## Skipped

### IN-01: Hostname validation

Deferred to Phase 120 per phase boundary — no change in this fix pass.

## Verification

- `bin/rails test test/lib/omniauth/strategies/mastodon_test.rb` — 5 runs, 0 failures
