---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Internationalization
status: planning
stopped_at: ""
last_updated: "2026-05-01T00:00:00.000Z"
last_activity: 2026-05-01 - Milestone v1.4 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-01 — Milestone v1.4 started

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-01)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.
**Shipped:** v1.1 (2026-04-27), v1.2 (2026-04-29), v1.3 (2026-04-30)
**Current milestone:** v1.4 — Internationalization

## Accumulated Context

### Shipped in v1.3

- `notes` table + `Note` model (`Crud::ByUser`, soft-delete, validations, `scope :recent`)
- `NotesController#create` — authenticated, `user_id` merged server-side, redirects to `root_path(tab: 'notes')`
- Simple-theme tab strip (ホーム/ノート) with jQuery switching, SSR `?tab=notes` initial state
- `_note_gadget.html.erb` with empty-state and reverse-chrono list
- `WelcomeControllerTest` gadget + isolation coverage; Cucumber `features/04.ノート.feature`
- `drawer_ui?` helper gating hamburger/drawer in layout; `layout_structure_test.rb` extended

### Critical Pitfalls (carry forward)

- Rails 8.1 `has_many ... delete_all` nullify incompatibility with NOT NULL `user_id` — use `Note.where(user_id: user.id).delete_all` in tests
- Theme leakage: both ERB guard (`favorite_theme == 'simple'`) and CSS scope (`.simple { }`) are required — one alone is insufficient
- CSRF: use `form_with(local: true)` — do not copy inline `authenticity_token` from portal layout

## Quick Tasks Completed

| # | Description | Date | Commit |
|---|-------------|------|--------|
| 260501-q01 | Replace Bookmarks nav with Home/Note in simple theme menu | 2026-05-01 | 66f2ebf |
| 260501-q02 | Remove simple-tabstrip nav (superseded by menu links) | 2026-05-01 | f73c484, 090f7cc |
| 260501-q03 | simple theme — Note tab visibility toggle via use_note preference | 2026-05-01 | f7b2267, bf98fd1, d8fb406 |

## Session Continuity

Last session: 2026-05-01T00:00:00.000Z
Stopped at: v1.3 milestone archived
Resume: `/gsd-new-milestone` to start v1.4
