---
phase: 16
slug: core-shell-and-shared-messages-translation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails default) + ESLint + Cucumber |
| **Config file** | `test/test_helper.rb`, `.eslintrc.*`, `features/support/*` |
| **Quick run command** | `bin/rails test test/i18n/ test/controllers/application_controller_test.rb test/controllers/notes_controller_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~5–10 minutes (Cucumber dominates) |

---

## Sampling Rate

- **After every task commit:** Run targeted `bin/rails test <file>` for the test file added or modified by the task
- **After every plan wave:** Run `bin/rails test` (full Minitest) + `yarn run lint`
- **Before `/gsd-verify-work`:** Full suite must be green per CLAUDE.md (lint + Minitest + Cucumber). Cucumber re-run-once policy applies.
- **Max feedback latency:** ~30s for targeted Minitest, ~2min for full Minitest

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-T1 | 16-01 | 1 | TRN-01 | — | `nav.*` ja catalog exists before view substitution | static catalog | `bin/rails runner "I18n.t('nav.home', locale: :ja)"` / parity gate | ✅ | ✅ green |
| 16-01-T2 | 16-01 | 1 | TRN-01 / TRN-04 | — | `nav.*` and `flash.errors.generic` en catalog mirrors ja | static catalog | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ | ✅ green |
| 16-01-T3 | 16-01 | 1 | TRN-04 | — | ja/en locale files maintain matching key sets | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ | ✅ green |
| 16-01-T4 | 16-01 | 1 | TRN-04 | — | rails-i18n validation defaults resolve in ja/en | unit | `bin/rails test test/i18n/rails_i18n_smoke_test.rb` | ✅ | ✅ green |
| 16-02-T1 | 16-02 | 2 | TRN-01 | — | Drawer chrome consumes `nav.*` keys without changing DOM structure | integration / static | `bin/rails test test/controllers/application_controller_test.rb` | ✅ | ✅ green |
| 16-02-T2 | 16-02 | 2 | TRN-01 | — | Simple-theme menu consumes the same `nav.*` keys | integration / static | `bin/rails test test/controllers/application_controller_test.rb` | ✅ | ✅ green |
| 16-02-T3 | 16-02 | 2 | TRN-04 | — | Note create fallback alert calls `t('flash.errors.generic')` at request time | integration / static | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ | ✅ green |
| 16-03-T1 | 16-03 | 3 | TRN-01 | T-16-08 | Chrome integration tests assert ja/en nav and menu ARIA strings | integration | `bin/rails test test/controllers/application_controller_test.rb` | ✅ | ✅ green |
| 16-03-T2 | 16-03 | 3 | TRN-04 | T-16-08 | Flash catalog lookup resolves to ja/en shared generic strings | integration | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ | ✅ green |
| 16-03-T3 | 16-03 | 3 | TRN-01 / TRN-04 | T-16-07 | Full phase gate proves no lint, Rails, or Cucumber regression | lint + unit + e2e | `NODENV_VERSION=20.19.4 yarn run lint`; `bin/rails test`; `bundle exec rake dad:test` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/i18n/locales_parity_test.rb` — fails if a key exists in `config/locales/ja.yml` but not in `config/locales/en.yml` (or vice-versa) for Phase 16 shared locale keys
- [x] `test/i18n/rails_i18n_smoke_test.rb` — asserts `I18n.t('errors.messages.blank', locale: :ja)` and `:en` resolve to rails-i18n defaults
- [x] `test/controllers/application_controller_test.rb` — TRN-01 chrome assertions for drawer nav and menu ARIA in ja/en

*If existing infrastructure already covers any of these, Wave 0 task is "verify exists" rather than "create".*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Native-brand rule for `<title>Bookmarks</title>` and logo `alt` | D-06 carry-forward | Subjective brand decision | Visually inspect `/` in both locales; brand text remains "Bookmarks" |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (parity test, rails-i18n smoke test, shell integration tests)
- [x] No watch-mode flags
- [x] Feedback latency < 30s for per-task quick run
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — Phase 16 gate passed on 2026-05-01 (`NODENV_VERSION=20.19.4 yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`).
