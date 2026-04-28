# Phase 5: Theme Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 5-Theme Foundation
**Areas discussed:** Token naming convention

---

## Token Naming Convention

| Option | Description | Selected |
|--------|-------------|----------|
| `--modern-color-primary` (prefixed) | Name carries the theme prefix. Explicit, conflict-free if other themes later define their own tokens. | ✓ |
| `--color-primary` (unprefixed) | No theme prefix — shorter names inside `.modern {}`. Cleaner at call site but indistinguishable from hypothetical global tokens. | |

**User's choice:** `--modern-*` prefix

**Notes:** None beyond the selection.

---

## Token Set Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal — colors only | 4 color tokens: primary, bg, text, header-bg. Drawer/typography tokens added in phases 7–9. | ✓ |
| Full upfront — colors + drawer + typography | All tokens for phases 7–9 defined now as placeholders. | |

**User's choice:** Minimal — colors only
**Notes:** Values confirmed as shown in preview: `#3b82f6`, `#ffffff`, `#1a1a1a`, `#1e40af`.

---

## Color Values

| Option | Description | Selected |
|--------|-------------|----------|
| Use the preview values | `#3b82f6` primary, `#ffffff` bg, `#1a1a1a` text, `#1e40af` header-bg. Blue-dominant, clean light theme. | ✓ |
| You decide — match the app | Claude picks values complementing the existing app style. | |

**User's choice:** Use the preview values as-is.

---

## Claude's Discretion

- Internal structure of `menu.js` stub (empty body, comment skeleton) — follow v1.1 JS conventions.
- Exact SCSS nesting style inside `.modern {}` — follow `simple.css.scss` as reference.

## Deferred Ideas

None.
