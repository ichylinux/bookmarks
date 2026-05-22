---
gsd_state_version: 1.0
milestone: v1.32
milestone_name: Admin Account Purge
status: Complete
last_updated: "2026-05-22"
last_activity: 2026-05-22 — v1.32 shipped (Phases 109–111 via gsd-autonomous)
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 3
  completed_plans: 3
  percent: 100
---

# State

## Current Position

Phase: —
Plan: —
Status: Milestone v1.32 complete
Last activity: 2026-05-22 — Autonomous execution finished; tri-suite green

Progress: [██████████] 100% (3/3 phases)

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.32 shipped — ready for next milestone planning

## Performance Metrics

- v1.32 close: `yarn run lint` ✓ · `bin/rails test` 559/559 ✓ · `dad:test` 34/34 ✓

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

- (v1.32) `purge!` uses explicit `delete_all` per table; final `user.delete` (not `destroy!`)
- (v1.32) `portal_layouts` deleted via `PortalLayout.where(user_id: id).delete_all`
- (v1.32) Cucumber `@admin_purge` uses `purge_e2e_test@example.com` — avoids fixture id 1/2/3
- (v1.31) `upsert_manual!` + refresh guard for manually-added X accounts
- (v1.30) Admin users list at `/admin/users` with `require_admin` gate

### Blockers/Concerns

- None

### Quick Tasks Completed

| # | Description | Date | Directory |
|---|-------------|------|-----------|
| 20260523-001 | Admin users index pagination (50 per page) | 2026-05-23 | [20260523-001-admin-users-pagination](./quick/20260523-001-admin-users-pagination/) |

## Operator Next Steps

- Run `/gsd-new-milestone` when ready to plan v1.33
- Commit implementation when satisfied with the diff
