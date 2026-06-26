# Technology Stack

**Project:** v1.37.0 モバイルでのタスク追加機能
**Researched:** 2026-06-26
**Scope:** Making the inline todo add form mobile-friendly within the existing Sprockets + SCSS + jQuery pipeline

---

## Executive Finding

No new dependencies. The entire v1.37.0 milestone is three files + locale keys. The hardest part is the CSS visibility fix for the "追加" link on touch devices — everything else follows from it.

---

## Root Cause Analysis

Before prescribing the fix, here is why the todo add form is broken on mobile today:

**Issue 1 — Entry point is untappable on touch devices (critical)**

In `welcome.css.scss`, the shared rule for `.bookmark-gadget-new-link, .todo-gadget-new-link`:

```scss
.bookmark-gadget-new-link,
.todo-gadget-new-link {
  margin-left: auto;
  opacity: 0;          // invisible by default
  transition: opacity 0.12s ease;

  @media (hover: none) {
    pointer-events: none;  // disabled on touch devices
  }
}

div.title:hover .todo-gadget-new-link {
  opacity: 1;  // only visible on hover — hover never fires on touch
}
```

On a touch-only device: the "新規" link is invisible (`opacity: 0`) and untappable (`pointer-events: none`). The `div.title:hover` reveal rule never fires on touch. This was intentional when there was no mobile add flow, but it blocks the entire feature.

**Issue 2 — Table element intrinsic sizing on narrow viewports (secondary)**

`_form.html.erb` uses `<table class="todo-form">`. `todos.css.scss` overrides with `display: block` + `tr { display: flex }`. This mostly works, but `<table>` retains the `table-layout: auto` minimum column width algorithm in some browsers even with `display: block`, which can cause subtle overflow at 320–375px. Replacing `<table>` with `<div>` eliminates this entirely.

**Issue 3 — iOS Safari auto-zoom on input focus (touch-specific)**

iOS Safari zooms the viewport when focusing an input whose computed font-size is below 16px. `common.css.scss` already sets `--font-size-medium-baseline: 16px` at `max-width: 767px`, so the body base is correct. However, if any ancestor in the gadget applies a smaller `font-size` via `em` cascade, the input inherits a sub-16px computed size. An explicit `font-size: 1rem` on the input under the mobile media query is the safe guard. (MEDIUM confidence — confirmed by CSS-Tricks, Defensive CSS.)

---

## Recommended Changes

### Change 1 — Fix link visibility on mobile (in `welcome.css.scss`)

**Where:** After the existing combined `.bookmark-gadget-new-link, .todo-gadget-new-link` block (around line 301).

**What to add:**
```scss
// Mobile: todo add link must be always visible and tappable on touch devices.
// Scoped to .todo-gadget-new-link only — bookmark link keeps hover-only behavior.
@media (hover: none) {
  .todo-gadget-new-link {
    opacity: 1;
    pointer-events: auto;
  }
}
```

**Cascade rationale:** Specificity is equal (`0,1,0` for both the combined rule and this override). Placing it after the combined rule ensures it wins. `@media (hover: none)` is correct — it targets touch-only/stylus devices, not desktop users with a narrow window. Do NOT use `@media (max-width: 767px)` here; that is a viewport-width check, not a pointer-type check.

**Do NOT** touch the shared `pointer-events: none` in the combined block — that is the correct behavior for `.bookmark-gadget-new-link` on mobile (no mobile bookmark-add flow exists).

### Change 2 — Replace `<table>` with `<div>` in `_form.html.erb`

**Where:** `app/views/todos/_form.html.erb`

**Current (3 lines of markup):**
```erb
<table class="todo-form">
  <tr>
    <td>…priority…</td>  <td>…title…</td>  <td>…submit…</td>
  </tr>
</table>
```

**Replacement:**
```erb
<div class="todo-form">
  <div class="todo-form-row">
    <div class="todo-form-cell todo-form-cell--priority">…priority…</div>
    <div class="todo-form-cell todo-form-cell--title">…title…</div>
    <div class="todo-form-cell todo-form-cell--submit">…submit…</div>
  </div>
</div>
```

**Why:** Eliminates all table intrinsic sizing edge cases. The existing flex rules in `todos.css.scss` apply identically — only the selectors need renaming. Desktop layout and `/todos/new` standalone page are unchanged; the visual result is identical because the flex properties are preserved.

### Change 3 — Update selectors in `todos.css.scss`

Rename selectors and add a mobile block. No flex property values change.

**Selector rename map:**

| Old selector | New selector |
|-------------|-------------|
| `form.todo table.todo-form` | `form.todo .todo-form` |
| `form.todo table.todo-form tbody` | (delete — no tbody in div structure) |
| `form.todo table.todo-form tr` | `form.todo .todo-form-row` |
| `form.todo table.todo-form td` | `form.todo .todo-form-cell` |
| `form.todo table.todo-form td:first-child` | `form.todo .todo-form-cell--priority` |
| `form.todo table.todo-form td:nth-child(2)` | `form.todo .todo-form-cell--title` |
| `form.todo table.todo-form td:last-child` | `form.todo .todo-form-cell--submit` |
| `html:lang(en) .todo form.todo table.todo-form td:first-child` | `html:lang(en) .todo form.todo .todo-form-cell--priority` |

**Mobile block to add inside `.todo { }` (append to existing `@media (max-width: 767px)` block at line 87):**

```scss
form.todo .todo-form {
  // iOS Safari: input must have computed font-size >= 16px to prevent viewport
  // auto-zoom on focus. body is 16px at this breakpoint (common.css.scss), but
  // em-cascade from gadget ancestors can reduce it. 1rem anchors to body root.
  input[type="text"] {
    font-size: 1rem;
  }

  // Eliminate 300ms double-tap delay on submit without a JS library.
  // Supported: Safari 9.3+, Chrome 55+.
  .todo-form-cell--submit input[type="submit"] {
    touch-action: manipulation;
  }
}
```

**Variable scope note:** `$portal-mobile-breakpoint` is defined in `welcome.css.scss` and is not in scope in `todos.css.scss` (Sprockets compiles files independently). Continue using the hardcoded `767px` — consistent with line 87 of `todos.css.scss`.

### Change 4 — Locale key update

**Files:** `config/locales/ja.yml`, `config/locales/en.yml`

**Keys to update:**
- `welcome.todo_gadget.new_link`: `"新規"` → `"追加"` (ja), `"New"` → `"Add"` (en)
- `welcome.todo_gadget.new_link_aria_label`: update to match (e.g., "タスクを追加" / "Add task")

---

## What NOT to Add

| Temptation | Why to refuse |
|------------|---------------|
| Auto-focus `input[type="text"]` in `todos.new_todo()` after AJAX prepend | Programmatic `.focus()` inside an AJAX callback does not reliably open the keyboard on iOS — browsers require focus to occur synchronously within a user-gesture handler. Adding it produces inconsistent behavior across browsers and is not needed because the user tapping the input is the natural next gesture. |
| FastClick or any touch JS library | `touch-action: manipulation` on the submit button covers the 300ms delay. The app already has `meta name="viewport" content="width=device-width"` which also eliminates the delay on modern browsers. No library needed. |
| Import `$portal-mobile-breakpoint` into `todos.css.scss` | Not in scope; Sprockets compiles SCSS files independently. The hardcoded `767px` on line 87 of `todos.css.scss` is the established pattern for this file. |
| CSS Grid for the form row | Flexbox is already in use and scales continuously. Grid adds no value and introduces new syntax. |
| Additional breakpoints below 767px | The form flex layout scales continuously. One breakpoint at 767px is sufficient. |
| Stacking form cells vertically on mobile | A 375px-wide viewport at 16px font can fit: priority select (3.5em ≈ 56px) + flex-grow title + 2-char "追加" submit on one row with space to spare. Stacking wastes gadget vertical space. In English locale the submit says "Add" (3 chars) — still comfortable. Only revisit stacking if actual device testing shows overflow. |
| New gems | None required. |
| Changes to any theme SCSS file | The form CSS is in `todos.css.scss` (non-theme). Theme files do not contain `.todo-form` selectors. |

---

## Integration Points with Existing SCSS Files

| File | What changes | What stays the same |
|------|-------------|----------------------|
| `welcome.css.scss` | Add `@media (hover: none) { .todo-gadget-new-link { opacity: 1; pointer-events: auto; } }` after the combined rule (~line 313) | All other combined-rule properties, `.bookmark-gadget-new-link` behavior, `.todo-gadget-complete-group`, gadget layout rules |
| `todos.css.scss` | Rename selectors (table→div, tr→row, td→cell); remove `tbody { display: block }`; add mobile font-size + touch-action block inside existing `@media (max-width: 767px)` | All flex property values, `$todo-priority-width` variable and mixin, highlighted-item rules, `li.highlighted form.todo` override, `form.todo` width/padding rules |
| `common.css.scss` | No changes | `--font-size-medium-baseline: 16px` at 767px already establishes the 16px body base |
| `themes/*.css.scss` | No changes | Theme files do not target `.todo-form` |
| `_form.html.erb` | Replace table/tr/td with div/div/div; keep all `f.` field helpers and onclick attributes | `form_with` model binding, `.todo` class on form, submit onclick handler strings |
| `_todo_gadget.html.erb` | Update locale key text ("新規"→"追加") | Link path, CSS class, AJAX onclick, complete-group structure |
| `config/locales/ja.yml`, `en.yml` | Update `welcome.todo_gadget.new_link` (and aria_label variant) | All other locale keys; i18n parity test continues to enforce key symmetry |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Root cause (link untappable) | HIGH | Direct code reading — `pointer-events: none` under `@media (hover: none)` is unambiguous |
| Form flex layout (selector rename) | HIGH | Mechanical — existing SCSS flex properties are layout-agnostic |
| iOS auto-zoom (16px threshold) | MEDIUM | Confirmed by multiple authoritative sources; body is already 16px so risk is low |
| touch-action: manipulation | MEDIUM | Browser support confirmed (Safari 9.3+); standard modern approach |
| No auto-focus after AJAX | MEDIUM | iOS restriction is well-documented; behavior verified against known browser constraints |

---

## Sources

- [16px or Larger Text Prevents iOS Form Zoom — CSS-Tricks](https://css-tricks.com/16px-or-larger-text-prevents-ios-form-zoom/)
- [Defensive CSS — Input zoom on iOS Safari](https://defensivecss.dev/tip/input-zoom-safari/)
- [300ms tap delay, gone away — Chrome for Developers](https://developer.chrome.com/blog/300ms-tap-delay-gone-away)
- Internal codebase: `todos.css.scss`, `welcome.css.scss`, `todos/_form.html.erb`, `welcome/_todo_gadget.html.erb`, `todos.js`, `common.css.scss`

---
*Stack research for: v1.37.0 モバイルでのタスク追加機能*
*Researched: 2026-06-26*
