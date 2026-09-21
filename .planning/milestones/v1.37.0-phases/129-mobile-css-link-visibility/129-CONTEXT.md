# Phase 129: Mobile CSS & Link Visibility - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

CSS-only changes to make the todo gadget "追加" link visible and tappable on touch devices, and the inline add form wrap gracefully on narrow mobile viewports. Also wraps standalone todo pages (`/todos/new`, `/todos/edit`) in a `.todo` div so they share the same CSS scope as the gadget form. No JavaScript changes. `_form.html.erb` is NOT touched.

</domain>

<decisions>
## Implementation Decisions

### Touch Device Visibility Override (MOB-01)
- Scope override to `.todo-gadget-new-link` only — `.bookmark-gadget-new-link` is excluded (bookmark new link opens a `<dialog>`, different UX)
- Add a new `@media (hover: none)` block in `welcome.css.scss` after the existing shared new-link rule, scoped exclusively to `.todo-gadget-new-link`: `opacity: 1; pointer-events: auto`
- Keep existing `transition: opacity 0.12s ease` — no animation occurs when opacity is already 1 on mobile, so no visual artifact

### Mobile Form Wrap Layout (MOB-02)
- Each form cell (priority, title, submit) gets full width on its own row via `flex: 0 0 100%` on `<td>` — matches success criteria "each occupy full width without horizontal overflow"
- Priority column fixed-width constraint (`$todo-priority-width`) is released on mobile (first `<td>` gets `flex: 0 0 100%`)
- Rules go inside the existing `.todo { @media (max-width: 767px) { ... } }` block in `todos.css.scss` — stays with other `.todo` mobile overrides; no new separate block needed

### Standalone Page Wrapper (MOB-03)
- Add `<div class="todo">` wrapper in `new.html.erb` and `edit.html.erb` only — `_form.html.erb` partial is NOT touched (shared by gadget, new, and edit render contexts)
- No additional `id` or class beyond `class="todo"` — all relevant CSS rules are `.todo`-scoped and don't require additional specificity

### iOS Zoom Guard (MOB-04)
- `font-size: 1rem` placed inside `.todo { @media (max-width: 767px) {} }` block, scoped to `form.todo td input[type="text"]` and `form.todo td select` — avoids touching other form elements on the page
- Scoped only within `form.todo` — not applied to all inputs within `.todo`

### Claude's Discretion
- Never use bare CSS `min()`/`max()` in SCSS — wrap in `calc()` (project precedent from v1.18, avoid Dart Sass misparse)
- Desktop layout (>767px) must be fully unaffected — mobile overrides must be entirely within `@media (max-width: 767px)` blocks

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `welcome.css.scss` — contains `.todo-gadget-new-link` shared rule with existing `@media (hover: none)` inside; also has `$portal-mobile-breakpoint: 768px` variable but the todos form uses 767px (one-pixel offset pattern)
- `todos.css.scss` — has `.todo { @media (max-width: 767px) { ... } }` block with existing `.todo-highlight-btn` mobile overrides; add flex-wrap and font-size rules here
- `_form.html.erb` — renders `form_with model: @todo, html: {class: 'todo'}` inside a `<table class="todo-form">` with 3 `<td>` elements (priority select, title text_field, submit button)
- `new.html.erb` / `edit.html.erb` — each is a single line `<%= render 'form' %>` with no wrapper; adding `<div class="todo">` here enables CSS scoping without touching the shared partial

### Established Patterns
- Mobile breakpoint for todo CSS: `@media (max-width: 767px)` (one pixel less than `$portal-mobile-breakpoint: 768px`)
- Touch device detection: `@media (hover: none)` — used for both pointer-events and opacity in existing link rules
- Flex layout for form: `form.todo table.todo-form tr { display: flex; flex-wrap: nowrap; }` — override `flex-wrap` to `wrap` in mobile

### Integration Points
- `welcome.css.scss`: add new `@media (hover: none) { .todo-gadget-new-link { ... } }` block after the existing shared new-link rule (around line 220+)
- `todos.css.scss`: add into existing `@media (max-width: 767px)` block inside `.todo { }` scope
- `app/views/todos/new.html.erb`: wrap `<%= render 'form' %>` with `<div class="todo">`
- `app/views/todos/edit.html.erb`: wrap `<%= render 'form' %>` with `<div class="todo">`

</code_context>

<specifics>
## Specific Ideas

- Success criterion 5 explicitly requires desktop (>767px) layout to be visually unchanged — all new rules must be strictly inside mobile media queries
- The `@media (hover: none)` fix is specifically for the "追加" (add) link — this is `.todo-gadget-new-link`, not the complete group or any other element
- The Cucumber `@mobile_portal` scenario in Phase 130 will call `ensure_mobile_viewport!` before `visit root_path` — Phase 129's CSS changes must work at 390px viewport width

</specifics>

<deferred>
## Deferred Ideas

- LOC-FUT-01: 英語ロケールキー `welcome.todo_gadget.new_link` を "Add" に変更 — deferred per user explicit decision (value stays "new")
- MOB-FUT-01: auto-focus on inline form — iOS Safari AJAX callback restriction prevents `.focus()` from working in this context; deferred to future milestone
- MOB-FUT-02: キャンセルボタン — empty title dismiss already works via existing pattern; dedicated cancel button deferred

</deferred>
