# Phase 7: Drawer CSS + Animation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `07-CONTEXT.md`.

**Date:** 2026-04-29
**Phase:** 7 — Drawer CSS + Animation
**Areas discussed:** Drawer panel width & box; Open/close motion

---

## Drawer panel width and box

| Option | Description | Selected |
|--------|-------------|----------|
| Q1a | Fixed 280px | |
| Q1b | Fixed 320px | |
| Q1c | Viewport-aware: `min(88vw, 320px)` / responsive cap | ✓ |
| Q2a | Background `var(--modern-bg)` | ✓ |
| Q2b | Slight off-white gray | |
| Q2c | Implementer discretion | |
| Q3a | Subtle shadow | |
| Q3b | Medium shadow | ✓ |
| Q3c | Strong shadow | |
| Q3d | Discretion | |

**User's choice:** Q1c, Q2a, Q3b (via letter replies: c, a, b)

---

## Open/close motion

| Option | Description | Selected |
|--------|-------------|----------|
| Q4a | 200ms | |
| Q4b | 250ms | ✓ |
| Q4c | 300ms | |
| Q5a | `ease-out` | ✓ |
| Q5b | Material-like cubic-bezier | |
| Q5c | `ease-in-out` | |
| Q5d | Discretion | |
| Q6a | Same duration and easing for drawer and overlay | ✓ |
| Q6b | Overlay slightly shorter | |
| Q6c | Discretion | |

**User's choice:** Q4b, Q5a, Q6a (via letter replies: b, a, a)

**Notes:** `prefers-reduced-motion: reduce` handled per ROADMAP / A11Y-01 (no transition); recorded as D-07 in CONTEXT.md.

---

## Claude's Discretion

- Exact `box-shadow` numeric values (medium).
- Z-index layering vs `#header` / tables.
- Hamburger line geometry and X morph; overlay rgba strength.

---

## Deferred Ideas

None.
