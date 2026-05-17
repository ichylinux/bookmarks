---
gsd_state_version: 1.0
milestone: v1.25
milestone_name: Portal Column Width Ratios
status: planning
last_updated: "2026-05-18T12:00:00.000Z"
last_activity: 2026-05-18 — Milestone v1.25 started (column width ratio sliders, desktop only)
progress:
  total_phases: 4
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
Last activity: 2026-05-18 — Milestone v1.25 started

Progress: 0/4 phases complete

## Project Reference

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.25 — per-column width ratios on desktop via preferences sliders (mobile unchanged)

## Performance Metrics

- v1.24 Phase 79 close: `yarn run lint` — green; `bin/rails test` — 407 runs, 0 failures; `bundle exec rake dad:test` — 25 scenarios, 0 failed.

## Accumulated Context

### Decisions

- (v1.25 planning) Column width customization is **desktop only**; mobile portal tab strip and single-column viewport behavior unchanged.
- (v1.25 planning) UX is **ratio sliders** on preferences (one per visible column, sum constrained to 100%), not drag-resize on the dashboard.
- (v1.24 Phase 77) `portalLazy.register` must check `loadedColumns[columnIndex]` before pushing to queue — PTM fires before gadget partial ready handlers.
- (v1.24 Phase 79) `notes_tabs.js` is simple-theme only (`if (!$('body').hasClass('simple')) return`). Modern/classic theme uses `?tab=notes` URL parameter — tab is server-determined. Simple theme lazy-fetches on first tab click; modern/classic theme fetches immediately if `?tab=notes`.
- (v1.24 Phase 79) `noteGadgetLoaded` custom event fires after $.get success; `initNoteGadget()` re-binds handlers safely (removes old handlers first).
- (v1.24 Phase 79) CRUD actions redirect to `root_path(tab: 'notes')` — unchanged.

### Blockers/Concerns

- Pre-existing: `$('.gadgets').sortable()` has no `isMobileViewport()` guard (tracked, not blocking).

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 20260518 | center note gadget loading message | 2026-05-18 | 7c3d626 | [20260518-center-note-gadget-loading-message](./quick/20260518-center-note-gadget-loading-message/) |
| 20260518 | archive completed milestone | 2026-05-18 | 2b78b34 | [20260518-archive-completed-milestone](./quick/20260518-archive-completed-milestone/) |

## Session Continuity

Last session: 2026-05-18
Stopped at: Milestone v1.25 initialized — requirements and roadmap defined; ready for Phase 80
Resume file: None
