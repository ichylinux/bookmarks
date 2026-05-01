---
phase: 17-feature-surface-translation
plan: 04
subsystem: ui
tags: [rails-i18n, feeds, calendars, sprockets, jquery]

requires:
  - phase: 17-feature-surface-translation
    provides: Phase 17 locale keys and Calendar weekday/month primitives from 17-01
provides:
  - Localized feed index, form, loading, error, and server-fed JavaScript messages
  - Localized calendar month, weekday, loading, form, and action chrome
  - Accessible localized labels for calendar glyph month controls
affects: [17-05-representative-validation, phase-18-translation-verification]

tech-stack:
  added: []
  patterns:
    - Server-rendered data attributes for JavaScript-visible translated messages
    - Rails I18n date formatting for calendar month captions
    - User/external content preserved as record data beside translated UI chrome

key-files:
  created:
    - .planning/phases/17-feature-surface-translation/17-04-SUMMARY.md
  modified:
    - app/views/feeds/index.html.erb
    - app/views/feeds/_form.html.erb
    - app/views/welcome/_feed.html.erb
    - app/assets/javascripts/feeds.js
    - app/views/welcome/_calendar.html.erb
    - app/views/calendars/get_gadget.html.erb
    - app/views/calendars/_form.html.erb
    - app/views/calendars/show.html.erb
    - app/views/calendars/edit.html.erb
    - test/controllers/feeds_controller_test.rb
    - test/controllers/calendars_controller_test.rb

key-decisions:
  - "Fed `feeds.js` alert text from translated ERB `data-*` attributes rather than adding a JavaScript i18n runtime."
  - "Added localized `aria-label` and `title` attributes to calendar `<<` and `>>` controls while preserving the visible glyph text."
  - "Kept feed titles/URLs, calendar record titles, and `holiday_jp` holiday names unchanged as user/external content."

patterns-established:
  - "Use `data-feed-url-required-message` -> `.data('feedUrlRequiredMessage')` and `data-feed-fetch-failed-message` -> `.data('feedFetchFailedMessage')` for feed form JS copy."
  - "Use `data-fetch-failed-message` on welcome feed containers for inline AJAX failure copy."
  - "Calendar captions use `l(@calendar.display_date, format: :calendar_month)`."

requirements-completed:
  - TRN-03
  - TRN-05

duration: 4 min
completed: 2026-05-01
---

# Phase 17 Plan 04: Feed, Calendar, and JavaScript-Visible Strings Summary

**Feed and calendar surfaces now render fixed UI chrome in Japanese or English, with feed JavaScript messages supplied by server-rendered translated attributes**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T11:24:00Z
- **Completed:** 2026-05-01T11:28:18Z
- **Tasks:** 2 completed
- **Files modified:** 12

## Accomplishments

- Localized feed list actions, empty state, table headings, form fetch button, submit labels, loading text, and error copy.
- Replaced hardcoded Japanese feed alert prose in `feeds.js` with jQuery reads from translated `data-*` attributes.
- Localized calendar month/year captions, weekday labels, loading sentence, submit labels, show/edit/delete/view labels, and edit heading.
- Added localized accessibility labels to `<<` / `>>` calendar controls while keeping the visible glyphs unchanged.
- Added representative ja/en controller coverage for feed/calendar UI chrome and explicit content-boundary assertions.

## Task Commits

1. **Task 1: Translate feed surfaces and server-fed JavaScript messages** - `804c752` (feat)
2. **Task 2: Translate calendar surfaces and accessible glyph labels** - `cc4c7ae` (feat)

**Plan metadata:** pending at summary creation

## Files Created/Modified

- `app/views/feeds/index.html.erb` - Uses locale/model keys for feed list UI chrome and shared action labels.
- `app/views/feeds/_form.html.erb` - Adds translated fetch button, create/update submit labels, and JS message `data-*` attributes.
- `app/views/welcome/_feed.html.erb` - Uses translated loading text and server-rendered failure message data for inline AJAX error copy.
- `app/assets/javascripts/feeds.js` - Reads alert messages from the clicked button data attributes; no hardcoded Japanese alert prose remains.
- `app/views/welcome/_calendar.html.erb` - Translates loading sentence while interpolating the stored calendar title unchanged.
- `app/views/calendars/get_gadget.html.erb` - Uses localized month formatting and adds localized labels to glyph month controls.
- `app/views/calendars/_form.html.erb` - Adds explicit translated create/update submit labels.
- `app/views/calendars/show.html.erb` - Uses shared translated edit/delete labels.
- `app/views/calendars/edit.html.erb` - Uses translated view action and edit heading.
- `test/controllers/feeds_controller_test.rb` - Covers ja/en feed UI, server-fed JS message attributes, loading/error copy, and unchanged feed content.
- `test/controllers/calendars_controller_test.rb` - Covers ja/en calendar caption/weekdays/actions/loading, glyph labels, unchanged titles, and preserved `holiday_jp` names.
- `.planning/phases/17-feature-surface-translation/17-04-SUMMARY.md` - Records plan execution outcome.

## Targeted Test Output

Final required command sequence:

```text
bin/rails test test/controllers/feeds_controller_test.rb && yarn run lint && bin/rails test test/controllers/calendars_controller_test.rb
Run options: --seed 45449

# Running:

...............

Finished in 1.432037s, 10.4746 runs/s, 62.8475 assertions/s.

15 runs, 90 assertions, 0 failures, 0 errors, 0 skips
yarn run v1.22.22
$ eslint "app/assets/javascripts/**/*.js"
Done in 0.99s.
Run options: --seed 3226

# Running:

....................

Finished in 1.604260s, 12.4668 runs/s, 73.5542 assertions/s.

20 runs, 118 assertions, 0 failures, 0 errors, 0 skips
```

Task-level required checks also passed:

- `bin/rails test test/controllers/feeds_controller_test.rb && yarn run lint` - PASS: 15 runs, 90 assertions; ESLint PASS.
- `bin/rails test test/controllers/calendars_controller_test.rb` - PASS: 20 runs, 118 assertions.

Per plan instruction, full `bin/rails test` and `bundle exec rake dad:test` were not run; those are reserved for `17-05-PLAN.md`.

## JavaScript-Fed Message Notes

- `feeds.js` now reads `$(button).data('feedUrlRequiredMessage')` and `$(button).data('feedFetchFailedMessage')`.
- `app/views/feeds/_form.html.erb` supplies those values via `data-feed-url-required-message` and `data-feed-fetch-failed-message`.
- `app/views/welcome/_feed.html.erb` supplies inline AJAX failure copy via `data-fetch-failed-message` on the feed gadget container.
- No `i18n-js`, `window.I18n`, imports, bundlers, or JavaScript translation registry were added.

## Intentional Untranslated Content

- Feed record fields (`feed.title`, `feed.feed_url`, `feed.display_count`) remain unchanged in both locales.
- Feed entry titles and URLs remain external feed content and are not translated.
- Calendar record titles (`gadget.title`, `@calendar.title`) remain unchanged and are only interpolated into translated UI sentences.
- `Calendar#holiday(date)` output from `holiday_jp`, including `元日`, remains Japanese external regional data by design.
- Calendar glyph text `<<` and `>>` remains unchanged; only `aria-label` and `title` are localized.

## Decisions Made

- Used existing 17-01 locale keys and did not modify `config/locales/ja.yml` or `config/locales/en.yml` in this plan.
- Kept feed/calendar record content assertions in controller tests to guard the translation boundary.
- Did not update `.planning/ROADMAP.md`, `.planning/STATE.md`, or pre-existing Phase 17 planning artifacts per orchestrator instruction.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The workflow referenced `agents/gsd-executor.md` for commit protocol details, but that file was not present under the local Cursor GSD install. Task commits followed `references/git-integration.md` and repository git rules instead. No implementation behavior was affected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `17-05-PLAN.md`: feed/calendar TRN-03 and TRN-05 representative coverage is in place, JavaScript-visible copy is server-fed, and untranslated external content boundaries are documented.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/17-feature-surface-translation/17-04-SUMMARY.md`.
- Task commits exist in git history: `804c752`, `cc4c7ae`.
- Final targeted checks passed exactly as listed above.
- No new dependencies, auth paths, network endpoints, file-access paths, schema changes, `.planning/ROADMAP.md`, or `.planning/STATE.md` changes were introduced by this plan.

---
*Phase: 17-feature-surface-translation*
*Completed: 2026-05-01*
