---
phase: 119-custom-omniauth-mastodon-strategy
reviewed: 2026-06-12T18:50:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - Gemfile
  - lib/omniauth/strategies/mastodon.rb
  - config/application.rb
  - config/initializers/devise.rb
  - app/models/user.rb
  - test/lib/omniauth/strategies/mastodon_test.rb
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
findings_fixed:
  critical: 0
  warning: 3
  info: 1
status: clean
fix_notes: "WR-01/WR-02 fixed (instance-scoped credential cache + skip re-registration); WR-03 fixed (parse_registration_response! with JSON/missing-field handling); IN-02 fixed (comment indentation). IN-01 intentionally skipped — hostname validation is Phase 120 scope."
---

# Phase 119: Code Review Report

**Reviewed:** 2026-06-12T18:50:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** clean (post-fix re-review)

## Summary

Phase 119 delivers a custom `OmniAuth::Strategies::Mastodon` OAuth2 strategy with dynamic instance targeting, per-instance app registration, Devise/User wiring, and WebMock unit tests. The overall architecture matches the phase plan and existing OAuth patterns. Three warnings were found in the strategy implementation around idempotent registration, error handling for malformed registration responses, and stale session credentials when the target instance changes. Two info items note deferred hostname validation (Phase 120) and minor style inconsistency.

## Warnings

### WR-01: `register_application!` Re-registers on Every `request_phase` — Orphan OAuth Apps

**File:** `lib/omniauth/strategies/mastodon.rb:74-93`

**Issue:** `register_application!` unconditionally POSTs to `/api/v1/apps` on every login attempt, even when valid `client_id`/`client_secret` are already cached in session for the same instance. Each retry creates a new OAuth application on the target Mastodon instance, polluting the instance with orphaned apps and adding unnecessary latency.

**Fix:** Skip registration when session credentials exist for the current `mastodon_instance`; re-register only when the instance changes or credentials are absent.

### WR-02: Stale Session Credentials Not Invalidated on Instance Change

**File:** `lib/omniauth/strategies/mastodon.rb:56-62,74-93`

**Issue:** `client_id` and `client_secret` are cached in session but not tied to `session[:mastodon_instance]`. If a user changes the target instance between attempts (Phase 120 form), the strategy may reuse credentials registered against a different instance while pointing `client.site` at the new host, causing authorization failures or confusing error states.

**Fix:** Track which instance the cached credentials belong to (e.g. `session[:mastodon_oauth_instance]`) and clear or re-register when `mastodon_instance` differs.

### WR-03: `JSON.parse` and Missing Fields in Registration Response Are Unhandled

**File:** `lib/omniauth/strategies/mastodon.rb:90-92`

**Issue:** A 2xx response with non-JSON body raises `JSON::ParserError` outside the OmniAuth failure path, surfacing as a 500. A JSON body missing `client_id` or `client_secret` silently stores nil values and falls through to Devise placeholder credentials, producing opaque OAuth errors later.

**Fix:** Rescue `JSON::ParserError` with `fail!(:invalid_credentials, ...)` and validate both fields are present before caching.

## Info

### IN-01: Hostname Validation Deferred to Phase 120 (Expected)

**File:** `lib/omniauth/strategies/mastodon.rb:68-72`

**Issue:** `validate_mastodon_instance!` only checks presence, not hostname format or SSRF safety. This is intentional per phase boundary — Phase 120 will normalize and validate the instance form input.

### IN-02: Misaligned Module Comment Indentation

**File:** `lib/omniauth/strategies/mastodon.rb:7-9`

**Issue:** The class comment sits at `module Strategies` indentation level instead of above or inside the class, reducing readability.

---

_Reviewed: 2026-06-12T18:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
