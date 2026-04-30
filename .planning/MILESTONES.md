# Milestones

## v1.3 — Quick Note Gadget (shipped 2026-04-30)

**Scope:** Phases 10–13 (10 plans) — data layer, notes controller, simple-theme tab UI, note gadget, Cucumber E2E, and drawer-gating helper. 14 files changed, 287 insertions.

**Key accomplishments:**

- `notes` table migration with composite `(user_id, created_at)` index; `Note` model with `Crud::ByUser`, soft-delete `destroy` override, `validates :body presence/length`, and `scope :recent`.
- `NotesController#create` — authenticated POST, `user_id` merged server-side from `current_user`, redirects to `root_path(tab: 'notes')`; integration tests cover auth, scoping, validation failure, and redirect.
- Simple-theme tab strip (ホーム/ノート) with jQuery switching (`notes_tabs.js`), SSR-driven initial state from `?tab=notes`, and all styles scoped under `.simple { }` — invisible on modern and classic themes.
- `_note_gadget.html.erb` partial: textarea + Save button, empty-state message ("メモはまだありません"), and reverse-chronological note list with escaped bodies and readable timestamps.
- `WelcomeControllerTest` extended with structure, empty-state, ordering/timestamp, and cross-user isolation coverage; 22 runs, 110 assertions, 0 failures.
- Cucumber `features/04.ノート.feature` — Japanese E2E: simple-theme activate → textarea fill → save → redirect to `?tab=notes` → list assert.
- `drawer_ui?` WelcomeHelper method gates hamburger + drawer blocks in layout; `layout_structure_test.rb` extended with classic drawer presence and simple-theme absence assertions.
- Human UAT 5/5 passed (2026-04-30).

**Archives:** [ROADMAP snapshot](milestones/v1.3-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.3-REQUIREMENTS.md)

---

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
