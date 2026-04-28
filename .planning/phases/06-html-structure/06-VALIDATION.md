---
phase: 6
slug: html-structure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails default) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb` |
| **Full suite command** | `bundle exec rake test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bundle exec ruby -Itest test/controllers/layout_structure_test.rb`
- **After every plan wave:** Run `bundle exec rake test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | NAV-01 | — | N/A | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_ハンバーガーボタン` | ❌ W0 | ⬜ pending |
| 6-01-02 | 01 | 1 | NAV-02 | — | N/A | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_ドロワーとオーバーレイ` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/controllers/layout_structure_test.rb` — stubs for NAV-01, NAV-02 (hamburger button, drawer/overlay structure, nav links, non-modern menu unaffected)

*Existing infrastructure (Minitest + Devise test helpers) covers the framework. Only the new test file needs creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drawer/overlay are direct `<body>` children (outside `.wrapper`) | NAV-02 | DOM structure requires browser DevTools inspection | Open app with modern theme, open DevTools, verify `.drawer` and `.drawer-overlay` are siblings of `.wrapper` at body level |
| Hamburger button visible in header area | NAV-01 | Visual position requires browser render | Open app with modern theme, confirm hamburger appears in header right side |
| Non-modern dropdown unaffected | NAV-02 | Requires switching theme and testing interaction | Switch to non-modern theme, open dropdown, verify all links work |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
