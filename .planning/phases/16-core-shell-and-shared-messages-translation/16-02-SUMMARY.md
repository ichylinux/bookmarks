---
phase: 16-core-shell-and-shared-messages-translation
plan: 02
subsystem: i18n
tags: [i18n, views, controller, substitution]

requires:
  - phase: 16-core-shell-and-shared-messages-translation
    provides: nav.* and flash.errors.generic locale catalog from Plan 16-01
provides:
  - Drawer navigation and menu ARIA rendered through shared nav.* keys
  - Simple-theme menu navigation rendered through shared nav.* keys
  - Note create fallback alert rendered through flash.errors.generic
affects: [phase-16, phase-17, phase-18, translation-coverage]

tech-stack:
  added: []
  patterns:
    - top-level absolute translation keys consumed from ERB views
    - inline per-request t() call for controller flash fallback

key-files:
  created:
    - .planning/phases/16-core-shell-and-shared-messages-translation/16-02-SUMMARY.md
  modified:
    - app/views/layouts/application.html.erb
    - app/views/common/_menu.html.erb
    - app/controllers/notes_controller.rb

key-decisions:
  - "Kept Bookmarks brand strings untranslated while translating operational navigation labels."
  - "Used shared absolute nav.* keys in both drawer and simple-theme menu instead of lazy lookup."
  - "Kept flash.errors.generic inline at the redirect call site so it resolves with the request locale."

patterns-established:
  - "Chrome strings shared by layout and partials should use top-level nav.* keys."
  - "Controller fallback flash translations should call t() inside the action, not at class load time."

requirements-completed: [TRN-01, TRN-04]

duration: 8 min
completed: 2026-05-01
---

# Phase 16 Plan 02: Core Shell Substitution Summary

**Layout, simple-theme menu, and note fallback alert now consume the shared Phase 16 translation catalog**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-01T07:03:25Z
- **Completed:** 2026-05-01T07:11:15Z
- **Tasks:** 3 completed
- **Files modified:** 3

## Accomplishments

- Replaced the drawer `aria-label="メニュー"` and seven drawer nav literals with `t('nav.*')`.
- Replaced the simple-theme menu's Home/Note/account menu nav literals with the same shared `t('nav.*')` keys.
- Replaced the note create fallback alert literal with inline `t('flash.errors.generic')`.
- Preserved `<title>Bookmarks</title>`, logo `alt="Bookmarks"`, and the `head-title` `Bookmarks` brand link unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Substitute hardcoded literals in application layout** - `63d1854` (feat)
2. **Task 2: Substitute hardcoded literals in simple-theme menu** - `57747f2` (feat)
3. **Task 3: Substitute note fallback alert** - `e986126` (feat)

**Plan metadata:** this summary commit.

## Files Created/Modified

- `app/views/layouts/application.html.erb` - Drawer ARIA and navigation labels now use `nav.*` keys.
- `app/views/common/_menu.html.erb` - Simple-theme menu labels now use the same shared `nav.*` keys; `use_note?` gate remains intact.
- `app/controllers/notes_controller.rb` - Generic fallback alert now uses `t('flash.errors.generic')` inline.
- `.planning/phases/16-core-shell-and-shared-messages-translation/16-02-SUMMARY.md` - Execution summary for this plan.

## Decisions Made

- Followed Plan 16-02 exactly: no locale YAML edits, no test additions, no feature-surface string work.
- Kept drawer/menu DOM structure unchanged; drawer behavior remains class-selector based and unaffected by label text.
- Used Ruby file-read assertions for acceptance checks because `rg` was unavailable in the shell environment.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The shell environment did not have `rg`; acceptance checks were run with Ruby file-read assertions instead of the plan's grep-style examples. This did not change implementation scope.

## Verification

- `ruby -e ... && bin/rails runner "ApplicationController.new"` — PASS (Task 1 acceptance)
- `ruby -e ...` — PASS (Task 2 acceptance)
- `ruby -e ... && bin/rails test test/controllers/notes_controller_test.rb` — PASS (`7 runs, 37 assertions, 0 failures, 0 errors`)
- `ruby -e ...` — PASS (`self-check ok`)
- `bin/rails test` — PASS (`138 runs, 700 assertions, 0 failures, 0 errors`)
- `NODENV_VERSION=20.19.4 yarn run lint` — PASS (`Done in 0.60s`)
- `bundle exec rake dad:test` — PASS (`9 scenarios, 28 steps, 0 failures`)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `16-03-PLAN.md`: integration tests can now assert chrome strings and flash behavior against the translated runtime output.

## Self-Check: PASSED

All Plan 16-02 tasks and acceptance criteria are implemented, committed, and verified. The full Rails, lint, and Cucumber gate commands passed.

---
*Phase: 16-core-shell-and-shared-messages-translation*
*Completed: 2026-05-01*
