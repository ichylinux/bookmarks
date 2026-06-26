# Feature Landscape

**Domain:** Mobile-friendly inline todo-add form (jQuery server-rendered Rails app)
**Researched:** 2026-06-26
**Milestone:** v1.37.0 — モバイルでのタスク追加機能

---

## Codebase Baseline (HIGH confidence — direct code reading)

The existing form (`app/views/todos/_form.html.erb`) uses a `<table class="todo-form">` with a single `<tr>` containing three `<td>` cells: priority `<select>`, title `<text_field>`, and submit `<button>`. This layout is correct on desktop but breaks on narrow screens because table cells enforce minimum content widths and do not wrap. The `<li>` injected by `todos.new_todo()` spans the gadget width, and on 320–390px devices the three columns compress or overflow horizontally.

The interaction model already in place:
- "新規" link in gadget header → `onclick: todos.new_todo(this)` → AJAX GET `new_todo_path?format=html` → injects `<li>{form HTML}</li>` at top of `<ol>`
- Submit: `todos.create_todo(trigger)` → if title empty, removes `<li>`; if filled, POSTs and replaces `<li>` with returned todo HTML
- Mobile breakpoint is `MOBILE_MQ = window.matchMedia('(max-width: 767px)')` — matching the existing `$portal-mobile-breakpoint`
- The same `_form.html.erb` partial is shared for both inline add and the `/todos/new` standalone full page; both paths must remain working after refactor

---

## Table Stakes

Features users expect. Missing = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Label rename: "新規" → "追加" | Milestone requirement; "追加" is the standard term for add-action in Japanese UI | Low | ja.yml + en.yml locale keys: `welcome.todo_gadget.new_link` and `new_link_aria_label` |
| Mobile-stacked form layout | On ≤767px screens, horizontal 3-column table overflows; vertical stacking is the standard mobile form pattern | Medium | Replace `<table>` with `<div class="todo-form">` + flex layout; on mobile: `flex-direction: column`, each field `width: 100%`; on desktop: `flex-direction: row` or compact |
| Full-width inputs on mobile | Touch targets must span the container for comfortable interaction; 44px minimum height per Apple HIG / Google Material | Low | CSS `width: 100%` on `<select>` and `<input type="text">` in mobile media query |
| Minimum touch target height | 44px is the platform standard; the existing `<select>` and `<button>` may render shorter on some devices | Low | `min-height: 44px` on form controls in mobile CSS |
| Auto-focus title input after injection | Standard mobile pattern: when form appears, keyboard opens automatically on the primary field, saving one tap | Low | In `todos.new_todo` AJAX callback, call `$(li).find('input[type="text"]').focus()` after `ol.prepend(...)`; guard with `MOBILE_MQ.matches` to avoid disrupting desktop scroll |
| Existing empty-title dismiss behavior preserved | `todos.create_todo` already removes `<li>` when title is empty — this is the lightweight cancel for power users | None | No change required; must not be broken by layout refactor |
| Desktop layout unchanged or improved | PROJECT.md requirement: "デスクトップ表示は現状を維持または改善" | Low | Flexbox row layout on desktop is a drop-in replacement for the table row; verify `/todos/new` standalone page renders correctly too |
| ja/en locale key parity | All new/changed locale keys must exist in both `ja.yml` and `en.yml`; parity enforced by existing i18n test | Low | One locale change (new_link text) plus any aria-label update |

---

## Differentiators

Features that set the interaction apart. Not expected from the milestone spec, but add meaningful polish.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Explicit cancel button (mobile) | Tap-outside is ambiguous on mobile (NN/G: users may not know what happened); a labeled "キャンセル" link removes the `<li>` explicitly without requiring an empty submit | Low | Add `<a href="#" class="todo-form-cancel">キャンセル</a>` inside the form; JS handler: `$(this).closest('li').remove()`. Locale key for ja/en. No new dependency. |
| Priority field visually secondary on mobile | On narrow screens, priority is secondary to title; showing title first reduces visual noise; easy via CSS `order:` property | Low | In the stacked flex column, use `order: -1` on the title input to move it above priority without changing DOM order (or reorder in HTML directly) |
| Form scrolls into view | When soft keyboard opens, the form row at top of `<ol>` may be pushed off screen; `scrollIntoView()` after focus ensures visibility | Low | One line in `todos.new_todo` callback after `.focus()`: `ol.find('li:first-child')[0].scrollIntoView({behavior: 'smooth', block: 'start'})` |

---

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Modal / overlay for add form | Conflicts with established inline pattern; adds complexity; breaks the "form in list" paradigm already used for edit | Keep the existing AJAX-inject-into-`<ol>` pattern |
| Bottom sheet (native-style) | Requires significant new JS and CSS; no React/native layer available; out of scope per PROJECT.md "no new JS complexity" constraint | Use in-list stacked form |
| Floating Action Button (FAB) | Changes the interaction model entirely; conflicts with the header link that already exists; major UX regression | Keep the "追加" header link as the trigger |
| Drag-to-dismiss / swipe-to-cancel | Complex gesture that conflicts with existing tap selection and gadget drag; requires new JS library or complex handler | Use empty-title-dismiss + optional explicit cancel button |
| Auto-save / real-time persistence | PROJECT.md Standing Out of Scope: "Real-time autosave — explicit save is the correct UX for deliberate capture" | Submit button or Enter key only |
| Full-page redirect for inline add | The whole point is inline; navigating to `/todos/new` full page is a regression for dashboard use | Keep AJAX injection; `/todos/new` page remains as fallback only |
| Multi-step add (priority then title then confirm) | Introduces friction; single-step is the established pattern in this app and competitors (Todoist, Things) | One-step inline form |
| Virtual keyboard suppression (preventDefault on focus) | Prevents soft keyboard from opening, breaking input on mobile | Allow default keyboard behavior on focus |
| Table-in-table nested layout | Adds specificity complexity and defeats the purpose of the layout refactor | Replace table entirely with flexbox |

---

## Feature Dependencies

```
Label rename (新規 → 追加)
  └─ locale keys: ja.yml + en.yml new_link + aria_label updated

Form layout refactor (table → flex)
  └─ _form.html.erb: table markup removed, div.todo-form added
  └─ todos.css.scss: .todo-form flex rules + @media (max-width: 767px)
  └─ Must not break: todos/new standalone page (same partial)
  └─ Must not break: edit form path (todos.open_edit → same partial via AJAX)

Auto-focus title input
  └─ Depends on: form layout refactor (input must be findable in new markup)
  └─ todos.js todos.new_todo: add .focus() call in AJAX callback

Cancel button (optional differentiator)
  └─ Depends on: form layout refactor (cancel placed inside .todo-form div)
  └─ todos.js: one-line handler for .todo-form-cancel click → closest('li').remove()
  └─ locale key: todos.form.cancel (ja + en)

Tests (Minitest + Cucumber)
  └─ Depends on: all above changes complete
  └─ Cucumber: selector updates if cancel button added; mobile viewport scenario
```

---

## MVP Recommendation

Prioritize for v1.37.0:

1. **Label rename** — one locale change, zero risk, matches milestone goal exactly
2. **Form layout refactor** — the core deliverable; table → flex, mobile stacked, desktop row
3. **Auto-focus title input on mobile** — single line in `todos.new_todo` callback; high UX payoff for minimal effort
4. **Tests** — Minitest structure assertions for new CSS classes; Cucumber mobile form scenario

Defer from this milestone:
- **Explicit cancel button** — useful but not in PROJECT.md target features list; add only if the empty-title dismiss is deemed insufficient during UAT
- **`scrollIntoView` polish** — add only if manual testing reveals the form is hidden by keyboard on the test device

---

## Implementation Notes (from codebase analysis, HIGH confidence)

**HTML change in `_form.html.erb`:**
Replace `<table class="todo-form"><tr><td>…</td><td>…</td><td>…</td></tr></table>` with a `<div class="todo-form">` containing the three form controls as direct children or wrapped in a single inner div. The `form_with` wrapper and submit `onclick` handlers (`todos.create_todo`, `todos.update_todo`) are unchanged.

**CSS location:** Use `todos.css.scss` for todo-form styles (consistent with project per-feature SCSS convention). Breakpoint is `767px` to match `MOBILE_MQ` in `todos.js` and `$portal-mobile-breakpoint` used throughout the project.

**JS change in `todos.js` `new_todo` function** — one addition in the AJAX callback:
```javascript
$.get(url, {format: 'html'}, function(html) {
  ol.prepend('<li>' + html + '</li>');
  if (MOBILE_MQ.matches) {
    ol.find('li:first-child input[type="text"]').focus();
  }
});
```

**Standalone `/todos/new` page:** The partial renders in a full-page context. The flex layout renders sensibly there too — on desktop as a horizontal form row, on mobile as a stacked form. No JS changes needed for this path.

**Edit form path:** `todos.open_edit($li)` either focuses an existing text input or fetches the edit partial via AJAX. The refactored partial is used for edit too — the stacked layout applies equally and is an improvement. No JS changes needed for the edit path.

---

## Sources

- Codebase direct analysis: `app/views/todos/_form.html.erb`, `app/assets/javascripts/todos.js`, `app/views/welcome/_todo_gadget.html.erb`, `.planning/PROJECT.md` (HIGH confidence)
- Smashing Magazine mobile form best practices: https://www.smashingmagazine.com/2018/08/best-practices-for-mobile-form-design/ (MEDIUM confidence — cross-checked)
- NN/G Cancel vs Close: https://www.nngroup.com/articles/cancel-vs-close/ (MEDIUM confidence)
- MobileSpoon keyboard usability rules: https://www.mobilespoon.net/2018/12/10-usability-rules-keyboard-mobile-app.html (MEDIUM confidence)
- CSS Tricks Flexbox guide: https://css-tricks.com/snippets/css/a-guide-to-flexbox/ (MEDIUM confidence)
