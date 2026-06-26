# Project Research Summary

**Project:** Bookmarks — v1.37.0 モバイルでのタスク追加機能
**Synthesized:** 2026-06-26
**Confidence:** HIGH

## Executive Summary

The v1.37.0 milestone is a focused mobile-usability fix for the inline todo-add form. The root cause is fully understood from direct codebase reading: the `.todo-gadget-new-link` is invisible and untappable on touch devices due to `opacity: 0` and `pointer-events: none` under `@media (hover: none)`, and the existing flex layout on `<table class="todo-form">` uses `flex-wrap: nowrap` which forces three form columns onto one row at 320–375px viewports. No new dependencies are required.

The recommended implementation approach is CSS-only: add a `@media (hover: none)` override in `welcome.css.scss` to make the link visible and tappable on touch devices, then add a `@media (max-width: 767px)` block inside the existing `.todo { }` scope in `todos.css.scss` to allow flex wrapping. Standalone pages (`/todos/new`, `/todos/:id/edit`) need a `<div class="todo">` wrapper so they inherit the same CSS scope as the gadget. The shared `_form.html.erb` partial is NOT touched; no JS changes are needed for layout. The one locale change is updating `welcome.todo_gadget.new_link` in `en.yml` from `"new"` to `"Add"` (ja.yml already reads「追加」).

Key risks are all well-characterized: Dart Sass will reject bare `min()`/`max()` calls (use `calc()` — project precedent from v1.18), iOS Safari silently ignores `.focus()` in AJAX callbacks (use `scrollIntoView()` instead), and the Cucumber `@mobile_portal` tag requires an explicit `ensure_mobile_viewport!` call in the step definition or the viewport never resizes.

## Key Findings

### Recommended Stack

No new dependencies. The entire milestone is 3–4 files plus locale keys.

**Root causes identified:**
1. **Critical:** `@media (hover: none) { pointer-events: none }` on `.todo-gadget-new-link` makes the entry point untappable on touch. Fix: add an override scoped to `.todo-gadget-new-link` only.
2. **Secondary:** `flex-wrap: nowrap` on the already-flex `<table>` overflows at 320–375px. Fix: `flex-wrap: wrap` in a mobile media query block.
3. **Minor:** iOS Safari auto-zoom fires when input font-size is below 16px. Guard with `font-size: 1rem`.

**Do NOT add:** auto-focus in AJAX callback (iOS restriction), FastClick, CSS Grid, extra breakpoints, or new gems.

### Expected Features

**Table stakes (must ship):**
- Label rename: `"新規"` → `"追加"` (locale keys only)
- Mobile flex-wrap form layout on ≤767px
- Full-width inputs and 44px minimum touch targets
- Desktop layout unchanged
- ja/en locale key parity maintained

**Differentiators (polish, not required for milestone):**
- Explicit cancel button
- Title field visually first on mobile (CSS `order`)
- `scrollIntoView()` after AJAX inject

**Anti-features (explicitly rejected):** Modal/overlay, bottom sheet, FAB, auto-focus (iOS incompatible), auto-save, multi-step add.

### Architecture Approach

**CSS-only, no partial change.**

- The `<table class="todo-form">` is already overridden to flex in gadget context via `todos.css.scss` (`.todo { form.todo { table.todo-form { tr { display: flex } } } }`). Problem is `flex-wrap: nowrap`.
- Add `@media (max-width: 767px) { tr { flex-wrap: wrap; } td:last-child { flex: 1 0 100%; } }` inside `.todo { }` in `todos.css.scss`.
- Add `<div class="todo">` wrapper in `new.html.erb` and `edit.html.erb` so standalone pages share the same CSS scope.
- `_form.html.erb` must NOT change — shared by 3 render contexts.
- `todos.js` must NOT change — layout is CSS-only.
- **Locale key state:** `ja.yml` already reads「追加」; only `en.yml` needs updating (`"new"` → `"Add"`).

### Critical Pitfalls

1. **Dart Sass `min()`/`max()` misparse** — never use bare CSS math functions in `.scss`; wrap in `calc()`. Project precedent from v1.18 (feeds.css.scss).
2. **iOS Safari ignores `.focus()` in AJAX callback** — async context loses user-gesture; keyboard never opens. Use `scrollIntoView()` instead.
3. Reverting table display in media query destroys existing flex — only ADD (`flex-wrap: wrap`), never set `display: table-*`.
4. Gadget-only CSS selector misses `/todos/new` — ensure `.todo` wrapper is present on standalone pages.
5. Double-tap edit regression — "追加" link must stay in gadget header, not inside any `<li>`.
6. Hollow `@mobile_portal` Cucumber scenario — `ensure_mobile_viewport!` must be called explicitly in the step before `visit root_path`.

## Implications for Roadmap

### Suggested Phase Structure (3 phases)

**Phase 1: Locale update**
- Rationale: Zero-risk isolated change; unblocks locale-dependent Cucumber steps
- Delivers: "追加" label in English UI (`en.yml` only)
- Files: `config/locales/en.yml`
- Pitfalls: None

**Phase 2: Mobile CSS + link visibility fix**
- Rationale: Core deliverable; CSS-only is the safest path given shared partial constraint
- Delivers: Tappable "追加" link on touch devices; stacked form on ≤767px; standalone pages covered by `.todo` wrapper; iOS zoom guard
- Files: `welcome.css.scss`, `todos.css.scss`, `app/views/todos/new.html.erb`, `app/views/todos/edit.html.erb`
- Pitfalls: Dart Sass, table display revert, gadget-only selector

**Phase 3: Test suite gate**
- Rationale: CLAUDE.md policy requires all three suites green before milestone completion
- Delivers: Minitest CSS contract tests; Cucumber `@mobile_portal` todo add scenario; tri-suite green
- Files: New/updated test and step definition files
- Pitfall: Must call `ensure_mobile_viewport!` explicitly in nav step

### Key Decisions for Roadmapper

- **Auto-focus is deferred.** Not viable on iOS via AJAX callback — requires pre-rendered hidden form to implement correctly.
- **Cancel button is optional.** Empty-title dismiss is the established pattern; explicit cancel is a differentiator for later.
- **No JS phase needed.** All layout work is CSS; `todos.js` is untouched.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack / root cause | HIGH | Direct codebase reading; CSS rules are unambiguous |
| Feature scope | HIGH | Cross-checked against PROJECT.md milestone goal |
| Architecture approach | HIGH | All findings from direct codebase reading |
| Pitfalls | HIGH | Project-specific confirmed by codebase; iOS/Sass by authoritative sources |

**Overall: HIGH**

---
*Research completed: 2026-06-26*
*Ready for roadmap: yes*
