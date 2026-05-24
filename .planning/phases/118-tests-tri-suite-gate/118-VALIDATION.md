---
phase: 118
slug: 118-tests-tri-suite-gate
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 118 — Validation Strategy

> Retroactive Nyquist artifact — v1.34 E2E coverage + tri-suite gate (TEST-01, TEST-02).

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Cucumber 9 + Capybara + Selenium (`dad:test`); Rails Minitest (cross-phase) |
| **Config file** | `features/14.連携アカウント.feature`, `features/support/hooks.rb`, `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/models/oauth_identity_test.rb test/models/user_password_auth_test.rb test/controllers/oauth_identities_controller_test.rb test/controllers/preferences_controller_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~30 seconds (Minitest bundle); ~3 minutes (tri-suite) |

## Sampling Rate

- **After every task commit:** Minitest bundle above (Phases 114–117 surfaces)
- **After every plan wave / before verify-work:** Full tri-suite
- **Max feedback latency:** 180 seconds (Minitest); 300 seconds (tri-suite)

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 118-T1 | 01 | 1 | TEST-02 | T-118-03 | 4 auth rows visible on preferences | e2e | `bundle exec rake dad:test` (scenario 1) | ✅ | ✅ green |
| 118-T2 | 01 | 1 | TEST-02 | T-118-04 | OAuth disconnect → row shows unlinked | e2e | `bundle exec rake dad:test` (scenario 2) | ✅ | ✅ green |
| 118-T3 | 01 | 1 | TEST-02 | T-118-03 | Last-auth disconnect shows error, stays linked | e2e | `bundle exec rake dad:test` (scenario 3) | ✅ | ✅ green |
| 118-T4 | 01 | 1 | TEST-02 | T-118-06 | `@connected_accounts` hook seeds/cleans test data | e2e | `features/support/hooks.rb` + dad:test | ✅ | ✅ green |
| 118-T5 | 01 | 1 | TEST-02 | — | Step definitions wire UI actions | e2e | `features/step_definitions/connected_accounts.rb` | ✅ | ✅ green |
| 118-T6 | 01 | 1 | TEST-01 | T-118-01–05 | Minitest covers model/controller/view paths | unit + integration | `bin/rails test` (591 runs) | ✅ | ✅ green |
| 118-T7 | 01 | 1 | TEST-01, TEST-02 | — | Tri-suite gate | integration | `yarn run lint && bin/rails test && bundle exec rake dad:test` | ✅ | ✅ green |

### TEST-01 Minitest bundle (implemented Phases 114–117)

| Surface | Test file | Runs |
|---------|-----------|------|
| `OauthIdentity` model + `from_omniauth` | `test/models/oauth_identity_test.rb` | 10 |
| `password_auth_enabled` lifecycle | `test/models/user_password_auth_test.rb` | 5 |
| Disconnect controller (OAuth + form) | `test/controllers/oauth_identities_controller_test.rb` | 8 |
| Connected Accounts section render | `test/controllers/preferences_controller_test.rb` | 1+ |
| Locale key parity | `test/i18n/locales_parity_test.rb` | 1 |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test stubs required.

## Manual-Only Verifications

All phase behaviors have automated verification.

*Isolated `@connected_accounts` runs are not supported — use full `bundle exec rake dad:test` per `CLAUDE.md`.*

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Tri-suite re-verified:** lint ✓ · `bin/rails test` 591/591 ✓ · `dad:test` 38/38 ✓

## Validation Sign-Off

- [x] All tasks have automated verify
- [x] Sampling continuity maintained
- [x] Wave 0 covers all requirements
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** retroactive — 2026-05-24
