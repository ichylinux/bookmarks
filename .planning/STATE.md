---
gsd_state_version: 1.0
milestone: v1.11
milestone_name: Device-aware Font Size Baseline
status: planning
stopped_at: "Phase 37 context gathered"
last_updated: "2026-05-06T14:42:00+09:00"
last_activity: "2026-05-06 — Captured Phase 37 context decisions"
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 37 (not started)  
Plan: —  
Status: Context gathered, ready for phase planning  
Last activity: 2026-05-06 — Captured Phase 37 context decisions

## Project Reference

See: `.planning/PROJECT.md`

**Current focus:** Plan Phase 37 with locked context decisions.

## Performance Metrics

v1.8 planning baseline created with full requirement-to-phase mapping (11/11). Execution gate remains tri-suite green: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (known flake rerun policy applies).

## Accumulated Context

### Decisions

- Mobile portal UI uses viewport max-width one px below `$portal-mobile-breakpoint` (768px): columns switch to numbered tabs + single visible column via `portal--column-active-N` on `.portal`.
- Tab strip is in the DOM for all viewports; hidden on wide screens with CSS (`display: none`).
- Simple theme: column tabs live inside `#simple-home-panel`, above the existing Home/Note simple tabs (REQ THEME-03).
- v1.8 phases use continuous numbering from prior milestone (start at Phase 29).
- v1.8 requirement mapping fixed as: Phase 29 (swipe/state-flow/accessibility sync), Phase 30 (localStorage restore + cross-theme parity), Phase 31 (verification gate).
- Phase 32 added for v1.8 lifecycle completion work (audit, complete, cleanup).
- Phase 32.1 inserted as urgent contract-gap closure for SWIPE-01 non-boundary right-swipe adjacent transition in E2E.
- Phase 33 added as post-v1.8 tab regression hardening baseline.
- Phase 33.1 inserted as urgent contract-gap closure for TEST-02 tab-click regression coverage in JS/Minitest.
- v1.11 milestone policy: keep 3-option font-size UX, apply device-aware medium baseline (PC14/mobile16), and define small/large as relative scaling.
- Existing-user safety policy: migrate `nil/medium -> small`, keep `small/large` unchanged, and show one-time notice.
- Phase 37 context decision: `common.css.scss` body font-size classes are authoritative; theme files follow via inherit/rem.
- Phase 37 context decision: medium baseline values are defined once in common CSS and switched by existing mobile breakpoint.
- Phase 37 context decision: only high-impact theme selectors are adjusted in this phase; full rem-normalization deferred.

### Roadmap Evolution

- Phase 32 added: Milestone Lifecycle Completion
- Phase 32.1 inserted after Phase 32 (URGENT): Close gap: SWIPE-01 — 非境界右スワイプの隣接遷移をE2E契約で明示化
- Phase 33 added: Tab Regression Hardening Baseline
- Phase 33.1 inserted after Phase 33 (URGENT): Close gap: TEST-02 — タブクリック回帰契約をJS/Minitestで明示化
- Phase 33.1 planned: 33.1-01 (tab-click JS/Minitest contract hardening + verification)
- Phase 33.1 executed: contract assertions expanded, verification passed, and summary/verification artifacts recorded.
- Phase 33 planned/executed: 033-01 baseline traceability closure completed with explicit linkage to 33.1 TEST-02 evidence and tri-suite verification.
- Phase 33.2 inserted: dedicated gap-closure lane for Cucumber scenario-state reset to reduce order-dependent dad:test flakiness.
- Phase 33.2 executed: centralized scenario reset hook added in `features/support/hooks.rb`; tri-suite passed with dad:test green on first run.
- Phase 37 added: Device-aware Typography Contract
- Phase 38 added: Existing-user Migration and One-time Notice
- Phase 39 added: Verification Gate

### Pending Todos

- None.

### Blockers/Concerns

None.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| Q-01 | Model class should inherit ApplicationRecord instead of ActiveRecord::Base | 2026-05-04 | 7b23b5d | — |
| Q-02 | HolidayJp holidays only render in Japanese locale | 2026-05-04 | this commit | `.planning/quick/260504-q02-holiday-jp-ja-locale/` |
| Q-03 | App icon at upper left links to root path | 2026-05-05 | 6603404 | `.planning/quick/260505-q03-app-icon-root-link/` |
| Q-04 | Document theme CSS separation convention | 2026-05-05 | this commit | `.planning/quick/260505-q04-theme-css-separation-reference/` |
| Q-05 | Make notice messages disposable without refreshing the page | 2026-05-05 | 81babad | `.planning/quick/260505-q05-disposable-notice-message/` |
| Q-06 | Use English for documents under .planning directory | 2026-05-05 | 4df0d6b | `.planning/quick/260505-q06-planning-docs-english/` |
| Q-07 | Simple-theme welcome CSS belongs in simple.scss | 2026-05-06 | b58fb95 | `.planning/quick/260506-q07-simple-theme-css-relocation/` |

## Session Continuity

Last session: 2026-05-04

Stopped at: v1.8 milestone archived and all phase plans completed.

Resume: start next milestone planning flow.
