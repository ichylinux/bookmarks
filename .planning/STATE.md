---
gsd_state_version: 1.0
milestone: v1.31
milestone_name: — X Account Manual Add
status: complete
stopped_at: Phase 108 complete (1/1) — all 5 phases done, milestone ready for closure
last_updated: 2026-05-22T21:00:00.000Z
last_activity: 2026-05-22 -- Phase 108 execution complete
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# State

## Current Position

Phase: 108
Plan: 108-01 complete
Status: All phases complete — milestone ready for closure
Last activity: 2026-05-22

Progress: [██████████] 100% (5/5 phases)

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.31 complete — planning next milestone

## Performance Metrics

- v1.30 close: `yarn run lint` ✓ · `bin/rails test` 528/528 ✓ · `dad:test` 31/31 ✓

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2 | ACCT-FUT-01 purge job after 90 days | open |
| v2 | ACCT-FUT-03 data export | open |
| v2 | XMAN-FUT-01 total cap on manually-added accounts | open |
| v2 | XMAN-FUT-02 bulk add by handle list | open |
| v2 | XMAN-FUT-03 dedicated remove action for manually-added accounts | open |

## Accumulated Context

### Decisions

- (v1.31) No cap on manually-added accounts for v1.31 — personal app, low volume; deferred as XMAN-FUT-01
- (v1.31) `upsert_manual!` uses `first_or_initialize` on `(user_id, x_user_id)`; always sets `manually_added: true, deleted: false` unconditionally regardless of new_record? state
- (v1.31) `refresh_cache_from_items!` soft-delete loop gains `next if acc.manually_added?`; `assign_attributes` call must NOT include `manually_added` field to preserve flag on overlap rows
- (v1.31) `upsert_manual!` implemented: first_or_initialize on (user_id, x_user_id); unconditionally sets manually_added: true, deleted: false; no selection side-effect
- (v1.31) refresh soft-delete loop guard: next if acc.manually_added? skips manually-added rows; assign_attributes in refresh loop excludes manually_added: to preserve flag on overlap rows
- (v1.31) `lookup_user_by_username` strips leading `@` before building URL path; stores API-returned canonical username, not raw input
- (v1.31) HTTP 403 from X API for suspended accounts maps to `:suspended` error symbol
- (v1.29) Instrumentation at controller after XClient returns; `record_x_api_call` helper
- (v1.29) Admin gate 404 for non-admins; drawer link `current_user.admin?`
- (v1.29) Report identity: email if valid, else `@username` from first XAccount
- (v1.29) `usage_summary(since:, until_time:)` for date-range filter

### Blockers/Concerns

- None

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260521-001 | シンプルテーマの時に X API 使用状況へのメニュー項目がありません。 | 2026-05-21 | 3f51073 | [260521-001-simple-theme-x-api-menu](./quick/20260521-simple-theme-x-api-menu/) |
| 260521-002 | Add unique index on users.uid; nullify uid on soft-delete | 2026-05-21 | 8889a6c | [add-index-users-uid](./quick/20260521-add-index-users-uid/) |
| 260521-003 | X API 使用状況を管理メニューとしてドロワー内でセパレータを使ってセクションを分離する | 2026-05-21 | 15142d0 | [admin-section-separator](./quick/20260521-admin-section-separator/) |
| 260521-004 | Drop OAuth 1.0a support from X API completely | 2026-05-21 | 3113e32 | [drop-oauth1-x-api](./quick/20260521-drop-oauth1-x-api/) |

## Session Continuity

Last session: 2026-05-22T07:18:50.491Z
Stopped at: context exhaustion at 80% (2026-05-22)
Resume file: None

## Accumulated Context

### Roadmap Evolution

- Phase 103.1 inserted after Phase 103 (2026-05-22): Retroactive verification artifacts for Phases 101–103 — process closure identified at milestone audit (missing VERIFICATION.md / VALIDATION.md)
- v1.31 Phases 104–108 defined (2026-05-22): Schema/Model/Refresh guard is load-bearing Phase 104; must have passing Minitest on refresh guard before Phase 105 begins

## Operator Next Steps

- Run `/gsd:plan-phase 104` to plan Phase 104 (Schema, Model & Refresh Guard).
- Critical: Phase 104 MUST include the `refresh_cache_from_items!` guard Minitest — nothing else ships until it passes.
