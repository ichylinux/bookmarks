# Phase 76: `portal_lazy.js` Coordinator - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 2 (1 new JS file + 1 new test file deferred to Phase 78)
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `app/assets/javascripts/portal_lazy.js` | utility / coordinator | event-driven (queue + dispatch) | `app/assets/javascripts/portal_mobile_tabs.js` | role-match (same domain, same viewport detection) |
| `app/assets/javascripts/portal_lazy.js` | utility / coordinator | event-driven | `app/assets/javascripts/todos.js` | namespace-pattern match (top-level global assignment, no jQuery wrapper) |
| `test/assets/portal_lazy_js_contract_test.rb` _(Phase 78)_ | test | — | `test/assets/portal_mobile_tabs_js_contract_test.rb` | exact |

---

## Pattern Assignments

### `app/assets/javascripts/portal_lazy.js` (utility, event-driven coordinator)

**Primary Analog:** `app/assets/javascripts/todos.js`
**Secondary Analog:** `app/assets/javascripts/portal_mobile_tabs.js`

---

#### Namespace declaration pattern (lines 1-6 of `todos.js`)

Copy verbatim, substituting `portalLazy` for `todos`:

```javascript
// Sprockets bundle: share namespace for load order (no new globals).
window.portalLazy = window.portalLazy || {};
// NOTE: `portalLazy` is a snapshot of the window.portalLazy reference at parse time.
// window.portalLazy remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const portalLazy = window.portalLazy;
```

Source: `app/assets/javascripts/todos.js` lines 1-6.

**Critical rule:** The namespace assignment must be at the top level — NOT inside `$(function(){})` or any `$(document).ready` wrapper. This ensures `window.portalLazy` exists synchronously before any `$(document).ready` callback fires.

---

#### Mobile viewport detection (lines 4-7 of `portal_mobile_tabs.js`)

Copy verbatim — must match `portal_mobile_tabs.js` exactly (same 767px breakpoint):

```javascript
const isMobileViewport = function() {
  if (!window.matchMedia) return false;
  return window.matchMedia('(max-width: 767px)').matches;
};
```

Source: `app/assets/javascripts/portal_mobile_tabs.js` lines 4-7.

**Constraint:** Cannot import from `portal_mobile_tabs.js` (no module system). Must duplicate. The threshold `767px` must not differ.

---

#### Parse-time CSS custom property read (from `_dashboard.html.erb` context)

The prehydration inline script (lines 1-12 of `_dashboard.html.erb`) writes the property:

```javascript
document.documentElement.style.setProperty('--portal-initial-active-index', String(restored));
```

Source: `app/views/welcome/_dashboard.html.erb` lines 8.

The coordinator reads it back at parse time with NaN guard:

```javascript
const rawIndex = document.documentElement.style.getPropertyValue('--portal-initial-active-index');
const parsed = parseInt(rawIndex, 10);
const initialColumnIndex = (Number.isNaN(parsed) || parsed < 0) ? 0 : parsed;
```

**The NaN guard is mandatory.** On desktop or first mobile visit the property is not set; `getPropertyValue` returns `''`; `parseInt('', 10)` returns `NaN`. Without the guard, `loadedColumns[NaN]` is set and no column loads. The guard pattern is identical to the one used in `portal_mobile_tabs.js` lines 19-21:

```javascript
// Source: portal_mobile_tabs.js lines 19-21 (analogous guard)
const n = parseInt(m[1], 10);
return Number.isNaN(n) ? 0 : n;
```

---

#### IIFE enclosure pattern

Wrap all internal state (queues, loadedColumns, initialColumnIndex, isMobileViewport) in an IIFE so only the two public methods are exposed on `window.portalLazy`. The `|| {}` guard and local alias are declared outside the IIFE (at top level), exactly as in `todos.js`:

```javascript
window.portalLazy = window.portalLazy || {};
const portalLazy = window.portalLazy;

(function() {
  // internal state and helpers here — closed over, not exposed
  const isMobileViewport = function() { ... };
  const rawIndex = ...;
  const initialColumnIndex = ...;
  const queues = {};
  const loadedColumns = {};

  portalLazy.register = function(columnIndex, loadFn) { ... };
  portalLazy.loadColumn = function(index) { ... };
})();
```

Source: `app/assets/javascripts/todos.js` lines 1-6 (namespace) + RESEARCH.md Pattern 1 (IIFE shell).

---

#### `register` method — desktop pass-through / mobile queue

```javascript
portalLazy.register = function(columnIndex, loadFn) {
  if (!isMobileViewport()) {
    loadFn();
    return;
  }
  queues[columnIndex] = queues[columnIndex] || [];
  queues[columnIndex].push(loadFn);
  if (columnIndex === initialColumnIndex) {
    portalLazy.loadColumn(columnIndex);
  }
};
```

On desktop: fires `loadFn` immediately — zero behavior change (DESKTP-01).
On mobile: enqueues `loadFn` by column index. If the registered column is the initially active column, drains immediately.

---

#### `loadColumn` method — synchronous mark-before-fire (IMPL-04)

```javascript
portalLazy.loadColumn = function(index) {
  if (loadedColumns[index]) return;
  loadedColumns[index] = true;           // MUST be before the for-loop (IMPL-04)
  const fns = queues[index] || [];
  for (let i = 0; i < fns.length; i++) {
    fns[i]();
  }
};
```

**IMPL-04 contract:** `loadedColumns[index] = true` must be set as the first statement inside the guard — before any `fns[i]()` is called. This prevents re-entrant double-fire on rapid tab switches (Pitfall 3 in RESEARCH.md).

---

#### `const`/`let` only — no `var`

From `portal_mobile_tabs.js` throughout (all bindings use `const` or `let`):

```javascript
const STORAGE_KEY = 'portalMobileActiveColumn';   // const for immutable binding
let startX = 0;                                    // let for reassigned value
```

ESLint `no-var` rule is enforced project-wide. The planner must not introduce `var` anywhere in `portal_lazy.js`.

---

#### Arrow function rule

From CONTEXT.md / CONVENTIONS.md: arrow functions are allowed for short data callbacks (e.g., `$.get` success handlers) but NOT where `function` keyword is required for `this`-as-element jQuery callbacks. In `portal_lazy.js`, there are no jQuery `this`-as-element callbacks — all public methods are plain function assignments on `portalLazy`. Either syntax is acceptable, but `function` is used consistently for method assignments in `todos.js` and `feeds.js`:

```javascript
// todos.js line 8 — method assigned with function keyword
todos.init = function(selector) { ... };

// feeds.js lines 8, 17 — method with function, short callback with arrow
feeds.fetch_title = function(button) {
  $.get(fetchPath, { feed_url: feedUrl }, (title) => {  // arrow ok for short callback
    ...
  });
};
```

Source: `app/assets/javascripts/todos.js` line 8; `app/assets/javascripts/feeds.js` lines 8, 17.

---

### `test/assets/portal_lazy_js_contract_test.rb` _(deferred to Phase 78)_

**Analog:** `test/assets/portal_mobile_tabs_js_contract_test.rb`

Copy the setup block verbatim, substituting `portal_lazy`:

```ruby
require 'test_helper'

class PortalLazyJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_lazy.js').read
  end
  ...
end
```

Source: `test/assets/portal_mobile_tabs_js_contract_test.rb` lines 1-7.

Each test uses `assert_includes @source, '<literal string>'` to verify key API signatures are present as text in the source file. Use `assert_match(/pattern/m, @source)` only when multi-line context is needed:

```ruby
# Single-line assertion pattern (lines 11-14 of portal_mobile_tabs_js_contract_test.rb)
assert_includes @source, "const STORAGE_KEY = 'portalMobileActiveColumn';"

# Multi-line assertion pattern (lines 23-24)
assert_match(/if \(isMobileViewport\(\)\) \{\s*window\.localStorage\.setItem/m, @source)
```

Source: `test/assets/portal_mobile_tabs_js_contract_test.rb` lines 11, 23.

---

## Shared Patterns

### Global Namespace (applies to `portal_lazy.js`)

**Source:** `app/assets/javascripts/todos.js` lines 1-6 and `app/assets/javascripts/feeds.js` lines 1-6.

Both files use identical structure — top-level `window.name = window.name || {}` followed by `const name = window.name`. This is the project-wide convention for Sprockets modules that expose a global API.

```javascript
window.todos = window.todos || {};
const todos = window.todos;
```

```javascript
window.feeds = window.feeds || {};
const feeds = window.feeds;
```

Apply to `portal_lazy.js` as: `window.portalLazy = window.portalLazy || {};` / `const portalLazy = window.portalLazy;`

### NaN / bounds guard on parsed integers (applies to `portal_lazy.js`)

**Source:** `app/assets/javascripts/portal_mobile_tabs.js` lines 19-21, 49-50, 108, 129-130.

Every `parseInt` call in the codebase is immediately guarded with `Number.isNaN(...)`:

```javascript
// portal_mobile_tabs.js line 19-21
const n = parseInt(m[1], 10);
return Number.isNaN(n) ? 0 : n;

// portal_mobile_tabs.js line 49-50
const index = parseInt($btn.attr('data-portal-column-index'), 10);
if (Number.isNaN(index)) return;

// portal_mobile_tabs.js line 129-130
const restored = parseInt(raw, 10);
if (Number.isNaN(restored) || restored < 0 || restored >= colCount) { ... }
```

Apply this guard to `initialColumnIndex` parse in `portal_lazy.js`: `(Number.isNaN(parsed) || parsed < 0) ? 0 : parsed`.

### Contract test `setup` block (applies to Phase 78 test file)

**Source:** `test/assets/portal_mobile_tabs_js_contract_test.rb` lines 3-8.

All contract tests in `test/assets/` use an `ActiveSupport::TestCase` subclass with a `setup` block that reads the source file as a string. Copy this structure for `portal_lazy_js_contract_test.rb`.

---

## No Analog Found

All files in this phase have close analogs. No entries.

---

## Metadata

**Analog search scope:** `app/assets/javascripts/`, `test/assets/`, `app/views/welcome/`
**Files scanned:** 6 (`portal_mobile_tabs.js`, `todos.js`, `feeds.js`, `application.js`, `_dashboard.html.erb`, `portal_mobile_tabs_js_contract_test.rb`)
**Pattern extraction date:** 2026-05-17
