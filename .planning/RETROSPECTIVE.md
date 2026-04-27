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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases (this file) | Key Change |
|-----------|--------------------|------------|
| v1.1 | 3 (numbered 2–4) | First full GSD milestone with roadmap + requirements + archive close-out |

### Cumulative quality

| Milestone | Automated tests | Notes |
|-----------|-----------------|--------|
| v1.1 | Minitest + Cucumber green at close | Manual D-04 smoke for JS-touching flows |

### Top lessons (to verify in v1.2+)

1. Keep SUMMARY one-liners meaningful for `milestone complete` and historiography.
2. Decide explicitly whether to archive phase dirs to `milestones/v*-phases/` (skipped this round; `/gsd-cleanup` remains available).
