---
phase: 127
slug: header-integrated-task-completion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 127 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (ActionDispatch::IntegrationTest) + ESLint + Cucumber |
| **Config file** | test/test_helper.rb; .eslintrc; features/ (dad:test) |
| **Quick run command** | `bin/rails test test/integration/dashboard_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~120 seconds (Minitest) + Cucumber spawn |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/integration/dashboard_test.rb` + `yarn run lint`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd-verify-work`:** Full tri-suite must be green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 127-01-01 | 01 | 1 | LAY-01, HDR-01 | — | N/A | structure | `bin/rails test test/integration/dashboard_test.rb` | ✅ | ⬜ pending |
| 127-01-02 | 01 | 1 | HDR-02, HDR-03, SEL-01, SEL-02 | — | empty-selection no-op | manual+lint | `yarn run lint` | ✅ | ⬜ pending |
| 127-01-03 | 01 | 1 | I18N-01 | — | N/A | i18n parity | `bin/rails test test/i18n_parity_test.rb` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* (Minitest, ESLint, Cucumber already configured. dashboard_test.rb assertions on `.todo_actions a` must be updated in-phase.)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live count update on row select/deselect (jQuery DOM) | HDR-03 | DOM-interaction not covered by Minitest structure tests | Phase 128 Cucumber E2E covers select→complete; manual browser check that count text follows selection in welcome gadget |
| 完了 link visibility toggle at 0↔1 selected | HDR-02 | JS display toggle | Phase 128 Cucumber / manual; structure test asserts presence in DOM |

*Full E2E automation deferred to Phase 128 (Cucumber).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
