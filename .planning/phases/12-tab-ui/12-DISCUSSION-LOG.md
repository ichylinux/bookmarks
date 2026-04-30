# Phase 12: Tab UI — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 12-tab-ui
**Areas discussed:** Labels & panels, Client switching & URL, Theme isolation, Layout (synthetic — `/gsd-next` advanced with `--auto`-equivalent defaults)

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
