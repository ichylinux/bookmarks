---
phase: 31
slug: verification-gate
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 31 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest + Cucumber + ESLint |
| **Config file** | `test/test_helper.rb`, `features/`, `.eslintrc*` |
| **Quick run command** | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~300 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb`
- **After every plan wave:** Run `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | REQ-31-01 Cross-theme revisit restore works for modern/classic/simple | -- | Theme change does not bypass mobile column restore logic | e2e | `bundle exec rake dad:test` | ✅ | ✅ green |
| 31-01-02 | 01 | 1 | REQ-31-02 Invalid persisted column falls back to first column and mobile-only guard remains intact | -- | Invalid localStorage values cannot force out-of-range activation | unit/contract | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb` | ✅ | ✅ green |
| 31-01-03 | 01 | 1 | REQ-31-03 Existing tab click/sync behavior remains regression-safe alongside swipe transitions | -- | Tab state, ARIA, and portal class sync stay consistent | unit/contract + e2e | `bin/rails test test/assets/portal_mobile_tabs_js_contract_test.rb && bundle exec rake dad:test` | ✅ | ✅ green |

*Status: ⬜ pending / ✅ green / ❌ red / ⚠ flaky*

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
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
