# Project Retrospective

*Living document updated at milestone boundaries.*

## Milestone: v1.1 — Modern JavaScript

**Shipped:** 2026-04-27  
**Phases:** 3 (2–4) | **Plans:** 6 | **Tasks:** 8 (per milestone close)

### What Was Built

- ESLint 9 + Prettier wired to Sprockets-served JS with a single `yarn run lint` entry point.
- First-party `app/assets/javascripts/` brought to `const`/`let`, explicit globals, and jQuery-`this`-safe patterns; legacy APIs (e.g. `$.delegate`) fixed where they broke under modern jQuery.
- Regression evidence: Minitest, Cucumber (`dad:test`), and a recorded D-04 manual smoke list.
- `CONVENTIONS.md` JavaScript section aligned with the linter and project rules (**DOCS-01**).

### What Worked

- **Small phases:** Tooling → edit → verify limited blast radius and kept verification traceable to roadmap requirements.
- **Audit before close:** `v1.1-MILESTONE-AUDIT.md` with **passed** status gave confidence to archive without re-litigating scope.

### What Was Inefficient

- Some `SUMMARY.md` files had thin `one_liner` fields, so automated accomplishment extraction produced noise until hand-edited in `MILESTONES.md`.
- Nyquist/VALIDATION flags on phases are **partial** by design (manual smoke); expect ongoing explanation for strict-automation expectations.

### Patterns Established

- **Lint-first, ship-second:** no Phase 3 mass edit without a green baseline from Phase 2.
- **Document the command surface:** README + `package.json` for lint is part of the definition of done, not an afterthought.

### Key Lessons

1. **Retroactive verification docs** (e.g. Phase 3 `VERIFICATION.md`) are acceptable for audit but cost time; prefer creating VERIFICATION with the phase in future.
2. **3-source traceability** (REQUIREMENTS + VERIFICATION + SUMMARY) catches gaps early; keep REQ IDs stable across phases.

### Cost Observations

- Not tracked in-repo for this milestone — add session/model metrics in a future close-out if product governance requires them.

---

## Milestone: v1.3 — Quick Note Gadget

**Shipped:** 2026-04-30
**Phases:** 4 (10–13) | **Plans:** 10

### What Was Built

- `notes` table migration, `Note` model with `Crud::ByUser`, soft-delete override, `scope :recent`, and `validates :body presence/length`.
- `NotesController#create`: authenticated POST, server-side `user_id` merge, redirect to `root_path(tab: 'notes')`.
- Simple-theme tab strip (ホーム/ノート) with ERB gate + jQuery switching (`notes_tabs.js`) + `?tab=notes` SSR state — invisible on other themes.
- `_note_gadget.html.erb`: textarea + Save, empty-state "メモはまだありません", reverse-chrono note list with timestamps.
- `WelcomeControllerTest` gadget + isolation coverage; Cucumber `features/04.ノート.feature` Japanese E2E.
- `drawer_ui?` helper gating hamburger + drawer in layout; extended `layout_structure_test.rb`.
- Human UAT 5/5 passed.

### What Worked

- **Zero new dependencies:** entire feature on existing stack — no bundler churn, no new abstractions.
- **Plan 01 → N execution:** splitting data layer, controller, tab UI, and gadget into focused phases kept each step verifiable in isolation.
- **Cucumber feature as living spec:** `04.ノート.feature` in Japanese matches the product intent; HEADLESS=true makes it runnable in CI without a display.
- **Quick-task workflow for small fixes:** `notes_tabs.js` modernization and tab label rename were handled as quick tasks without polluting phase scope.

### What Was Inefficient

- **Milestone audit run too early:** `v1.3-MILESTONE-AUDIT.md` was generated before phases 12–13 were built, producing a stale `gaps_found` report. Audit should run after all phases complete.
- **Phase 10 missing `VERIFICATION.md`:** model tests and UAT passed but were never promoted to VERIFICATION format, leaving a Nyquist gap. The pattern is now clear: create VERIFICATION with the phase, not retroactively.
- **Rails 8.1 `delete_all` gotcha:** cost debug time in Phase 13 tests; now documented in STATE.md and memory.

### Patterns Established

- **Server-side ownership merge:** `permit(:body).merge(user_id: current_user.id)` — never accept `user_id` from the client.
- **Theme isolation two-gate:** ERB `favorite_theme == 'simple'` guard AND CSS `.simple { }` scope required together; one alone leaks.
- **Query-param tab state:** `root_path(tab: 'notes')` redirect + `URLSearchParams` read on DOM ready survives POST/redirect cycle cleanly.
- **`drawer_ui?` helper:** explicit boolean from `WelcomeHelper` is cleaner than `favorite_theme != 'simple'` inline — a reusable pattern for future theme-conditional layout blocks.

### Key Lessons

1. **`delete_all` on a NOT NULL FK in Rails 8.1 issues a nullifying UPDATE, not a DELETE.** Use `Note.where(user_id: user.id).delete_all` in tests.
2. **Milestone audit timing matters.** Run `/gsd-audit-milestone` only after all phases are complete — an early audit can look alarming when later phases are simply unbuilt.
3. **Single-day sprints are feasible for scoped gadgets.** Phases 10–13 (10 plans) shipped on one calendar date by keeping scope narrow and the stack unchanged.

### Cost Observations

- Not tracked in-repo for this milestone.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Key Change |
|-----------|--------|------------|
| v1.1 | 3 (2–4) | First full GSD milestone with roadmap + requirements + archive close-out |
| v1.2 | 5 (5–9) | Added UI-SPEC, drawer JS interaction, full-page CSS polish; first multi-plan theme phase |
| v1.3 | 4 (10–13) | First data-layer → controller → UI → tests pipeline; Cucumber E2E; zero-dep constraint held |

### Cumulative quality

| Milestone | Automated tests | Notes |
|-----------|-----------------|--------|
| v1.1 | Minitest + Cucumber green at close | Manual D-04 smoke for JS-touching flows |
| v1.2 | Minitest + SCSS contract tests | Human UAT 5/5; drawer reduced-motion manual |
| v1.3 | Minitest + Cucumber HEADLESS green | Human UAT 5/5; Phase 10 VERIFICATION skipped |

### Top lessons (carry forward)

1. Keep SUMMARY one-liners meaningful for `milestone complete` and historiography.
2. Phase dirs not archived to `milestones/v*-phases/` — `/gsd-cleanup` available for retroactive archival.
3. Run `/gsd-audit-milestone` only after **all** phases complete; early audits produce misleading `gaps_found` reports.
4. Create `VERIFICATION.md` with the phase, not retroactively — saves Nyquist remediation work at close.
