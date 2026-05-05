# Research: Phase 029 — Swipe Navigation Foundation

**Date:** 2026-05-05  
**Phase:** 029  
**Researcher role:** Answer "What do I need to know to PLAN this phase well?"

---

## Summary

Phase 29 extends `portal_mobile_tabs.js` with touch-based swipe detection on `.portal`, routing through a new shared `activateColumn()` function that both the existing tab click handler and the new swipe handler will call (STATE-01). All design decisions are pre-recorded in `029-CONTEXT.md`. This document verifies those decisions against the actual codebase and surfaces one critical implementation pitfall not covered there.

---

## 1. Current `portal_mobile_tabs.js` State

**Confidence: HIGH** [VERIFIED: app/assets/javascripts/portal_mobile_tabs.js]

File is 32 lines. Two functions:
- `syncPortalClasses($portal, index)` — strips all `portal--column-active-*` classes, adds `portal--column-active-<index>`
- Anonymous click handler on `$root.on('click', '.portal-column-tab', ...)` — inlines tab `--active` / `aria-selected` sync, then calls `syncPortalClasses`

**Refactor required for STATE-01:** The tab sync logic currently lives inline in the click handler. Extracting `activateColumn($portal, $tabs, index)` that wraps both the tab UI sync and `syncPortalClasses` is the only path that gives swipe and tap a single shared flow.

**Current DOM traversal pattern** in click handler:
```javascript
const $tabs = $btn.closest('.portal-column-tabs');
const $portal = $tabs.next('.portal');
```
The swipe handler will need the reverse: given `.portal`, find its preceding sibling `.portal-column-tabs`:
```javascript
const $tabs = $portal.prev('.portal-column-tabs');
```

---

## 2. DOM Structure

**Confidence: HIGH** [VERIFIED: app/views/welcome/_portal_column_section.html.erb]

```html
<div class="portal-column-tabs" role="tablist" aria-label="...">
  <button class="portal-column-tab portal-column-tab--active"
          data-portal-column-index="0" aria-selected="true" ...>1</button>
  <button class="portal-column-tab"
          data-portal-column-index="1" aria-selected="false" ...>2</button>
  <button class="portal-column-tab"
          data-portal-column-index="2" aria-selected="false" ...>3</button>
</div>
<div class="portal portal--column-active-0">
  <div id="column_0" class="gadgets portal-column" role="tabpanel" ...>...</div>
  <div id="column_1" class="gadgets portal-column" role="tabpanel" ...>...</div>
  <div id="column_2" class="gadgets portal-column" role="tabpanel" ...>...</div>
</div>
```

Key structural facts:
- Server always renders `portal--column-active-0` as initial state — DOM read for current index is always safe
- Same partial (`_portal_column_section.html.erb`) is rendered by all three themes (modern, classic, simple)
- No theme-specific DOM differences in the portal section — Phase 29 JS is fully theme-agnostic

---

## 3. Portal Column Count

**Confidence: HIGH** [VERIFIED: app/models/portal.rb line 13]

`Portal#portal_columns` always creates a 3-element array:
```ruby
@portal_columns = [[], [], []]
```

Column count is always 3. Reading `colCount` from `.portal-column-tab` count in JS is safe and matches the model.

---

## 4. CSS and Breakpoint

**Confidence: HIGH** [VERIFIED: app/assets/stylesheets/welcome.css.scss lines 1–97]

- `$portal-mobile-breakpoint: 768px` — single source of truth, do not hardcode in JS
- Mobile tab strip shown at `max-width: 767px` (breakpoint − 1px)
- Wide screen: `@media (min-width: 768px)` hides `.portal-column-tabs { display: none }`
- Mobile single-column visibility via `@for $i from 0 through 7 { .portal.portal--column-active-#{$i} #column_#{$i} { display: block } }`

The swipe handler fires at any viewport width. This is intentional — column count reading from DOM and activation via `activateColumn()` works regardless, and tab strip visibility is CSS-only. No JS viewport check is needed.

---

## 5. ESLint / Sprockets Constraints

**Confidence: HIGH** [VERIFIED: eslint.config.mjs, package.json, app/assets/javascripts/application.js]

- ESLint v9 flat config. Browser globals available. `$` / `jQuery` are `readonly` globals — jQuery usage is fine.
- `application.js` uses `//= require_tree .` — all JS files concatenated by Sprockets
- `package.json` has zero runtime dependencies — no npm packages can be added for runtime use
- No ES module `import`/`export` syntax in `.js` files (Sprockets requires plain scripts)
- `const`/`let`, arrow functions, template literals: fine (Babel parser, `@babel/preset-env`)

---

## 6. CRITICAL PITFALL: Chrome Passive Touch Listeners

**Confidence: HIGH** [ASSUMED based on Chrome behavior; applies to this codebase's jQuery pattern]

The existing code uses `$(document).on('click', ...)` event delegation. **This pattern cannot be used for `touchmove` when `event.preventDefault()` is needed.**

Chrome marks `document`-level touch event listeners as **passive by default**. Calling `event.preventDefault()` from a passive listener is silently ignored (console warning only). This breaks SWIPE-02 (vertical scroll must not trigger column switch and horizontal gesture must suppress page scroll).

**Required approach:** Attach touch listeners directly to each `.portal` element using native `addEventListener` with `{ passive: false }`:

```javascript
document.querySelectorAll('.portal').forEach(function(portal) {
  portal.addEventListener('touchstart', onTouchStart, { passive: true });
  portal.addEventListener('touchmove', onTouchMove, { passive: false }); // passive: false required
  portal.addEventListener('touchend', onTouchEnd);
});
```

`touchstart` can remain passive (no `preventDefault()` needed there). Only `touchmove` requires `{ passive: false }`.

**Impact on CONTEXT.md decision "event delegation on `$document`":** That decision must be revised. Direct attachment to `.portal` elements in the `$(function() { ... })` block is the correct approach. Since there is exactly one `.portal` per page, this is a non-issue for performance.

---

## 7. Swipe Event Simulation for Cucumber Tests

**Confidence: MEDIUM** [ASSUMED — Capybara/Selenium behavior with synthetic TouchEvent]

Capybara (Selenium + Chrome) has no native swipe API. The established workaround is `page.execute_script(...)` to dispatch synthetic `TouchEvent` objects:

```javascript
// Example swipe simulation
function simulateSwipe(element, startX, endX, y) {
  function touch(x, y) {
    return new Touch({ identifier: 1, target: element, clientX: x, clientY: y });
  }
  element.dispatchEvent(new TouchEvent('touchstart', {
    touches: [touch(startX, y)], changedTouches: [touch(startX, y)], bubbles: true
  }));
  element.dispatchEvent(new TouchEvent('touchmove', {
    touches: [touch(endX, y)], changedTouches: [touch(endX, y)], bubbles: true, cancelable: true
  }));
  element.dispatchEvent(new TouchEvent('touchend', {
    touches: [], changedTouches: [touch(endX, y)], bubbles: true
  }));
}
```

The `@mobile_portal` Cucumber tag already sets viewport to 390×844. Existing infrastructure in `features/support/window_resize.rb` handles Before/After hooks. No new support files are needed — a new step definition file for swipe steps fits the pattern.

**Vertical scroll non-interference (SWIPE-02)**: Simulate a touch with `|dy| > |dx|` (e.g., startX=195, startY=300, endX=196, endY=400) and assert no column change occurred.

---

## 8. Minitest Scope for Phase 31 (TEST-01)

**Confidence: HIGH** [VERIFIED: test/controllers/welcome_controller/welcome_controller_test.rb]

All existing Minitest tests are `ActionDispatch::IntegrationTest` — HTTP-level, no JS execution. There are no system tests in this project.

**Implication for TEST-01:** Minitest cannot verify JS behavior (swipe detection, active-column sync during interaction). TEST-01 coverage must be scoped to:
- Server-rendered HTML structure: `portal--column-active-0` initial class present
- Tab `aria-selected="true"` on column 0 tab at page load
- Three `.portal-column-tab` elements rendered per theme

JS behavior verification (column switch works, tab stays in sync, swipe triggers correctly) belongs exclusively to Cucumber (TEST-02).

---

## 9. Active Column Index Derivation

**Confidence: HIGH** [VERIFIED: portal_mobile_tabs.js + CONTEXT.md decision]

The current active column index is read from the DOM — which `.portal-column-tab` has `portal-column-tab--active`. No separate JS variable caches this. The swipe handler uses:

```javascript
const $activeTab = $tabs.find('.portal-column-tab--active');
const currentIndex = parseInt($activeTab.attr('data-portal-column-index'), 10);
```

This is safe because server always renders column 0 as active, and `activateColumn()` keeps DOM in sync.

---

## 10. Existing Cucumber Test (Regression Baseline)

**Confidence: HIGH** [VERIFIED: features/03.モダンテーマ.feature, features/step_definitions/modern_theme.rb]

The `@mobile_portal` scenario "モバイル幅でポータル列タブを切り替えられる" verifies:
1. Three `.portal-column-tab` buttons visible at mobile width
2. Clicking column 2 tab → `.portal.portal--column-active-1` and `button.portal-column-tab--active[data-portal-column-index="1"]`

This scenario is the regression baseline for tab-click behavior that Phase 29 must not break (UXA-01, UXA-02).

---

## Recommendations for Planner

| Area | Recommendation |
|------|----------------|
| JS implementation | Extend `portal_mobile_tabs.js`; extract `activateColumn()` before adding swipe logic |
| Touch listener attachment | Use native `addEventListener` with `{ passive: false }` on `.portal` directly — **not** jQuery event delegation on `$document` |
| Swipe test technique | `page.execute_script(...)` dispatching synthetic `TouchEvent` in Cucumber steps |
| Minitest scope | Server-rendered HTML structure only; JS behavior = Cucumber only |
| Column count | Always 3; reading from `.portal-column-tab` count in DOM is safe |
| Theme handling | No per-theme branching needed in Phase 29; all themes render same portal partial |

---

## Open Questions for Planner

1. **`touchstart` on tab buttons**: If a user begins a gesture on a `.portal-column-tab` button, `touchstart` fires there first. Should the swipe handler listen on `.portal` (which contains the tabs) and let the gesture propagate naturally, or should tab buttons have `touch-action: pan-y` to help the browser? [ASSUMED no change needed, but worth confirming]

2. **`touch-action` CSS property**: Adding `touch-action: pan-y` to `.portal` would tell the browser to handle vertical panning natively while letting JS handle horizontal — potentially cleaner than the dx/dy ratio check. CONTEXT.md does not mention this. Planner should decide whether to supplement or replace the ratio check with CSS `touch-action`. [ASSUMED: dx/dy ratio approach from CONTEXT.md is sufficient]

---

*Research complete: 2026-05-05*
