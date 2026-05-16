---
gsd_state_version: 1.0
milestone: v1.22
milestone_name: Landing at Root
status: complete
last_updated: "2026-05-17T00:00:00.000Z"
last_activity: 2026-05-17 — All phases complete (70–72)
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 3
  completed_plans: 3
  percent: 100
---

# State

## Current Position

Phase: — (all complete)
Plan: —
Status: Milestone complete — tri-suite green (384 runs, 0 failures; Cucumber 25/25)
Last activity: 2026-05-17 — Phases 70–72 shipped

```
Progress: [░░░░░░░░░░] 0/3 phases complete
```

## Project Reference

See: `.planning/PROJECT.md` (Current Milestone: v1.22)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.  
**Current focus:** v1.22 — Landing at Root

## Performance Metrics

- Baseline (v1.18 close): `yarn run lint` — green; `bin/rails test` — green; `bundle exec rake dad:test` — green (24 scenarios).
- v1.19 close: `yarn run lint` — green; `bin/rails test` — 363 runs, 0 failures; `bundle exec rake dad:test` — 24 scenarios, 0 failed.
- v1.20 close: tri-suite green (confirmed before milestone archive).
- v1.21 close: `yarn run lint` — green; `bin/rails test` — 381 runs, 0 failures; `bundle exec rake dad:test` — 25 scenarios, 0 failed.

## Accumulated Context

### Decisions

- (Implementation) `faraday-oauth1` with `f.request :oauth1, 'header', consumer_key:, consumer_secret:, token:, token_secret:` for X API v2 User Context.
- (CSS) Replaced Sass `max(100%, min-content)` in `feeds.css.scss` with `width: 100%` to avoid Dart Sass interpreting CSS `max()` as Sass `max()` during `application` bundle compile in test.
- (v1.19) `XClient#fetch_recent_tweets` builds its own Faraday connection (no `@forced_connection` check) — WebMock used for that method's tests rather than Faraday `:test`.
- (v1.21) `set_display_count_default` is a `before_save` callback (fires after validation) — validation enforces >0 so the callback is a nil-guard only; DB default of 5 handles the practical case.

### Pending Todos

None.

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

Milestone v1.21 completed (2026-05-16) — 1 phase (69), 6 requirements (XCNT-01 through XCNT-06), tri-suite green.
Milestone v1.22 started (2026-05-17) — roadmap created: Phase 70 (routing refactor), Phase 71 (test contracts), Phase 72 (Twitter uid fix).
