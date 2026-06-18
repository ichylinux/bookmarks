---
phase: 127-header-integrated-task-completion
plan: "02"
subsystem: todo-gadget
tags: [javascript, bugfix, gap-closure, sel-01]
status: complete
mode: gap_closure

dependency_graph:
  requires:
    - "127-01 (header complete group + _updateCompleteGroup)"
  provides:
    - "Selection preserved across toggle_highlight AJAX re-render"
  affects:
    - app/assets/javascripts/todos.js

tech_stack:
  added: []
  patterns:
    - "Capture client-only DOM state (wasSelected) before server partial replaceWith; re-apply after"

key_files:
  created: []
  modified:
    - app/assets/javascripts/todos.js
  deleted: []

decisions:
  - "Preserve-and-reapply .selected on li + span:first-child after replaceWith (minimal fix vs in-place DOM update refactor)"

metrics:
  duration: "<5 minutes"
  completed: "2026-06-19T00:00:00Z"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 127 Plan 02: Highlight/Selection Gap Closure Summary

**One-liner:** Fixed `todos.toggle_highlight` so AJAX re-render no longer drops client-only `.selected` state — highlight and completion selection are independent again (SEL-01).

## Gap Closed

**Symptom:** Clicking a row's highlight button (強調表示 / 強調解除) caused the completion checkmark (`span.selected` / `li.selected`) to disappear.

**Root cause:** `toggle_highlight` success callback used `$li.replaceWith(html)`. Server partial `_todo.html.erb` does not include client-only `.selected` class, so selected rows lost selection on highlight toggle.

**Fix:** Before AJAX, capture `wasSelected = $li.hasClass('selected')` and `ol = $li.closest('ol')`. On success, wrap HTML in `$newLi`, re-apply `.selected` to `$newLi` and `$newLi.find('span:first-child')` when `wasSelected`, then `replaceWith` and call `todos._updateCompleteGroup(ol)`.

## Tasks Completed

| # | Task | Files |
|---|------|-------|
| 1 | Preserve selection across toggle_highlight re-render | todos.js |

## Verification

| Check | Result |
|-------|--------|
| `yarn run lint` | 0 errors |
| `bin/rails test` | 679 runs, 0 failures |
| `bundle exec rake dad:test` | 38 scenarios, 0 failures |

## Manual Validation (operator)

Reproduce in browser before closing Phase 127:

1. Select a todo row (checkmark visible)
2. Click its highlight button (強調表示)
3. **Expected:** checkmark remains; header count unchanged

Automated coverage for this flow is scheduled in Phase 128.
