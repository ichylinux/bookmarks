---
phase: 14
slug: locale-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest 5.x with `ActionDispatch::IntegrationTest` |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `rails test test/controllers/application_controller_test.rb test/models/preference_test.rb` |
| **Full suite command** | `rails test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `rails test test/controllers/application_controller_test.rb test/models/preference_test.rb`
- **After every plan wave:** Run `rails test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Migration | 01 | 1 | I18N-01 | — | N/A | schema check | `rails db:migrate && rails db:schema:dump` | ✅ | ⬜ pending |
| SUPPORTED_LOCALES + validates | 01 | 1 | I18N-01, I18N-03 | T-14-01 | Invalid locale rejected at model write time | unit | `rails test test/models/preference_test.rb` | ✅ exists (add method) | ⬜ pending |
| config.i18n.available_locales | 01 | 1 | I18N-03 | T-14-01 | Unsupported locale assignment raises before pipeline guards it | boot check | `rails runner 'puts I18n.available_locales'` | ✅ | ⬜ pending |
| Localization concern | 02 | 1 | I18N-02, I18N-03 | T-14-01 | Whitelist check prevents InvalidLocale exception; pipeline returns :ja on all invalid inputs | integration | `rails test test/controllers/application_controller_test.rb` | ❌ W0 | ⬜ pending |
| ApplicationController include | 02 | 1 | I18N-02 | — | N/A | integration | `rails test test/controllers/application_controller_test.rb` | ❌ W0 | ⬜ pending |
| html lang layout change | 02 | 1 | I18N-04 | — | N/A | integration | `rails test test/controllers/application_controller_test.rb` | ❌ W0 | ⬜ pending |
| Integration tests (4 paths) | 03 | 1 | VERI18N-01 | T-14-01 | All 4 resolution paths verified via assert_select | integration | `rails test test/controllers/application_controller_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/controllers/application_controller_test.rb` — 4 integration test stubs for VERI18N-01 (I18N-02 paths 1+2, I18N-03, default :ja)

*`test/models/preference_test.rb` already exists — add one method, no Wave 0 stub needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Devise flash messages appear in resolved locale on sign-in redirect | I18N-02 | Requires live browser; flash message locale depends on around_action ordering under redirect flow | Sign in as English-locale user; verify Devise flash is in English |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
