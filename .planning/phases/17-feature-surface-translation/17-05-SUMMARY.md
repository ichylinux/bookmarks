---
phase: 17-feature-surface-translation
plan: 05
subsystem: testing
tags: [rails-i18n, validation, minitest, cucumber, full-gate]

requires:
  - phase: 17-feature-surface-translation
    provides: Phase 17 feature-surface implementation from plans 17-01 through 17-04
provides:
  - Representative bilingual validation coverage for Phase 17 success criteria 1-4
  - Full lint, Minitest, and Cucumber gate results for Phase 17
  - Documented untranslated-content boundaries for final verification
affects: [phase-18-translation-verification, v1.4-internationalization]

tech-stack:
  added: []
  patterns:
    - Representative ja/en controller assertions plus locale parity
    - Server-rendered data attribute validation for JavaScript-visible messages
    - Cucumber rerun-once policy documentation for phase gates

key-files:
  created:
    - .planning/phases/17-feature-surface-translation/17-05-SUMMARY.md
  modified:
    - test/controllers/welcome_controller/welcome_controller_test.rb
    - test/controllers/calendars_controller_test.rb

key-decisions:
  - "Closed only missing representative validation gaps: dashboard fixed gadget titles and Japanese calendar-specific view action coverage."
  - "Kept full-gate validation evidence in the summary without modifying shared ROADMAP.md or STATE.md."
  - "No JavaScript i18n pipeline was added; JS-visible feed messages remain server-rendered data attributes."

patterns-established:
  - "Final translation validation should combine focused representative assertions with the full CLAUDE.md gate."
  - "Dashboard tests should assert fixed gadget titles translate while feed/calendar record titles stay as stored content."

requirements-completed:
  - TRN-02
  - TRN-03
  - TRN-05

duration: 4 min
completed: 2026-05-01
---

# Phase 17 Plan 05: Representative Validation and Full Gate Summary

**Phase 17 feature-surface translation is covered by representative ja/en assertions and a green lint, Minitest, and Cucumber gate**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T11:29:00Z
- **Completed:** 2026-05-01T11:32:31Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments

- Audited plans 17-01 through 17-04 against the representative samples in `17-VALIDATION.md`.
- Added missing dashboard ja/en assertions for `BookmarkGadget#title` while proving feed and calendar record titles remain unchanged content.
- Added Japanese coverage for the calendar-specific `calendars.actions.view` CTA (`カレンダーを表示`), complementing existing English `View Calendar` coverage.
- Ran the complete project gate required by `CLAUDE.md`; all three suites passed and `dad:test` did not need a rerun.

## Task Commits

1. **Task 1: Close representative bilingual validation gaps** - `444ccf9` (test)
2. **Task 2: Run full Phase 17 gate and resolve regressions** - no code changes required after the gate passed

**Plan metadata:** pending at summary creation

## Files Created/Modified

- `test/controllers/welcome_controller/welcome_controller_test.rb` - Adds ja/en dashboard assertions for localized fixed gadget names and unchanged feed/calendar record titles.
- `test/controllers/calendars_controller_test.rb` - Adds Japanese calendar-specific view action coverage.
- `.planning/phases/17-feature-surface-translation/17-05-SUMMARY.md` - Records validation coverage and full gate results.

## Representative Coverage Notes

- Locale key parity: `test/i18n/locales_parity_test.rb` keeps `ja.yml` and `en.yml` key sets symmetric.
- Bookmarks: existing controller coverage verifies ja/en breadcrumb, action, helper, submit labels, and unchanged folder/bookmark titles and URLs.
- Dashboard gadgets: added ja/en `BookmarkGadget#title` coverage; existing Todo, feed, and calendar tests verify fixed gadget names localize while user-created feed/calendar titles remain unchanged.
- Notes/Todos: existing controller coverage verifies ja/en note labels, Todo priority options/display, unchanged note bodies and Todo titles, and numeric priority values.
- Feeds/JavaScript: existing controller coverage verifies exact `data-feed-url-required-message` and `data-feed-fetch-failed-message` values in the active locale. A code search found no `i18n-js`, `window.I18n`, or JavaScript translation registry usage.
- Calendars: existing stable-date coverage for `2026-01-01` verifies ja/en month/year, weekdays, localized glyph labels, and unchanged `holiday_jp` holiday name `元日`; this plan added Japanese `カレンダーを表示` CTA coverage.

## Full Gate Results

```text
yarn run lint
PASS: eslint app/assets/javascripts/**/*.js
Done in 0.97s.
```

```text
bin/rails test
PASS: 181 runs, 1043 assertions, 0 failures, 0 errors, 0 skips
```

```text
bundle exec rake dad:test
PASS: 9 scenarios, 28 steps, 0 failed
Randomized with seed 11772
```

Post-review rerun after `309965e` (`fix(17-04): localize feed form wrapper navigation`) confirmed the same full gate remains green.

## Targeted Validation Result

```text
bin/rails test test/i18n/locales_parity_test.rb test/controllers/bookmarks_controller_test.rb test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/todos_controller_test.rb test/controllers/preferences_controller_test.rb test/controllers/feeds_controller_test.rb test/controllers/calendars_controller_test.rb
PASS: 104 runs, 700 assertions, 0 failures, 0 errors, 0 skips
```

## Cucumber Rerun Details

No rerun was required. The first `bundle exec rake dad:test` run passed with 0 failed scenarios, so the known preference/theme/note leakage flake policy did not apply.

## Intentional Untranslated Content

- Bookmark titles, URLs, folder names, and parent folder names remain user content.
- Note bodies and Todo titles remain user content.
- Feed site names, feed URLs, feed titles, feed entry titles, and feed entry URLs remain record/external content.
- Calendar record titles remain user content.
- `holiday_jp` holiday names such as `元日` remain Japanese external regional data by design.
- Calendar glyph text `<<` and `>>` remains unchanged; only accessible labels are localized.

## Decisions Made

- Added representative test coverage rather than exhaustive string assertions, relying on locale parity for full key symmetry.
- Did not modify `.planning/ROADMAP.md`, `.planning/STATE.md`, or pre-existing untracked Phase 17 planning artifacts.
- Did not add production behavior, dependencies, JavaScript globals, or an i18n build pipeline.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.  
**Impact on plan:** No scope changes.

## Issues Encountered

Code review found one feed wrapper translation gap after the initial full gate: `app/views/feeds/new.html.erb` and `app/views/feeds/edit.html.erb` still rendered `一覧へ` directly. Fixed in `309965e` by using `t('actions.back_to_list')` and adding feed controller assertions for English `Back to list` and Japanese `一覧に戻る`; targeted feed tests and the full gate passed afterward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 17 implementation and validation evidence are ready for orchestrator state/roadmap updates and Phase 18 planning. Phase 18 can use this summary as the Phase 17 sign-off for TRN-02, TRN-03, and TRN-05.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/17-feature-surface-translation/17-05-SUMMARY.md`.
- Representative validation test commit exists in git history: `444ccf9`.
- Targeted representative Minitest passed.
- Full `CLAUDE.md` gate passed after the post-review fix: `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test`.
- No shared tracking files were modified by this plan.

---
*Phase: 17-feature-surface-translation*
*Completed: 2026-05-01*
