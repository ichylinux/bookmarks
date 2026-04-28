---
phase: 7
slug: drawer-css-animation
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-29
---

# Phase 7 — UI Design Contract

> Visual and interaction contract for Phase 7: Drawer CSS + Animation. Pure CSS (`body.modern` / `body.drawer-open`), no new JS — Phase 8 wires handlers.
>
> DOM selectors and labels are unchanged from `.planning/phases/06-html-structure/06-UI-SPEC.md`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — manual SCSS via Sprockets |
| Preset | not applicable |
| Component library | none |
| Icon library | none — hamburger is CSS-drawn (this phase completes line → X morph) |
| Font | system default (`font-family` not redefined until Phase 9 STYLE-02) |

Source: STACK constraint (Rails + Sprockets + jQuery; no SPA framework).

---

## Spacing Scale (Phase 7 — active tokens)

Declared values — all multiples of 4 px:

| Token | Value | Phase 7 usage |
|-------|-------|---------------|
| xs | 4px | Icon-to-label gaps inside drawer (if applicable) |
| sm | 8px | Dense stack gaps |
| md | 16px | Default vertical padding inside `.drawer nav` block |
| lg | 24px | Horizontal padding inside drawer panel (nav inset) |
| xl | 32px | Not used unless additional vertical sectioning is needed |

**Exceptions (justified):** none beyond **320px / 88vw** — viewport cap is structural width, not a spacing token clash.

Nested link vertical rhythm: **`padding-top` / `padding-bottom` ≥ 12px** per tap target (`12px = 4×3`, valid).

---

## Typography (Phase 7 — drawer chrome only)

Body copy app-wide stays at legacy baseline until Phase 9 — see `06-UI-SPEC.md`. This phase declares only drawer interior rules.

| Role | Size | Weight | Line height |
|------|------|--------|-------------|
| Drawer nav link (default) | 14px | 400 | 1.4 |
| Drawer nav link (active / current route) — future hook | 14px | 600 | 1.4 |

**≤4 sizes, ≤2 weights:** one size tier (14px), two weights (400 / 600) for default vs active.

Use existing Japanese link labels verbatim — copy authority remains `06-UI-SPEC.md` Copywriting Contract.

---

## Color

Consumption of Phase 5 tokens (`modern.css.scss`); no new custom properties unless required by libsass literals.

| Role | Token / value | Usage (Phase 7) |
|------|---------------|-----------------|
| Dominant (surface) | `--modern-bg` | Drawer panel background |
| Secondary (chrome) | `--modern-header-bg` | Optional top strip inside drawer header area (if styled); otherwise nav background only `--modern-bg` |
| Accent (interaction) | `--modern-color-primary` | Active drawer link color, `:focus-visible` outline for hamburger and nav links |
| Body text | `--modern-text` | Nav link text |
| Overlay | `rgba(0, 0, 0, 0.5)` | `.drawer-overlay` fill when `body.drawer-open` (single overlay colour; not a second accent) |
| Destructive | N/A this phase | No destructive affordance in drawer CSS |

**Accent reserved for:** primary interactive feedback in drawer (active link, `:focus-visible` rings on hamburger and links). **Not** for static body text or passive chrome.

**60 / 30 / 10:** Drawer panel is mostly `--modern-bg` (dominant); header-level chrome may use `--modern-header-bg` as secondary band; accent reserved for links/focus as above.

---

## Motion & Layering Contract

Locked from `07-CONTEXT.md` (D-01–D-07). Implement only under `body.modern`.

| Item | Contract |
|------|----------|
| Panel width | `width: min(88vw, 320px)` |
| Closed position | Off-canvas left: `transform: translateX(-100%)` (or equivalent so the full panel clears the viewport) |
| Open trigger | `body.modern.drawer-open` on `<body>` |
| Slide transition | `250ms`, `ease-out`, property `transform` |
| Overlay fade | Same **250ms** and **ease-out** on `opacity` (or equivalent), **no stagger** vs drawer |
| Reduced motion | `@media (prefers-reduced-motion: reduce)` → **zero-duration** transitions for drawer + overlay (instant state) |

**Z-index stack (must sit above `.wrapper` content and table-heavy pages):**

| Layer | Selector (Phase 7) | Minimum intent |
|-------|--------------------|----------------|
| Backdrop | `.drawer-overlay` | Below panel, above main content |
| Panel | `.drawer` | Above backdrop |
| Hamburger | `.modern #header .head-box .hamburger-btn` (or equivalent scoped rule) | **Above** drawer leading edge so the control stays visible and tappable when open |

Concrete values are implementer-chosen as long as paint order respects the table and matches `STATE.md` specificity note (`.modern #header .head-box` when competing with `common.css.scss`).

**Shadow:** medium-depth `box-shadow` on `.drawer` (single medium stack — e.g. `0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` or equivalent — not “hero” elevation).

---

## Hamburger → X Morph (CSS-only)

| Constraint | Contract |
|------------|----------|
| Touch target | Minimum **44×44px** (`min-width` / `min-height`) |
| Default state | Three horizontal bars via `::before` / `::after` / `box-shadow` on `button.hamburger-btn` (empty — no children) |
| Open state | When `body.drawer-open`: lines rotate/translate into a clear **X** (no new text/icon font) |
| Contrast | Line colour must meet **WCAG AA** against `--modern-header-bg` (implementer picks `#fff` or near-white if needed) |

---

## DOM & State (reference)

Unchanged from Phase 6 — see `06-UI-SPEC.md` § DOM Structure Contract:

- `button.hamburger-btn` — `aria-label="メニュー"`
- `div.drawer` — direct child of `<body>`, contains `<nav>` with seven links
- `div.drawer-overlay` — sibling, empty

**Phase 7 visual states:**

| State | CSS condition | Drawer | Overlay | Hamburger |
|-------|----------------|--------|---------|-----------|
| Closed | `body.modern:not(.drawer-open)` | Off-canvas | Hidden / inert visually | Bars |
| Open | `body.modern.drawer-open` | Slid in | Visible dimmer | X |
| Reduced motion open/close | same + `prefers-reduced-motion: reduce` | Instant snap | Instant opacity | Snap (no transition) |

**Out of scope (Phase 8):** backdrop click, Esc, nav link navigation — NAV-03 behaviour; Phase 7 CSS only enables the visuals when `.drawer-open` is toggled manually (e.g. DevTools) for acceptance.

---

## Copywriting Contract

No new user-facing strings in Phase 7. Authoritative labels and `aria-label` remain:

| Element | Copy | Source |
|---------|------|--------|
| Hamburger `aria-label` | `メニュー` | `06-UI-SPEC.md` |
| Nav links (1–7) | Unchanged Japanese/English mix | `06-UI-SPEC.md` table |
| Primary CTA / empty / error / destructive | N/A | Structural/motion phase only |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| N/A — no component registry | none | not applicable |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS — no new copy; Phase 6 table referenced
- [x] Dimension 2 Visuals: PASS — focal hierarchy: dimmed page → drawer panel → hamburger control on top stack
- [x] Dimension 3 Color: PASS — 60/30/10 and accent reservation explicit; overlay is non-accent `rgba`
- [x] Dimension 4 Typography: PASS — one drawer size (14px), two weights (400 / 600)
- [x] Dimension 5 Spacing: PASS — scale uses 4 px multiples only
- [x] Dimension 6 Registry Safety: PASS — no third-party registry

**Approval:** approved 2026-04-29
