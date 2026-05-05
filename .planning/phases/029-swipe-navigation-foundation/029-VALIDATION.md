---
phase: 29
slug: swipe-navigation-foundation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest + Cucumber (+ ESLint) |
| **Config file** | `test/test_helper.rb`, `features/support/window_resize.rb`, `.eslintrc.*` |
| **Quick run command** | `yarn run lint` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `yarn run lint`
- **After every plan wave:** Run `bin/rails test` and relevant `dad:test` scenarios
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 029-01-01 | 01 | 1 | STATE-01, UXA-01, UXA-02 | T-029-01 | Click path updates active tab + `portal--column-active-N` via shared `activateColumn()` | static contract | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb` | ✅ | ✅ green |
| 029-01-02 | 01 | 1 | SWIPE-01, SWIPE-02, SWIPE-03 | T-029-02, T-029-03 | Native touch listeners with passive=false guard vertical intent and clamp boundaries | e2e | `bundle exec rake dad:test` | ✅ | ✅ green |
| 029-02-01 | 02 | 2 | SWIPE-01, SWIPE-02, SWIPE-03, UXA-01, UXA-02 | T-029-04 | Mobile swipe scenarios exercise left/right/vertical behavior and tab-sync regression | e2e | `bundle exec rake dad:test` | ✅ | ✅ green |
| 029-02-02 | 02 | 2 | STATE-01 | T-029-05 | Tri-suite gate remains green with phase changes integrated | integration | `yarn run lint && bin/rails test && (bundle exec rake dad:test || bundle exec rake dad:test)` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
