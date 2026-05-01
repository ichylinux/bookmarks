---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Internationalization
status: ready-to-execute
stopped_at: "Phase 14 planned"
last_updated: "2026-05-01T00:00:00Z"
last_activity: 2026-05-01 - Phase 14 (Locale Infrastructure) planned; 3 plans ready to execute
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 3
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 14 — Locale Infrastructure
Plan: — (3 plans ready)
Status: Ready to execute (3 plans: 14-01 data layer, 14-02 concern+wiring, 14-03 tests)
Last activity: 2026-05-01 — Phase 14 planning complete; 14-01/14-02/14-03 PLAN.md files created

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-01)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.
**Shipped:** v1.1 (2026-04-27), v1.2 (2026-04-29), v1.3 (2026-04-30)
**Current milestone:** v1.4 — Internationalization

## v1.4 Roadmap

| Phase | Name | Status |
|-------|------|--------|
| 14 | Locale Infrastructure | Not started |
| 15 | Language Preference | Not started |
| 16 | Core Shell & Shared Messages Translation | Not started |
| 17 | Feature Surface Translation | Not started |
| 18 | Auth, 2FA & Translation Verification | Not started |

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
| 260501-q04 | remove table 'tweets' since there is no reference to it | 2026-05-01 | 3f215d4 |
| 260501-q05 | Font size preference (large, medium, small) | 2026-05-01 | 7ac28f1, e8608a0 |

## Session Continuity

Last session: 2026-05-01T00:00:00Z
Stopped at: Phase 14 planning complete (3 plans)
Resume: `/gsd-execute-phase 14` to execute the Locale Infrastructure plans
