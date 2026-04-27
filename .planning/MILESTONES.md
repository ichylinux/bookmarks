# Milestones

## v1.1 — Modern JavaScript (shipped 2026-04-27)

**Scope:** Phases 2–4 (6 plans, 8 tasks) — lint/style baseline, Sprockets JS modernization, verification and `CONVENTIONS.md`.

**Key accomplishments:**

- ESLint 9 flat config and Prettier on `app/assets/javascripts/` with `yarn run lint` clean in CI and locally.
- Contributor docs: `yarn install` / `yarn run lint` in README; `CONVENTIONS.md` JavaScript section; production asset precompile still succeeds.
- `app/assets/javascripts/` modernized: `const`/`let`, jQuery `this`-safe handlers, no leaked globals; critical fixes (e.g. `$.delegate` → `.on()`) where needed.
- Regression gate: Minitest and Cucumber green; D-04 manual smoke (5/5) for JS-touched flows; **VERI-01–03**, **DOCS-01** closed.

**Archives:** [ROADMAP snapshot](milestones/v1.1-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.1-REQUIREMENTS.md) · [Milestone audit](milestones/v1.1-MILESTONE-AUDIT.md)

---

## v1.0 — Foundation

Pre–GSD planning work on this repo:

- **Automatic title scrape** — `GET /bookmarks/fetch_title` with jQuery blur handler; see git history in `.planning/phases/` if present.

---
*Last updated: 2026-04-27 — v1.1 complete-milestone close-out*
