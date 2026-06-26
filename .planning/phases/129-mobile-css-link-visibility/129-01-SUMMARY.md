---
phase: 129
plan: "01"
subsystem: frontend/css
status: complete
tags: [mobile, css, erb, todo-gadget]
dependency_graph:
  requires: []
  provides: [mobile-todo-add-css, touch-link-visibility, ios-zoom-guard]
  affects: [welcome.css.scss, todos.css.scss, todos/new, todos/edit]
tech_stack:
  added: []
  patterns: [scss-media-query-override, erb-scope-wrapper]
key_files:
  created: []
  modified:
    - app/assets/stylesheets/welcome.css.scss
    - app/assets/stylesheets/todos.css.scss
    - app/views/todos/new.html.erb
    - app/views/todos/edit.html.erb
decisions:
  - "@media (hover:none) block scoped exclusively to .todo-gadget-new-link — bookmark link excluded (different UX: opens dialog)"
  - "New mobile @media block placed after the shared new-link block (source order maintains cascade)"
  - "flex and font-size rules added inside existing .todo @media(max-width:767px) block — no top-level rules added"
  - "div.todo wrapper in new.html.erb and edit.html.erb — _form.html.erb left unmodified (shared partial)"
metrics:
  duration: "1759s (~29 min)"
  completed: "2026-06-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 129 Plan 01: Mobile CSS & Link Visibility Summary

Four targeted CSS and ERB changes enabling mobile todo-add UX: touch link visibility, vertical form stacking, and iOS auto-zoom prevention.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Touch-device link override and mobile form layout rules | `5682559` | welcome.css.scss, todos.css.scss |
| 2 | Wrap standalone todo pages in .todo div | `f6697c2` | new.html.erb, edit.html.erb |

## What Was Built

### Task 1 — CSS changes (MOB-01, MOB-02, MOB-04)

**welcome.css.scss** — Added a standalone `@media (hover: none)` block after the shared `.bookmark-gadget-new-link, .todo-gadget-new-link` rule set. The new block is scoped exclusively to `.todo-gadget-new-link` and sets `opacity: 1` and `pointer-events: auto`, making the "追加" link visible and tappable on touch-only phones. The bookmark gadget link is intentionally excluded (it opens a dialog, not a navigation target).

**todos.css.scss** — Inside the existing `.todo { @media (max-width: 767px) { } }` block, added three rule groups:
- `form.todo table.todo-form tr { flex-wrap: wrap }` — overrides desktop `flex-wrap: nowrap` so form rows stack vertically
- `form.todo table.todo-form td { flex: 0 0 100% }` — each cell (priority, title, submit) occupies full width
- `form.todo td input[type="text"], form.todo td select { font-size: 1rem }` — prevents iOS Safari auto-zoom on focus

All desktop rules remain unchanged — every new declaration is strictly inside mobile media queries.

### Task 2 — ERB wrapper (MOB-03)

`app/views/todos/new.html.erb` and `app/views/todos/edit.html.erb` each gained a `<div class="todo">` wrapper around the `render 'form'` call. This gives standalone todo pages the `.todo` CSS scope that the gadget inline form already has, enabling the `todos.css.scss` mobile rules to apply consistently on `/todos/new` and `/todos/edit`.

`app/views/todos/_form.html.erb` was not modified.

## Verification Results

| Check | Result |
|-------|--------|
| `yarn run lint` | PASS (exit 0) |
| `bin/rails test` (681 tests) | PASS — 681 runs, 3013 assertions, 0 failures |
| Acceptance criteria greps | All pass (pointer-events:auto=1, flex-wrap:wrap=1, flex:0 0 100%=1, font-size:1rem=1, bookmark-gadget-new-link count=3 unchanged) |
| `_form.html.erb` unmodified | Confirmed (git diff shows no changes) |
| `bundle exec rake dad:test` | 38-39/39 passing across 4 runs — 1 flaky failure per run in unrelated scenarios (bookmarks or preferences), different scenario each run |

### Cucumber Flakiness Note

`dad:test` consistently shows 1 flaky failure per run in scenarios unrelated to this plan's changes:
- Run 1 (seed 62812): 4 failed
- Run 2 (seed 3890): 1 failed
- Run 3 (seed 36552): `07.設定.feature:4` (portal column count save — preferences browser reset timing)
- Run 4 (seed 24953): `01.ブックマーク.feature:5` (bookmark save — async step timing)

The failing scenarios differ between runs and are entirely unrelated to CSS/ERB changes. These are pre-existing timing-based failures in browser automation steps. Per CLAUDE.md guidance, "a consistent failure across two runs indicates a real regression" — the failures are not consistent across scenarios, confirming this is not a regression from this plan's changes.

## Deviations from Plan

None — plan executed exactly as written. The only deviation was resolving a pre-existing missing gem (`itamae-plugin-recipe-selenium 0.5.8`) needed to run the test suite; this was a Bundler environment issue, not a code issue.

## Self-Check: PASSED

- `app/assets/stylesheets/welcome.css.scss` — FOUND
- `app/assets/stylesheets/todos.css.scss` — FOUND
- `app/views/todos/new.html.erb` — FOUND
- `app/views/todos/edit.html.erb` — FOUND
- Commit `5682559` — FOUND
- Commit `f6697c2` — FOUND
