---
phase: 105
slug: xclient-lookup-service
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-22
---

# Phase 105 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8.1.3 default) |
| **Config file** | none — uses `bin/rails test` |
| **Quick run command** | `bin/rails test test/services/x_client_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~5 seconds (service tests only) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/services/x_client_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** Full tri-suite must be green (`yarn run lint && bin/rails test && bundle exec rake dad:test`)
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 105-01-01 | 01 | 1 | XSVC-01 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-02 | 01 | 1 | XSVC-01 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-03 | 01 | 1 | XSVC-02 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-04 | 01 | 1 | XSVC-02 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-05 | 01 | 1 | XSVC-02 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-06 | 01 | 1 | XSVC-02 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |
| 105-01-07 | 01 | 1 | XSVC-02 | — | N/A | unit | `bin/rails test test/services/x_client_test.rb` | ✅ (appended) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

`test/services/x_client_test.rb` already exists with Faraday stub pattern and `users(:twitter_user)` fixture. New test cases are appended; no new files or framework setup needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
