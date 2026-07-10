---
phase: 260710-p6v-mobile-gadget-add-btn-after-done
plan: 01
subsystem: ui
tags: [jquery, mobile, todo-gadget, cucumber]

requires: []
provides:
  - "todos.delete_todos success callback removes title--gadget-actions-visible from the gadget header"
  - "Source-contract test guarding the removeClass call"
  - "@mobile_portal Cucumber scenario covering the completed-state add-button visibility"
affects: []

tech-stack:
  added: []
  patterns:
    - "Header UI-state class (title--gadget-actions-visible) is cleared alongside model-mutating actions (delete_todos) to keep transient UI state in sync with data state"

key-files:
  created: []
  modified:
    - app/assets/javascripts/todos.js
    - test/assets/todo_gadget_mobile_css_contract_test.rb
    - features/02.タスク.feature
    - features/step_definitions/todos.rb

key-decisions:
  - "Fixed at the single call site (delete_todos success callback) rather than touching _updateCompleteGroup, since only the bulk-complete flow leaves the header's actions-visible class stale"
  - "No CSS or desktop-facing changes — desktop uses hover-only visibility and never sets the persistent class, so it was unaffected by the bug"

requirements-completed: [QUICK-MOB-ADDBTN-01]

duration: 15min
completed: 2026-07-10
---

# Quick Task 260710-p6v: Mobile gadget add-button fix after bulk complete Summary

**Fixed a one-line jQuery bug where completing tasks via the mobile header's bulk-complete action left the "追加" (add) button visible; added a source-contract test and a `@mobile_portal` Cucumber scenario to lock in the fix.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2/2 completed
- **Files modified:** 4

## Accomplishments
- `todos.delete_todos`'s success callback now removes `title--gadget-actions-visible` from the gadget header, so the mobile "追加" link stays hidden immediately after a bulk complete (and only reappears when the user taps the header again, as expected)
- Added a source-contract unit test asserting the `removeClass` call exists in the `delete_todos` success path
- Added a new `@mobile_portal` Cucumber scenario exercising tap-header → select 2 tasks → complete → assert the header's actions-visible state is cleared

## Task Commits

1. **Task 1: delete_todos 成功時にヘッダの actions-visible を除去 + ソース契約テスト** - `1a56721` (fix)
2. **Task 2: モバイル完了後に追加ボタンが出ない E2E シナリオを追加** - `2212e00` (test)

_Note: docs/state commit is handled by the orchestrator, not included above._

## Files Created/Modified
- `app/assets/javascripts/todos.js` - `delete_todos` success callback now removes `title--gadget-actions-visible` from `.title--gadget-with-icon` after hiding completed items
- `test/assets/todo_gadget_mobile_css_contract_test.rb` - new test asserting the `removeClass` call is present in `delete_todos`
- `features/02.タスク.feature` - new `@mobile_portal` scenario: complete after tapping header, then verify actions-visible is gone
- `features/step_definitions/todos.rb` - two new step definitions: tap header (assert actions-visible appears) and assert actions-visible is cleared after completion

## Decisions Made
- Applied the fix at the single point of mutation (`delete_todos`'s success callback) rather than generalizing `_updateCompleteGroup`, since that function has no other caller that leaves the class stale
- Reused the existing "a.head-title" click guard in the "タスクガジェットで N 件のタスクを選択します。" step as-is — it's a no-op on mobile viewports because `.head-title` is `display:none` under `max-width: 480px`, confirmed before relying on it

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Bug fixed and covered by both a fast source-contract unit test and a full-browser Cucumber scenario. All three project test suites pass:
- `yarn run lint` — green
- `bin/rails test` — 685/685 green (was 684/684 before this task)
- `bundle exec rake dad:test` — 41/41 scenarios, 181/181 steps green (was 40/40 before this task)

No follow-up work identified.

## Self-Check: PASSED

- FOUND: app/assets/javascripts/todos.js contains `removeClass('title--gadget-actions-visible')` in `delete_todos`
- FOUND: test/assets/todo_gadget_mobile_css_contract_test.rb contains new contract test
- FOUND: features/02.タスク.feature contains new `@mobile_portal` scenario
- FOUND: features/step_definitions/todos.rb contains two new step definitions
- FOUND: commit 1a56721 (`git log --oneline --all | grep 1a56721`)
- FOUND: commit 2212e00 (`git log --oneline --all | grep 2212e00`)

---
*Phase: 260710-p6v-mobile-gadget-add-btn-after-done*
*Completed: 2026-07-10*
