# Milestones

## v1.2 — Modern Theme (shipped 2026-04-29)

**Scope:** Phases 5–9 (7 plans) — theme infrastructure, hamburger drawer navigation, full-page CSS polish. 14 source files changed, 589 lines added.

**Key accomplishments:**

- Modern theme selectable from `/preferences` — activates `body.modern` class with CSS custom property tokens; non-modern themes fully unaffected.
- `menu.js` jQuery stub with `body.modern` guard — zero side effects until the class is present.
- Hamburger button + drawer/overlay rendered unconditionally in layout; CSS hides them under non-modern themes.
- Drawer slides and fades via CSS alone (`transform: translateX`, backdrop `opacity`) with WCAG `prefers-reduced-motion` support.
- Drawer fully interactive via `menu.js`: hamburger toggle, backdrop click, Esc key, nav link click — coexists with legacy email dropdown.
- Full-page visual polish: blue header bar (replaces `#AAA`), 16px system font stack, padded tables with zebra/hover, tokenized action buttons and form controls. CI-guarded by two Minitest SCSS contract tests.

**Archives:** [ROADMAP snapshot](milestones/v1.2-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.2-REQUIREMENTS.md)

---

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
*Last updated: 2026-04-29 — v1.2 complete-milestone close-out*
