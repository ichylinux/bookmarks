---
phase: 7
slug: drawer-css-animation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for drawer CSS work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest (built-in) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/assets/modern_drawer_css_contract_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~5–30 seconds (project size) |

---

## Sampling Rate

- **After every task batch touching SCSS or tests:** Run `bin/rails test test/assets/modern_drawer_css_contract_test.rb`
- **After wave / before human UAT:** Run `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** < 60 seconds typical

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 7-01-01 | 01 | 1 | NAV-03 (CSS surface) | — | N/A — presentational | integration | `bin/rails test test/assets/modern_drawer_css_contract_test.rb` | ✅ | ⬜ pending |
| 7-01-02 | 01 | 1 | A11Y-01 | — | N/A | integration | same file | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing Minitest + `test_helper.rb` — no new framework
- [ ] `test/assets/modern_drawer_css_contract_test.rb` — contract scan (created in Plan 01)

*Wave 0 = one new test file that locks SCSS contracts.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Slide + fade smoothness | ROADMAP SC 1–2 | Motion perception | Chrome: `body.modern` + toggle `drawer-open`; observe 250ms ease-out |
| Z-order over tables | ROADMAP SC 3 | Visual stacking | Open drawer on data-heavy page; drawer + overlay cover content |
| Hamburger reads as X | ROADMAP SC 4 | Visual | With `drawer-open`, icon is unambiguous X |
| Reduced motion instant | ROADMAP SC 5 / A11Y-01 | OS setting | Enable “reduce motion”; toggle class — no visible transition |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or manual map above
- [ ] Sampling continuity: contract test runs after SCSS edits
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` in frontmatter after first green run

**Approval:** pending
