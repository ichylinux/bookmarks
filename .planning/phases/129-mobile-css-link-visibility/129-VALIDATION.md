---
phase: 129
slug: mobile-css-link-visibility
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
---

# Phase 129 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (CSS contract test in Phase 130) + Cucumber (via daddy/cucumber-rails) |
| **Config file** | `test/test_helper.rb` (Minitest); `features/support/env.rb` (Cucumber) |
| **Quick run command** | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run contract tests
- **After every plan wave:** Run full test suite
- **Before `/gsd-verify-work`:** Full suite must be green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 129-01-01 | 01 | 0 | MOB-01, MOB-02, MOB-04 | CSS & layout validation | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` | ✅ yes | ✅ green |
| 129-01-02 | 01 | 0 | MOB-03 | view scope wrapping | `bin/rails test` | ✅ yes | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `app/assets/stylesheets/welcome.css.scss` contains `@media (hover: none)` block for `.todo-gadget-new-link`
- [x] `app/assets/stylesheets/todos.css.scss` contains mobile overrides
- [x] `app/views/todos/new.html.erb` and `app/views/todos/edit.html.erb` have `.todo` class wrappers

---

## Manual-Only Verifications

*All phase behaviors are validated by the tri-suite (contract test + Cucumber mobile portal specs).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
