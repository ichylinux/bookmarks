---
phase: 17-feature-surface-translation
plan: 02
subsystem: ui
tags: [rails-i18n, bookmarks, cucumber, integration-tests]

requires:
  - phase: 17-feature-surface-translation
    provides: Phase 17 locale catalog keys and BookmarkGadget title primitive from 17-01
provides:
  - Localized bookmark index, form, show, and edit UI chrome
  - Representative ja/en bookmark integration coverage for TRN-02
  - Updated Japanese Cucumber bookmark smoke labels for explicit submit copy
affects: [17-05-representative-validation, phase-18-translation-verification]

tech-stack:
  added: []
  patterns:
    - Rails ERB lazy lookup for bookmark view copy
    - Shared action keys for bookmark links
    - User-created bookmark/folder content rendered as record values only

key-files:
  created:
    - .planning/phases/17-feature-surface-translation/17-02-SUMMARY.md
  modified:
    - app/views/bookmarks/index.html.erb
    - app/views/bookmarks/_form.html.erb
    - app/views/bookmarks/show.html.erb
    - app/views/bookmarks/edit.html.erb
    - test/controllers/bookmarks_controller_test.rb
    - features/01.ブックマーク.feature
    - features/step_definitions/bookmarks.rb

key-decisions:
  - "Used explicit kind=folder/bookmark query parameters on bookmark creation links so the shared new form can render deterministic submit labels."
  - "Kept bookmark titles, URLs, folder names, parent folder names, and delete-confirmation interpolation values as stored user content."
  - "Updated only the Japanese Cucumber bookmark submit label that changed from Rails default 登録する to explicit ブックマークを追加."

patterns-established:
  - "Bookmark partial copy resolves under bookmarks.form.* and shared actions resolve through actions.*."
  - "Tests assert translated chrome and unchanged Japanese user content under English locale."

requirements-completed:
  - TRN-02

duration: 2 min
completed: 2026-05-01
---

# Phase 17 Plan 02: Bookmark Feature Surface Translation Summary

**Bookmark screens now render fixed UI chrome through ja/en locale keys while preserving bookmark and folder records as user content**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-01T11:14:11Z
- **Completed:** 2026-05-01T11:16:59Z
- **Tasks:** 3 completed
- **Files modified:** 8

## Accomplishments

- Localized bookmark index breadcrumbs, action headers, edit/delete links, show actions, parent-folder label, and edit heading.
- Localized bookmark form placeholder/help text, parent-folder label, root option, and deterministic submit labels for Add Bookmark, Create Folder, and Update.
- Added representative ja/en controller assertions covering bookmark labels, form labels, show/edit labels, unchanged Japanese user content, and translated delete confirmations.
- Updated the bookmark Cucumber smoke step from Rails default `登録する` to the explicit Japanese `ブックマークを追加` button.

## Task Commits

1. **Task 1: Translate bookmark index/show/edit chrome** - `4e5239c` (feat)
2. **Task 2: Translate bookmark form and deterministic submit labels** - `a6b8527` (feat)
3. **Task 3: Update bookmark tests and Cucumber label expectations** - `c68afb2` (test)

**Plan metadata:** pending at summary creation

## Files Created/Modified

- `app/views/bookmarks/index.html.erb` - Uses locale keys for breadcrumbs, action titles, table action heading, edit/delete labels, and distinguishes folder/bookmark creation intent.
- `app/views/bookmarks/_form.html.erb` - Uses `bookmarks.form.*` keys for placeholder, helper text, parent-folder label, root option, and submit labels.
- `app/views/bookmarks/show.html.erb` - Uses shared action keys and localized parent-folder chrome.
- `app/views/bookmarks/edit.html.erb` - Adds localized edit heading and back-to-list action.
- `test/controllers/bookmarks_controller_test.rb` - Adds ja/en bookmark UI assertions and explicit user-content boundary coverage.
- `features/01.ブックマーク.feature` - Renames the submit step to the new visible Japanese button label.
- `features/step_definitions/bookmarks.rb` - Clicks `ブックマークを追加` instead of the old Rails default `登録する`.
- `.planning/phases/17-feature-surface-translation/17-02-SUMMARY.md` - Records plan execution outcome.

## Targeted Test Output

Required command:

```text
bin/rails test test/controllers/bookmarks_controller_test.rb
Run options: --seed 45723

# Running:

..........................

Finished in 1.657659s, 15.6848 runs/s, 106.1738 assertions/s.

26 runs, 176 assertions, 0 failures, 0 errors, 0 skips
```

Per plan instruction, full `bin/rails test`, `yarn run lint`, and `bundle exec rake dad:test` were not run; those are reserved for `17-05-PLAN.md`.

## Cucumber Label Changes

- Scenario text changed from `登録ボタンをクリックしてブックマークを保存すると...` to `ブックマークを追加ボタンをクリックしてブックマークを保存すると...`.
- Step definition now clicks the visible `ブックマークを追加` button instead of Rails default `登録する`.
- No broad Cucumber scenario rewrite was made; bookmark Cucumber remains smoke coverage.

## Bookmark Translation Boundary Notes

- Bookmark titles render from `b.title` / `@bookmark.title` unchanged in all locales.
- Bookmark URLs render from `b.url` / `@bookmark.url` unchanged in all locales.
- Folder and parent folder names render from `f.title`, `@parent.title`, and `@bookmark.parent.title` unchanged in all locales.
- Delete confirmation still translates the sentence with `messages.confirm_delete` and interpolates the stored bookmark title via `name: b.title`.
- Translation keys are never derived from bookmark or folder user content.

## Decisions Made

- Used `kind=folder` and `kind=bookmark` on the two new-bookmark links because the existing shared `new` action/form otherwise cannot distinguish which explicit submit label to show before the user enters a URL.
- Kept model attribute labels for `title` and `url` via `Bookmark.human_attribute_name` rather than duplicating them under bookmark view keys.
- Left Cucumber execution for the later phase gate per this plan's targeted-check instruction.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- Shell self-check initially attempted to use `rg`, which was unavailable in the shell PATH. The same commit existence check was rerun successfully with `git rev-parse --verify`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `17-03-PLAN.md` and final `17-05-PLAN.md` validation. Bookmark TRN-02 representative coverage is in place, and the user-content boundary is documented for the later translation audit.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/17-feature-surface-translation/17-02-SUMMARY.md`.
- Task commits exist in git history: `4e5239c`, `a6b8527`, `c68afb2`.
- Final targeted check passed: `bin/rails test test/controllers/bookmarks_controller_test.rb`.
- No new dependencies, auth paths, network endpoints, file-access paths, or schema changes were introduced.

---
*Phase: 17-feature-surface-translation*
*Completed: 2026-05-01*
