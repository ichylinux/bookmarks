---
phase: 127-header-integrated-task-completion
plan: "01"
subsystem: todo-gadget
tags: [ui, erb, scss, javascript, i18n, refactor]
status: complete

dependency_graph:
  requires: []
  provides:
    - "todo gadget header complete group (span.todo-gadget-complete-group)"
    - "todos._updateCompleteGroup helper"
    - "welcome.todo_gadget.selected_count locale key (ja/en)"
    - "todos.delete_todos rewritten with closest-ol fallback and meta CSRF"
  affects:
    - "app/views/welcome/_todo_gadget.html.erb"
    - "app/views/common/_gadget_title_with_icon.html.erb"
    - "app/assets/javascripts/todos.js"
    - "app/assets/stylesheets/welcome.css.scss"
    - "app/assets/stylesheets/todos.css.scss"
    - "config/locales/ja.yml"
    - "config/locales/en.yml"
    - "test/controllers/welcome_controller/dashboard_test.rb"

tech_stack:
  added: []
  patterns:
    - "data-template attribute for ERB→JS i18n string passing"
    - "closest-ol fallback pattern (also in todos.new_todo) for out-of-ol trigger resolution"
    - "Optional complete_group: local slot in _gadget_title_with_icon.html.erb mirroring header_link: pattern"

key_files:
  created: []
  modified:
    - app/views/welcome/_todo_gadget.html.erb
    - app/views/common/_gadget_title_with_icon.html.erb
    - config/locales/ja.yml
    - config/locales/en.yml
    - test/controllers/welcome_controller/dashboard_test.rb
    - app/assets/stylesheets/welcome.css.scss
    - app/assets/stylesheets/todos.css.scss
    - app/assets/javascripts/todos.js
  deleted:
    - app/views/todos/_actions.html.erb

decisions:
  - "Used Option A (complete_group: local) for _gadget_title_with_icon.html.erb to cleanly separate the ERB concern without bundling both links into header_link:"
  - "Kept display management via $group.css('display', 'inline-flex') and $group.hide() per UI-SPEC (not a CSS class toggle)"
  - "welcome.css.scss split into shared visual rule (all three link selectors) and new-link-only rule (margin-left:auto, opacity:0) to prevent Pitfall 4"

metrics:
  duration: "17 minutes"
  completed: "2026-06-18T15:09:54Z"
  tasks_completed: 3
  tasks_total: 3
  files_changed: 8
  files_deleted: 1
---

# Phase 127 Plan 01: Header-Integrated Task Completion Summary

**One-liner:** Relocated the todo gadget's 完了 action from the standalone `.todo_actions` list row into the gadget header using a `span.todo-gadget-complete-group` with live selection count, `data-template` i18n wiring, and rewritten `todos.delete_todos` with closest-ol fallback and meta CSRF.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add header complete group, selected_count locale keys, update dashboard assertions | eb09fe3 | _todo_gadget.html.erb, _gadget_title_with_icon.html.erb, ja.yml, en.yml, dashboard_test.rb |
| 2 | CSS refactor complete-group styles, clean dead action-row selectors, delete _actions.html.erb | 00984ad | welcome.css.scss, todos.css.scss, _actions.html.erb (deleted) |
| 3 | Rewire todos.js — selection count update, complete-group toggle, delete_todos rewrite | 94c15b3 | todos.js |

## What Was Built

### ERB Changes (Task 1)

`_todo_gadget.html.erb`: Removed `render 'todos/actions'` (LAY-01 — vertical space reclaimed). Added `complete_group:` local to the `render 'common/gadget_title_with_icon'` call (Option A). The complete group renders as `span.todo-gadget-complete-group` containing a `span.todo-gadget-selected-count` (with `aria-live="polite"` and `data-template="%{count}件選択中"`) and an `<a class="todo-gadget-complete-link">` linking to `delete_todos_path`.

`_gadget_title_with_icon.html.erb`: Added optional `complete_group:` local slot mirroring the existing `header_link:` guard pattern.

### Locale Keys (Task 1)

Added `welcome.todo_gadget.selected_count` to both `ja.yml` (`"%{count}件選択中"`) and `en.yml` (`"%{count} selected"`). i18n parity test passes.

### Dashboard Test Fix (Task 1)

Updated two breaking assertions in `dashboard_test.rb` (lines 94 and 109) from `#todo .todo_actions a` to `#todo .title .todo-gadget-complete-link`, matching the new header location. Count remains 1 (complete link is always in DOM, just hidden).

### CSS Refactor (Task 2)

`welcome.css.scss`: Split the single `.bookmark-gadget-new-link, .todo-gadget-new-link` rule into:
- Shared visual rule (includes `.todo-gadget-complete-link`): `flex-shrink`, font, padding, border, cursor
- New-link-only rule: `margin-left: auto`, `opacity: 0`, `transition`

Added `.todo-gadget-complete-group { display: none; align-items: center; gap: 4px; flex-shrink: 0; }` and `.todo-gadget-selected-count` rules.

`todos.css.scss`: Removed `.todo_actions` rule block. Replaced all 7 `:not(.todo_actions)` exclusion selectors with clean equivalents per PATTERNS.md replacement table.

`app/views/todos/_actions.html.erb`: Deleted (no longer rendered).

### JavaScript Rewire (Task 3)

`todos.js`:
- **Changes 1–3**: Dropped `:not(.todo_actions)` from `dblclick`, `touchstart`, `touchend` event selectors (SEL-01)
- **Change 4**: Dropped `:not(.todo_actions)` from `$li.siblings()` filter
- **Change 5**: Dropped `:not(.todo_actions)` from touchstart click-away detection
- **Change 6**: Removed inert parent-class guard from `click 'li span:first-child'`; added `todos._updateCompleteGroup(ol)` call (HDR-03)
- **`todos._updateCompleteGroup` helper**: Reads `ol.find('li.selected').length`, updates `data-template` text via `.replace('%{count}', count)`, shows/hides group via `$group.css('display','inline-flex')` / `$group.hide()` (HDR-02, HDR-03)
- **Change 7**: `todos.new_todo` uses `ol.prepend()` instead of the removed `.todo_actions` anchor
- **Change 8**: `todos.delete_todos` fully rewritten — closest-ol fallback for header-context trigger (Pitfall 1), CSRF from `meta[name="csrf-token"]`, empty-selection guard (`if (params.todo_id.length === 0) return;`), count reset on POST success (SEL-02)

## Verification Results

| Check | Result |
|-------|--------|
| `yarn run lint` | PASS (0 errors) |
| `bin/rails test dashboard_test.rb locales_parity_test.rb` | PASS (24 runs, 137 assertions, 0 failures) |
| `bin/rails test` (full suite) | PASS (679 runs, 2985 assertions, 0 failures, 0 skips) |
| `grep -rn 'todo_actions' app/` | 0 matches (ALL_CLEAN) |
| `I18n.t('welcome.todo_gadget.selected_count', count: 2, locale: :ja)` | `2件選択中` |
| `I18n.t('welcome.todo_gadget.selected_count', count: 2, locale: :en)` | `2 selected` |

## Deviations from Plan

None — plan executed exactly as written. Option A (add `complete_group:` local to shared partial) was chosen as recommended; both options were equivalent.

## Known Stubs

None. The complete group HTML is rendered unconditionally in the server response (always in DOM). CSS keeps it `display:none` by default; JS reveals it on first selection. No placeholder text or hardcoded empty values flow to UI rendering.

## Threat Flags

No new threat surface introduced. CSRF source changed from `data-authenticity_token` on the removed `.todo_actions` partial to `meta[name="csrf-token"]` — the same token value already used by `todos.toggle_highlight`. No new endpoints, parameters, or auth paths.

## Self-Check: PASSED

Files exist:
- `app/views/welcome/_todo_gadget.html.erb` — FOUND (contains `todo-gadget-complete-group`)
- `app/views/common/_gadget_title_with_icon.html.erb` — FOUND (contains `complete_group` slot)
- `app/assets/javascripts/todos.js` — FOUND (contains `_updateCompleteGroup`)
- `app/assets/stylesheets/welcome.css.scss` — FOUND (contains `todo-gadget-complete-group`)
- `app/views/todos/_actions.html.erb` — CORRECTLY DELETED

Commits exist:
- eb09fe3: Task 1 (ERB + locale + test assertions)
- 00984ad: Task 2 (CSS + delete partial)
- 94c15b3: Task 3 (todos.js rewire)
