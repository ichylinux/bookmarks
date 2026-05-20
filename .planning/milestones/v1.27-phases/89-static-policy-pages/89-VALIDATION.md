---
phase: 89
slug: static-policy-pages
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-19
---

# Phase 89 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest / ActionDispatch::IntegrationTest |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 89-01-01 | 01 | 1 | PRIV-01, TOS-01 | Unauthenticated GET returns 200, not redirect | integration | `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb` | ❌ Wave 0 | ⬜ pending |
| 89-01-02 | 01 | 1 | PRIV-02, TOS-02 | Locale param switches content language | integration | `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb` | ❌ Wave 0 | ⬜ pending |
| 89-01-03 | 01 | 1 | PRIV-03 | Privacy policy covers data, X login, email, retention | integration | `bin/rails test test/controllers/privacy_controller_test.rb` | ❌ Wave 0 | ⬜ pending |
| 89-01-04 | 01 | 1 | TOS-03 | ToS covers acceptable use, availability, termination | integration | `bin/rails test test/controllers/terms_controller_test.rb` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/controllers/privacy_controller_test.rb` — stubs for PRIV-01, PRIV-02, PRIV-03
- [ ] `test/controllers/terms_controller_test.rb` — stubs for TOS-01, TOS-02, TOS-03

*Both files are new — existing infrastructure (test_helper.rb, Devise test helpers) covers all shared setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Page renders correctly in browser with proper typography/layout | UI-SPEC | Visual review only | Visit /privacy and /terms in browser; confirm layout matches UI-SPEC (lang switcher, back link, section headings) |
| X Developer Portal can access both URLs | PRIV-01, TOS-01 | External system | Verify URLs are publicly accessible (no auth wall) after deployment |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
