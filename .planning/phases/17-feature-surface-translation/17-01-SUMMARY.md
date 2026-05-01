---
phase: 17-feature-surface-translation
plan: 01
subsystem: i18n
tags: [rails-i18n, locale-catalog, gadgets, todos, calendar]

requires:
  - phase: 16-core-shell-and-shared-messages-translation
    provides: shared locale catalogs, request-scoped I18n locale, and parity tests
provides:
  - Phase 17 ja/en locale key skeleton for downstream feature-surface plans
  - Runtime-localized Bookmark and Todo gadget titles
  - Runtime-localized Todo priority labels with unchanged numeric values
  - Runtime-localized Calendar weekday/month primitives with holiday names left external
affects: [17-02-bookmarks, 17-03-notes-todos, 17-04-feeds-calendar-js]

tech-stack:
  added: []
  patterns:
    - Absolute I18n keys from model/gadget code
    - Runtime option helpers for enum-like model labels
    - Rails date I18n primitives for calendar chrome

key-files:
  created:
    - test/models/todo_test.rb
    - test/models/calendar_test.rb
    - .planning/phases/17-feature-surface-translation/17-01-SUMMARY.md
  modified:
    - config/locales/ja.yml
    - config/locales/en.yml
    - app/models/bookmark_gadget.rb
    - app/models/todo_gadget.rb
    - app/models/todo.rb
    - app/models/calendar.rb

key-decisions:
  - "Preserved Todo numeric priority constants and made labels resolve through runtime I18n helpers."
  - "Kept Japanese holiday_jp names untranslated because they are external regional data, not app chrome."
  - "Committed only 17-01 implementation files and this summary; shared ROADMAP/STATE planning changes were left untouched for the orchestrator."

patterns-established:
  - "Model/gadget translations use absolute keys such as gadgets.bookmark.title."
  - "Todo.priority_options returns localized label/value pairs while values remain 1, 2, and 3."
  - "Calendar#day_of_week reads Rails date.abbr_day_names for the active locale."

requirements-completed:
  - TRN-02
  - TRN-03
  - TRN-05

duration: 4 min
completed: 2026-05-01
---

# Phase 17 Plan 01: Locale Catalog + Translation Primitives Summary

**Rails I18n locale skeleton and model-level translation primitives for downstream feature surface rewrites**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T11:07:00Z
- **Completed:** 2026-05-01T11:11:15Z
- **Tasks:** 3 completed
- **Files modified:** 9

## Accomplishments

- Seeded matching Phase 17 ja/en keys for shared actions, fixed gadget titles, Todo priorities, bookmark/note/feed/calendar feature copy, JavaScript-fed message copy, and `date.formats.calendar_month`.
- Replaced fixed `BookmarkGadget#title` and `TodoGadget#title` strings with runtime `I18n.t(...)` calls.
- Added runtime Todo priority helpers while preserving stored numeric priority values and legacy `Todo::PRIORITIES` callers.
- Changed Calendar weekday labels to use Rails I18n date data and covered month formatting through the seeded locale keys.

## Task Commits

Each task was committed atomically, with TDD tasks split into RED test and GREEN implementation commits:

1. **Task 1: Seed Phase 17 locale catalog keys** - `13a7c51` (feat)
2. **Task 2 RED: Todo/gadget runtime translation tests** - `179960c` (test)
3. **Task 2 GREEN: Runtime gadget titles and Todo priority helpers** - `f4f6c1a` (feat)
4. **Task 3 RED: Calendar primitive tests** - `5a294e6` (test)
5. **Task 3 GREEN: Calendar weekday localization** - `1d75dc0` (feat)

**Plan metadata:** pending at summary creation

## Files Created/Modified

- `config/locales/ja.yml` - Added Japanese Phase 17 key skeleton.
- `config/locales/en.yml` - Added matching English Phase 17 key skeleton.
- `app/models/bookmark_gadget.rb` - Localizes fixed Bookmark gadget title through `I18n.t`.
- `app/models/todo_gadget.rb` - Localizes fixed Todo gadget title through `I18n.t`.
- `app/models/todo.rb` - Adds priority key mapping, runtime option/label helpers, and dynamic legacy label access.
- `app/models/calendar.rb` - Resolves weekday labels from `date.abbr_day_names`.
- `test/models/todo_test.rb` - Covers gadget title and Todo priority runtime localization.
- `test/models/calendar_test.rb` - Covers weekday/month localization and unchanged holiday_jp names.

## Commands Run

- `bin/rails test test/i18n/locales_parity_test.rb` - PASS: 1 run, 4 assertions.
- `bin/rails test test/models/todo_test.rb` - RED before implementation, then PASS: 3 runs, 11 assertions.
- `bin/rails test test/models/calendar_test.rb` - RED before implementation, then PASS: 3 runs, 9 assertions.
- Final targeted sequence: `bin/rails test test/i18n/locales_parity_test.rb && bin/rails test test/models/todo_test.rb && bin/rails test test/models/calendar_test.rb` - PASS for all three commands.

## Test Results

- `test/i18n/locales_parity_test.rb`: PASS, ja/en key sets remain symmetric.
- `test/models/todo_test.rb`: PASS, ja/en labels switch with `I18n.with_locale`, and priority values remain numeric.
- `test/models/calendar_test.rb`: PASS, weekdays/month format localize, and a known `holiday_jp` holiday name remains Japanese.

## Decisions Made

- Kept `Todo::PRIORITIES` as a dynamic compatibility object so existing callers like `.invert` continue working until downstream views are translated.
- Used `date.formats.calendar_month` for month captions and `date.abbr_day_names` for weekday primitives.
- Did not update `.planning/ROADMAP.md`, `.planning/STATE.md`, or pre-existing Phase 17 planning artifacts per orchestrator instruction.

## Intentional Untranslated Content

- `Calendar#holiday(date)` remains unchanged. Japanese holiday names returned by `holiday_jp`, such as `元日`, are external regional data and intentionally remain untranslated even under `:en`.
- User-created or external values such as bookmark titles, Todo titles, feed titles, calendar record titles, and note bodies were not translated in this plan.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commits created: `179960c`, `5a294e6`.
- GREEN commits created after RED: `f4f6c1a`, `1d75dc0`.
- Refactor commit: not needed.

## Next Phase Readiness

Ready for `17-02-PLAN.md` and `17-03-PLAN.md`: locale keys and runtime primitives are available for feature view rewrites.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/17-feature-surface-translation/17-01-SUMMARY.md`.
- All five implementation/test commits exist in git history.
- Final targeted checks passed.
- No new stubs, new dependencies, auth paths, network endpoints, file-access paths, or schema changes were introduced.

---
*Phase: 17-feature-surface-translation*
*Completed: 2026-05-01*
