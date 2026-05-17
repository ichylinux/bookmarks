# Phase 76: `portal_lazy.js` Coordinator - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

A new `portal_lazy.js` coordinator module exists and is available at `window.portalLazy` with the full public API (`register(columnIndex, loadFn)` and `loadColumn(index)`), but causes zero visible behavior change — all gadgets still load immediately because no partial calls `register` yet. On desktop, `register` fires `loadFn` immediately (pass-through). On mobile, the module queues registered load functions and drains each column's queue on first `loadColumn(index)` call.

</domain>

<decisions>
## Implementation Decisions

### Initial Column Detection
- Read `--portal-initial-active-index` from `document.documentElement.style.getPropertyValue()` at file parse time — the prehydration script in `_dashboard.html.erb` writes it synchronously before any other JS; avoids duplicate localStorage access
- Fall back to `0` when the CSS property is absent or invalid (private browsing, no prior visit) — column 0 is always initially visible
- Keep `initialColumnIndex` as an internal variable — not exposed on `window.portalLazy`; not part of IMPL-01 contract

### Module API Structure
- Initialize with a top-level IIFE that sets `window.portalLazy` — makes `register` and `loadColumn` available synchronously before any `$(document).ready` fires; consistent with global namespace pattern in CONVENTIONS.md (`window.name = window.name || {}`)
- Track load state with a plain object: `const loadedColumns = {}` — ES5/6 compatible, simple, consistent with codebase style
- `loadColumn(index)` marks synchronously before firing any load functions — satisfies IMPL-04 ("load state marked synchronously before any $.get fires")
- `loadColumn` is a no-op when called for an already-loaded column (early return)
- Desktop/mobile detection uses exact `window.matchMedia('(max-width: 767px)')` pattern from `portal_mobile_tabs.js` — same 767px breakpoint

### Claude's Discretion
- Internal queue data structure (plain JS object or nested array — either is fine)
- File placement in `app/assets/javascripts/portal_lazy.js` — Sprockets alphabetical order guarantees it loads before `portal_mobile_tabs.js`

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `portal_mobile_tabs.js` — `isMobileViewport()` pattern using `window.matchMedia('(max-width: 767px)').matches`; `STORAGE_KEY = 'portalMobileActiveColumn'`; `activateColumn()` function that will be extended in Phase 77
- `_dashboard.html.erb` — inline prehydration IIFE that reads localStorage and writes `--portal-initial-active-index` to `document.documentElement.style` synchronously; coordinator reads this property at parse time

### Established Patterns
- Global namespace declaration: `window.name = window.name || {}` then `const name = window.name` (from CONVENTIONS.md)
- jQuery callbacks that use `this` as element: use `function`, not arrow function
- Short data callbacks (`$.get` success): may use arrow functions
- `const`/`let` only — `var` is forbidden (ESLint `no-var` enforced)
- Sprockets alphabetical load order: `portal_lazy.js` loads before `portal_mobile_tabs.js` automatically

### Integration Points
- AJAX gadget partials (`_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb`) — each uses `$(document).ready` + `$.get`; Phase 77 will wrap these in `portalLazy.register(columnIndex, loadFn)`
- `activateColumn()` in `portal_mobile_tabs.js` — Phase 77 will add `window.portalLazy.loadColumn(index)` call inside it
- `window.matchMedia('(max-width: 767px)').matches` — shared mobile detection threshold; must match exactly

</code_context>

<specifics>
## Specific Ideas

No specific UI or interaction requirements — this phase creates a zero-visible-behavior-change coordinator. All implementation choices align with the IMPL-01 contract defined in REQUIREMENTS.md.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
