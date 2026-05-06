# Phase 29 Context: Swipe Navigation Foundation

**Date:** 2026-05-05
**Phase:** 029 — Swipe Navigation Foundation
**Goal:** Enable left/right swipe switching between adjacent columns on mobile, reflected through the same state flow as tab interaction.

---

<domain>
This phase delivers swipe gesture detection layered on top of the existing mobile tab UI. No backend changes. No new Rails routes or models. Pure JavaScript/DOM: `portal_mobile_tabs.js` is extended to handle `touchstart`/`touchmove`/`touchend` events on the `.portal` container, calling the same `activateColumn()` function that tab clicks use.
</domain>

---

<canonical_refs>
- `app/assets/javascripts/portal_mobile_tabs.js` — existing tab click handler; will be extended with swipe logic
- `app/views/welcome/_portal_column_section.html.erb` — portal DOM structure (`.portal-column-tabs`, `.portal`, `data-portal-column-index`)
- `app/assets/stylesheets/welcome.css.scss` — `$portal-mobile-breakpoint: 768px`; `portal--column-active-N` class pattern (lines 1–97)
- `.planning/REQUIREMENTS.md` — v1.8 requirements: SWIPE-01, SWIPE-02, SWIPE-03, STATE-01, UXA-01, UXA-02
</canonical_refs>

---

<decisions>

## Swipe Detection: Native Touch Events

**Decision:** Use native browser touch events (`touchstart`, `touchmove`, `touchend`) — no library.

HammerJS or similar would require vendoring a file or adding a gem, complicating the Sprockets pipeline. Native touch APIs are fully supported on mobile Safari and Chrome. The existing codebase uses zero npm runtime dependencies; this stays consistent with that constraint.

Implementation attaches to `.portal` (the column container) via event delegation on `$document`. This matches the existing pattern (`$root.on('click', '.portal-column-tab', ...)`) and gives a single listener for all portal instances on the page.

## Shared State Flow: Extract `activateColumn()`

**Decision:** Extract a named `activateColumn($portal, $tabs, index)` function. Both the existing tab click handler and the new swipe handler call it.

This is required by STATE-01: "Active column updates through a single state flow for both tab tap and swipe." Inlining separate sync logic in each handler would create two diverging code paths. The refactored function encapsulates:
1. `syncPortalClasses($portal, index)` — updates `portal--column-active-N` on `.portal`
2. Tab `--active` class and `aria-selected` updates on `.portal-column-tabs` buttons

The existing `syncPortalClasses` helper remains; `activateColumn` wraps it and adds the tab sync.

## Vertical Scroll Discrimination: dx/dy Ratio at 10px Intent Threshold

**Decision:** On `touchstart`, record `startX`/`startY`. On `touchmove`, once cumulative displacement exceeds 10px in any direction, compare `Math.abs(dx)` vs `Math.abs(dy)`. If vertical component dominates (`|dy| > |dx|`), mark the gesture as `scrollIntent = true` and stop processing (let the browser handle native scroll). If horizontal dominates, call `event.preventDefault()` and track the horizontal displacement.

The 10px threshold filters micro-movements before intent is clear. `preventDefault()` on horizontal gestures prevents the page from scrolling sideways while the column switch is in progress. This satisfies SWIPE-02.

State variables live only for the duration of one touch sequence and are reset on `touchstart`.

## Swipe Completion: `touchend` with 50px Minimum Displacement

**Decision:** Column switch fires on `touchend`, not live during drag. If `totalDx ≥ 50px` → attempt switch to next column (right swipe). If `totalDx ≤ -50px` → attempt switch to previous column (left swipe). Under 50px absolute displacement = cancelled gesture; no column change.

Live switching would feel broken in a single-visible-column layout where intermediate states are invisible. The 50px threshold represents roughly 1/6 of a 320px viewport — intentional but not demanding.

## Boundary Clamping: No Wrap (SWIPE-03)

**Decision:** When computing `newIndex = currentIndex ± 1`, clamp to `[0, colCount - 1]`. If `newIndex === currentIndex` after clamping (already at boundary), do not call `activateColumn()`. No wrap-around. This satisfies SWIPE-03 ("out-of-range swipe does not change active column").

Column count is derived from the number of `.portal-column-tab` elements inside the sibling `.portal-column-tabs`.

## File Organization: Extend `portal_mobile_tabs.js`

**Decision:** All mobile column interaction logic lives in `portal_mobile_tabs.js`. No new file.

Swipe and tab handlers share `activateColumn()` and `syncPortalClasses()`. Splitting into two files would require either a shared module (impossible with Sprockets concatenation order dependency) or polluting `window` globals. A single file is the correct choice for this stack.

## Active Column Tracking: DOM-Derived, Not a JS Variable

**Decision:** The current active column index is always read from the DOM — specifically, which `.portal-column-tab` has class `portal-column-tab--active`, or which `portal--column-active-N` class is on `.portal`. No separate JS variable caches this.

This avoids stale state if anything outside JS modifies the DOM. The portal DOM is server-rendered with `portal--column-active-0` always as initial state (column 1), so reading from the DOM is always safe.

</decisions>

---

<deferred>
- Swipe animation / visual transition between columns (CSS transform slide) — not in v1.8 scope; would require layout restructuring
- Touch velocity for fast-flick detection (momentum) — out of scope; 50px threshold is sufficient for v1.8
</deferred>

---

*Self-discussed: 2026-05-05. All decisions made by AI in self-discuss mode.*
