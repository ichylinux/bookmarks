---
phase: 13
slug: note-gadget-integration-tests
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest + Cucumber/Capybara |
| **Config file** | `test/test_helper.rb`, `features/support/env.rb` |
| **Quick run command** | `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/welcome_controller/layout_structure_test.rb test/controllers/notes_controller_test.rb` |
| **Full suite command** | `bin/rails test && cucumber features/04.ノート.feature` |
| **Estimated runtime** | ~60 seconds for focused checks; full suite depends on browser startup |

---

## Sampling Rate

- **After every task commit:** Run the focused command relevant to touched files.
- **After every plan wave:** Run `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/welcome_controller/layout_structure_test.rb test/controllers/notes_controller_test.rb` plus `cucumber features/04.ノート.feature` once the Cucumber feature exists.
- **Before `/gsd-verify-work`:** Focused Minitest checks and the note Cucumber feature must be green.
- **Max feedback latency:** ~60 seconds for focused Rails checks; Cucumber may be slower due to browser startup.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | NOTE-02 | — | Notes queried through `current_user.notes.recent` only | controller | `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb` | ✅ | ⬜ pending |
| 13-02-01 | 02 | 1 | NOTE-02, NOTE-03 | — | Other users' notes do not render in the Note tab | controller | `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb` | ✅ | ⬜ pending |
| 13-03-01 | 03 | 2 | NOTE-02 | — | Browser save flow returns to `?tab=notes` and shows new note | cucumber | `cucumber features/04.ノート.feature` | ❌ W0 | ⬜ pending |
| 13-04-01 | 04 | 1 | Folded todos | — | Simple theme does not render hidden drawer DOM | controller | `bin/rails test test/controllers/welcome_controller/layout_structure_test.rb` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers Rails controller tests. Phase execution must create:

- [ ] `features/04.ノート.feature` — Cucumber save-flow scenario for Phase 13.
- [ ] `features/step_definitions/notes.rb` — step definitions for the note save flow.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-04-30
