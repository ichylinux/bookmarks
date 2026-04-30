---
phase: 11
slug: notes-controller
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-30
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest (integration + model from suite) |
| **Config file** | `test/test_helper.rb`, `ENV['RAILS_ENV']=test` |
| **Quick run command** | `bin/rails test test/controllers/notes_controller_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~60–120s full suite / ~5–15s focused controller test |

---

## Sampling Rate

- **After every task commit:** `bin/rails test test/controllers/notes_controller_test.rb`
- **After wave / plan completion:** `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite must be green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | NOTE-01 | T-11-01 | Only POST /notes route exposed for notes | integration | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | NOTE-01 | T-11-02 | Authenticated create scoped to `current_user` | integration | same | ✅ | ⬜ pending |
| 11-01-03 | 01 | 1 | NOTE-01 | T-11-03 | Unauthenticated POST redirected to sign-in | integration | same | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new test framework install.

---

## Manual-Only Verifications

*All phase behaviors have automated verification (per ROADMAP — Minitest before views).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when approved

**Approval:** pending
