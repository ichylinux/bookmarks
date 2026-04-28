---
phase: 8
slug: drawer-js-interaction
status: approved
extends_visual_spec: ../07-drawer-css-animation/07-UI-SPEC.md
created: 2026-04-29
---

# Phase 8 — UI Design Contract (JavaScript)

> **Visual** chrome (drawer panel, overlay, hamburger→X, motion, tokens) is defined in `.planning/phases/07-drawer-css-animation/07-UI-SPEC.md`. This document locks **behaviour** for `menu.js` under `body.modern`.

---

## Scope

| In scope | Out of scope (per `08-CONTEXT.md`) |
|----------|-------------------------------------|
| Toggle `drawer-open` on `<body>` via hamburger, overlay, Esc, drawer nav links | `aria-expanded`, focus trap, swipe-to-close |
| Isolation from `$('html').click` in `_menu.html.erb` | Edits to inline `<script>` in `_menu.html.erb` unless impossible |

---

## DOM Selectors (unchanged from Phase 7)

| Role | Selector |
|------|----------|
| Open state on `body` | `body.modern.drawer-open` |
| Hamburger | `button.hamburger-btn` (in `#header .head-box`) |
| Overlay (backdrop) | `.drawer-overlay` |
| Drawer panel | `.drawer` |
| Drawer links | `.drawer nav a` |

---

## Interaction Contract

| ID | Trigger | Expected behaviour |
|----|---------|-------------------|
| I-01 | **Click** `.hamburger-btn` | `stopPropagation()` on the event so it does **not** reach `$('html').click`. Toggle: if `body` lacks `drawer-open`, add it; else remove it. |
| I-02 | **Click** `.drawer-overlay` | Remove `drawer-open` from `body`. Clicks on `.drawer` **never** use this rule (sibling markup — panel does not sit inside overlay). |
| I-03 | **`keydown` `Escape`** on `document` | If `body.modern` has `drawer-open`, remove `drawer-open`. If drawer closed or not `modern`, no-op. |
| I-04 | **Click** any `.drawer nav a` | Remove `drawer-open` **before** navigation (handler does not use `preventDefault` unless a future requirement says so). |
| I-05 | **Non-modern** `body` | `menu.js` must **not** register any of I-01–I-04 handlers (early return — existing Phase 5 pattern). |

---

## Legacy menu coexistence (ROADMAP SC5)

| Check | Expectation |
|-------|-------------|
| Email dropdown | After Phase 8, user can still open `.email` menu, choose links, and dismiss via outside click (`$('html').click` path in `_menu.html.erb`) on **non-modern** and **modern** themes. |
| Hamburger vs dismiss | I-01 **must** use `stopPropagation()` so opening/closing the drawer does not spuriously trigger the global dismiss handler in ways that break dropdown state. |

---

## Lifecycle

| Rule | Value |
|------|-------|
| Init | `$(function () { ... })` (same as current `menu.js`) |
| No Turbo hook | Unless a failing test proves full-page reload is insufficient — not part of Phase 8 by default |

---

*Visual copy, colour, motion: `07-UI-SPEC.md`. Phase 8: behaviour only.*
