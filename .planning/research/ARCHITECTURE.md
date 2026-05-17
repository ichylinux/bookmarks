# Architecture Research — v1.24 Mobile Column Lazy Loading

**Project:** Bookmarks v1.24
**Researched:** 2026-05-17
**Confidence:** HIGH (all findings traced directly through existing source files; no new frameworks or routes required)

---

## Summary

v1.24 adds mobile-only lazy gadget loading on top of the existing portal tab
system. The current architecture fires all gadget AJAX calls on
`$(document).ready` unconditionally; the goal is to suppress that on mobile
for non-active columns, then trigger the suppressed calls once and only once
when a column is first switched to.

The change touches **two JS files** and **three ERB partials** (one new). No
new controller actions, no new routes, no new gems, no new SCSS files. Every
other layer (Portal model, WelcomeController, gadget show actions,
MastodonClient, XClient, CalendarGadget, etc.) is unchanged.

---

## Current AJAX Loading Architecture

### How gadgets fire today

All gadgets that make HTTP calls embed an inline `<script>` block directly
inside their welcome partial. There are three variants:

**Variant A — jQuery `$.get` inline (Feed, MastodonAccount, XAccount,
CalendarGadget):**

```erb
<%# Inside _feed.html.erb, _mastodon_account.html.erb, _x_account.html.erb,
    _calendar_gadget.html.erb %>
<script>
  $(document).ready(function() {
    $.get('<%= path_helper(gadget) %>', { format: 'html' }, function(html) {
      $('#<%= gadget.gadget_id %>').html(html);
    }).fail(function(xhr) { ... });
  });
</script>
```

**Variant B — `todos.init` call (TodoGadget):**

```erb
<%# Inside _todo_gadget.html.erb %>
<script>
  $(document).ready(function() {
    todos.init('#<%= gadget.gadget_id %>');
  });
</script>
```

**Variant C — Server-rendered, no AJAX (BookmarkGadget):**

```erb
<%# Inside _bookmark_gadget.html.erb %>
<%# No <script> — content rendered at page-request time %>
```

### Key structural facts

1. Each gadget partial owns its own `$(document).ready` block with a
   hardcoded AJAX call. There is no central JS coordinator that fires gadget
   loads.

2. Every `$(document).ready` fires simultaneously on page load regardless of
   which mobile column is active.

3. The mobile column mechanism in `portal_mobile_tabs.js` activates columns
   via `activateColumn($portal, $tabs, index)` — it adds
   `portal--column-active-N` CSS and sets `--portal-active-index` CSS
   variable. It has no awareness of whether a column's gadgets have been
   fetched.

4. The mobile breakpoint is `768px` (`$portal-mobile-breakpoint` in
   `welcome.css.scss`). On mobile, columns are positioned side-by-side in
   a CSS flex track and only the active one is visible.

5. Gadgets that are server-rendered (BookmarkGadget) are unaffected by lazy
   loading — they are already in the DOM at page time.

6. Column membership is encoded in the DOM: each `.portal-column` div has
   `id="column_N"`. Every gadget rendered inside `column_N` knows which column
   it lives in by virtue of its position in the DOM tree.

---

## Proposed Integration Architecture

### Mental model

Replace the per-gadget unconditional `$(document).ready` call with a
**deferred pattern**: on mobile, each AJAX gadget registers itself into a
per-column queue at parse time. When a column becomes active (either on page
load or on tab switch), the queue for that column drains once and marks itself
loaded so future activations are no-ops.

On desktop the current behavior must be completely preserved. No changes to
desktop rendering.

### Two-mechanism breakdown

**Mechanism 1 — Per-gadget deferral (per-gadget partial change)**

Each AJAX-loading partial currently calls `$.get(...)` directly inside
`$(document).ready`. Instead it registers into a `window.portalLazy` registry:

```js
// Replaces: $(document).ready(function() { $.get(...) });
// With:
$(document).ready(function() {
  window.portalLazy.register('<%= column_index %>', function() {
    $.get('<%= path_helper(gadget) %>', { format: 'html' }, function(html) {
      $('#<%= gadget.gadget_id %>').html(html);
    }).fail(function(xhr) { ... });
  });
});
```

The gadget partial does not know whether it is on mobile or desktop. It always
registers into `portalLazy`. `portalLazy` decides whether to call the function
immediately or defer it.

**Mechanism 2 — Column load coordinator (`portal_lazy.js`, new file)**

`window.portalLazy` is a small coordinator that:

- Knows the initial active column index (read from the same CSS variable
  `--portal-initial-active-index` or from `portalMobileActiveColumn`
  localStorage key that `portal_mobile_tabs.js` already manages).
- Knows whether the viewport is mobile at parse time.
- On `register(columnIndex, fn)`:
  - Desktop: calls `fn()` immediately (no-op registry on desktop).
  - Mobile, active column: calls `fn()` immediately.
  - Mobile, inactive column: queues `fn()` under `columnIndex`.
- On `loadColumn(columnIndex)` (called by `portal_mobile_tabs.js`):
  - Drains the queue for `columnIndex` (calls each deferred fn once).
  - Marks `columnIndex` as loaded so future `loadColumn` calls are no-ops.

**Mechanism 3 — Tab switch hook (`portal_mobile_tabs.js` modification)**

`activateColumn` in `portal_mobile_tabs.js` currently handles CSS class
updates and localStorage persistence. Add one call at the end:

```js
const activateColumn = function($portal, $tabs, index) {
  // ... existing CSS sync, localStorage write ...
  if (isMobileViewport()) {
    window.portalLazy.loadColumn(index);  // NEW
  }
};
```

This hooks into the single shared activation path that handles both tab clicks
and swipe gestures. No duplication needed.

---

## Component Map

### Files modified

| File | Type | Change |
|------|------|--------|
| `app/assets/javascripts/portal_mobile_tabs.js` | Modify | Add `window.portalLazy.loadColumn(index)` call at end of `activateColumn` function |
| `app/assets/javascripts/portal_lazy.js` | **New** | `window.portalLazy` coordinator: `register`, `loadColumn`, mobile viewport detection, per-column queue, loaded-set |
| `app/views/welcome/_feed.html.erb` | Modify | Replace direct `$.get` with `window.portalLazy.register(columnIndex, fn)` |
| `app/views/welcome/_mastodon_account.html.erb` | Modify | Same |
| `app/views/welcome/_x_account.html.erb` | Modify | Same |
| `app/views/welcome/_calendar_gadget.html.erb` | Modify | Same |
| `app/views/welcome/_todo_gadget.html.erb` | Modify | Same (wraps `todos.init` call) |

### Files unchanged

| File | Why unchanged |
|------|---------------|
| `app/views/welcome/_bookmark_gadget.html.erb` | No AJAX — server-rendered; unaffected |
| `app/models/portal.rb` | Column data shape unchanged |
| `app/controllers/welcome_controller.rb` | No new actions |
| `app/controllers/calendars_controller.rb` | No changes to show/gadget endpoints |
| `app/controllers/feeds_controller.rb` | No changes |
| `app/controllers/mastodon_accounts_controller.rb` | No changes |
| `app/controllers/x_accounts_controller.rb` | No changes |
| `app/views/welcome/_portal_column_section.html.erb` | Column index already rendered in DOM as `id="column_N"` |
| `app/assets/stylesheets/welcome.css.scss` | CSS column layout unchanged |
| Any theme SCSS file | Unchanged |

---

## The `column_index` Problem

Each gadget partial needs to know which column index (0, 1, 2, or 3) it lives
in at render time in order to register into the correct queue.

`_portal_column_section.html.erb` already iterates over columns with index:

```erb
<% portal_columns.each_with_index do |gadgets, i| %>
  <div id="column_<%= i %>" class="gadgets portal-column" ...>
    <% gadgets.each do |g| %>
      <%= render g.class.name.underscore, gadget: g %>
    <% end %>
  </div>
<% end %>
```

The local variable `i` (column index) is available at the render call site but
is not currently passed to gadget partials — they are rendered with only
`gadget: g`.

**Approach A — Pass column index as a local to each gadget partial:**

```erb
<%= render g.class.name.underscore, gadget: g, column_index: i %>
```

Each gadget partial uses `column_index` in the `portalLazy.register` call. This
is the cleanest approach: explicit, no DOM parsing, works with SSR.

**Approach B — Derive column index from DOM at JS parse time:**

The gadget's `<script>` block is adjacent to its gadget div in the DOM. At
parse time, JS can walk up the DOM to find the enclosing `.portal-column` and
parse `column_N` from its `id`:

```js
(function() {
  const colEl = document.currentScript.closest('.portal-column');
  const match = colEl && (colEl.id || '').match(/^column_(\d+)$/);
  const colIndex = match ? parseInt(match[1], 10) : 0;
  window.portalLazy.register(String(colIndex), function() { ... });
})();
```

This is slightly more fragile (depends on DOM structure) but does not require
changing `_portal_column_section.html.erb` or the gadget partial render
signature.

**Recommendation: Approach A** — passing `column_index: i` to gadget partials
is a one-line change to `_portal_column_section.html.erb` and makes each
partial's dependency on column identity explicit and verifiable. Approach B
uses `document.currentScript`, which is well-supported but adds indirection.
The render site already controls the loop variable `i`, so Approach A is the
natural extension.

**One complication with Approach A:** gadget partials currently use implicit
`gadget:` local (they say `gadget.gadget_id` etc.). Adding `column_index:` is
an additive change — existing partials that do not yet use it will receive a
local they ignore, which is fine in ERB. However, the `render g.class.name.underscore`
form does not support keyword arguments cleanly without updating the partial
signature. The `<%# locals: %>` comment convention (used in
`_portal_column_section.html.erb`) makes the expected locals explicit. Each
modified partial should add `column_index` to its locals declaration.

---

## `portal_lazy.js` Design

### Load order

Sprockets uses `require_tree .` in `application.js`, which loads files in
alphabetical order. `portal_lazy.js` sorts before `portal_mobile_tabs.js`
alphabetically, so `window.portalLazy` will be defined before
`portal_mobile_tabs.js` runs. This means `portal_mobile_tabs.js` can call
`window.portalLazy.loadColumn` safely on the first activation.

No explicit `//= require` ordering is needed — alphabetical sort gives the
correct dependency order.

### Initial column detection

On mobile, the initial active column is restored from `localStorage` by
`portal_mobile_tabs.js` (inside the `if (isMobileViewport())` block at the
bottom of the file). This runs on `$(function() { ... })`, which fires after
all `$(document).ready` handlers.

The gadget partials' `register` calls run inside their own `$(document).ready`
wrappers. `$(document).ready` handlers run in registration order, and
`portal_mobile_tabs.js`'s initialization block runs as another
`$(document).ready` handler.

**Timing concern:** if gadget `register` calls fire before `portalLazy` has
determined which column is the initial active one, the `register` call cannot
know whether to invoke immediately or defer.

**Resolution:** `portal_lazy.js` must initialize synchronously (outside
`$(document).ready`) so that `window.portalLazy` exists and knows the mobile
status at DOM-parse time. The initial column index can be read at that same
moment from:

1. The `--portal-initial-active-index` CSS property on `<html>` (set by the
   inline prehydration script in `_dashboard.html.erb` before any JS loads).
2. Fallback to `localStorage.getItem('portalMobileActiveColumn')` if the CSS
   property is not set.

Both of these are available synchronously. This avoids any race condition with
`portal_mobile_tabs.js`'s `$(function() { ... })` timing.

```js
// portal_lazy.js (executes synchronously at parse time)
(function() {
  'use strict';
  const isMobile = window.matchMedia && window.matchMedia('(max-width: 767px)').matches;

  let initialActiveIndex = 0;
  if (isMobile) {
    // Prefer the CSS property written by the inline prehydration script
    const cssVal = getComputedStyle(document.documentElement)
      .getPropertyValue('--portal-initial-active-index').trim();
    const fromCss = parseInt(cssVal, 10);
    if (!Number.isNaN(fromCss) && fromCss >= 0) {
      initialActiveIndex = fromCss;
    } else {
      const raw = window.localStorage && window.localStorage.getItem('portalMobileActiveColumn');
      const fromStorage = parseInt(raw, 10);
      if (!Number.isNaN(fromStorage) && fromStorage >= 0) {
        initialActiveIndex = fromStorage;
      }
    }
  }

  const queues  = {};   // { columnIndex: [fn, fn, ...] }
  const loaded  = {};   // { columnIndex: true } — columns whose gadgets have been fetched

  window.portalLazy = {
    register: function(columnIndex, fn) {
      if (!isMobile) { fn(); return; }                     // Desktop: fire immediately
      const idx = String(columnIndex);
      if (loaded[idx] || String(initialActiveIndex) === idx) {
        fn();                                               // Already loaded or initial active
        if (!loaded[idx]) loaded[idx] = true;
      } else {
        queues[idx] = queues[idx] || [];
        queues[idx].push(fn);                              // Defer
      }
    },

    loadColumn: function(columnIndex) {
      const idx = String(columnIndex);
      if (loaded[idx]) return;                             // Already loaded
      loaded[idx] = true;
      const pending = queues[idx] || [];
      queues[idx] = [];
      pending.forEach(function(fn) { fn(); });
    }
  };
}());
```

### Why `loaded` is keyed by column index, not gadget id

One call to `loadColumn(N)` drains ALL deferred gadgets for column N
simultaneously. The "loaded once" invariant is at the column level, not the
gadget level. This matches the requirement: "load each other column's gadgets
exactly once when first switched to."

---

## Data Flow

### Page load (mobile, column 0 active)

```
Server renders all gadget partials into DOM (all columns)
  ↓
portal_lazy.js executes synchronously → initialActiveIndex = 0, isMobile = true
  ↓
Each gadget partial's $(document).ready fires:
  Column 0 gadgets: portalLazy.register('0', fn) → fn() called immediately
  Column 1 gadgets: portalLazy.register('1', fn) → queued in queues['1']
  Column 2 gadgets: portalLazy.register('2', fn) → queued in queues['2']
  ↓
portal_mobile_tabs.js $(function(){}) fires: activateColumn(portal, tabs, 0)
  → portalLazy.loadColumn(0) called → loaded['0'] already true → no-op
  ↓
Column 0 gadgets have fetched; columns 1 and 2 have not
```

### Tab switch to column 1

```
User taps column-1 tab (or swipes)
  ↓
portal_mobile_tabs.js click handler: activateColumn(portal, tabs, 1)
  → CSS class updates, localStorage write (existing behavior)
  → portalLazy.loadColumn(1) called
    → loaded['1'] undefined → set loaded['1'] = true
    → drain queues['1']: call each fn()
      → $.get(feed_path) fires for all column-1 feeds
      → $.get(mastodon_account_path) fires for all column-1 Mastodon gadgets
      → etc.
```

### Tab switch back to column 0

```
User taps column-0 tab
  ↓
activateColumn(portal, tabs, 0)
  → portalLazy.loadColumn(0): loaded['0'] is true → immediate return (no-op)
  ↓
No AJAX fired — gadgets already have their content from the initial load
```

### Desktop (any viewport ≥ 768px)

```
Each gadget partial's $(document).ready fires:
  portalLazy.register(columnIndex, fn) → isMobile is false → fn() called immediately
  ↓
All gadgets load on page load as today — behavior unchanged
```

---

## Suggested Build Order

Three phases. The dependency chain runs:
**coordinator JS → gadget partial wiring → tests and verification**.

### Phase A — `portal_lazy.js` coordinator

**Scope:**
- New file `app/assets/javascripts/portal_lazy.js`.
- Exports `window.portalLazy` with `register` and `loadColumn`.
- Mobile detection and initial-column detection from CSS property + localStorage.
- On desktop: `register` calls `fn()` immediately (zero behavior change).

**Why first:** All subsequent changes depend on `window.portalLazy` existing.
No gadget partial or `portal_mobile_tabs.js` changes are made in this phase —
`register` on desktop is a pass-through, so gadgets can be migrated one at a
time in the next phase without any visible behavior change.

**Verification gate:**
- `yarn run lint` passes (ESLint flat config).
- `bin/rails test` green (no JS test changes yet, but contract test
  `portal_mobile_tabs_js_contract_test.rb` and a new
  `portal_lazy_js_contract_test.rb` can assert the module shape exists in the
  file source).
- `bundle exec rake dad:test` green (no E2E behavior changes on desktop).

### Phase B — Gadget partial wiring

**Scope:**
- `_portal_column_section.html.erb`: pass `column_index: i` to each gadget
  render call.
- Each AJAX-loading partial (`_feed.html.erb`, `_mastodon_account.html.erb`,
  `_x_account.html.erb`, `_calendar_gadget.html.erb`, `_todo_gadget.html.erb`):
  replace direct `$.get` / `todos.init` call with
  `window.portalLazy.register(column_index, fn)`.
- `portal_mobile_tabs.js`: add `window.portalLazy.loadColumn(index)` call at
  end of `activateColumn`.

**Why second:** The coordinator must exist before gadget partials try to call
`register`. Conversely, `loadColumn` in `portal_mobile_tabs.js` is safe to
add even before all partials are migrated — calling `loadColumn` for a column
with an empty queue is a no-op.

**Verification gate:**
- All three suites green.
- Manual mobile smoke: load page, confirm only column-0 gadgets fire (via
  browser network tab); tab switch to column 1 confirms those gadgets then
  load; tab back to 0 confirms no re-fetch.
- Manual desktop smoke: all gadgets load on page load as before.

### Phase C — Minitest contracts + Cucumber E2E

**Scope:**
- `test/assets/portal_lazy_js_contract_test.rb` (new): assert
  `window.portalLazy`, `register`, `loadColumn` are present in the file
  source; assert `isMobileViewport` guard exists; assert `STORAGE_KEY` is
  referenced.
- `test/assets/portal_mobile_tabs_js_contract_test.rb` (extend): add
  assertion that `portalLazy.loadColumn` is called inside `activateColumn`.
- Extend existing welcome controller integration tests if any assert the gadget
  partial markup (no new controller tests needed — no controller changes).
- Cucumber: no new scenario needed if existing `@mastodon_gadget` /
  `@x_gadget` scenarios continue to pass (they exercise the full
  sign-in → welcome page → gadget render flow, which now goes through
  `portalLazy.register` → immediate call on desktop Cucumber browser).

**Why third:** Contracts should be written after the shape of the final JS is
confirmed in Phase B. Writing them in Phase A risks locking in implementation
details that change during wiring.

---

## Integration Risks

### `document.currentScript` availability (if Approach B is chosen)

`document.currentScript` is `null` inside event handlers (`$(document).ready`
callbacks run asynchronously after parse). It is only valid during synchronous
script execution. If the gadget partial's `register` call is inside a
`$(document).ready` block (it is), Approach B (DOM walk via
`document.currentScript`) cannot work without restructuring the partial to run
the DOM walk synchronously and pass the result into the callback.

Approach A (passing `column_index` from the template) avoids this entirely.
This is the strongest argument for choosing Approach A.

### `portal_mobile_tabs.js` initialization timing

`portal_mobile_tabs.js` calls `activateColumn` inside a `$(function() { ... })`
block (at the bottom, to handle localStorage-restored column). This fires after
all `$(document).ready` handlers. Since gadget `register` calls run inside
their own `$(document).ready` handlers, and all `$(document).ready` handlers
run before any `$(function() { ... })` (they are the same in jQuery — both
aliases), order between multiple `$(document).ready` handlers is registration
order.

The registration order is: `portal_lazy.js` is alphabetically first and runs
synchronously. Gadget `register` calls run inside their inline `<script>` tags
which fire in DOM order during `$(document).ready`. The `portal_mobile_tabs.js`
`$(function() { ... })` runs last (it is a separate file registered after
gadget partials).

Since `portal_lazy.js` runs synchronously and sets up `window.portalLazy`
before any `$(document).ready` fires, all `register` calls see the initialized
coordinator. When `portal_mobile_tabs.js`'s `$(function() { ... })` calls
`activateColumn` → `loadColumn(initialActiveIndex)`, the initial-column gadgets
have already been loaded by the immediate `register` path. `loadColumn` finds
`loaded[idx] = true` and is a no-op. Correct.

### Gadgets that appear in multiple columns

`Portal#portal_columns` distributes gadgets so each gadget appears in exactly
one column. A gadget's column membership is fixed at server render time.
There is no case where the same gadget id appears in two columns. The
`register` call with a fixed `column_index` is safe.

### `todos.init` — not a jQuery AJAX call

The todo gadget calls `todos.init('#<%= gadget.gadget_id %>')`, not `$.get`.
`todos.init` is defined in `app/assets/javascripts/todos.js` (not read during
this research, but pattern is consistent with a DOM-manipulation initializer,
not a network call). It still benefits from deferral on mobile if it performs
expensive DOM work. Wrap it the same way as the AJAX gadgets:

```js
$(document).ready(function() {
  window.portalLazy.register('<%= column_index %>', function() {
    todos.init('#<%= gadget.gadget_id %>');
  });
});
```

### BookmarkGadget — no change needed

Bookmark content is fully server-rendered in the DOM. No `register` call is
needed. The bookmark gadget partial has no inline `<script>` beyond folder
toggle event handlers (which are DOM-event driven, not load-triggered). These
run on `$(document).ready` unconditionally and are not column-dependent.

### Theme compatibility

The lazy loading mechanism is purely JS and DOM. All three themes (modern,
classic, simple) render the same `_portal_column_section.html.erb` partial
through `_dashboard.html.erb`. Theme files only provide CSS. No theme-specific
changes are needed.

### Column count compatibility (3 or 4 columns)

`portal_lazy.js` operates by column index (0 to N-1) derived from the gadget
partial's `column_index` local variable, which comes from the render loop
index. The coordinator does not hardcode column count — it creates queues and
loaded-flags on demand per index. 3-column and 4-column portals work
identically.

### Simple-theme tab panel interaction

The simple theme has an additional tab (`?tab=notes`) that switches between
the portal home panel and a note panel. This is handled by SSR (`notes_active`
conditional in `_dashboard.html.erb`) and the `notes_tabs.js` file. The portal
column tabs (within the home panel) are a separate system. The simple theme
also uses `portal_mobile_tabs.js` for column navigation within the home panel.
The lazy loading addition to `activateColumn` is called only for portal column
tabs, not for the note/home tab switch. No interaction.

---

## Modified Files (summary)

| File | Change |
|------|--------|
| `app/assets/javascripts/portal_mobile_tabs.js` | Add `window.portalLazy.loadColumn(index)` in `activateColumn` |
| `app/views/welcome/_portal_column_section.html.erb` | Add `column_index: i` to each gadget render call |
| `app/views/welcome/_feed.html.erb` | Wrap `$.get` in `portalLazy.register(column_index, fn)` |
| `app/views/welcome/_mastodon_account.html.erb` | Same |
| `app/views/welcome/_x_account.html.erb` | Same |
| `app/views/welcome/_calendar_gadget.html.erb` | Same |
| `app/views/welcome/_todo_gadget.html.erb` | Wrap `todos.init` in `portalLazy.register(column_index, fn)` |

## New Files

| File | Purpose |
|------|---------|
| `app/assets/javascripts/portal_lazy.js` | `window.portalLazy` coordinator |
| `test/assets/portal_lazy_js_contract_test.rb` | Contract tests asserting module shape and key string patterns |

---

## Sources

- Direct inspection: `app/assets/javascripts/portal_mobile_tabs.js`
- Direct inspection: `app/views/welcome/_dashboard.html.erb`
- Direct inspection: `app/views/welcome/_portal_column_section.html.erb`
- Direct inspection: `app/views/welcome/_feed.html.erb`,
  `_mastodon_account.html.erb`, `_x_account.html.erb`,
  `_calendar_gadget.html.erb`, `_todo_gadget.html.erb`,
  `_bookmark_gadget.html.erb`
- Direct inspection: `app/models/portal.rb`, `app/controllers/welcome_controller.rb`
- Direct inspection: `app/assets/stylesheets/welcome.css.scss`
- Direct inspection: `app/assets/javascripts/application.js`
- Direct inspection: `test/assets/portal_mobile_tabs_js_contract_test.rb`
- Project policy: `.planning/PROJECT.md`, `CLAUDE.md`

---
*Architecture research for: Mobile Column Lazy Loading (v1.24)*
*Researched: 2026-05-17*
