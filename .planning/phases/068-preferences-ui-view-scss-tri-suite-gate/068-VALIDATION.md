---
phase: 068
slug: preferences-ui-view-scss-tri-suite-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-15
---

# Phase 068 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 7.2 built-in) + Cucumber (daddy gem via `bundle exec rake dad:test`) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/controllers/preferences_controller_test.rb test/i18n/locales_parity_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~60s (Minitest) + ~120s (Cucumber) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/controllers/preferences_controller_test.rb test/i18n/locales_parity_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite (`yarn run lint && bin/rails test && bundle exec rake dad:test`) must be green
- **Max feedback latency:** ~60 seconds (Minitest only)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 068-01-01 | 01 | 1 | COL-02, COL-03 | portal_column_count filtered by strong params; out-of-range rejected by model validation | integration | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ (existing file) | ⬜ pending |
| 068-01-02 | 01 | 1 | COL-05 | HTML class attribute leaks column count — non-sensitive UI state | integration | `bin/rails test test/controllers/preferences_controller_test.rb` | ✅ (existing file) | ⬜ pending |
| 068-02-01 | 02 | 2 | COL-07 | N/A | unit/integration | `bin/rails test test/controllers/preferences_controller_test.rb test/controllers/welcome_controller/layout_structure_test.rb` | ✅ (existing files) | ⬜ pending |
| 068-02-02 | 02 | 2 | COL-08 | Cucumber scenario validates end-to-end form submit + reload | E2E | `yarn run lint && bin/rails test && bundle exec rake dad:test` | ✅ (new file) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `features/07.設定.feature` — new file; Cucumber scenario for portal_column_count save+reload
- [ ] `features/step_definitions/preferences.rb` — two new step definitions added to existing file

*All other test infrastructure (Minitest, LocalesParityTest, layout_structure_test.rb) is pre-existing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Portal renders 4 columns visually on desktop | COL-05 | CSS rendering requires browser; not covered by Minitest assert_select alone | Sign in, set portal_column_count=4, visit `/`, confirm 4 portal-column sections are visible side-by-side at viewport ≥768px |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
