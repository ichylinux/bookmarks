# Phase 7: Drawer CSS + Animation - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Pure CSS in `themes/modern.css.scss` (and existing layout markup only if unavoidable): when `body.drawer-open` is toggled manually (e.g. DevTools), the `.drawer` panel slides in from the left with `transform: translateX`, `.drawer-overlay` fades in, stacking order is above page content, `.hamburger-btn` morphs visually to an X, and `prefers-reduced-motion: reduce` removes transitions. No JS for open/close — Phase 8 wires behaviour. Scoped to `body.modern` so non-modern themes are unaffected.

</domain>

<decisions>
## Implementation Decisions

### Drawer panel width and box (discussion 2026-04-29)

- **D-01 (Q1):** Panel horizontal size uses a **viewport-aware cap**: implement as **`width: min(88vw, 320px)`** (equivalent intent: never wider than 320px, on narrow viewports cap at 88vw so the panel does not overrun the screen).
- **D-02 (Q2):** Panel **background** is **`var(--modern-bg)`** (Phase 5 token).
- **D-03 (Q3):** Panel **shadow is medium strength** — clear enough that the drawer reads as layered above content, without extreme depth. Exact `box-shadow` values: **Claude's discretion** within “medium”.

### Open/close motion (discussion 2026-04-29)

- **D-04 (Q4):** Default transition **duration `250ms`** for slide and overlay fade (when motion is allowed).
- **D-05 (Q5):** Default **easing: `ease-out`** for those transitions.
- **D-06 (Q6):** **Drawer slide and overlay fade use the same duration and the same easing** (no deliberate stagger).

### Reduced motion (ROADMAP / A11Y-01)

- **D-07:** When `prefers-reduced-motion: reduce` is active, drawer and overlay **appear/disappear with no transition** (instant state change). Overrides D-04–D-06 for that media query.

### Claude's Discretion

- Exact `translateX` off-canvas value (match drawer width so panel is fully hidden when closed).
- Z-index values for `.drawer`, `.drawer-overlay`, and hamburger stacking — must satisfy ROADMAP “above page content” and coexist with `#header` / `.wrapper` (see STATE pitfall: `.modern #header .head-box` specificity where header conflicts arise).
- Hamburger **line thickness, gap, and X morph geometry** (button remains empty; lines via `::before` / `::after` / `box-shadow` per Phase 6).
- Overlay fill colour (e.g. `rgba(0, 0, 0, 0.5)` or similar) — not locked in discussion; keep readable contrast with tokens where sensible.

</decisions>

<specifics>
## Specific Ideas

- User prefers **balanced** motion: 250ms, `ease-out`, drawer and overlay **in lockstep**.
- Panel should feel **not cramped on small viewports** (88vw cap) while staying **≤ 320px** on larger screens.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and acceptance
- `.planning/ROADMAP.md` § Phase 7 — five success criteria (translateX slide, reversible, z-index, hamburger-to-X, `prefers-reduced-motion`).
- `.planning/REQUIREMENTS.md` — **NAV-03** Phase 7 portion (backdrop/link/Esc close are **Phase 8**); **A11Y-01** (reduced motion) **Phase 7**.

### Prior phase decisions
- `.planning/phases/06-html-structure/06-CONTEXT.md` — `.hamburger-btn` (empty, `aria-label`), `.drawer` / `.drawer-overlay` placement, class names, `.modern` scoping expectation.
- `.planning/phases/05-theme-foundation/05-CONTEXT.md` — `--modern-*` token names; libsass: custom property **values** remain plain CSS literals.

### Implementation files
- `app/assets/stylesheets/themes/modern.css.scss` — primary deliverable for Phase 7 rules.
- `app/views/layouts/application.html.erb` — hamburger, drawer, overlay markup (Phase 6); avoid markup changes unless CSS cannot meet SC.
- `.planning/STATE.md` § Accumulated Context — drawer clipping, header specificity, `menu.js` guard (Phase 8).

### Conventions
- `.planning/codebase/CONVENTIONS.md` — SCSS/asset patterns if referenced by project.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `app/assets/stylesheets/themes/modern.css.scss` — `.modern {}` block with design tokens; Phase 7 extends with drawer, overlay, hamburger, and `body.modern.drawer-open` rules.
- `app/views/layouts/application.html.erb` — `.hamburger-btn`, `.drawer`, `.drawer-overlay` already in DOM for signed-in users.

### Established patterns
- Theme styles live under `.modern` selector; Phase 6 locked **visibility/control** to Phase 7 CSS for non-modern themes.
- Phase 6 **D-01** plans flex + `justify-content: space-between` on `.modern #header .head-box` for hamburger on the right — Phase 7 should align hamburger/line/X animation with that layout.

### Integration points
- Slide target: `body.drawer-open` class on `<body>` (Phase 8 will toggle; Phase 7 styles assume class present).
- Drawer closed state: default off-canvas via `transform: translateX(-100%)` (or equivalent) when `body:not(.drawer-open)` under `.modern`, or equivalent pattern consistent with markup.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-drawer-css-animation*
*Context gathered: 2026-04-29*
