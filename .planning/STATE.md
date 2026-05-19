---
gsd_state_version: 1.0
milestone: "v1.28"
milestone_name: "Account Self-Service Deletion"
status: planning
stopped_at: ""
last_updated: "2026-05-20T12:00:00.000Z"
last_activity: 2026-05-20 — Phase 91 context gathered
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
Last activity: 2026-05-20 — Milestone v1.28 started

```
Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/4 phases)
```

## Project Reference

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** v1.28 — account self-service deletion (user soft-delete; 90-day policy alignment; purge job deferred)

## Performance Metrics

- v1.27 close: `yarn run lint` — green; `bin/rails test` — 485 runs, 0 failures; `bundle exec rake dad:test` — 27/27
- v1.26 close: `yarn run lint` — green; `bin/rails test` — 458 runs, 0 failures; `bundle exec rake dad:test` — 27/27

## Deferred Items

Items acknowledged at milestone close on 2026-05-18 (`gsd-sdk query audit-open` showed quick-task rows as `missing` while work is already merged — scanner / directory drift only):

| Category | Item | Status |
|----------|------|--------|
| quick_task | archive-completed-milestone | acknowledged |
| quick_task | mobile-note-edit-textarea-height | acknowledged |
| quick_task | portal-slider-count-sync | acknowledged |

## Accumulated Context

### Decisions

- (v1.28 planning) Account deletion is **two-stage**: (1) user soft-delete + immediate access/PII cut-off; (2) hard-delete user + related rows via background job after **90 days** (job deferred to future milestone)
- (v1.28 planning) Transactional tables (bookmarks, notes, feeds, todos, portals, portal_layouts, preferences, mastodon_accounts, x_accounts, visited_links) are **not** modified at delete request time
- (v1.28 planning) ToS/privacy locale text must be **updated** to match 90-day retention (v1.27 promised immediate full erasure — wording correction required before ship)
- (v1.26) `visited_links` table: unique prefix index on `(user_id, url)` length **767**
- (v1.26) `VisitedLink.record!(user, url)` uses `upsert`; fragment-only normalization
- (v1.27) `PagesController` fully public for `/privacy` and `/terms`

### Blockers/Concerns

- Pre-existing: Cucumber scenario-order flakes
- (v1.28) Do not ship deletion UI until policy pages reflect 90-day model (Phase 91 before or with Phase 93)

### Roadmap Evolution

- v1.28 phases 91–94 added for account self-service deletion

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 20260520 | スマホでガジェットの長押しドラッグ並べ替え | 2026-05-20 | 09c9ee8 | [20260520-mobile-gadget-sort](./quick/20260520-mobile-gadget-sort/) |
| 20260519 | note update replaces full reload with in-place AJAX | 2026-05-19 | eb98bc7 | [20260519-note-update-ajax](./quick/20260519-note-update-ajax/) |
| 20260519 | show note edit time inline on mobile | 2026-05-19 | aa6308e | [20260519-mobile-note-edit-time](./quick/20260519-mobile-note-edit-time/) |
| 20260519 | refresh landing page — sync changelog | 2026-05-19 | d3470d7 | [20260519-refresh-landing-page](./quick/20260519-refresh-landing-page/) |
| 20260519 | new bookmark dialog on dashboard | 2026-05-19 | 7dfe7ec | [20260519-bookmark-gadget-new-dialog](./quick/20260519-bookmark-gadget-new-dialog/) |
| 20260519 | landing page language switcher | 2026-05-19 | d5128ea | [20260519-landing-language-switcher](./quick/20260519-landing-language-switcher/) |

## Session Continuity

Last session: 2026-05-20
Stopped at: Phase 91 context gathered
Resume file: .planning/phases/91-policy-wording-90-day-retention/91-CONTEXT.md

## Operator Next Steps

- `/gsd-plan-phase 91` — plan Phase 91 (policy YAML updates)
