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
| **Framework** | Minitest (bundled Rails 7.2) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/models/x_api_call_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/models/x_api_call_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 96-01-T1 | 96-01 | 1 | DATA-01, DATA-03 | schema inspection + migration run | `bin/rails db:migrate && bin/rails runner "puts ActiveRecord::Base.connection.table_exists?(:x_api_calls)"` | N/A (migration) | pending |
| 96-01-T2 | 96-01 | 1 | DATA-02 | unit | `bin/rails test test/models/x_api_call_test.rb` | Wave 0 | pending |
| 96-02-T1 | 96-02 | 2 | DATA-01, DATA-02, DATA-03 | unit (full) | `bin/rails test test/models/x_api_call_test.rb` | Wave 0 | pending |

---

## Wave 0 Gaps

Files that must be created before tests can run:

- [ ] `test/models/x_api_call_test.rb` — created in Plan 96-02, Wave 2
- [ ] `test/fixtures/x_api_calls.yml` — created in Plan 96-01, Wave 1

*(No framework install needed — Minitest already present)*

---

## Phase Gate

Before marking Phase 96 complete, ALL of the following must be green:

```
yarn run lint
bin/rails test
bundle exec rake dad:test
```

Per CLAUDE.md phase verification policy.
