---
phase: 131-feed-visit-recording
plan: 01
subsystem: api
tags: [rails, visited_links, feed, jquery, upsert]

requires: []
provides:
  - Nullable title/source columns on visited_links
  - Feed-aware VisitedLink.record! upsert
  - VisitedLinksController feed branch for source=feed
  - Feed gadget JS POST with title and source
affects:
  - 132-history-page-navigation-i18n

actuals:
  tokens: 2105
  tasks: 3
  commits: 3
plan_head_before: f6e69d3bb572793c90e546d679d96333b7fca162

tech-stack:
  added: []
  patterns:
    - "Feed-only title/source when params[:source] == 'feed' exactly"
    - "Feed gadget detection via feed_ id prefix in visited_links.js"

key-files:
  created:
    - db/migrate/20260921100000_add_title_and_source_to_visited_links.rb
  modified:
    - app/models/visited_link.rb
    - app/controllers/visited_links_controller.rb
    - app/assets/javascripts/visited_links.js
    - test/controllers/visited_links_controller_test.rb
    - test/models/visited_link_test.rb
    - test/assets/visited_links_js_contract_test.rb

key-decisions:
  - "Extended record! with optional title:/source: kwargs; non-feed calls unchanged"
  - "title limit 2083, source limit 32 per existing string conventions"
  - "Feed detection uses closest('.gadget') id indexOf('feed_') === 0 matching Feed#gadget_id"

patterns-established:
  - "Controller gates title/source persistence on exact source='feed' string match"
  - "JS branches POST payload by feed_ gadget id prefix; Mastodon/X remain URL-only"

requirements-completed: [REC-01, REC-02]

coverage:
  - id: D1
    description: "Feed POST persists normalized URL, title, and source='feed'"
    requirement: REC-01
    verification:
      - kind: integration
        ref: "test/controllers/visited_links_controller_test.rb#test_feed_create_persists_title_and_source"
        status: pass
    human_judgment: false
  - id: D2
    description: "Re-click upserts visited_at without duplicate row"
    requirement: REC-02
    verification:
      - kind: unit
        ref: "test/models/visited_link_test.rb#test_feed_record_updates_visited_at_and_title_without_duplicate"
        status: pass
      - kind: integration
        ref: "test/controllers/visited_links_controller_test.rb#test_feed_idempotent_create_updates_visited_at"
        status: pass
    human_judgment: false
  - id: D3
    description: "Non-feed requests store URL only; title/source remain nil"
    verification:
      - kind: unit
        ref: "test/models/visited_link_test.rb#test_non_feed_source_does_not_persist_title_or_source"
        status: pass
      - kind: integration
        ref: "test/controllers/visited_links_controller_test.rb#test_non_feed_ignores_title_and_source"
        status: pass
    human_judgment: false
  - id: D4
    description: "Feed gadget JS posts url+title+source; other gadgets post url only"
    verification:
      - kind: unit
        ref: "test/assets/visited_links_js_contract_test.rb"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-21
status: complete
---

# Phase 131 Plan 01: Feed Visit Recording Summary

**Feed article clicks persist title + URL with source='feed' via extended upsert, while Mastodon/X gadgets remain URL-only**

## Performance

- **Duration:** 25 min
- **Started:** 2026-09-21T06:43:00Z
- **Completed:** 2026-09-21T07:08:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added nullable `title` and `source` columns to `visited_links` with migration
- Extended `VisitedLink.record!` to include feed title/source in upsert when `source == 'feed'`
- Updated `VisitedLinksController#create` to pass feed params only when `source='feed'`
- Updated `visited_links.js` to detect `feed_` gadget ids and POST `{ url, title, source: 'feed' }`
- Added scoped Minitest coverage for REC-01/REC-02 and JS contract assertions

## Task Commits

1. **Task 1: End-to-end feed POST persists title + source — backend only** - `c9310e2` (feat)
2. **Task 2: Upsert idempotency and non-feed isolation tests** - `a80cd16` (test)
3. **Task 3: Feed gadget JS sends title + source; contract tests updated** - `2158a98` (feat)

## Files Created/Modified

- `db/migrate/20260921100000_add_title_and_source_to_visited_links.rb` - Adds nullable title/source columns
- `app/models/visited_link.rb` - Feed-aware upsert in `record!`
- `app/controllers/visited_links_controller.rb` - Feed branch in `create`
- `app/assets/javascripts/visited_links.js` - Conditional POST payload by gadget id
- `test/controllers/visited_links_controller_test.rb` - Feed create, idempotent, non-feed tests
- `test/models/visited_link_test.rb` - Feed upsert and non-feed ignore tests
- `test/assets/visited_links_js_contract_test.rb` - Feed/non-feed payload contract tests

## Decisions Made

- Extended existing `record!` signature with keyword args rather than adding `record_feed!`
- Used `title.to_s.strip.presence` to store nil for blank titles after strip
- Feed detection via `gadgetId.indexOf('feed_') === 0` matching `Feed#gadget_id`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 132 can read `visited_links` rows where `source='feed'` with title for history UI
- Cucumber E2E coverage deferred to Phase 133 per CONTEXT

---
*Phase: 131-feed-visit-recording*
*Completed: 2026-09-21*

## Self-Check: PASSED

- FOUND: db/migrate/20260921100000_add_title_and_source_to_visited_links.rb
- FOUND: app/models/visited_link.rb
- FOUND: c9310e2
- FOUND: a80cd16
- FOUND: 2158a98
