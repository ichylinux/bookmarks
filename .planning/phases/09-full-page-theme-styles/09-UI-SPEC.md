---
phase: 9
slug: full-page-theme-styles
status: approved
extends_visual_spec: ../07-drawer-css-animation/07-UI-SPEC.md
created: 2026-04-29
---

# Phase 9 — UI Design Contract (Full-Page Theme)

> **Drawer / hamburger / motion:** inherited from Phase 7 (`07-UI-SPEC.md`). This contract locks **global surfaces** under `body.modern` for STYLE-01–STYLE-04.

---

## Scope

| In scope | Out of scope |
|----------|----------------|
| `themes/modern.css.scss` only (additive rules inside `.modern`) | Devise / auth page HTML redesign |
| `#header .head-box`, `.header` nav strip, `body` typography, `table`, `.actions`, form controls | New component library, font files, build tool migration |
| Contract test strings for CI | Pixel-perfect design QA |

---

## Tokens (extend Phase 7)

Existing: `--modern-color-primary`, `--modern-bg`, `--modern-text`, `--modern-header-bg`.

**Phase 9 additions (plain literals only):**

| Token | Purpose | Example |
|-------|---------|---------|
| `--modern-header-fg` | Text/icons on primary header bar | `#ffffff` |
| `--modern-border` | Default border for inputs / secondary chrome | `#d1d5db` or equivalent |
| `--modern-surface-alt` | Table header / zebra alt row | subtle gray derived from palette |
| `--modern-danger` | Delete / destructive affordance | distinct red hex |

(Exact hex values chosen in implementation; must remain libsass-safe.)

---

## Surfaces

### S-01 — Primary header (`STYLE-01`)

| Selector | Must |
|----------|------|
| `.modern #header .head-box` | Background uses `var(--modern-header-bg)` (or same hue as token). **No** raw `#AAA`. Text/icon contrast readable. |
| `.modern #header .head-box` | Padding aligned with Phase 7 flex row; hamburger rules unchanged. |

### S-02 — Nav strip `.header` (`STYLE-01`)

| Selector | Must |
|----------|------|
| `.modern .header` | Not the old “floating 20px bar” look — min-height, padding, link colour readable on page background. |
| `.modern .header a` | Visible hover/focus; email dropdown `.menu` remains usable (border/background cohesive). |

### S-03 — Body typography (`STYLE-02`)

| Selector | Must |
|----------|------|
| `.modern` (body carries class) | `font-size: 16px`; `line-height` ≥ 1.5; `font-family` system stack per `09-CONTEXT.md` D-04. |

### S-04 — Data tables (`STYLE-03`)

| Selector | Must |
|----------|------|
| `.modern table` | `th` / `td` padding clearly > legacy 5px (e.g. 10–12px). |
| `.modern table` | Header row visually distinct (background or bottom border). |
| `.modern table tbody tr:nth-child(even)` **or** hover | Alternating or enhanced hover — no “bare HTML table” look. |

### S-05 — Action links (`STYLE-04`)

| Selector | Must |
|----------|------|
| `.modern .actions a` | Pill/button appearance using tokens; hover state; `focus-visible` outline. |

### S-06 — Form controls (`STYLE-04`)

| Selectors | Must |
|-----------|------|
| `.modern input`, `textarea`, `select` (reasonable subset of types) | Border, padding, `border-radius`, focus ring using primary token. |
| `.modern input:focus-visible`, etc. | Visible focus — WCAG-friendly outline. |

---

## Interaction

No new JS. Existing focus/hover behaviours only.

---

## Quality bar

- Sprockets compiles with no error.
- `bin/rails test` includes passing SCSS contract test.
- No regression to non-modern theme (selectors remain `.modern`-scoped).

---

*Drawer visual tokens: `07-UI-SPEC.md`. Phase 9: remainder of page chrome.*
