# Phase 8 — Technical Research

**Phase:** Drawer JS Interaction  
**Question:** What do we need to know to plan `menu.js` changes without breaking `_menu.html.erb`?

## RESEARCH COMPLETE

---

## A. Global `html` click vs hamburger

- **Finding:** `_menu.html.erb` binds `$('html').click` to add `hidden` to `.menu` when the target is outside `.email`.
- **Implication:** Every **hamburger** click **must** call `event.stopPropagation()` (per `08-CONTEXT` D-03) so the bubble phase does not run the dismiss handler when we intend only to toggle the drawer — avoiding double-behavior and broken dropdown state.

---

## B. Overlay vs panel (markup)

- **Finding:** `application.html.erb` renders `.drawer` and `.drawer-overlay` as **siblings** under `body`.
- **Implication:** Backdrop close is implemented as a **direct** click handler on `.drawer-overlay`, not as “click outside drawer” on `document` (avoids fighting the email dismiss handler and matches D-04).

---

## C. Esc key

- **Finding:** No existing **Escape** handler in `_menu.html.erb` for the email menu.
- **Implication:** `document` `keydown` listener for `Escape` is safe for Phase 8 when guarded with `body.modern` + `drawer-open` (D-05). Optional: jQuery namespaced event (`keydown.drawerPhase8`) for clarity; teardown not required for traditional full page loads.

---

## D. Nav links

- **Finding:** Drawer links are full page GET navigations (`link_to`).
- **Implication:** Synchronous `removeClass('drawer-open')` in a delegated click handler on `.drawer nav a` satisfies D-06 without `preventDefault`.

---

## E. Test stack

- **Finding:** Repo has `ActionDispatch::IntegrationTest` with layout assertions (`layout_structure_test.rb`) but **no** system tests that execute JavaScript yet (`ApplicationSystemTestCase` exists with Selenium + Chrome).
- **Implication:** Phase 8 should add `test/system/` coverage using **headless Chrome** for class-toggle behaviour (NAV-02/NAV-03). Include `Devise::Test::IntegrationHelpers` in system tests or sign in via UI. Prefer updating `ApplicationSystemTestCase` to include Devise helpers once, then implement drawer tests in a dedicated file.

---

## F. Reduced motion

- **Finding:** `08-CONTEXT.md` — JS does **not** read `prefers-reduced-motion`; Phase 7 CSS owns instant transitions.
- **Implication:** No `matchMedia` in Phase 8.

---

## Validation Architecture

Phase validation uses **Rails Minitest** (existing) plus **new system tests** for JS behaviour.

| Dimension | Strategy |
|-----------|----------|
| Automated | `bin/rails test`; `test/system/modern_drawer_interaction_test.rb` (headless) for open/close paths; optional integration test for legacy dropdown dismiss |
| Manual | Browser: modern theme, exercise hamburger, overlay, Esc, drawer link; repeat email dropdown on classic vs modern |
| Sampling | After implementation: `bin/rails test test/system/…` then full suite |

Nyquist note: **no** DB schema push for this phase.

---

## G. Schema / ORM

- **Finding:** No migration or ORM schema files in scope.
- **Implication:** No `[BLOCKING]` schema push task.
