# Phase 7 — Technical Research

**Phase:** Drawer CSS + Animation  
**Question:** What do we need to know to plan implementation in `modern.css.scss` only?

## RESEARCH COMPLETE

---

## A. Stacking and specificity (Rails + `common.css.scss`)

- **Finding:** `STATE.md` requires `.modern #header .head-box` (not `.modern .head-box`) to beat `#header` rules in legacy CSS.
- **Implication:** Hamburger button rules MUST nest under `.modern #header .head-box` or an equally specific selector so the control stays visible and styled above the drawer edge (per `07-UI-SPEC.md` z-index contract).

---

## B. Drawer geometry vs `translateX`

- **Finding:** Panel width is locked to `width: min(88vw, 320px)` (`07-CONTEXT.md` D-01).
- **Implication:** Closed state should use `transform: translateX(-100%)` so the panel moves by its own width regardless of exact pixel width (avoids hard-coding `-320px`).

---

## C. Overlay interaction (Phase 7 vs 8)

- **Finding:** ROADMAP Phase 7 success criteria are purely visual when `.drawer-open` is toggled manually. Backdrop click / Esc / link click are Phase 8 (`NAV-03` behaviour).
- **Implication:** Phase 7 CSS may set `pointer-events: none` on overlay when closed and `pointer-events: auto` when open so Phase 8 can attach click handlers without changing markup.

---

## D. `prefers-reduced-motion`

- **Finding:** `A11Y-01` and D-07 require zero-duration transitions under `@media (prefers-reduced-motion: reduce)` for drawer slide and overlay fade.
- **Implication:** Use a single media query block that sets `transition-duration: 0s` (or `transition: none`) for `.drawer`, `.drawer-overlay`, and hamburger line transforms.

---

## E. Hamburger morphology

- **Finding:** Button is empty; Phase 6 delivered no inner elements. `07-UI-SPEC.md` specifies `::before` / `::after` / `box-shadow` for three bars and morph to X when `body.drawer-open`.
- **Implication:** Plan tasks for pseudo-elements with `transition` on `transform` (also suppressed in reduced-motion block).

---

## F. Verification approach

- **Finding:** No existing test reads theme SCSS; full visual proof remains manual (DevTools body class).
- **Implication:** Add a lightweight Minitest that reads `modern.css.scss` and asserts required substrings (contracts from CONTEXT/UI-SPEC) so CI catches accidental deletion of critical rules.

---

## Validation Architecture

Phase validation uses **Rails Minitest** already in the repo.

| Dimension | Strategy |
|-----------|----------|
| Automated | `bin/rails test` after changes; optional new `test/...` file scanning SCSS for contract strings |
| Manual | Browser DevTools: toggle `body` class `modern drawer-open` on signed-in page — observe slide, overlay, hamburger X |
| Sampling | After each task: run targeted test file; end of phase: full `bin/rails test` |

Nyquist note: CSS-only phase — no DB schema push; build risk is asset compile (Sprockets) and test green.

---

## G. Schema / ORM

- **Finding:** No Prisma/Drizzle/Payload/Supabase migrations in scope.
- **Implication:** No `[BLOCKING]` schema push task.
