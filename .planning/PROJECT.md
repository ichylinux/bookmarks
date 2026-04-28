# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## Current Milestone: v1.2 Modern Theme

**Goal:** Add a selectable "Modern" theme with a hamburger side-drawer nav and clean, full-page styling throughout the app.

**Target features:**
- New `modern` theme option in the preferences UI
- Hamburger button in the header opens a side drawer with all navigation links
- Full-page modern styling: header bar, body typography, tables, action buttons, and forms

## Requirements

### Validated

- [x] User authentication and per-user data isolation (Devise, existing app behaviour) — **Re-verified in Phase 4** via automated and smoke paths
- [x] Bookmarks, feeds, todos, and portal-related features work in development as verified — **Phase 4 (VERI-01–03, manual smoke)**
- [x] In-repo browser JavaScript under `app/assets/javascripts/` uses a consistent, modern style (`const`/`let`, no accidental globals, clear structure) while remaining compatible with Sprockets, jQuery, and Babel — **Validated in Phases 3–4** (style + verification)
- [x] A documented baseline for JS style (lint and/or project conventions) is enforced or checkable for future changes — **Validated in Phase 2** (ESLint/Prettier, `yarn run lint`, README + `package.json`); **conventions in** `.planning/codebase/CONVENTIONS.md` **Phase 3–4 (DOCS-01)**
- [x] No regressions in existing behaviour; automated tests and manual smoke paths pass — **Phase 4**

### Active (v1.2)

- [ ] New `modern` theme selectable via preferences (theme string stored in DB, no migration needed)
- [ ] Hamburger button in modern theme header opens a side drawer with all nav links
- [ ] Full-page modern styling: header, body typography, tables, action buttons, forms

### Out of Scope (carried from v1.1; revisit when planning)

- Introducing a new frontend framework, npm-heavy bundler migration, or replacing the asset pipeline — defer unless explicitly opened in a later milestone
- Large UX redesigns unrelated to code style
- TypeScript conversion — not required for v1.1 (may be revisited later)

## Context

- Stack and architecture: see `.planning/codebase/STACK.md` and `ARCHITECTURE.md`
- JavaScript (post–v1.1): first-party `app/assets/javascripts/` follows ESLint + `CONVENTIONS.md`; Sprockets + Babel + jQuery 4 + Rails UJS unchanged
- **Shipped v1.1 (2026-04-27):** tooling baseline, script modernization (Phases 2–3), full test + smoke verification (Phase 4). Details: `.planning/MILESTONES.md`, `.planning/milestones/v1.1-ROADMAP.md`

## Constraints

- **Stack**: Sprockets + jQuery + existing gem pipeline — new JS must not break asset compilation or production minification
- **Browsers**: Target environments implied by Babel `preset-env` and project policy; avoid syntax that the pipeline does not transpile
- **Compatibility**: Preserve behaviour of `.js.erb` and controller-driven JS responses where used

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|--------|
| Keep Sprockets for v1.1 | Minimize risk; style modernization is the goal, not a framework migration | **Shipped v1.1** — asset pipeline unchanged; bundler/SPA still out of scope until a later milestone opens them |

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

## Shipped

### v1.1 — Modern JavaScript (2026-04-27)

**Goal achieved:** In-repo JavaScript is maintainable and lint-consistent without replacing Sprockets or jQuery.

**Delivered:** ESLint/Prettier + docs; `app/assets/javascripts/` refactor; Minitest, Cucumber, and D-04 smoke; `CONVENTIONS.md` JS section.

---
*Last updated: 2026-04-28 — v1.2 Modern Theme milestone started*
