# Phase 76: `portal_lazy.js` Coordinator - Research

**Researched:** 2026-05-17
**Domain:** Sprockets JavaScript module, browser-side lazy loading coordinator
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Initial Column Detection:**
- Read `--portal-initial-active-index` from `document.documentElement.style.getPropertyValue()` at file parse time — the prehydration script in `_dashboard.html.erb` writes it synchronously before any other JS; avoids duplicate localStorage access
- Fall back to `0` when the CSS property is absent or invalid (private browsing, no prior visit) — column 0 is always initially visible
- Keep `initialColumnIndex` as an internal variable — not exposed on `window.portalLazy`; not part of IMPL-01 contract

**Module API Structure:**
- Initialize with a top-level IIFE that sets `window.portalLazy` — makes `register` and `loadColumn` available synchronously before any `$(document).ready` fires; consistent with global namespace pattern (`window.name = window.name || {}`)
- Track load state with a plain object: `const loadedColumns = {}` — ES5/6 compatible, simple, consistent with codebase style
- `loadColumn(index)` marks synchronously before firing any load functions — satisfies IMPL-04 ("load state marked synchronously before any $.get fires")
- `loadColumn` is a no-op when called for an already-loaded column (early return)
- Desktop/mobile detection uses exact `window.matchMedia('(max-width: 767px)')` pattern from `portal_mobile_tabs.js` — same 767px breakpoint

### Claude's Discretion
- Internal queue data structure (plain JS object or nested array — either is fine)
- File placement in `app/assets/javascripts/portal_lazy.js` — Sprockets alphabetical order guarantees it loads before `portal_mobile_tabs.js`

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAZY-01 | On mobile (≤768px), only gadgets in the initially active column are AJAX-loaded on page load | `register()` on mobile queues `loadFn` by column index; only column `initialColumnIndex` loads immediately |
| LAZY-02 | When the user switches to a new column tab, that column's gadgets are loaded on first visit | `loadColumn(index)` drains queue for that index — called by `activateColumn()` in Phase 77 |
| LAZY-03 | Revisiting an already-loaded column does not trigger another AJAX request | `loadedColumns[index]` flag; `loadColumn` is no-op when flag is already truthy |
| LAZY-04 | Load state resets on each page load — gadgets reload fresh on explicit page refresh | `loadedColumns` is in-memory JS object; naturally resets on page reload |
| DESKTP-01 | Desktop behavior is unchanged — all gadgets in all columns load on page load as today | On desktop (`isMobileViewport()` returns false), `register()` fires `loadFn` immediately (pass-through) |
| DESKTP-02 | Feature works correctly across all themes (modern/classic/simple) and both column counts (3 and 4) | Coordinator is theme-agnostic; uses only `window.matchMedia` and CSS custom property — no theme selectors |
| IMPL-01 | A new `portal_lazy.js` coordinator module exposes `window.portalLazy` with `register(columnIndex, loadFn)` and `loadColumn(index)` API | This is the entire scope of Phase 76 — create the module file |
</phase_requirements>

---

## Summary

Phase 76 creates a single new file: `app/assets/javascripts/portal_lazy.js`. This file exposes a `window.portalLazy` coordinator with two public methods (`register` and `loadColumn`) via a top-level IIFE. The module causes zero visible behavior change on its own because no gadget partial calls `register` yet — that wiring happens in Phase 77.

The coordinator reads the initially active column index from the CSS custom property `--portal-initial-active-index` set by the prehydration inline script in `_dashboard.html.erb` at parse time. On desktop (`window.matchMedia('(max-width: 767px)').matches === false`), `register` fires `loadFn` immediately as a transparent pass-through. On mobile, `register` enqueues `loadFn` keyed by `columnIndex`; `loadColumn(index)` drains that queue once and marks the column loaded synchronously before dispatching any load functions.

The file must be named `portal_lazy.js` so Sprockets' alphabetical `require_tree .` loads it before `portal_mobile_tabs.js`, ensuring `window.portalLazy` exists before any `$(document).ready` handler in gadget partials fires. All three test suites must pass; this phase introduces no behavior change so existing Cucumber scenarios are not at risk.

**Primary recommendation:** Write `portal_lazy.js` as a top-level IIFE (not wrapped in `$(function(){})`), matching the `window.todos = window.todos || {}` namespace pattern, with inline detection of mobile viewport and the initial column index at parse time.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lazy-load coordination (queue, dispatch) | Browser / Client | — | Pure in-memory JS state; no server involvement |
| Mobile viewport detection | Browser / Client | — | `window.matchMedia` is a browser API |
| Initial column index detection | Browser / Client | Frontend Server (SSR) | SSR writes the CSS custom property; client reads it at parse time |
| Load state tracking (`loadedColumns`) | Browser / Client | — | Session-only memory; resets on page reload by design |
| Gadget AJAX fetching | Browser / Client | API / Backend | AJAX fetches remain in gadget partials (Phase 77); backend serves responses |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Sprockets | (Rails 8.1 bundled) | JS bundling via `require_tree .` | Already in use; no new tooling needed |
| jQuery | (bundled via application.js) | DOM queries in gadget partials | Already required globally |
| `window.matchMedia` | Browser native | Mobile viewport detection | Exact pattern from `portal_mobile_tabs.js` |

**No new packages are installed in Phase 76.** The module is pure vanilla JS using browser APIs and the existing jQuery global.

### Supporting

None required for this phase.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Top-level IIFE for parse-time init | `$(document).ready` wrapper | `$(document).ready` fires after all inline `<script>` in gadget partials — too late; IIFE is parse-time |
| `window.matchMedia('(max-width: 767px)')` | Reading CSS breakpoint from a data attribute | CSS property approach is already established in `portal_mobile_tabs.js`; must match exactly |
| `document.documentElement.style.getPropertyValue(...)` | Second `localStorage.getItem(...)` call | Avoid double localStorage read; prehydration already wrote the CSS property |

---

## Package Legitimacy Audit

No external packages are installed in this phase. Section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Page load (parse time)
        |
        v
[_dashboard.html.erb inline script]
  reads localStorage 'portalMobileActiveColumn'
  writes --portal-initial-active-index to document.documentElement.style
        |
        v  (Sprockets require_tree order: portal_lazy.js before portal_mobile_tabs.js)
[portal_lazy.js IIFE — parse time]
  reads --portal-initial-active-index → initialColumnIndex
  detects isMobileViewport()
  sets window.portalLazy = { register, loadColumn }
        |
        v
[$(document).ready fires — gadget partials]
  Phase 76: $.get fires unconditionally (no register calls yet)
  Phase 77: each partial calls window.portalLazy.register(columnIndex, loadFn)
        |
    (mobile path)                   (desktop path)
        |                                |
  register() enqueues loadFn       register() calls loadFn() immediately
  for columnIndex                  (pass-through)
        |
  loadColumn(initialColumnIndex) auto-fires at register time
  (initial column only loads immediately)
        |
  [User taps tab → activateColumn() in portal_mobile_tabs.js]
  → calls window.portalLazy.loadColumn(index) [Phase 77]
  → drains queue for that index, marks loaded, fires loadFns
```

### Recommended Project Structure

```
app/assets/javascripts/
├── portal_lazy.js          # NEW — coordinator IIFE (Phase 76)
├── portal_mobile_tabs.js   # Existing — tab/swipe UI; Phase 77 wires loadColumn here
└── [other existing files]
```

### Pattern 1: Top-Level IIFE with `window.name = window.name || {}` Namespace

**What:** Module wraps all logic in an immediately-invoked function expression, exposing only the public API on `window`. Internal state (queues, flags, initialColumnIndex) is closed over.

**When to use:** When the module must execute synchronously at parse time (before `$(document).ready`) and must not pollute the global scope beyond a single named property.

**Example (verified from `todos.js` pattern):**
```javascript
// Source: app/assets/javascripts/todos.js (VERIFIED in codebase)
window.todos = window.todos || {};
const todos = window.todos;

todos.init = function(selector) { /* ... */ };
```

For `portal_lazy.js`, the same namespace initialization is used, but the initialization logic runs inside the IIFE body rather than in `$(document).ready`:

```javascript
// portal_lazy.js — pattern to implement
window.portalLazy = window.portalLazy || {};
const portalLazy = window.portalLazy;

(function() {
  const isMobileViewport = function() {
    if (!window.matchMedia) return false;
    return window.matchMedia('(max-width: 767px)').matches;
  };

  const rawIndex = document.documentElement.style.getPropertyValue('--portal-initial-active-index');
  const parsed = parseInt(rawIndex, 10);
  const initialColumnIndex = (Number.isNaN(parsed) || parsed < 0) ? 0 : parsed;

  const queues = {};
  const loadedColumns = {};

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

  portalLazy.loadColumn = function(index) {
    if (loadedColumns[index]) return;
    loadedColumns[index] = true;
    const fns = queues[index] || [];
    for (let i = 0; i < fns.length; i++) {
      fns[i]();
    }
  };
})();
```

**Note on pattern choice:** The above uses `window.portalLazy = window.portalLazy || {}` outside the IIFE then populates it inside. This is consistent with `todos.js`, `feeds.js`, and `calendars.js`. An alternative is to assign the full object literal inside the IIFE — either satisfies IMPL-01. The `|| {}` guard prevents double-initialization if the file were somehow included twice.

### Pattern 2: Synchronous `getPropertyValue` at Parse Time

**What:** `document.documentElement.style.getPropertyValue('--portal-initial-active-index')` returns the inline style value set by the prehydration script, not the computed CSS value. Because inline styles are set before the Sprockets bundle executes, this call is reliable at parse time.

**When to use:** Whenever you need to read a value written by an inline `<script>` in the HTML `<head>` or `<body>` before the external JS bundle executes.

**Example (from `_dashboard.html.erb`):**
```javascript
// Source: app/views/welcome/_dashboard.html.erb (VERIFIED in codebase)
document.documentElement.style.setProperty('--portal-initial-active-index', String(restored));
```

Reading it back:
```javascript
// In portal_lazy.js — at IIFE parse time
const rawIndex = document.documentElement.style.getPropertyValue('--portal-initial-active-index');
// Returns '' if not set (private mode, first visit, desktop). Fall back to 0.
```

### Anti-Patterns to Avoid

- **Wrapping the whole module in `$(function(){})`:** This delays initialization to DOMContentLoaded. Gadget partials' own `$(document).ready` handlers would call `window.portalLazy.register()` — but if the coordinator itself initializes in `$(document).ready`, load order between handlers is undefined. The IIFE must run at parse time.
- **Reading localStorage directly for initial column index:** The prehydration script already does this. Reading it again in `portal_lazy.js` is redundant and can be inconsistent if the prehydration guard (mobile-only) is not reproduced exactly.
- **Exposing `initialColumnIndex` on `window.portalLazy`:** The CONTEXT.md decision explicitly keeps it internal. The planner must not add it to the public API.
- **Using `var`:** ESLint `no-var` rule is enforced. Use `const` and `let` only.
- **Arrow functions where `this` is the element:** Not directly relevant to this module (no jQuery element callbacks), but follow the convention.
- **Firing load functions inside `loadedColumns[index] = true` setter logic after the flag is set:** Flag must be set BEFORE iterating `fns[i]()` — this is the synchronous mark-before-fire contract (IMPL-04).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mobile breakpoint detection | Custom pixel comparison | `window.matchMedia('(max-width: 767px)').matches` | Exact pattern from `portal_mobile_tabs.js`; must match to avoid split-brain |
| Load-once guard | Complex promise chains | Simple `loadedColumns[index]` boolean flag | Queue drains once synchronously; no async coordination needed |
| CSS custom property reading | DOM traversal for column classes | `document.documentElement.style.getPropertyValue(...)` | Prehydration writes to `documentElement.style` inline; this is the correct read path |

**Key insight:** The entire coordinator is ~30 lines. Resist the temptation to add configuration, events, or additional API surface. Phase 76 success criterion is the API exists and works — Phase 77 wires it.

---

## Common Pitfalls

### Pitfall 1: Initializing inside `$(document).ready` instead of at parse time

**What goes wrong:** `window.portalLazy` is undefined when inline `<script>` blocks inside gadget partials execute their `$(document).ready` callbacks. In Phase 77, those callbacks call `portalLazy.register(...)` — if the coordinator isn't on `window` yet, a TypeError crashes all gadgets.

**Why it happens:** Developers instinctively wrap module init in `$(function(){})` following the pattern in `portal_mobile_tabs.js`.

**How to avoid:** Use a top-level IIFE (no `$()` wrapper). The file body executes at Sprockets bundle parse time — `window.portalLazy` is assigned before any `$(document).ready` queue drains.

**Warning signs:** `TypeError: Cannot read properties of undefined (reading 'register')` in browser console.

### Pitfall 2: `getPropertyValue` returns empty string on desktop or first mobile visit

**What goes wrong:** On desktop (matchMedia check in prehydration prevents write) or on first mobile visit (no localStorage value), `--portal-initial-active-index` is not set. `getPropertyValue` returns `''`. `parseInt('', 10)` returns `NaN`. If not guarded, `initialColumnIndex` becomes `NaN` and `loadColumn(NaN)` sets `loadedColumns[NaN] = true` — no column loads.

**Why it happens:** Missing NaN guard on the parsed integer.

**How to avoid:** `const initialColumnIndex = (Number.isNaN(parsed) || parsed < 0) ? 0 : parsed;`

**Warning signs:** On mobile with no prior visit, all gadgets fail to load content.

### Pitfall 3: `loadColumn` fires load functions before setting the flag

**What goes wrong:** On rapid swipe, `activateColumn()` is called twice for the same index before the first `$.get` completes. If `loadedColumns[index]` is set inside the success callback (or after `fns[i]()`), a second `loadColumn(index)` call between fire and completion dispatches all load functions again, triggering duplicate AJAX requests.

**Why it happens:** Async thinking — "mark as loaded after it finishes loading."

**How to avoid:** Set `loadedColumns[index] = true` as the first line inside `loadColumn`, before the `for` loop. This is IMPL-04.

**Warning signs:** Network inspector shows duplicate AJAX calls for same feed/gadget when switching tabs quickly.

### Pitfall 4: Sprockets load order regression

**What goes wrong:** A developer renames `portal_lazy.js` to something alphabetically after `portal_mobile_tabs.js` (e.g., `portal_lazy_coordinator.js` < `portal_mobile_tabs.js` — actually fine, but `portal_z.js` would not be). Or adds an explicit `//= require portal_mobile_tabs` before `portal_lazy.js` in `application.js`.

**Why it happens:** Misunderstanding that `//= require_tree .` is alphabetical.

**How to avoid:** Keep filename `portal_lazy.js`. Verify: `p` < `p`o`r`t`a`l`_`l` < `p`o`r`t`a`l`_`m` — `portal_lazy.js` comes before `portal_mobile_tabs.js` alphabetically. [VERIFIED: manual sort confirms this.]

**Warning signs:** `window.portalLazy is undefined` after Phase 77 wiring.

### Pitfall 5: `todos.init` is NOT an AJAX gadget — do not wrap in Phase 77

**What goes wrong:** Phase 77 scope includes wrapping AJAX gadget partials in `register`. `_todo_gadget.html.erb` also uses `$(document).ready`, which could be mistakenly wrapped.

**Why it matters for Phase 76:** Phase 76 research must document this clearly so the Phase 77 plan does not include `_todo_gadget.html.erb` as a target.

**Finding:** `todos.js` exposes `todos.init(selector)` which only attaches jQuery event listeners (dblclick, click) — no AJAX call on initialization. The AJAX calls (`$.get`, `$.post`) in todos are user-triggered (dblclick on li, link clicks). `_todo_gadget.html.erb` calls `todos.init()` in `$(document).ready` — this is DOM initialization, not AJAX fetching. **Do not wrap `_todo_gadget.html.erb` in `portalLazy.register`.**

### Pitfall 6: `$('.gadgets').sortable()` has no mobile guard

**What goes wrong:** `$('.gadgets').sortable()` is called unconditionally in `_dashboard.html.erb` on `$(document).ready`. On mobile, jQuery UI sortable is active on all column containers, which can interfere with swipe gestures.

**Finding:** Confirmed — no `isMobileViewport()` guard exists around `$('.gadgets').sortable()`. [VERIFIED in codebase: `_dashboard.html.erb` line 31 calls `.sortable()` with no mobile check.] This is a pre-existing blocker concern noted in `STATE.md` but is **OUT OF SCOPE for Phase 76**. Phase 76 does not touch `_dashboard.html.erb`. It is tracked for Phase 78.

---

## Code Examples

### CSS Custom Property Written by Prehydration Script

```javascript
// Source: app/views/welcome/_dashboard.html.erb (VERIFIED in codebase)
(function prehydrateMobilePortalColumn() {
  try {
    if (!window.matchMedia || !window.matchMedia('(max-width: 767px)').matches) return;
    const raw = window.localStorage.getItem('portalMobileActiveColumn');
    const restored = Number.parseInt(raw, 10);
    if (Number.isNaN(restored) || restored < 0) return;
    document.documentElement.style.setProperty('--portal-initial-active-index', String(restored));
  } catch (e) {
    // Ignore localStorage access errors in private mode or restricted browsers.
  }
})();
```

**Key detail:** The property is only set when (1) mobile viewport AND (2) valid localStorage value. On desktop or first visit, `getPropertyValue('--portal-initial-active-index')` returns `''`.

### CSS Variable Fallback Chain (for reference)

```scss
// Source: app/assets/stylesheets/welcome.css.scss (VERIFIED in codebase)
transform: translateX(calc(-100% * var(--portal-active-index, var(--portal-initial-active-index, 0))));
```

`--portal-active-index` is set by `activateColumn()` in `portal_mobile_tabs.js`. `--portal-initial-active-index` is the prehydration value. `0` is the final fallback.

### Mobile Viewport Detection (exact pattern to reuse)

```javascript
// Source: app/assets/javascripts/portal_mobile_tabs.js (VERIFIED in codebase)
const isMobileViewport = function() {
  if (!window.matchMedia) return false;
  return window.matchMedia('(max-width: 767px)').matches;
};
```

Must be duplicated verbatim in `portal_lazy.js` (can't import from `portal_mobile_tabs.js` — they are separate Sprockets files with no module system).

### Global Namespace Pattern

```javascript
// Source: app/assets/javascripts/todos.js (VERIFIED in codebase)
window.todos = window.todos || {};
const todos = window.todos;

todos.init = function(selector) { /* ... */ };
```

`portal_lazy.js` uses the same pattern: `window.portalLazy = window.portalLazy || {}; const portalLazy = window.portalLazy;`

### Contract Test Pattern for Phase 78

```ruby
# Source: test/assets/portal_mobile_tabs_js_contract_test.rb (VERIFIED in codebase)
require 'test_helper'

class PortalMobileTabsJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_mobile_tabs.js').read
  end

  test 'mobile column state is persisted and restored from localStorage' do
    assert_includes @source, "const STORAGE_KEY = 'portalMobileActiveColumn';"
  end
end
```

Phase 78 will create `test/assets/portal_lazy_js_contract_test.rb` using the same structure, reading `app/assets/javascripts/portal_lazy.js` as `@source` and asserting presence of key API signatures.

---

## Key Findings from Source Investigation

### AJAX Gadget Partials — All Use `$(document).ready` + `$.get`

| Partial | AJAX Pattern | Phase 77 Target |
|---------|-------------|-----------------|
| `_feed.html.erb` | `$(document).ready` → `$.get(feed_path(gadget))` | Yes |
| `_mastodon_account.html.erb` | `$(document).ready` → `$.get(mastodon_account_path(...))` | Yes |
| `_x_account.html.erb` | `$(document).ready` → `$.get(x_account_path(...))` | Yes |
| `_calendar_gadget.html.erb` | `$(document).ready` → `$.get(get_gadget_calendars_path(...))` | Yes |
| `_todo_gadget.html.erb` | `$(document).ready` → `todos.init(selector)` only (DOM event binding, no AJAX) | **No** |

[VERIFIED in codebase: read all five partials directly.]

### Column Index Availability for Phase 77

Gadget partials are rendered via `render g.class.name.underscore, gadget: g` in `_portal_column_section.html.erb` — no `column_index` local is passed. In Phase 77, the column index must be derived from the DOM. The column container `<div>` has `id="column_<%= i %>"` — so scripts can use `$(this).closest('.portal-column').attr('id')` or read `data-portal-column-index` from the parent. This is a Phase 77 concern; Phase 76 does not need to resolve it. [VERIFIED in codebase: `_portal_column_section.html.erb` line 26-28.]

### Sprockets Load Order — Confirmed

Alphabetical sort of all JS files with `portal_lazy.js` added:
```
portal_lazy.js          ← 'l' < 'm'
portal_mobile_tabs.js
```
`portal_lazy.js` loads before `portal_mobile_tabs.js` without any manifest changes. [VERIFIED: manual sort.]

### `$('.gadgets').sortable()` — No Mobile Guard

Confirmed present at `_dashboard.html.erb` line 31, inside `$(document).ready`, with no `isMobileViewport()` condition. This is pre-existing; not introduced by Phase 76. Out of scope for Phase 76.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All gadgets load unconditionally on `$(document).ready` | Coordinator queues mobile loads; desktop pass-through | Phase 76 (this phase) creates the API; Phase 77 wires it | No behavior change in Phase 76; full lazy loading in Phase 77 |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `document.documentElement.style.getPropertyValue('--portal-initial-active-index')` correctly reads the inline style set by the prehydration script at Sprockets bundle execution time | Architecture Patterns / Code Examples | If Sprockets bundles execute before the inline script runs, read returns `''` and all mobile loads fall back to column 0 — acceptable fallback behavior, not a crash |

**All other claims verified directly from codebase files.**

---

## Open Questions

1. **Column index availability in gadget partials (Phase 77 concern)**
   - What we know: Partials are rendered with `gadget:` local only; no `column_index:` local is passed.
   - What's unclear: The cleanest approach for Phase 77 to derive column index (DOM traversal vs. adding `column_index:` local to render call in `_portal_column_section.html.erb`).
   - Recommendation: This is a Phase 77 research/planning concern. Adding `column_index:` as an ERB local to the render call is the cleanest solution. Phase 76 research notes it so the Phase 77 planner is forewarned.

2. **`$('.gadgets').sortable()` mobile guard (Phase 78 concern)**
   - What we know: No guard exists; sortable is active on mobile.
   - What's unclear: Whether jQuery UI sortable actually causes swipe conflicts in practice (may be masked by touch event propagation).
   - Recommendation: Track in Phase 78; not a Phase 76 concern.

---

## Environment Availability

Step 2.6: All phase work is pure JavaScript file creation with no new external dependencies. The Sprockets pipeline, jQuery, and browser `window.matchMedia` are already in use. No environment audit needed.

**Skip condition met:** No external CLI tools, services, or runtimes required beyond the existing Rails/Sprockets stack.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (ActiveSupport::TestCase) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/assets/` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IMPL-01 | `window.portalLazy` exposed with `register` and `loadColumn` | unit (contract) | `bin/rails test test/assets/portal_lazy_js_contract_test.rb` | ❌ Wave 0 (Phase 78) |
| LAZY-01 | On mobile, `register` queues loadFn; initial column fires immediately | unit (contract) | `bin/rails test test/assets/portal_lazy_js_contract_test.rb` | ❌ Wave 0 (Phase 78) |
| LAZY-03 | `loadColumn` is no-op for already-loaded column | unit (contract) | `bin/rails test test/assets/portal_lazy_js_contract_test.rb` | ❌ Wave 0 (Phase 78) |
| LAZY-04 | No persistent load state (no localStorage write) | unit (contract) | `bin/rails test test/assets/portal_lazy_js_contract_test.rb` | ❌ Wave 0 (Phase 78) |
| DESKTP-01 | Desktop: `register` fires `loadFn` immediately | unit (contract) | `bin/rails test test/assets/portal_lazy_js_contract_test.rb` | ❌ Wave 0 (Phase 78) |
| IMPL-01/LAZY-01 | Existing `@mobile_portal` Cucumber scenarios still pass | e2e | `bundle exec rake dad:test` | ✅ existing |

**Note:** TEST-01 (Minitest contract tests for `portal_lazy.js`) is scoped to Phase 78. Phase 76 has no dedicated test file to create — verification is that the existing test suites all remain green after creating `portal_lazy.js`.

### Sampling Rate

- **Per task commit:** `yarn run lint` (catches `no-var`, syntax errors)
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` all green before marking Phase 76 complete

### Wave 0 Gaps

- [ ] `test/assets/portal_lazy_js_contract_test.rb` — covers IMPL-01, LAZY-01, LAZY-03, LAZY-04, DESKTP-01 — **deferred to Phase 78 per traceability matrix**

*(All existing test infrastructure covers the regression requirement — no gaps in Phase 76 itself.)*

---

## Security Domain

This phase creates a client-side JavaScript module with no authentication, no user input validation, no cryptography, and no server communication. ASVS categories V2 (Authentication), V3 (Session Management), V4 (Access Control), V5 (Input Validation), V6 (Cryptography) do not apply. The module reads a CSS custom property written by inline script — no external input is processed.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 76 |
|-----------|-------------------|
| `yarn run lint` must be green | `portal_lazy.js` must pass ESLint `no-var` rule and Prettier formatting |
| `bin/rails test` must be green | No new test file required in Phase 76; existing tests must not break |
| `bundle exec rake dad:test` must be green | Zero behavior change in Phase 76 means existing `@mobile_portal` Cucumber scenarios are unaffected |
| `no-var` ESLint rule enforced | Use only `const` and `let` in `portal_lazy.js` |
| Arrow functions: only where `this` is not an element | Module has no jQuery `this`-as-element callbacks; arrow functions are acceptable for short callbacks |
| `window.name = window.name || {}` pattern | `window.portalLazy = window.portalLazy || {}` is the required namespace declaration |
| Cucumber re-run policy | If `dad:test` fails once, re-run before declaring regression — intermittent failures are pre-existing |

---

## Sources

### Primary (HIGH confidence)

- `app/assets/javascripts/portal_mobile_tabs.js` — `isMobileViewport()` pattern, `STORAGE_KEY`, `activateColumn()`, full module structure
- `app/views/welcome/_dashboard.html.erb` — exact CSS custom property name (`--portal-initial-active-index`), prehydration IIFE, `sortable()` call with no mobile guard
- `app/assets/javascripts/todos.js` — global namespace pattern (`window.todos = window.todos || {}`); confirms `todos.init` is DOM-only
- `app/views/welcome/_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb` — all confirmed as `$(document).ready` + `$.get` AJAX partials
- `app/views/welcome/_todo_gadget.html.erb` — confirmed NOT an AJAX gadget
- `app/views/welcome/_portal_column_section.html.erb` — gadget render call pattern; `id="column_<%= i %>"` on column containers
- `test/assets/portal_mobile_tabs_js_contract_test.rb` — contract test pattern for Phase 78
- `eslint.config.mjs` — confirmed `no-var` enforced via `@eslint/js` recommended; Babel parser used
- `.planning/codebase/CONVENTIONS.md` — `const`/`let` only, arrow function rules, namespace pattern

### Secondary (MEDIUM confidence)

- Node.js sort verification of alphabetical load order — confirms `portal_lazy.js` < `portal_mobile_tabs.js`

### Tertiary (LOW confidence)

None — all claims verified directly from codebase files.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use; no new packages
- Architecture: HIGH — verified from actual source files
- Pitfalls: HIGH — verified from source (sortable guard absence, todos.init pattern, alphabetical order)
- API contract: HIGH — CONTEXT.md decisions are locked; verified against existing codebase patterns

**Research date:** 2026-05-17
**Valid until:** 2026-06-17 (stable codebase; no external dependencies)
