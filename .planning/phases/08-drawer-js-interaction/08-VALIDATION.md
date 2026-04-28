---
phase: 8
slug: drawer-js-interaction
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails 8 Minitest + Capybara (Selenium) |
| **Config file** | `test/application_system_test_case.rb` |
| **Quick run command** | `bin/rails test test/system/modern_drawer_interaction_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~30–90 seconds (depends on Chrome startup) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test` scoped to the files touched (system + any new integration tests)
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01 | 01 | 1 | NAV-02, NAV-03 | T-8-01 / — | No new XSS vectors; behaviour-only JS | system | `bin/rails test test/system/modern_drawer_interaction_test.rb` | ❌ W0 | ⬜ pending |
| 8-01-02 | 01 | 1 | NAV-03 (legacy) | — | N/A | system / integration | `bin/rails test test/system/modern_drawer_interaction_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/system/modern_drawer_interaction_test.rb` — system coverage for toggling `body.drawer-open`
- [ ] `ApplicationSystemTestCase` includes `Devise::Test::IntegrationHelpers` if not already (one-line change)

*Wave 0 completes when system tests run green locally.*

---

## Manual-Only Verifications

| Behaviour | Requirement | Why Manual | Test Instructions |
|-----------|-------------|------------|-------------------|
| Animation feel / tap targets | NAV-02 | Visual timing is CSS Phase 7 | Open/close drawer on real device or DevTools device mode |
| Classic theme dropdown | NAV-03 / SC5 | Theme matrix | Sign in, switch to non-modern theme, open email menu, verify dismiss |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable on CI
- [ ] `nyquist_compliant: true` set in frontmatter after sign-off

**Approval:** pending
