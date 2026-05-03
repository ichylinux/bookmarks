# Milestones

## v1.5 — Verification Debt Cleanup (shipped 2026-05-04)

**Scope:** Phases 19–22 (7 plans) — shared verification rubric (Phase 19), Phase 05 closure (Phase 20), Phase 06 closure (Phase 21), Phase 09 closure + milestone sync (Phase 22).

**Key accomplishments:**

- Phase 19: Shared verification rubric (`19-VERIFICATION-RUBRIC.md`) defining baseline tri-suite runs, hybrid claim table + per-claim evidence blocks, fail-first / minimal-fix / one-rerun policy. Closes VERF-01, VERF-02.
- Phase 20: `05-VERIFICATION.md` closure-ready with `P05-C01..C03` PASS for THEME-01/02/03, including THEME-03 drawer-contract alignment (modern + classic, simple excluded by `drawer_ui?`). Closes P05V-01, P05V-02.
- Phase 21: `06-VERIFICATION.md` closure-ready with `P06-C01..C03` PASS for NAV-01/02 plus non-modern (classic + simple) unaffected contract per Phase 6 success criterion 4. Modern + classic + simple interaction evidence captured. Closes P06V-01, P06V-02.
- Phase 22: `09-VERIFICATION.md` closure-ready with `P09-C01..C04` PASS for STYLE-01..04, anchored to `modern_full_page_theme_contract_test.rb` selectors (`.modern #header .head-box`, `font-size: 16px` + `-apple-system`, `.modern table` + `nth-child`, `.modern .actions` + `input[type="`). STYLE-05 explicitly out of scope. Closes P09V-01, P09V-02.
- Cross-document milestone sync (`ROADMAP.md`, `STATE.md`, `MILESTONES.md`, `PROJECT.md`) consistently reflects v1.5 closure. Closes MSYN-01.
- Tri-suite gate (lint + Minitest + Cucumber with one-rerun policy) green at v1.5 closure commit.

**Archives:** [ROADMAP snapshot](milestones/v1.5-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.5-REQUIREMENTS.md)

---

## v1.4 Internationalization (Shipped: 2026-05-03)

**Phases completed:** 7 phases, 19 plans, 32 tasks

**Key accomplishments:**

- Plan 15-02 の補修
- Shared shell and flash translation catalog with ja/en parity enforcement and rails-i18n validation-default verification
- Layout, simple-theme menu, and note fallback alert now consume the shared Phase 16 translation catalog
- Chrome and shared-flash translation behavior is now covered by ja/en integration tests, with the full Phase 16 verification gate green
- Rails I18n locale skeleton and model-level translation primitives for downstream feature surface rewrites
- Bookmark screens now render fixed UI chrome through ja/en locale keys while preserving bookmark and folder records as user content
- Note and Todo surfaces now render fixed UI chrome in Japanese or English while preserving note bodies, Todo titles, and numeric priority values
- Feed and calendar surfaces now render fixed UI chrome in Japanese or English, with feed JavaScript messages supplied by server-rendered translated attributes
- Phase 17 feature-surface translation is covered by representative ja/en assertions and a green lint, Minitest, and Cucumber gate
- Localized failed sign-in alerts now render through the shared Rails layout in both Japanese and English
- Auth and 2FA pages now have integration coverage proving Japanese and English rendering paths
- Phase 18 passed the full local gate and the remaining translation audit was approved
- Pending 2FA OTP pages now honor saved account locale before OTP completion

---

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
*Last updated: 2026-05-04 — v1.5 verification debt cleanup close-out*
