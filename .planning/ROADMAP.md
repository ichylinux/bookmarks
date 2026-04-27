# Roadmap: Bookmarks

## Overview

Milestone **v1.1 — Modern JavaScript** delivers a repeatable lint/style baseline, refactors in-repo Sprockets JavaScript to modern patterns (`const`/`let`, clear handlers, no accidental globals), and closes with full verification and updated conventions—without replacing Sprockets or jQuery.

**Phase numbering:** Continues from the previous work (local phase 1, automatic title scrape). This milestone runs **Phases 2–4**.

## Phases

- [x] **Phase 2: JavaScript tooling baseline** — ESLint/Prettier (or documented equivalent), npm scripts, repo rules compatible with Sprockets + Babel
- [x] **Phase 3: Modernize application scripts** — Apply style rules across `app/assets/javascripts/`, preserve behaviour and jQuery semantics (completed 2026-04-27)
- [x] **Phase 4: Verify and document** — Tests, smoke checks, and CONVENTIONS update for JavaScript (completed 2026-04-27)

## Phase Details

### Phase 2: JavaScript tooling baseline
**Goal:** Contributors can run the same static checks; rules match how assets are built today.

**Depends on:** Nothing in this milestone (first phase of v1.1; prior phase 1 shipped outside this file)

**Requirements:** TOOL-01, TOOL-02

**Success criteria** (what must be TRUE):

1. Running the documented lint (or check) command reports no violations in the current codebase **or** only documented auto-fixable issues that the phase resolves before completion.
2. A new contributor can read `package.json` or project docs and know exactly how to run the JS style checks.
3. Asset pipeline and Babel config remain valid: `RAILS_ENV=production` asset precompile (or the project's standard compile check) succeeds after tool addition.

**Plans:** TBD (refined in `/gsd-plan-phase 2`)

Plans:

- [x] 02-01: TBD
- [x] 02-02: TBD

---

### Phase 3: Modernize application scripts
**Goal:** All first-party `app/assets/javascripts/` code matches the new baseline; behaviour unchanged.

**Depends on:** Phase 2

**Requirements:** STYL-01, STYL-02, STYL-03, STYL-04

**Success criteria** (what must be TRUE):

1. No `var` in first-party app scripts except documented exceptions; `const`/`let` used consistently.
2. Callbacks and handlers follow the project's documented rule for arrow functions vs. `function` with respect to jQuery `this`.
3. Global/window namespace usage is explicit and limited—no new leaked globals; existing patterns (e.g. `bookmarks` object) are either kept working or refactored safely.
4. UJS, `.js.erb` flows, and jQuery `$(document).ready` (or agreed lifecycle hooks) still behave as before in manual checks.

**Plans:** 2/2 plans complete

Plans:

- [x] 03-01: TBD
- [x] 03-02: TBD

---

### Phase 4: Verify and document
**Goal:** Proving no regressions and locking conventions for the future.

**Depends on:** Phase 3

**Requirements:** VERI-01, VERI-02, VERI-03, DOCS-01

**Success criteria** (what must be TRUE):

1. Minitest and Cucumber (and any other required suites) are green; no new failures from JS changes.
2. A short smoke list for bookmark, feed, todo, and gadget UIs (where JS is involved) is executed and recorded (checkbox in plan or UAT note).
3. No regression reported for forms, UJS, or JS-driven responses for touched areas.
4. `CONVENTIONS.md` (or linked doc) includes a JavaScript section aligned with the linter and the patterns used in code.

**Plans:** 2 plans

Plans:

- [x] 04-01-PLAN.md — Run lint, Minitest, and Cucumber; document pre-existing failures; confirm no JS-attributable regressions (VERI-01, VERI-03)
- [x] 04-02-PLAN.md — Execute D-04 smoke checklist for JS-touched flows; review and confirm CONVENTIONS.md JavaScript section (VERI-02, DOCS-01)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 2. JavaScript tooling | v1.1 | 2/2 | Complete | 2026-04-27 |
| 3. Modernize scripts | v1.1 | 2/2 | Complete    | 2026-04-27 |
| 4. Verify and document | v1.1 | 2/2 | Complete | 2026-04-27 |

---
*Created: 2026-04-27 — milestone v1.1*  
*Last updated: 2026-04-27 — milestone v1.1 complete (Phase 4 done)*
