---
phase: 64
slug: webmock-baseline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-14
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest + Cucumber (via `bundle exec rake dad:test`) |
| **Config file** | `test/test_helper.rb`, `test/support/webmock.rb` (new) |
| **Quick run command** | `bin/rails test` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~60 seconds (Minitest) + ~120 seconds (Cucumber) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test`
- **After every plan wave:** Run `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | HTTP-01 | — | WebMock gem installed | integration | `bundle exec ruby -e "require 'webmock'"` | ✅ | ⬜ pending |
| 64-01-02 | 01 | 1 | HTTP-01 | — | disable_net_connect! configured | integration | `bin/rails test` | ✅ | ⬜ pending |
| 64-01-03 | 01 | 1 | HTTP-01 | — | localhost allowlisted | integration | `bin/rails test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test stubs needed — this phase IS the test infrastructure change.

---

## Manual-Only Verifications

All phase behaviors have automated verification via `bin/rails test` and `bundle exec rake dad:test`.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
