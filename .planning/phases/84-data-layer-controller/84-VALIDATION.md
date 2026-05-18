---
phase: 84
slug: data-layer-controller
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-18
---

# Phase 84 — Validation Strategy

> Reconstructed from `84-*-PLAN.md`, `84-*-SUMMARY.md`, and `84-VERIFICATION.md` (no prior `*-VALIDATION.md`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails default) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~2–3 min (full gate; Cucumber dominates) |

---

## Sampling Rate

- **After every task commit:** `bin/rails test` on touched test paths + affected models/controllers
- **After every plan wave:** `yarn run lint && bin/rails test`
- **Before `/gsd-verify-work`:** Full gate per `CLAUDE.md` (lint + Minitest + `dad:test`)
- **Max feedback latency:** ~180 s (dominated by `dad:test`)
- **Note:** `dad:test` may show intermittent unrelated flakes; re-run once per `CLAUDE.md` before treating as regression.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 84-01-01 | 01 | 1 | DAT-01 | T-84-03 | Prefix unique index prevents migration/key overflow | integration | `bin/rails db:migrate:status \| grep visited_links` (after migrate); regressions caught by model suite | ✅ migration | ✅ green |
| 84-01-02 | 01 | 1 | DAT-01, DAT-02, DAT-03 | T-84-01–04 | `record!` idempotent; `urls_for` user-scoped; normalize strips fragment | unit | `bin/rails test test/models/visited_link_test.rb` | ✅ | ✅ green |
| 84-02-01 | 02 | 2 | DAT-04 | T-84-05–07 | Authenticated POST only; CSRF inherited; `current_user` anchor | integration | `bin/rails routes \| grep visited_links`; covered end-to-end in controller tests | ✅ | ✅ green |
| 84-02-02 | 02 | 2 | DAT-04 | T-84-05–07 | Hook resets visited state between Cucumber scenarios | integration | `bin/rails test test/controllers/visited_links_controller_test.rb` | ✅ | ✅ green |

*Status: ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing Rails/Minitest infrastructure covers this phase; no Wave 0 stubs required.

---

## Manual-Only Verifications

All behaviors above have automated Minitest coverage (including contract assertion that `features/support/hooks.rb` contains `VisitedLink.delete_all` via `test_cucumber_hooks_include_visited_link_reset`).

**Operational:** If `dad:test` fails once, re-run per repository flake policy before escalating.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infra equivalence
- [x] Sampling continuity maintained across plans 01 → 02
- [x] Wave 0 N/A (no MISSING stubs)
- [x] No watch-mode flags in commands above
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-18

---

## Validation Audit — 2026-05-18

Nyquist retrofill from artifacts (`84-VERIFICATION.md` + PLAN/SUMMARY).

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap resolved:** `features/support/hooks.rb` contract (`VisitedLink.delete_all`) was verified only by grep in VERIFICATION; added `VisitedLinksControllerTest#test_cucumber_hooks_include_visited_link_reset`.
