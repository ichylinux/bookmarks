---
gsd_state_version: 1.0
milestone: v1.32
milestone_name: Admin Account Purge
status: in_progress
stopped_at: —
last_updated: 2026-05-22T00:00:00.000Z
last_activity: 2026-05-22 — Roadmap created for v1.32 (Phases 109–111)
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 109 — Model Layer — Purge Predicate & Cascade
Plan: —
Status: Not started
Last activity: 2026-05-22 — Roadmap created for v1.32 (Phases 109–111)

Progress: [__________] 0% (0/3 phases)

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.32 Admin Account Purge — Phase 109 next

## Performance Metrics

- v1.31 close: `yarn run lint` ✓ · `bin/rails test` 546/546 ✓ · `dad:test` 33/33 ✓

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2 | ACCT-FUT-01b scheduled purge job after 90 days | open |
| v2 | ACCT-FUT-03 data export before purge | open |
| v2 | PURGE-FUT-01 bulk purge of all eligible accounts | open |
| v2 | XMAN-FUT-01 total cap on manually-added accounts | open |
| v2 | XMAN-FUT-02 bulk add by handle list | open |
| v2 | XMAN-FUT-03 dedicated remove action for manually-added accounts | open |

## Accumulated Context

### Decisions

- (v1.32 planning) `purge!` must use explicit `delete_all` per table — not `dependent: :destroy` cascade; no FK constraints in schema so ordering is logical not enforced
- (v1.32 planning) `portal_layouts` has no `has_many` on User; must be included explicitly as `PortalLayout.where(user_id: id).delete_all`
- (v1.32 planning) `purgeable?` must nil-guard `deleted_at` before the `<= 90.days.ago` comparison; nullable column
- (v1.32 planning) Cucumber `@admin_purge` hook must create a non-fixture user (not fixture ids 1/2/3) to avoid breaking `@account_deletion` scenario
- (v1.32 planning) Controller confirmation flow mirrors `Users::AccountDeletionsController` from v1.28: GET renders confirm page, DELETE executes, `data: { turbo: false }` on form
- (v1.31) No cap on manually-added accounts for v1.31 — personal app, low volume; deferred as XMAN-FUT-01
- (v1.31) `upsert_manual!` uses `first_or_initialize` on `(user_id, x_user_id)`; always sets `manually_added: true, deleted: false` unconditionally regardless of new_record? state
- (v1.31) `refresh_cache_from_items!` soft-delete loop gains `next if acc.manually_added?`; `assign_attributes` call must NOT include `manually_added` field to preserve flag on overlap rows
- (v1.29) Instrumentation at controller after XClient returns; `record_x_api_call` helper
- (v1.29) Admin gate 404 for non-admins; drawer link `current_user.admin?`

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

Last session: 2026-05-22T00:00:00.000Z
Stopped at: roadmap created
Resume file: None

## Accumulated Context

### Roadmap Evolution

- v1.32 Phases 109–111 defined (2026-05-22): Model-first order mirrors v1.31 — purge logic correct before UI exists; controller before views; Cucumber last as full-stack gate

## Operator Next Steps

- Run `/gsd:plan-phase 109` to plan Phase 109 (Model Layer — Purge Predicate & Cascade).
- Critical: Phase 109 MUST include the `portal_layouts` delete_all assertion and nil-guard test for `purgeable?` — these are the two highest-risk correctness gaps.
