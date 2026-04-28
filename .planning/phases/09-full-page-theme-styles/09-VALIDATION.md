---
phase: 9
slug: full-page-theme-styles
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-29
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for CSS/theme work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest (ActiveSupport::TestCase) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/assets/modern_full_page_theme_contract_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~10–30 seconds |

---

## Sampling Rate

- **After every task commit:** Run contract test file + `yarn run lint` if JS touched (Phase 9: SCSS only — lint optional)
- **After plan complete:** `bin/rails test`
- **Before UAT:** Full suite green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 9-01 T1 | 01 | 1 | STYLE-01 | T-9-01 / — | N/A — presentation only | asset grep | `bin/rails test test/assets/modern_full_page_theme_contract_test.rb` | ✅ | ⬜ pending |
| 9-01 T2 | 01 | 1 | STYLE-02 | — | N/A | asset grep | same | ✅ | ⬜ pending |
| 9-01 T3 | 01 | 1 | STYLE-03 | — | N/A | asset grep | same | ✅ | ⬜ pending |
| 9-01 T4 | 01 | 1 | STYLE-04 | — | N/A | asset grep + manual spot | same + checklist | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers phase requirements — Wave 0 stubs not needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| No visible `#AAA` band in header | STYLE-01 | Colour perception | Sign in, modern theme, visually confirm header uses token blue / contrast |
| Form focus rings visible | STYLE-04 | Browser paint | Tab through Preferences fields |

---

## Validation Sign-Off

- [ ] All tasks have automated contract checks or documented manual steps
- [ ] Full suite green before phase verify
- [ ] `nyquist_compliant: true` when execution complete

**Approval:** pending
