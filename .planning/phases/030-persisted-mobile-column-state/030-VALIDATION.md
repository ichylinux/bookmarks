---
phase: 30
slug: persisted-mobile-column-state
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 30 — Validation Strategy

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
- **After every plan wave:** Run `bin/rails test` and `bundle exec rake dad:test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 030-01-01 | 01 | 1 | STATE-02 | T-030-01 / — | Column selection persists to `portalMobileActiveColumn` only through shared activation flow | static contract | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb` | ✅ | ✅ green |
| 030-01-02 | 01 | 1 | STATE-03 | T-030-02 / — | Invalid or missing saved value falls back to first column without breakage | static contract + e2e | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb && bundle exec rake dad:test` | ✅ | ✅ green |
| 030-01-03 | 01 | 1 | UXA-03 | T-030-03 / — | Restore and fallback behavior remains consistent in mobile UX scenarios | e2e | `bundle exec rake dad:test` | ✅ | ✅ green |
| 030-01-04 | 01 | 1 | STATE-02, STATE-03, UXA-03 | T-030-04 / — | Tri-suite regression gate validates integrated behavior end-to-end | integration | `yarn run lint && bin/rails db:test:prepare && bin/rails test && bundle exec rake dad:test` | ✅ | ✅ green |

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
