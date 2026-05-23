---
gsd_state_version: 1.0
milestone: v1.33
milestone_name: Facebook Login
status: complete
last_updated: "2026-05-24"
last_activity: 2026-05-24 — Phase 113 complete; all phases done; tri-suite gate green
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# State

## Current Position

Phase: 113 (complete)
Plan: —
Status: All phases complete — ready for milestone audit/completion
Last activity: 2026-05-24 — Phase 113 complete; tri-suite gate green (lint ✓ Minitest 567/567 ✓ Cucumber 35/35 ✓)

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-24)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.33 Facebook Login — COMPLETE

## Performance Metrics

- v1.33 close: `yarn run lint` ✓ · `bin/rails test` 567/567 ✓ · `dad:test` 35/35 ✓
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
| v2 | FBFUT-01 Disconnect Facebook from account settings | open |
| v2 | FBFUT-02 Show connected providers in preferences page | open |

## Accumulated Context

### Decisions

- (v1.33) Facebook uses email-based find-or-create in `User.from_omniauth`, same pattern as `:google_oauth2`; `scope: 'email'` only — no `public_profile`
- (v1.33) No live Facebook OAuth round-trip in Cucumber — static presence check is sufficient for CI
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
| 20260523-obsolete-adr-audit | Audit for obsolete ADRs / stale decision docs | 2026-05-23 | [20260523-obsolete-adr-audit](./quick/20260523-obsolete-adr-audit/) |
| 20260523-001 | Admin users index pagination (50 per page) | 2026-05-23 | [20260523-001-admin-users-pagination](./quick/20260523-001-admin-users-pagination/) |
| 20260524-oauth-promote | Promote Google/X OAuth buttons above email form | 2026-05-24 | [20260524-oauth-promote](./quick/20260524-oauth-promote/) |

## Operator Next Steps

- Run `/gsd:complete-milestone` to archive v1.33 and prepare for next version
</content>
</invoke>