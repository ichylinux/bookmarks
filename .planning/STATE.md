---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Column Count Preference
status: Awaiting next milestone
last_updated: "2026-05-15T10:18:06.276Z"
last_activity: 2026-05-16 — Completed quick task: add icon to bookmark gadget header
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# State

## Current Position

Phase: Milestone v1.20 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-15 — Milestone v1.20 completed and archived

## Project Reference

See: `.planning/PROJECT.md` (Current Milestone: v1.20)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.  
**Current focus:** v1.20 — User-selectable portal column count (3 or 4) on preferences screen

## Performance Metrics

- Baseline (v1.18 close): `yarn run lint` — green; `bin/rails test` — green; `bundle exec rake dad:test` — green (24 scenarios).
- v1.19 close: `yarn run lint` — green; `bin/rails test` — 363 runs, 0 failures; `bundle exec rake dad:test` — 24 scenarios, 0 failed.

## Accumulated Context

### Decisions

- (Implementation) `faraday-oauth1` with `f.request :oauth1, 'header', consumer_key:, consumer_secret:, token:, token_secret:` for X API v2 User Context.
- (CSS) Replaced Sass `max(100%, min-content)` in `feeds.css.scss` with `width: 100%` to avoid Dart Sass interpreting CSS `max()` as Sass `max()` during `application` bundle compile in test.
- (v1.19) `XClient#fetch_recent_tweets` builds its own Faraday connection (no `@forced_connection` check) — WebMock used for that method's tests rather than Faraday `:test`.

### Pending Todos

- (Carry-forward) PITFALL-02 / `XAUTH-FUT-01`: switch Twitter `from_omniauth` lookup from `name` to `uid` — deferred to v1.20+.

### Blockers/Concerns

None.

## Quick Tasks Completed

| Date | Slug | Description |
|------|------|-------------|
| 2026-05-16 | landing-page-icons-changelog | Added SVG icons to landing page value cards + changelog entry for gadget header icons |
| 2026-05-16 | add-icon-bookmark-gadget-header | Added bookmark icon to bookmark gadget header (shared gadget_title_with_icon partial) |
| 2026-05-16 | add-icon-task-gadget-header | Added todo icon to task gadget header (shared gadget_title_with_icon partial) |
| 2026-05-15 | add-icon-calendar-gadget-header | Added calendar icon to calendar gadget header (shared gadget_title_with_icon partial) |
| 2026-05-14 | update-whats-new | Added X (Twitter) following feature entry to What's New changelog (both locales) |
| 2026-05-14 | update-whats-new-column-nav | Added column navigation buttons toggle entry to What's New changelog (both locales) |

## Session Continuity

Milestone v1.19 executed via `/gsd-autonomous` (all 3 phases in one session). STATE/ROADMAP updated manually post-execution.
v1.20 roadmap created 2026-05-15 — 2 phases (67–68), 8 requirements (COL-01 through COL-08), 100% coverage.
v1.20 Phase 67 executed via `/gsd-autonomous` on 2026-05-15 — migration + model + tests complete; 373 runs, 0 failures. COL-01, COL-04, COL-06 validated.

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
