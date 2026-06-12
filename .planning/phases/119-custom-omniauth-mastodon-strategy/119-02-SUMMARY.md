---
phase: 119-custom-omniauth-mastodon-strategy
plan: 02
subsystem: auth
tags: [omniauth, mastodon, oauth2, webmock, minitest]

requires:
  - phase: 119-01
    provides: strategy skeleton and Devise wiring
provides:
  - Dynamic instance site from session[:mastodon_instance]
  - Per-instance OAuth app registration via POST /api/v1/apps
  - verify_credentials uid and info in auth hash
  - WebMock-isolated strategy tests
affects: [120, 121]

tech-stack:
  added: []
  patterns: [session-scoped OAuth client credentials, WebMock strategy unit tests]

key-files:
  created: [test/lib/omniauth/strategies/mastodon_test.rb]
  modified: [lib/omniauth/strategies/mastodon.rb]

key-decisions:
  - "Session keys: mastodon_instance, mastodon_oauth_client_id, mastodon_oauth_client_secret"
  - "uid is raw account id string; composite {instance}:{id} deferred to Phase 121"

patterns-established:
  - "Strategy registers OAuth app in request_phase before authorize redirect"
  - "Unit tests call request_phase/callback_phase directly with WebMock stubs"

requirements-completed: [STRAT-02, STRAT-03, STRAT-04]

duration: 20min
completed: 2026-06-12
---

# Phase 119 Plan 02 Summary

**Full dynamic Mastodon OAuth2 strategy with app registration, verify_credentials identity, and WebMock Minitest coverage.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-12T18:25:00Z
- **Completed:** 2026-06-12T18:45:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Strategy reads `session[:mastodon_instance]` and sets `client.site` to `https://{instance}`
- `request_phase` POSTs `/api/v1/apps` and caches client_id/secret in session
- `callback_phase` fetches `/api/v1/accounts/verify_credentials` for uid and info
- Three WebMock tests cover registration redirect, callback auth hash, and missing instance failure

## Task Commits

1. **Task 1–2: Dynamic site, registration, verify_credentials** - `e047c02` (feat, combined with Plan 01 skeleton commit)
2. **Task 3: WebMock Minitest** - `fe6333f` (test)

## Files Created/Modified

- `lib/omniauth/strategies/mastodon.rb` - Full strategy implementation
- `test/lib/omniauth/strategies/mastodon_test.rb` - WebMock-isolated tests

## Deviations

- Full strategy implementation landed in the same commit as Plan 01 skeleton (`e047c02`) during inline execution; functionally complete before test commit.
- Fail-without-instance test asserts `env['omniauth.error']` after `Devise::MissingWarden` because fail! routes through Devise failure app without Warden in unit context.

## Self-Check: PASSED

- `grep mastodon_instance lib/omniauth/strategies/mastodon.rb` — PASS
- `grep /api/v1/apps lib/omniauth/strategies/mastodon.rb` — PASS
- `grep verify_credentials lib/omniauth/strategies/mastodon.rb` — PASS
- `bin/rails test test/lib/omniauth/strategies/mastodon_test.rb` — 3 runs, 0 failures
- `bin/rails test` — 624 runs, 0 failures
