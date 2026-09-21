---
phase: 130
slug: test-coverage-tri-suite-gate
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 7.2 built-in) + Cucumber (via daddy/cucumber-rails) |
| **Config file** | `test/test_helper.rb` (Minitest); `features/support/env.rb` (Cucumber) |
| **Quick run command** | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~180 seconds (Cucumber headless Chrome) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb`
- **After every plan wave:** Run `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~10 seconds (Minitest only); ~180 seconds (full Cucumber)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 130-01-01 | 01 | 0 | TEST-01 | unit (CSS contract) | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` | ✅ yes | ✅ green |
| 130-01-02 | 01 | 0 | TEST-02, TEST-03 | E2E (Cucumber @mobile_portal) | `bundle exec rake dad:test` | ✅ (extend existing) | ✅ green |
| 130-01-03 | 01 | 0 | TEST-01, TEST-02, TEST-03 | tri-suite gate | `yarn run lint && bin/rails test && bundle exec rake dad:test` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/assets/todo_gadget_mobile_css_contract_test.rb` — covers TEST-01 (Minitest CSS contract test)

*Cucumber infrastructure (window_resize.rb, modern_theme.rb step definitions, todos.rb step definitions) already exists — no Wave 0 additions needed for TEST-02/TEST-03.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
