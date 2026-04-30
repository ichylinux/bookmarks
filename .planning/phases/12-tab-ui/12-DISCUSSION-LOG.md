# Phase 12: Tab UI — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 12-tab-ui
**Areas discussed:** Labels & panels, Client switching & URL, Theme isolation, Layout (synthetic); **session 2:** URL sync on click, Tab control element (`button` vs link)

---

## Labels & panel scope

| Option | Description | Selected |
|--------|-------------|----------|
| Japanese (ROADMAP SC) | ホーム / ノート | ✓ |
| English (REQUIREMENTS draft) | Home / Note | |

**User's choice:** Auto — ROADMAP success criteria are authoritative for copy.
**Notes:** REQUIREMENTS TAB bullets still say English; CONTEXT.md records Japanese for implementation.

---

## Client tab switching

| Option | Description | Selected |
|--------|-------------|----------|
| jQuery show/hide + query param | Matches STATE; no new deps | ✓ |
| Turbolinks / Turbo visit | Not in stack | |
| Cookie-only tab memory | Conflicts with explicit `?tab=` redirect contract | |

**User's choice:** Auto — jQuery + `URLSearchParams` on load.

---

## Theme isolation

| Option | Description | Selected |
|--------|-------------|----------|
| ERB + SCSS `.simple` + JS early return | Double guard per STATE pitfall list | ✓ |
| ERB only | Insufficient if global JS runs | |

**User's choice:** Auto — triple alignment with Phase 11 / v1.3 notes.

---

## Notes panel content in Phase 12

| Option | Description | Selected |
|--------|-------------|----------|
| Shell only; Phase 13 mounts gadget | Matches phase boundary | ✓ |
| Full gadget in Phase 12 | Scope creep vs ROADMAP | |

**User's choice:** Auto — shell + placeholder acceptable.

---

## Claude's Discretion

- Active tab styling details, optional ARIA enhancements, placeholder microcopy.

## Deferred Ideas

- Per-note delete, note themes beyond simple — existing roadmap / REQUIREMENTS deferrals
- Bookmarkable `?tab=` via client-side URL sync — deferred (D-07)

---

## URL sync on tab click (user-selected area 1)

| Option | Description | Selected |
|--------|-------------|----------|
| Query only on full load / redirect | Tab clicks are display-only; `?tab=` comes from server redirect or initial GET | ✓ |
| `history.pushState` on each click | URL always reflects active tab; shareable deep links | |

**User's choice:** Discussed areas 1–2; locked **redirect/GET-only query** (recommended: simpler, matches ROADMAP, no history spam).
**Notes:** Recorded as **D-07** in CONTEXT.md.

---

## Tab control element (user-selected area 2)

| Option | Description | Selected |
|--------|-------------|----------|
| `button type="button"` + menu-like CSS | Accessible default action; style like `_menu` | ✓ |
| `link_to` + preventDefault | Appearance matches links; more foot-guns | |

**User's choice:** **`button`** pattern (recommended).
**Notes:** Recorded as **D-08** in CONTEXT.md; **D-06** updated to defer to D-08.
