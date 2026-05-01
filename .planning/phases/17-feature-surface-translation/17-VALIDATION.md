---
phase: 17
slug: feature-surface-translation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails integration/model tests) + ESLint + Cucumber |
| **Config file** | `test/test_helper.rb`, `test/i18n/locales_parity_test.rb`, `features/support/*` |
| **Quick run command** | `bin/rails test test/i18n/locales_parity_test.rb test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/bookmarks_controller_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~5-10 minutes (Cucumber dominates) |

---

## Sampling Rate

- **After every task commit:** Run targeted `bin/rails test <changed test file>` plus `test/i18n/locales_parity_test.rb` when locale files change
- **After every plan wave:** Run `bin/rails test` and `yarn run lint` when JavaScript changed
- **Before `/gsd-verify-work`:** Full suite must be green per `CLAUDE.md`: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`
- **Max feedback latency:** ~30s for targeted Minitest, ~2min for full Minitest excluding Cucumber

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-T1 | 17-01 | 1 | TRN-02 / TRN-03 / TRN-05 | — | Locale key skeleton exists in both `ja.yml` and `en.yml` | static catalog | `bin/rails test test/i18n/locales_parity_test.rb` | yes | pending |
| 17-01-T2 | 17-01 | 1 | TRN-03 | — | Todo priority labels resolve at request time without changing numeric stored values | model/integration | `bin/rails test test/models/todo_test.rb test/controllers/preferences_controller_test.rb` | maybe add | pending |
| 17-01-T3 | 17-01 | 1 | TRN-03 | — | Calendar weekday/month display uses active locale while `holiday_jp` names remain unchanged | model/integration | `bin/rails test test/models/calendar_test.rb test/controllers/calendars_controller_test.rb` | maybe add | pending |
| 17-02-T1 | 17-02 | 2 | TRN-02 | — | Bookmark fixed labels/actions/help text localize; bookmark and folder names remain user content | integration | `bin/rails test test/controllers/bookmarks_controller_test.rb` | yes | pending |
| 17-03-T1 | 17-03 | 2 | TRN-03 | — | Note and Todo gadget fixed UI localizes; note/todo bodies remain user content | integration/e2e | `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/todos_controller_test.rb` | yes | pending |
| 17-04-T1 | 17-04 | 3 | TRN-03 / TRN-05 | — | Feed fixed labels and JS-visible alert/error text come from server-rendered translated values | integration + lint | `bin/rails test test/controllers/feeds_controller_test.rb && yarn run lint` | maybe add | pending |
| 17-04-T2 | 17-04 | 3 | TRN-03 | — | Calendar gadget month/weekday/loading/action copy localizes; record titles and holidays remain unchanged | integration | `bin/rails test test/controllers/calendars_controller_test.rb` | maybe add | pending |
| 17-05-T1 | 17-05 | 4 | TRN-02 / TRN-03 / TRN-05 | — | Representative bilingual feature paths pass and no Cucumber regression remains | lint + unit + e2e | `yarn run lint && bin/rails test && bundle exec rake dad:test` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [x] `test/i18n/locales_parity_test.rb` — existing key parity test must cover every new Phase 17 key added to `ja.yml` / `en.yml`
- [x] `test/controllers/bookmarks_controller_test.rb` — representative `ja` and `en` assertions for bookmark UI labels plus unchanged user content
- [x] `test/controllers/welcome_controller/welcome_controller_test.rb` — representative `ja` and `en` assertions for gadget titles, note/todo copy, and unchanged user content
- [x] `test/controllers/feeds_controller_test.rb` or equivalent — assertions for server-rendered `data-*` JavaScript messages
- [x] `test/controllers/calendars_controller_test.rb` or equivalent — assertions for localized weekday/month UI and intentionally untranslated `holiday_jp` names

*Existing infrastructure covers Rails integration tests, locale parity, ESLint, and Cucumber execution. Phase 17 may add focused assertions to existing files rather than creating a separate test framework.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| English wording quality for newly translated feature labels | TRN-02 / TRN-03 / TRN-05 | Automated tests can prove locale selection and key presence, but not product copy quality | Inspect bookmark, note, todo, feed, and calendar surfaces in `en` locale after implementation |
| Japanese holiday names remain intentionally untranslated in English calendar UI | TRN-03 | This is a product boundary decision rather than a translation failure | Inspect an English calendar view containing a `holiday_jp` holiday and confirm the surrounding UI is English while the holiday name remains Japanese |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references for TRN-02, TRN-03, and TRN-05
- [x] No watch-mode flags
- [x] Feedback latency < 30s for targeted Minitest
- [x] `nyquist_compliant: true` set in frontmatter once the final Phase 17 plan maps tasks to this strategy

**Approval:** approved 2026-05-01 — Phase 17 plans map every validation sample to automated targeted checks plus the full `CLAUDE.md` gate.
