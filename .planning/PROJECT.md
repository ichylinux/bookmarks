# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## Requirements

### Validated

- [ ] User authentication and per-user data isolation (Devise, existing app behaviour)
- [ ] Bookmarks, feeds, todos, and portal-related features work in production as currently shipped

### Active (milestone v1.1)

- [ ] In-repo browser JavaScript under `app/assets/javascripts/` uses a consistent, modern style (const/let, no accidental globals, clear structure) while remaining compatible with Sprockets, jQuery, and the existing Babel setup
- [ ] A documented baseline for JS style (lint and/or project conventions) is enforced or checkable for future changes
- [ ] No regressions in existing behaviour; automated tests and manual smoke paths still pass

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
| Keep Sprockets for v1.1 | Minimize risk; style modernization is the goal, not a framework migration | — Pending |

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

## Current Milestone: v1.1 Modern JavaScript

**Goal:** Bring in-repository JavaScript up to a maintainable, modern style without changing the overall Rails + Sprockets + jQuery architecture.

**Target features:**
- Adopt and apply a practical modern baseline (e.g. `const`/`let`, arrow functions where they improve clarity, avoid leaking globals, consistent formatting)
- Add or wire tooling so style is **repeatable** (ESLint and/or Prettier, aligned with Babel and Sprockets constraints)
- Verify behaviour: existing tests pass; critical flows (bookmarks, feeds, gadgets) manually smoke-tested
- Update `.planning/codebase/CONVENTIONS.md` (or equivalent) for JavaScript so future work matches the new baseline

---
*Last updated: 2026-04-27 after milestone v1.1 (Modern JavaScript) start*
