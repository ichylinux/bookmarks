---
phase: 18
slug: auth-2fa-and-translation-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails default) + Cucumber (dad:test) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/controllers/ test/i18n/` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~30 seconds (quick), ~2 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/controllers/ test/i18n/`
- **After every plan wave:** Run full suite (`yarn run lint && bin/rails test && bundle exec rake dad:test`)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds (quick), 120 seconds (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | AUTHI18N-01 | — | Flash renders in request locale | integration | `bin/rails test test/controllers/users/sessions_controller_test.rb` | ✅ | ⬜ pending |
| 18-01-02 | 01 | 1 | AUTHI18N-01 | — | Layout renders flash[:alert] | integration | `bin/rails test test/controllers/users/sessions_controller_test.rb` | ✅ | ⬜ pending |
| 18-01-03 | 01 | 1 | AUTHI18N-03 | — | English locale shows EN flash | integration | `bin/rails test test/controllers/users/sessions_controller_test.rb` | ✅ | ⬜ pending |
| 18-02-01 | 02 | 1 | AUTHI18N-02 | — | 2FA pages render locale-keyed text | integration | `bin/rails test test/controllers/two_factor_authentication_controller_test.rb` | ✅ | ⬜ pending |
| 18-02-02 | 02 | 1 | VERI18N-02 | — | Representative EN/JA paths covered | integration | `bin/rails test test/controllers/` | ✅ | ⬜ pending |
| 18-03-01 | 03 | 2 | VERI18N-03 | — | Zero unexplained hardcoded JA literals | unit | `bin/rails test test/i18n/` | ✅ | ⬜ pending |
| 18-03-02 | 03 | 2 | VERI18N-04 | — | ja.yml/en.yml key parity maintained | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- `test/controllers/users/sessions_controller_test.rb` — extend with locale flash assertions
- `test/controllers/two_factor_authentication_controller_test.rb` — extend with locale assertions
- `test/i18n/locales_parity_test.rb` — already exists and passes; new keys must maintain parity

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sign-in page renders Japanese via devise-i18n engine (no local view) | AUTHI18N-01 | Visual confirmation of engine-served view | Boot server, visit `/users/sign_in`, verify `ログイン` heading |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (quick) / 120s (full)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
