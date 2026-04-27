# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## Requirements

### Validated

- [x] User authentication and per-user data isolation (Devise, existing app behaviour) — **Re-verified in Phase 4** via automated and smoke paths
- [x] Bookmarks, feeds, todos, and portal-related features work in development as verified — **Phase 4 (VERI-01–03, manual smoke)**
- [x] In-repo browser JavaScript under `app/assets/javascripts/` uses a consistent, modern style (`const`/`let`, no accidental globals, clear structure) while remaining compatible with Sprockets, jQuery, and Babel — **Validated in Phases 3–4** (style + verification)
- [x] A documented baseline for JS style (lint and/or project conventions) is enforced or checkable for future changes — **Validated in Phase 2** (ESLint/Prettier, `yarn run lint`, README + `package.json`); **conventions in** `.planning/codebase/CONVENTIONS.md` **Phase 3–4 (DOCS-01)**
- [x] No regressions in existing behaviour; automated tests and manual smoke paths pass — **Phase 4**

### Active (milestone v1.1)

*(Milestone v1.1 is complete — no open active items from this list.)*

### Out of Scope (v1.1)

- Introducing a new frontend framework, npm-heavy bundler migration, or replacing the asset pipeline — defer unless explicitly opened in a later milestone
- Large UX redesigns unrelated to code style
- TypeScript conversion — not required for v1.1 (may be revisited later)

## Context

- Stack and architecture: see `.planning/codebase/STACK.md` and `ARCHITECTURE.md`
- JavaScript today: ES5/ES6-style files concatenated by Sprockets; `babel.config.js` is present for transforms; jQuery 4 and Rails UJS are in the manifest
- Legacy patterns observed: `var`, IIFE/window globals, jQuery `$(document).ready` — these should be modernized in line with the chosen style guide and tooling

## Constraints

- **Stack**: Sprockets + jQuery + existing gem pipeline — new JS must not break asset compilation or production minification
- **Browsers**: Target environments implied by Babel `preset-env` and project policy; avoid syntax that the pipeline does not transpile
- **Compatibility**: Preserve behaviour of `.js.erb` and controller-driven JS responses where used

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|--------|
| Keep Sprockets for v1.1 | Minimize risk; style modernization is the goal, not a framework migration | **Held for v1.1** — no bundler migration in this milestone (Phases 2–4) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

## Current Milestone: v1.1 Modern JavaScript — **complete** (2026-04-27)

**Goal (achieved):** In-repository JavaScript is brought to a maintainable, modern style without changing the overall Rails + Sprockets + jQuery architecture.

**Delivered:**
- Tooling and conventions (ESLint, `yarn run lint`, `CONVENTIONS.md` JavaScript section)
- Script modernization across `app/assets/javascripts/` (Phase 3)
- Full verification: lint, Minitest, Cucumber, and recorded manual smoke (Phase 4)

**Next:** Run `/gsd-complete-milestone` or plan the next milestone when ready.

---
*Last updated: 2026-04-27 — Milestone v1.1 complete (Phase 4 verify-and-document)*
