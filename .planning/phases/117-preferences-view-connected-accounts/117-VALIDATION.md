---
phase: 117
slug: 117-preferences-view-connected-accounts
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 117 — Validation Strategy

> Retroactive Nyquist artifact — preferences Connected Accounts UI (VIEW-01–03).

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest + Cucumber (E2E in Phase 118) |
| **Config file** | `test/test_helper.rb`, `features/14.連携アカウント.feature` |
| **Quick run command** | `bin/rails test test/controllers/oauth_identities_controller_test.rb test/controllers/preferences_controller_test.rb -n /connected_accounts|form_auth/` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~15 seconds (targeted); ~3 minutes (tri-suite) |

## Sampling Rate

- **After every task commit:** Targeted controller tests above
- **After every plan wave:** `yarn run lint && bin/rails test`
- **Before `/gsd-verify-work`:** Full tri-suite green
- **Max feedback latency:** 180 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01 | 01 | 1 | VIEW-01 | T-117-01 | Connected Accounts section with 4 rows | integration | `bin/rails test test/controllers/preferences_controller_test.rb -n connected_accounts` | ✅ | ✅ green |
| 117-02 | 01 | 1 | VIEW-02 | T-117-04 | Linked/unlinked badges + disconnect buttons | integration + e2e | Minitest above; Phase 118 `features/14.連携アカウント.feature` | ✅ | ✅ green |
| 117-03 | 01 | 1 | VIEW-03 | — | ja/en locale key parity | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ | ✅ green |
| 117-04 | 01 | 1 | VIEW-02 | T-117-02 | Form disconnect when OAuth fallback exists | integration | `bin/rails test test/controllers/oauth_identities_controller_test.rb -n form_auth` | ✅ | ✅ green |
| 117-05 | 01 | 1 | VIEW-02 | T-117-02 | Form disconnect blocked as last auth method | integration | `bin/rails test test/controllers/oauth_identities_controller_test.rb -n form_auth` | ✅ | ✅ green |
| 117-06 | 01 | 1 | VIEW-02 | T-117-05 | Form disconnect no-op when already disabled | integration | `bin/rails test test/controllers/oauth_identities_controller_test.rb -n form_auth` | ✅ | ✅ green |

## Wave 0 Requirements

- [x] `test/controllers/oauth_identities_controller_test.rb` — form-auth destroy paths (added 2026-05-24)
- [x] `test/controllers/preferences_controller_test.rb` — `test_connected_accounts_section_renders_four_auth_rows`

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Disconnect button click → row becomes "Not connected" | VIEW-02 | Browser DOM transition | Phase 118 Cucumber `features/14.連携アカウント.feature` scenario 2 |

*E2E disconnect UX is owned by Phase 118; Minitest covers server + static render.*

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

*Gaps filled: 3× form-auth controller tests, 1× preferences connected-accounts render test.*

## Validation Sign-Off

- [x] All tasks have automated verify or documented manual E2E (Phase 118)
- [x] Sampling continuity maintained
- [x] Wave 0 gaps filled
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** retroactive — 2026-05-24
