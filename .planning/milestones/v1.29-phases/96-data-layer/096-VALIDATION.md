---
phase: 96
slug: data-layer
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest 5.x |
| **Config file** | test/test_helper.rb |
| **Quick run command** | `bin/rails test test/models/x_api_call_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/models/x_api_call_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 96-01-01 | 01 | 1 | DATA-01 | — | N/A | migration | `bin/rails db:migrate && bin/rails db:schema:dump` | ❌ W0 | ⬜ pending |
| 96-01-02 | 01 | 1 | DATA-02 | — | N/A | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ W0 | ⬜ pending |
| 96-01-03 | 01 | 1 | DATA-03 | — | N/A | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ W0 | ⬜ pending |
| 96-02-01 | 02 | 2 | DATA-01 | — | N/A | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ W0 | ⬜ pending |
| 96-02-02 | 02 | 2 | DATA-02 | — | N/A | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ W0 | ⬜ pending |
| 96-02-03 | 02 | 2 | DATA-03 | — | N/A | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/x_api_call_test.rb` — stubs for DATA-01/02/03
- [ ] `test/fixtures/x_api_calls.yml` — test fixture data

*Existing infrastructure (test_helper.rb, fixtures pattern) covers the rest.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
