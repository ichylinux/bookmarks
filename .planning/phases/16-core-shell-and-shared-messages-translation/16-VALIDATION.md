---
phase: 16
slug: core-shell-and-shared-messages-translation
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `bin/rails test test/integration test/i18n` |
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

> Filled by planner — each task in PLAN.md must have an automated verify command or be tied to a Wave 0 dependency.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | TRN-01 / TRN-04 | — | N/A (UI translation) | integration | `bin/rails test test/integration/<file>` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/i18n/locale_parity_test.rb` — fails if a key exists in `config/locales/ja.yml` but not in `config/locales/en.yml` (or vice-versa) for the keys touched in Phase 16 (TRN-04 success criterion 4)
- [ ] `test/i18n/rails_i18n_smoke_test.rb` — asserts `I18n.t('errors.messages.blank', locale: :ja)` and `:en` resolve to non-missing strings (D-04 verification)
- [ ] `test/integration/locale_shell_test.rb` — stubs for TRN-01 (drawer/menu nav strings render in active locale)

*If existing infrastructure already covers any of these, Wave 0 task is "verify exists" rather than "create".*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Native-brand rule for `<title>Bookmarks</title>` and logo `alt` | D-06 carry-forward | Subjective brand decision | Visually inspect `/` in both locales; brand text remains "Bookmarks" |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (parity test, rails-i18n smoke test, shell integration test stubs)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for per-task quick run
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
