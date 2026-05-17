---
phase: 77-gadget-partial-wiring-tab-hook
plan: "01"
subsystem: javascript-wiring
tags:
  - sprockets
  - javascript
  - lazy-loading
  - mobile
  - gadgets
dependency_graph:
  requires:
    - window.portalLazy.register(columnIndex, loadFn)
    - window.portalLazy.loadColumn(index)
  provides:
    - mobile lazy loading live (IMPL-02, IMPL-03, IMPL-04)
  affects:
    - app/assets/javascripts/portal_lazy.js (bug fix)
    - app/assets/javascripts/portal_mobile_tabs.js (tab hook)
    - app/views/welcome/_*_gadget.html.erb (4 partials)
    - app/views/welcome/_portal_column_section.html.erb
key_files:
  created: []
  modified:
    - app/assets/javascripts/portal_lazy.js
    - app/assets/javascripts/portal_mobile_tabs.js
    - app/views/welcome/_portal_column_section.html.erb
    - app/views/welcome/_feed.html.erb
    - app/views/welcome/_mastodon_account.html.erb
    - app/views/welcome/_x_account.html.erb
    - app/views/welcome/_calendar_gadget.html.erb
decisions:
  - Fixed portalLazy.register to check loadedColumns[columnIndex] before pushing to queue; JS bundle loads in <head> so portal_mobile_tabs.js ready handler fires before gadget partial ready handlers — without this fix, activateColumn(initial) marks column loaded before any gadget registers, causing all register() calls to hit the already-loaded no-op path
  - Used local_assigns.fetch(:column_index, 0) for safe default in gadget partials when rendered outside portal context
  - Did not wrap _todo_gadget (todos.init is DOM event binding, no AJAX on init) or _bookmark_gadget (no script)
  - window.portalLazy.loadColumn(index) added unconditionally inside isMobileViewport() block — portal_lazy.js loads before portal_mobile_tabs.js alphabetically, so window.portalLazy is always present
metrics:
  duration: "~15 minutes"
  completed: "2026-05-17"
  files_modified: 7
requirements:
  - IMPL-02
  - IMPL-03
  - IMPL-04
---

# Phase 77 Plan 01: Gadget Partial Wiring + Tab Hook Summary

**One-liner:** All AJAX gadget partials route through `portalLazy.register`; `activateColumn` drains each column on first visit; mobile lazy loading live.

## What Was Built

### Bug Fix: `portal_lazy.js` `register`

Added early check in `register`: if `loadedColumns[columnIndex]` is already true, call `loadFn()` directly and return. This fixes a critical ordering issue: the JS bundle is loaded in `<head>`, so `portal_mobile_tabs.js`'s `$(document).ready` handler fires before the gadget partials' inline `$(document).ready` handlers. `activateColumn` (which now calls `loadColumn`) runs first with an empty queue, marking the column as loaded — without this fix, all subsequent `register` calls for that column would hit the no-op path.

### Column Index Propagation

`_portal_column_section.html.erb`: added `column_index: i` to each `render g.class.name.underscore, gadget: g` call inside the `portal_columns.each_with_index` loop.

### Gadget Partial Wiring (4 files)

Each partial's `$(document).ready` now wraps the `$.get` call inside `window.portalLazy.register(columnIndex, function() { ... })`:

- `_feed.html.erb`
- `_mastodon_account.html.erb`
- `_x_account.html.erb`
- `_calendar_gadget.html.erb`

Not wrapped (as specified in Phase 76 hand-off): `_todo_gadget.html.erb` (DOM event binding only), `_bookmark_gadget.html.erb` (no script).

### Tab Hook: `portal_mobile_tabs.js`

`activateColumn()` mobile block now calls `window.portalLazy.loadColumn(index)` after `localStorage.setItem`. This covers all three activation paths: tab click, swipe, and localStorage restore.

## Requirements Addressed

| ID | Description | Status |
|----|-------------|--------|
| IMPL-02 | All AJAX gadget partials register with coordinator | ✅ Done |
| IMPL-03 | activateColumn() triggers portalLazy.loadColumn | ✅ Done |
| IMPL-04 | Load state marked synchronously before $.get fires | ✅ Inherited from Phase 76 |

## Tri-Suite Results

| Suite | Command | Result |
|-------|---------|--------|
| Lint | `yarn run lint` | Green (0 warnings, 0 errors) |
| Minitest | `bin/rails test` | 395 runs, 0 failures, 0 errors, 0 skips |
| Cucumber | `bundle exec rake dad:test` | 25 scenarios, 25 passed, 0 failed |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| All tasks | c9c265d | feat(77): wire gadget partials to portalLazy coordinator; add tab hook |

## Self-Check: PASSED
