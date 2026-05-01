---
phase: 17-feature-surface-translation
plan: 03
subsystem: ui
tags: [rails-i18n, notes, todos, cucumber, integration-tests]

requires:
  - phase: 17-feature-surface-translation
    provides: Phase 17 locale catalog keys, Todo priority helpers, and TodoGadget title primitive from 17-01
provides:
  - Localized simple-theme note gadget chrome
  - Localized Todo gadget actions, forms, priority display, and preference default priority select
  - Representative ja/en note and Todo integration coverage for TRN-03
  - Updated Japanese Cucumber note/todo smoke labels for intentional visible-copy changes
affects: [17-05-representative-validation, phase-18-translation-verification]

tech-stack:
  added: []
  patterns:
    - Rails ERB lazy lookup for note and Todo partial copy
    - Runtime Todo.priority_options consumption in Todo and preference forms
    - User-created note bodies and Todo titles rendered as record values only

key-files:
  created:
    - .planning/phases/17-feature-surface-translation/17-03-SUMMARY.md
  modified:
    - app/views/welcome/_note_gadget.html.erb
    - app/views/todos/_actions.html.erb
    - app/views/todos/_form.html.erb
    - app/views/todos/index.html.erb
    - app/views/preferences/index.html.erb
    - test/controllers/welcome_controller/welcome_controller_test.rb
    - test/controllers/todos_controller_test.rb
    - test/controllers/preferences_controller_test.rb
    - features/02.タスク.feature
    - features/04.ノート.feature
    - features/step_definitions/todos.rb
    - features/step_definitions/notes.rb

key-decisions:
  - "Kept Note and Todo user content outside translation: note.body and todo.title render unchanged in all locales."
  - "Used Todo.priority_options for both Todo forms and preference default priority select so labels localize while numeric values remain 1, 2, and 3."
  - "Updated only Japanese Cucumber labels whose visible UI copy intentionally changed: Todo gadget/add action and Note save action."

patterns-established:
  - "Feature partial fixed copy resolves through view-scoped lazy keys such as welcome.note_gadget.* and todos.form.*."
  - "Todo select consumers should use Todo.priority_options rather than Todo::PRIORITIES.invert."
  - "Cucumber remains Japanese smoke coverage; detailed bilingual assertions live in Minitest."

requirements-completed:
  - TRN-03

duration: 3 min
completed: 2026-05-01
---

# Phase 17 Plan 03: Note and Todo Feature Surface Translation Summary

**Note and Todo surfaces now render fixed UI chrome in Japanese or English while preserving note bodies, Todo titles, and numeric priority values**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-01T11:19:53Z
- **Completed:** 2026-05-01T11:23:15Z
- **Tasks:** 3 completed
- **Files modified:** 12

## Accomplishments

- Localized note gadget heading, body label, submit label, and empty state through `welcome.note_gadget.*`.
- Localized Todo gadget actions, Todo create/update submit labels, Todo priority options/display, and Todo index delete label.
- Switched the preference default priority select to `Todo.priority_options`.
- Added representative ja/en tests for note chrome, Todo gadget chrome, Todo priority options/display, preference default priority options, and unchanged user content.

## Task Commits

1. **Task 1: Translate note gadget chrome** - `a7558d6` (feat)
2. **Task 2: Translate Todo gadget, forms, actions, and priority display** - `2b91d63` (feat)
3. **Task 3: Extend note/todo representative tests and browser-smoke labels** - `cb3f8cf` (test)

**Plan metadata:** pending at summary creation

## Files Created/Modified

- `app/views/welcome/_note_gadget.html.erb` - Uses lazy translation keys for note gadget fixed copy.
- `app/views/todos/_actions.html.erb` - Uses `todos.actions.*` labels while preserving JS hooks and authenticity token data.
- `app/views/todos/_form.html.erb` - Uses `Todo.priority_options` and translated create/update submit labels.
- `app/views/todos/index.html.erb` - Uses shared delete label for fixed delete action copy.
- `app/views/preferences/index.html.erb` - Uses `Todo.priority_options` for `default_priority`.
- `test/controllers/welcome_controller/welcome_controller_test.rb` - Covers ja/en note and Todo gadget chrome plus user-content boundaries.
- `test/controllers/todos_controller_test.rb` - Covers localized priority options/display, create/update labels, numeric values, and unchanged Todo titles.
- `test/controllers/preferences_controller_test.rb` - Covers ja/en localized default priority options with numeric values.
- `features/02.タスク.feature` - Updates visible Todo gadget/action labels to `タスク` and `タスクを追加`.
- `features/04.ノート.feature` - Updates the note save step wording to `メモを保存`.
- `features/step_definitions/todos.rb` - Clicks `タスクを追加` for localized Todo add actions.
- `features/step_definitions/notes.rb` - Clicks `メモを保存` for localized note save.
- `.planning/phases/17-feature-surface-translation/17-03-SUMMARY.md` - Records plan execution outcome.

## Targeted Test Output

Required command 1:

```text
bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb
Run options: --seed 21727

# Running:

..............

Finished in 1.490848s, 9.3906 runs/s, 66.4052 assertions/s.

14 runs, 99 assertions, 0 failures, 0 errors, 0 skips
```

Required command 2:

```text
bin/rails test test/controllers/todos_controller_test.rb test/controllers/preferences_controller_test.rb
Run options: --seed 38490

# Running:

.........................

Finished in 1.993721s, 12.5394 runs/s, 91.7882 assertions/s.

25 runs, 183 assertions, 0 failures, 0 errors, 0 skips
```

Additional Task 3 combined check:

```text
bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/todos_controller_test.rb test/controllers/preferences_controller_test.rb
39 runs, 282 assertions, 0 failures, 0 errors, 0 skips
```

Per plan instruction, full `yarn run lint`, full `bin/rails test`, and `bundle exec rake dad:test` were not run; those are reserved for `17-05-PLAN.md`.

## Cucumber Label Changes

- `features/04.ノート.feature` now describes saving with `メモを保存`; `features/step_definitions/notes.rb` clicks the visible `メモを保存` button instead of the old `保存`.
- `features/02.タスク.feature` now expects the Japanese Todo gadget title `タスク` instead of `Todo`.
- `features/02.タスク.feature` and `features/step_definitions/todos.rb` now use/click `タスクを追加` instead of `新しいタスク`.
- The Todo form create submit remains `登録`, so the existing Cucumber step for blank create submission was intentionally left unchanged.

## Note/Todo Boundary Notes

- Note bodies continue to render from `note.body` unchanged; English note tests assert Japanese body text is still present as stored.
- Todo titles continue to render from `todo.title` unchanged; English Todo tests assert Japanese task titles are still present as stored.
- Todo priority display localizes through `Todo#priority_name`, but stored/select values remain numeric (`1`, `2`, `3`).
- Translation keys are never derived from note bodies or Todo titles.
- Existing Todo index row structure was not refactored; only the fixed delete label changed, per plan scope.

## Decisions Made

- Kept Japanese Todo form create/update labels as the seeded `登録` / `更新` copy from 17-01, while localizing English to `Create` / `Update`.
- Left `_todo.html.erb` untouched because it already consumes the runtime-localized `todo.priority_name` and record-backed `todo.title`.
- Did not update `.planning/ROADMAP.md`, `.planning/STATE.md`, or pre-existing Phase 17 planning artifacts per orchestrator instruction.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The workflow referenced `agents/gsd-executor.md` for commit protocol details, but that file was not present under the local GSD install. Task commits followed `references/git-integration.md` and repository git rules instead. No implementation behavior was affected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `17-04-PLAN.md` and final `17-05-PLAN.md` validation. Note/Todo TRN-03 representative coverage is in place, Cucumber visible labels align with the intentional Japanese UI copy changes, and the user-content boundary is documented for later translation audit.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/17-feature-surface-translation/17-03-SUMMARY.md`.
- Task commits exist in git history: `a7558d6`, `2b91d63`, `cb3f8cf`.
- Final targeted checks passed exactly as listed above.
- No new dependencies, auth paths, network endpoints, file-access paths, schema changes, `.planning/ROADMAP.md`, or `.planning/STATE.md` changes were introduced by this plan.

---
*Phase: 17-feature-surface-translation*
*Completed: 2026-05-01*
