---
gsd_state_version: 1.0
milestone: v1.26
milestone_name: Visited Link Tracking
status: executing
stopped_at: "v1.26 roadmap created — run `/gsd:plan-phase 84` to start Phase 84"
last_updated: "2026-05-18T10:31:43.147Z"
last_activity: 2026-05-18 -- Phase 84 planning complete
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 2
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 84 next — planning data layer
Plan: —
Status: Ready to execute
Last activity: 2026-05-18 -- Phase 84 planning complete

## Project Reference

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.26 — Visited Link Tracking (Phase 84: Data Layer + Controller)

## Performance Metrics

- v1.25 close: `yarn run lint` — green; `bin/rails test` — 416 runs, 0 failures; `bundle exec rake dad:test` — 25/25 on first run; second run 1 scenario-order flake (settings form visit / note gadget)

## Accumulated Context

### Decisions

- (v1.26) `visited_links` table: `(user_id, url varchar(2083), visited_at)`; unique index on `(user_id, url(768))` (utf8mb4 prefix required)
- (v1.26) `VisitedLink.record!(user, url)` uses `upsert` (atomic insert-or-ignore, no TOCTOU race); `urls_for(user)` returns a `Set` of normalized URLs
- (v1.26) `normalize_url` strips fragment (`#...`) only — no query-string normalization by design
- (v1.26) `@visited_urls` assigned once per gadget show action (`FeedsController`, `MastodonAccountsController`, `XAccountsController`) — not in `WelcomeController#index`; AJAX-only query
- (v1.26) JS click handler uses `$(document).on('click.visitedLinks', '.gadget ol li a[href]', fn)` delegation — survives AJAX re-render; optimistic `addClass` before `$.post`
- (v1.26) `jquery_ujs.js` `$.ajaxPrefilter` provides CSRF token automatically — no manual CSRF plumbing in `visited_links.js`
- (v1.25) `preferences.portal_column_widths` JSON array; integers summing to 100; length must match `portal_column_count`
- (v1.25) Equal defaults: 3列 `[34,33,33]`, 4列 `[25,25,25,25]`; nil/mismatch length normalizes to equal split before validate
- (v1.25) Desktop: `--portal-col-width-pct` CSS variable per `.portal-column`; mobile unchanged
- (v1.25) Preferences: linked range sliders (`portal_column_width_sliders.js`); column-count change rebuilds slider row via template

### Blockers/Concerns

- Pre-existing: Cucumber scenario-order flakes (note gadget AJAX timing, occasional preferences visit without session)
- (v1.26) Cucumber `Before` hook must include `VisitedLink.delete_all` in same commit as migration to prevent visited-state leakage between scenarios

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 20260518 | center note gadget loading message | 2026-05-18 | 7c3d626 | [20260518-center-note-gadget-loading-message](./quick/20260518-center-note-gadget-loading-message/) |
| 20260518 | archive completed milestone | 2026-05-18 | 2b78b34 | [20260518-archive-completed-milestone](./quick/20260518-archive-completed-milestone/) |
| 20260518 | ポータル列数変更時のスライダー数連動修正 | 2026-05-18 | 35c7c75 | [20260518-portal-slider-count-sync](./quick/20260518-portal-slider-count-sync/) |
| 20260518 | landing page refresh — value copy + v1.25 changelog entry | 2026-05-18 | fdfea61 | [20260518-landing-page-refresh](./quick/20260518-landing-page-refresh/) |
| 20260518 | scroll to top when switching mobile portal columns via swipe | 2026-05-18 | 6587d2d | [20260518-mobile-swipe-scroll-top](./quick/20260518-mobile-swipe-scroll-top/) |
| 20260518 | simplify CSS styles — remove redundant declarations | 2026-05-18 | 737db5a | [20260518-simplify-css-styles](./quick/20260518-simplify-css-styles/) |
| 20260518 | auto-resize note edit textarea height on mobile | 2026-05-18 | 296fe5c | [20260518-mobile-note-edit-textarea-height](./quick/20260518-mobile-note-edit-textarea-height/) |

## Session Continuity

Last session: 2026-05-18
Stopped at: v1.26 roadmap created — run `/gsd:plan-phase 84` to start Phase 84
Last activity: 2026-05-18 — v1.26 roadmap created (Phases 84–87)
Resume file: None
