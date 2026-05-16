---
gsd_state_version: 1.0
milestone: v1.23
milestone_name: Icon Display Preference
status: in_progress
last_updated: "2026-05-17T00:00:00.000Z"
last_activity: 2026-05-17 — Roadmap created; Phase 73 next
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 73 — Data + Model Layer
Plan: —
Status: Roadmap created; ready to begin Phase 73
Last activity: 2026-05-17 — Roadmap created (Phases 73–75)

```
Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/3 phases complete)
```

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-17)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.23 Icon Display Preference — Phase 73: Data + Model Layer

## Performance Metrics

- Baseline (v1.18 close): `yarn run lint` — green; `bin/rails test` — green; `bundle exec rake dad:test` — green (24 scenarios).
- v1.19 close: `yarn run lint` — green; `bin/rails test` — 363 runs, 0 failures; `bundle exec rake dad:test` — 24 scenarios, 0 failed.
- v1.20 close: tri-suite green (confirmed before milestone archive).
- v1.21 close: `yarn run lint` — green; `bin/rails test` — 381 runs, 0 failures; `bundle exec rake dad:test` — 25 scenarios, 0 failed.
- v1.22 close: `yarn run lint` — green; `bin/rails test` — 384 runs, 0 failures; `bundle exec rake dad:test` — 25 scenarios, 0 failed.

## Accumulated Context

### Decisions

- (Implementation) `faraday-oauth1` with `f.request :oauth1, 'header', consumer_key:, consumer_secret:, token:, token_secret:` for X API v2 User Context.
- (CSS) Replaced Sass `max(100%, min-content)` in `feeds.css.scss` with `width: 100%` to avoid Dart Sass interpreting CSS `max()` as Sass `max()` during `application` bundle compile in test.
- (v1.19) `XClient#fetch_recent_tweets` builds its own Faraday connection (no `@forced_connection` check) — WebMock used for that method's tests rather than Faraday `:test`.
- (v1.21) `set_display_count_default` is a `before_save` callback (fires after validation) — validation enforces >0 so the callback is a nil-guard only; DB default of 5 handles the practical case.
- (v1.23 planning) Icon suppression via `body.no-icons` CSS class on `<body>` — same pattern as `body.modern` for theme. CSS rules target `.gadget-title-icon` and `.drawer-nav-icon`. No partial changes needed.

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

Milestone v1.22 completed (2026-05-17) — 3 phases (70–72), tri-suite green (384 Minitest, 25 Cucumber).
Milestone v1.23 started (2026-05-17) — roadmap created: Phase 73 (Data + Model Layer), Phase 74 (CSS + View Layer), Phase 75 (Preferences UI + Locale + Tests).
Next action: begin Phase 73 — migration for `show_icons` boolean column, model constant, `default_preference` update, validation.
