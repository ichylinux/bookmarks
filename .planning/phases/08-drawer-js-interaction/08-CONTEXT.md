# Phase 8: Drawer JS Interaction - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire **jQuery** in `menu.js` so users with the **modern** theme can **open and close** the side drawer via the hamburger, **backdrop click**, **Esc**, and **drawer nav links**, by toggling **`drawer-open` on `<body>`** (CSS from Phase 7 owns motion). The implementation **must not break** the legacy dropdown in `_menu.html.erb`, especially the existing **`$('html').click`** handler that dismisses the email menu. **No new capabilities** beyond ROADMAP success criteria — e.g. `aria-expanded` polish and focus trapping stay **out of scope** unless listed in Future requirements.

</domain>

<decisions>
## Implementation Decisions

### Toggle contract (ROADMAP SC1)
- **D-01:** **`drawer-open` is the only open state** — add/remove class on `<body>` together with existing **`modern`** class from theme; no parallel hidden flag required for Phase 8.

### Hamburger (ROADMAP SC1 + STATE pitfall)
- **D-02:** **Hamburger `click` toggles** the drawer.
- **D-03:** Hamburger handler uses **`event.stopPropagation()`** so the event does **not** reach `$('html').click` in `app/views/common/_menu.html.erb` (avoids interfering with dropdown dismiss logic and spurious closes).

### Backdrop (ROADMAP SC2)
- **D-04:** **Click on `.drawer-overlay`** (only the overlay, not the panel) **closes** the drawer (remove `drawer-open`). Panel clicks do not close via overlay rule — overlay is a **sibling** of `.drawer` in layout.

### Escape key (ROADMAP SC3)
- **D-05:** While **`body.modern` has `drawer-open`**, **`keydown`** on **`document`** for **`Escape`** closes the drawer. Handler should be **guarded** so it no-ops when the drawer is closed or theme is not modern.

### Nav links (ROADMAP SC4)
- **D-06:** **Delegated `click`** on **`.drawer nav a`**: **remove `drawer-open`** before navigation proceeds (synchronous handler; do not preventDefault unless a future requirement demands SPA-style interception).

### Scope and legacy menu (ROADMAP SC5)
- **D-07:** **`menu.js` entry guard:** if **`body` lacks `modern`**, **return immediately** and **attach no drawer listeners** (existing Phase 5 pattern).
- **D-08:** **Do not edit** `_menu.html.erb` **inline `<script>`** for Phase 8 unless a technical impossibility is documented — prefer **isolating drawer behaviour in `menu.js`** only.

### Runtime / lifecycle
- **D-09:** Use **`$(function() { ... })`** for registration (no Turbo/Turbolinks hooks detected in repo). If full-page patterns change later, revisit with `turbo:load` — **not part of Phase 8** unless tests prove a gap.

### Claude's Discretion
- Exact **names** of handler functions, **`on`/`off`** vs one-time binding, **`keydown` namespace** string, and **Minitest vs system** integration test structure — as long as SC1–SC5 and ESLint/`no-var` pass.
- Whether overlay click uses **mousedown vs click** — default **click** unless UX research says otherwise.

</decisions>

<specifics>
## Specific Ideas

- Prior phases already chose **balanced** drawer motion in CSS; JS should only toggle class, not timings.
- **Reduced motion** remains CSS-only (Phase 7); JS does not read `prefers-reduced-motion` for Phase 8.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — **Phase 8** goal, success criteria 1–5, dependencies (Phase 7).
- `.planning/REQUIREMENTS.md` — **NAV-02**, **NAV-03** (interaction slice for this phase).

### Prior phase artifacts
- `.planning/phases/07-drawer-css-animation/07-CONTEXT.md` — Phase boundary; CSS owns motion; `drawer-open` on `body`.
- `.planning/phases/07-drawer-css-animation/07-01-SUMMARY.md` — Implemented stack/z-index and libsass notes (no Phase 8 markup change expected).
- `.planning/phases/07-drawer-css-animation/07-UI-SPEC.md` — DOM selectors (`.drawer`, `.drawer-overlay`, `.hamburger-btn`).
- `.planning/phases/06-html-structure/06-CONTEXT.md` — Markup placement (drawer outside `.wrapper`).

### Live code (integration)
- `.planning/STATE.md` — **Critical Pitfalls**: `menu.js` guard, **`$('html').click` + `stopPropagation`** on hamburger.
- `app/views/layouts/application.html.erb` — Hamburger, `.drawer`, `.drawer-overlay` structure.
- `app/views/common/_menu.html.erb` — **Legacy** `$(document).ready`, **email/menu**, **`$('html').click`** dismiss — regression target.
- `app/assets/javascripts/menu.js` — Phase 8 implementation site.
- `app/assets/stylesheets/themes/modern.css.scss` — Visual open/close tied to `body.modern.drawer-open`.

### Conventions
- `.planning/codebase/CONVENTIONS.md` — jQuery/`this` vs arrow functions, `const`/`let`, ESLint.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`menu.js`** — Already wrapped in `$(function() { ... })` with **`modern` guard**; extend inside the guard for drawer only.

### Established Patterns
- **Legacy menu:** `_menu.html.erb` uses **`var`** in inline script (out of ESLint scope); **new code** in `menu.js` must stay **`const`/`let`** and pass **`yarn run lint`**.
- **Dismiss-on-outside-click:** `$('html').click` closes dropdown when target is **not** inside `.email`; hamburger must **stopPropagation** so opening the drawer does not fire that path in a way that breaks dropdown state.

### Integration Points
- **`body` class list** from `favorite_theme` in layout — **`modern`** + **`drawer-open`** toggled only by `menu.js`.
- **Drawer markup** is **`if user_signed_in?`** in layout — same guard as dropdown; signed-out users do not load drawer DOM.

</code_context>

<deferred>
## Deferred Ideas

- **`aria-expanded`** on hamburger and live region announcements — **Future** per `.planning/REQUIREMENTS.md` (A11Y-F01-style); not ROADMAP Phase 8.
- **Focus trap / initial focus inside drawer** — not in Phase 8 success criteria; consider a later a11y phase if needed.
- **Swipe-to-close** drawer — new capability; backlog / future phase.

</deferred>

---

*Phase: 08-drawer-js-interaction*
*Context gathered: 2026-04-29*
