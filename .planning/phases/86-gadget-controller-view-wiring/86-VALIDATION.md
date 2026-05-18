---
phase: 86
slug: gadget-controller-view-wiring
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-18
---

# Phase 86 — Validation Strategy

> Reconstructed from `86-*-PLAN.md`, `86-*-SUMMARY.md`, and `86-VERIFICATION.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (`ActionDispatch::IntegrationTest`, shared `test/support/query_counter.rb`) |
| **Config file** | `test/test_helper.rb` (loads `test/support/*.rb`) |
| **Quick run command** | `bin/rails test test/helpers/application_helper_test.rb test/controllers/feeds_controller_test.rb test/controllers/mastodon_accounts_controller_test.rb test/controllers/x_accounts_controller_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~2–3 min (full gate) |

---

## Sampling Rate

- **After every task commit:** Controller tests for the touched gadget(s) + `application_helper_test` when helper changes
- **After each plan wave:** `yarn run lint && bin/rails test`
- **Before `/gsd-verify-work`:** Full gate per `CLAUDE.md`
- **Max feedback latency:** ~180 s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 86-01-01 | 01 | 1 | GAD-04 | T-86-01–03 | Nil-safe helper; single batched `urls_for` per `show` | unit / grep | `bin/rails test test/helpers/application_helper_test.rb`; `grep` assignments per PLAN | ✅ | ✅ green |
| 86-01-02 | 01 | 1 | GAD-01–03 | T-86-03 | Item links only get `visited_link_class`; headers unchanged | integration | Template assertions covered by Plan 02 controller tests + grep checklist | ✅ | ✅ green |
| 86-02-01 | 02 | 1 | GAD-01, GAD-04 | T-86-05–06 | Visited class + exactly one `visited_links` SQL per feed show | integration | `bin/rails test test/controllers/feeds_controller_test.rb` | ✅ | ✅ green |
| 86-02-02 | 02 | 1 | GAD-02–04 | T-86-05–06 | Same for Mastodon + X gadgets | integration | `bin/rails test test/controllers/mastodon_accounts_controller_test.rb test/controllers/x_accounts_controller_test.rb` | ✅ | ✅ green |

---

## Wave 0 Requirements

`test/support/query_counter.rb` ships with Plan 02; no separate Wave 0 stub wave needed beyond existing Rails harness.

---

## Manual-Only Verifications

All GAD behaviors covered by Minitest (including `count_visited_link_queries` N+1 guard).

---

## Validation Sign-Off

- [x] GAD-01–04 traced to automated tests or PLAN grep equivalents superseded by tests
- [x] Sampling continuity across Plans 01 → 02
- [x] Notification-scoped query counter — no leaked subscriptions (`sql.active_record` block form)
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-05-18

---

## Validation Audit — 2026-05-18

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap resolved:** `visited_link_class(nil, url)` behavior was documented in `86-VERIFICATION.md` but lacked an automated assertion — added `ApplicationHelperTest` case `"visited_link_class returns empty string when visited_set is nil (GAD-04 nil-guard)"`.
