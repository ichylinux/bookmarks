# Architecture Research

**Domain:** Mobile-friendly inline todo add form — v1.37.0
**Researched:** 2026-06-26
**Confidence:** HIGH (all findings derived from direct codebase reading)

## Standard Architecture

### System Overview

```
GADGET CONTEXT (inline, AJAX-injected)
┌────────────────────────────────────────────────────────┐
│  <div class="gadget todo">   ← .todo ancestor scope    │
│    [gadget header]                                      │
│      .todo-gadget-new-link ──→ todos.new_todo()         │
│                                    ↓ $.get new_todo_path│
│    <ol>                            ↓ {format:'html'}    │
│      <li>                          ↓                    │
│        _form.html.erb  ←───────────┘                   │
│        (table.todo-form → CSS-overridden to flex row)   │
│      </li>                                              │
│    </ol>                                                │
└────────────────────────────────────────────────────────┘

STANDALONE CONTEXT (/todos/new, /todos/:id/edit)
┌────────────────────────────────────────────────────────┐
│  new.html.erb / edit.html.erb                          │
│    <%= render 'form' %>                                 │
│      _form.html.erb                                     │
│      (table.todo-form → renders as REAL HTML TABLE     │
│       because .todo ancestor is absent)                 │
└────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| File | Responsibility | Contexts that use it |
|------|----------------|----------------------|
| `app/views/todos/_form.html.erb` | Shared form HTML — `<table class="todo-form">` with priority select, title input, submit | Gadget inline (AJAX), `/todos/new`, `/todos/:id/edit` |
| `app/views/todos/new.html.erb` | Standalone new-task page — only `<%= render 'form' %>` | `/todos/new` page load |
| `app/views/todos/edit.html.erb` | Standalone edit page — only `<%= render 'form' %>` | `/todos/:id/edit` page load |
| `app/assets/stylesheets/todos.css.scss` | All todo CSS — gadget-scoped flex override on `form.todo table.todo-form` | Both contexts (scoping differs) |
| `app/assets/javascripts/todos.js` | `todos.new_todo()`, `todos.create_todo()`, `todos.update_todo()`, mobile double-tap, MOBILE_MQ | Gadget only (JS not involved in standalone page submit) |
| `app/views/welcome/_todo_gadget.html.erb` | Gadget container — renders `.gadget.todo` div, gadget header with "add" link, `<ol>` list | Welcome page only |
| `config/locales/ja.yml` / `en.yml` | `welcome.todo_gadget.new_link` (header link text); `todos.form.create` / `todos.form.update` (submit button text) | Both contexts |

## Critical Finding: The Table is Already Flex in Gadget Context

`todos.css.scss` already transforms `table.todo-form` into a flex row — **but only when the form is inside a `.todo` ancestor:**

```scss
.todo {                                   // matches .gadget.todo div
  form.todo table.todo-form {
    display: block;
    tbody { display: block; }
    tr {
      display: flex;                      // ← flex row already applied
      flex-wrap: nowrap;                  // ← THIS is the mobile problem
      align-items: center;
      width: 100%;
    }
    td:first-child  { flex: 0 0 auto; width: 3.5em; }   // priority
    td:nth-child(2) { flex: 1 1 0; min-width: 0; }      // title (grows)
    td:last-child   { flex: 0 0 auto; }                  // submit (fixed)
  }
}
```

The mobile problem is `flex-wrap: nowrap` forcing all three fields into one line on a ~320–375px viewport. The submit button and priority select eat ~120px combined, leaving ~200px for the title field — cramped and worse in English (`4.5em` priority width vs `3.5em` Japanese).

**On the standalone page** (`/todos/new`, `/todos/:id/edit`), no `.todo` ancestor exists, so none of these rules apply. The `<table>` renders as a real HTML table — potentially overflowing on mobile.

## Recommended Architecture: CSS-Only + Minimal View Wrapper

### The Approach

**Step 1 — Add `.todo` wrapper in `new.html.erb` and `edit.html.erb`:**

```erb
<%# was: <%= render 'form' %> %>
<div class="todo">
  <%= render 'form' %>
</div>
```

This makes the standalone page share the same CSS scope as the gadget. The `.todo` styles for `ol`/`li`/`span` elements have no effect (those elements don't appear on standalone pages).

**Step 2 — Add a single `@media` block inside the existing `.todo { }` scope in `todos.css.scss`:**

```scss
@media (max-width: 767px) {
  form.todo table.todo-form {
    tr { flex-wrap: wrap; }
    td:last-child {
      flex: 1 0 100%;
      text-align: right;
    }
  }
}
```

This produces a two-row mobile layout:
- Row 1: `[Priority ~3.5em][Title — flex: 1, fills remaining width]`
- Row 2: `[Submit button — full width, right-aligned]`

Both gadget and standalone contexts get identical mobile behavior once the `.todo` wrapper is present.

### Why Not the Alternatives

**Option B — Replace `<table>` with `<div>` in `_form.html.erb`:**
The `<table>` is already CSS-overridden away from table semantics (it's `display: block` → flex). A div refactor requires rewriting all `td`/`tr` selectors in `todos.css.scss` and touching the shared partial — higher risk for zero visible benefit. Rejected.

**Option C — Top-level CSS with no wrapper div:**
A top-level `form.todo table.todo-form { display: flex }` conflicts with `.modern table { width: auto }` — both have specificity (0,1,1). The current nested selector `.todo form.todo table.todo-form` wins at (0,2,1) precisely because of the ancestor. Adding `flex-wrap: wrap` at top level without also setting `display: flex` on `tr` is a no-op for standalone pages. Rejected.

## Shared Partial Constraint: Impact Matrix

| Change | Risk to Gadget Inline | Risk to `/todos/new` | Risk to `/todos/:id/edit` |
|--------|----------------------|---------------------|--------------------------|
| CSS `@media` inside `.todo` scope | None — selector already established | None — covered by new wrapper | None — covered by new wrapper |
| Add `<div class="todo">` wrapper in `new.html.erb` / `edit.html.erb` | None — doesn't touch gadget at all | Low — `.todo` styles for `ol`/`li`/`span` don't fire (no such elements) | Low — same |
| `_form.html.erb` — NO CHANGE | Safe | Safe | Safe |

## Data Flow

### Inline Add (Gadget Mobile Path)

```
User taps "追加" link (.todo-gadget-new-link)
    ↓ onclick: todos.new_todo(this)
    ↓ $.get(new_todo_path, {format: 'html'})
    ↓
TodosController#new → render '_form' (HTML fragment)
    ↓ returns <table class="todo-form"> markup
    ↓
ol.prepend('<li>' + html + '</li>')
    ↓
Form is now inside .gadget.todo → all .todo CSS applies
    ↓ mobile @media block fires if viewport ≤767px
    ↓ two-row layout: [priority][title] / [submit]
    ↓
User fills title, taps submit
    ↓ onclick: todos.create_todo(trigger)
    ↓ if title empty: removes <li> (cancel)
    ↓ else: $.post(action, form.serialize())
    ↓
TodosController#create → render todo partial (HTML)
    ↓
form.closest('li').after(html).remove() — new todo appears, form removed
```

### Standalone New Page (/todos/new)

```
User navigates to /todos/new
    ↓
TodosController#new → new.html.erb
    ↓ <div class="todo"> wrapper (new)
    ↓ render '_form'
    ↓
Page renders with flex layout + mobile @media identical to gadget
    ↓
User fills form, clicks submit
    ↓ onclick: todos.create_todo(trigger) (same function)
    ↓ $.post(action, form.serialize())
    ↓
TodosController#create → response
```

## New vs Modified Files

### Files to MODIFY

| File | What Changes | Phase |
|------|--------------|-------|
| `config/locales/en.yml` | `welcome.todo_gadget.new_link`: `"new"` → `"Add"` (Japanese already reads「追加」) | 1: Locale |
| `app/views/todos/new.html.erb` | Add `<div class="todo">` wrapper around `render 'form'` | 2: Mobile CSS |
| `app/views/todos/edit.html.erb` | Add `<div class="todo">` wrapper around `render 'form'` | 2: Mobile CSS |
| `app/assets/stylesheets/todos.css.scss` | Add `@media (max-width: 767px)` block inside existing `.todo { }` scope | 2: Mobile CSS |

### Files That MUST NOT Change

| File | Reason |
|------|--------|
| `app/views/todos/_form.html.erb` | Shared partial — zero changes needed; table structure + form attributes stay exactly as-is |
| `app/assets/javascripts/todos.js` | No JS behavior changes needed; `todos.new_todo()` / `create_todo()` / `update_todo()` work as-is; mobile layout is CSS-only |
| `app/views/welcome/_todo_gadget.html.erb` | The "追加" text comes from locale key only; no structural change needed |

## Architectural Patterns to Follow

### Pattern 1: Mobile Override Inside Existing Scope

**What:** Add `@media` rules as a block inside the `.todo { }` SCSS scope, co-located with the existing form rules.

**When:** All mobile overrides for the gadget and (after wrapper addition) standalone forms live together in `todos.css.scss`.

**Example placement:**
```scss
.todo {
  // ... existing gadget/list rules ...

  form.todo table.todo-form {
    // ... existing desktop flex rules ...
  }

  // Add this block — mirrors placement of existing
  // li.highlighted and .todo-highlight-btn mobile blocks
  @media (max-width: 767px) {
    form.todo table.todo-form {
      tr { flex-wrap: wrap; }
      td:last-child {
        flex: 1 0 100%;
        text-align: right;
      }
    }
  }

  // ... existing @media (max-width: 767px) { li.highlighted ... } ...
}
```

### Pattern 2: Locale-First Text Changes

**What:** The header link text is driven entirely by `t('welcome.todo_gadget.new_link')` — change the locale YAML, no ERB or JS changes needed.

**When:** Any UI text already wired through locale keys. The `en.yml` key is the only file to touch for the text change.

### Pattern 3: AJAX Form Re-injection is CSS-Transparent

**What:** `todos.new_todo()` injects form HTML via `ol.prepend('<li>' + html + '</li>')`. The form lands inside `.gadget.todo`, so CSS flex rules and the new mobile `@media` block apply automatically. No JS rewiring needed.

**When:** All future responsive changes to the form layout can remain CSS-only.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Modifying `_form.html.erb` Structure

**What people do:** Replace `<table class="todo-form">` with `<div>` elements or add conditional class logic.

**Why it's wrong:** The partial is rendered in 3 contexts. The `<table>` does not cause layout problems — it's already CSS-overridden to flex in gadget context. Changing the HTML requires updating all CSS selectors under `form.todo table.todo-form` and risks breaking edit-mode inline rendering.

**Do this instead:** Keep the table. Add a `@media` CSS override and add the `.todo` ancestor wrapper to standalone views.

### Anti-Pattern 2: Using JavaScript for Mobile Layout

**What people do:** Detect mobile viewport in `todos.js` and dynamically reorder or re-stack form elements.

**Why it's wrong:** The codebase already uses `MOBILE_MQ` for interaction detection (double-tap, highlight visibility), not layout. JS-driven layout creates repaint flicker and adds test surface area. CSS `@media` is the correct tool for layout changes.

**Do this instead:** `@media (max-width: 767px)` inside `.todo { }` — matches the established 767px breakpoint used by both `todos.css.scss` and `todos.js`.

### Anti-Pattern 3: Duplicating `_form.html.erb` into a Mobile Variant

**What people do:** Create `_mobile_form.html.erb` and conditionally render based on request type or user agent.

**Why it's wrong:** Two partial sources for the same data diverge over time. The `todos.create_todo()` / `todos.update_todo()` functions assume a single form structure. User-agent-based rendering is unreliable.

**Do this instead:** Single partial with responsive CSS. The `flex-wrap: wrap` model handles both desktop and mobile gracefully in one stylesheet.

### Anti-Pattern 4: Top-Level Media Query Without Flex Ancestor Setup

**What people do:** Write a top-level `@media { form.todo table.todo-form tr { flex-wrap: wrap } }` without ensuring `display: flex` is also set in that context.

**Why it's wrong:** `flex-wrap: wrap` has no effect unless `display: flex` is already on the element. On standalone pages without the `.todo` ancestor, `tr` is not flex, so the media query does nothing.

**Do this instead:** Either add the `.todo` wrapper div (preferred) or duplicate the full flex setup at top level while carefully managing specificity against `.modern table`.

## Suggested Build Phase Order

### Phase 1: Locale text update

**Goal:** Confirm and update `new_link` text in `en.yml` from `"new"` to `"Add"`.

**Files:** `config/locales/en.yml` only.

**Why first:** Zero risk, isolated change. Japanese is already「追加」. Unblocks locale-dependent Cucumber steps in Phase 3.

### Phase 2: Mobile-friendly CSS + standalone view wrapper

**Goal:** Make the inline form comfortable on mobile viewports in both gadget and standalone contexts.

**Files:**
- `app/assets/stylesheets/todos.css.scss` — add `@media` block inside `.todo { }`
- `app/views/todos/new.html.erb` — add `.todo` wrapper div
- `app/views/todos/edit.html.erb` — add `.todo` wrapper div

**Does not touch:** `_form.html.erb`, `todos.js`, `_todo_gadget.html.erb`.

### Phase 3: Test suite + tri-suite gate

**Goal:** Minitest CSS structure tests + Cucumber mobile form scenario; all three suites green.

**Minitest additions:**
- CSS contract test asserting `@media (max-width: 767px)` block present in `todos.css.scss`
- CSS contract test asserting `flex-wrap: wrap` rule present in mobile block

**Cucumber additions:**
- Mobile viewport (`@mobile_portal`) scenario: sign in, navigate to welcome, tap "追加" link, fill title input, tap submit, verify new task appears in list

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `_todo_gadget.html.erb` ↔ `_form.html.erb` | AJAX — `todos.new_todo()` fetches `new_todo_path`, response injected into `<ol>` | Form always lands inside `.gadget.todo` — CSS auto-applies |
| `_form.html.erb` ↔ `TodosController#new` | Server renders partial with `@todo = Todo.new` | Already set; no change needed |
| `todos.css.scss` ↔ `new.html.erb` / `edit.html.erb` | Selector `.todo form.todo table.todo-form` requires `.todo` ancestor | Adding `.todo` wrapper div is the integration connector for standalone pages |
| Mobile breakpoint | `MOBILE_MQ = window.matchMedia('(max-width: 767px)')` in JS mirrors `@media (max-width: 767px)` in CSS | Must remain in sync — 767px is the established app-wide mobile breakpoint |

### Locale Key State at Research Time

| Key | `ja.yml` | `en.yml` | Action Needed |
|-----|----------|----------|---------------|
| `welcome.todo_gadget.new_link` | `"追加"` (already correct) | `"new"` | Update en to `"Add"` |
| `welcome.todo_gadget.new_link_aria_label` | `"タスクを追加"` | `"Add task"` | None — both already correct |
| `todos.form.create` | `"登録"` | `"Create"` | None — submit button text unchanged |
| `todos.form.update` | `"更新"` | `"Update"` | None — unchanged |

## Sources

- Direct codebase reading: `app/views/todos/_form.html.erb`, `app/assets/stylesheets/todos.css.scss`, `app/assets/javascripts/todos.js`, `app/views/welcome/_todo_gadget.html.erb`, `app/views/todos/new.html.erb`, `app/views/todos/edit.html.erb`, `config/locales/ja.yml`, `config/locales/en.yml`
- Project context: `.planning/PROJECT.md` — v1.37.0 milestone goal and architecture constraints (Confidence: HIGH — authoritative first-party source)

---
*Architecture research for: v1.37.0 mobile-friendly inline todo add form*
*Researched: 2026-06-26*
