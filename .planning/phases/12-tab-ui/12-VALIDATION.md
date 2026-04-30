---
phase: 12
slug: tab-ui
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-30
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest + `ActionDispatch::IntegrationTest` |
| **Config file** | none — Rails default test configuration |
| **Quick run command** | `bin/rails test test/controllers/welcome_controller/ test/controllers/notes_controller_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~60 seconds targeted, project-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/controllers/welcome_controller/ test/controllers/notes_controller_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds for targeted checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | TAB-01 | — | N/A | integration | `bin/rails test test/controllers/welcome_controller/` | W0 | pending |
| 12-01-02 | 01 | 1 | TAB-02 | — | Tab buttons do not navigate or submit forms | integration/manual UAT | `bin/rails test test/controllers/welcome_controller/` | W0 | pending |
| 12-01-03 | 01 | 1 | TAB-03 | T-12-01 | `tab` query is treated as an allowlisted state (`notes` or home default), never reflected raw | integration | `bin/rails test test/controllers/welcome_controller/ test/controllers/notes_controller_test.rb` | W0 | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `test/controllers/welcome_controller/` — add or extend tests for simple-theme tab labels, non-simple absence, and `tab=notes` initial state
- [ ] `test/controllers/notes_controller_test.rb` — keep existing redirect coverage for `root_path(tab: 'notes')`
- [ ] Manual or browser-level check for "no page reload" if the existing test stack cannot prove client-side behavior

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clicking between Home and Note does not reload the page | TAB-02 | Rails integration tests cannot directly observe browser-side reloads without a system/browser driver | Sign in with simple theme, open welcome page, click `ノート`, then `ホーム`; confirm panels switch immediately and the address bar does not change |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-30
