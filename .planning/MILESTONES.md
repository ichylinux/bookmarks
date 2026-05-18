# Milestones

## v1.26 — Visited Link Tracking (shipped 2026-05-18)

**Scope:** Phases 84–88 (5 phases, 8 plans, 6 tasks) — server-side visited URLs, gadget wiring, delegated JS handler, planning traceability closure.

Known deferred items at close: 3 (see STATE.md under **Deferred Items** — quick-task scanner false positives).

**Key accomplishments:**

- MySQL `visited_links` migration (utf8mb4 prefix index url(767)) and `VisitedLink` model with atomic upsert idempotency, fragment-stripping normalization, and Set-returning `urls_for`.
- Minimal `VisitedLinksController#create` returning 204, routed via `resources :visited_links, only: [:create]`; Cucumber `VisitedLink.delete_all` isolation; integration tests for auth, idempotency, normalization.
- `.gadget a.link--visited` in `common.css.scss` and `ApplicationHelper#visited_link_class` with contract + unit tests.
- Nil-guarded helper + `assign_visited_urls` on three gadget controllers + partial wiring; controller tests for visited class and N+1 absence.
- `visited_links.js` delegated click handler (fragment strip, optimistic class, fire-and-forget POST); `VisitedLinksJsContractTest`; Cucumber `@feed_visited_links` E2E.
- Phase 88: REQUIREMENTS / ROADMAP / SUMMARY `requirements_completed` alignment + planning contract test for closure traceability.

**Tri-suite gate at close:** `yarn run lint` ✓ · 458 Minitest 0 failures · Cucumber 27/27 (`dad:test`, per milestone audit).

**Archives:** [ROADMAP snapshot](milestones/v1.26-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.26-REQUIREMENTS.md) · [Audit](milestones/v1.26-MILESTONE-AUDIT.md)

---

## v1.25 — Portal Column Width Ratios (shipped 2026-05-18)

**Scope:** Phases 80–83 (4 phases, 4 plans) — `portal_column_widths` JSON persistence, linked ratio sliders, desktop CSS variable layout.

**Key accomplishments:**

- Added `portal_column_widths` JSON column on `preferences`; model validates sum=100, length=`portal_column_count`, positive integers; `normalize_portal_column_widths_length` before_validation normalizes length mismatch to equal split; equal defaults: 3-col `[34,33,33]`, 4-col `[25,25,25,25]`.
- Preferences page renders one linked range slider per column via `_portal_column_widths` partial + `<template>` row; `portal_column_width_sliders.js` IIFE handles redistribute-on-drag and rebuilds slider rows on column-count change.
- Desktop portal columns render at saved ratios via `--portal-col-width-pct` inline CSS variable on each `.portal-column`; mobile tab strip layout unchanged.
- Minitest: 9 model validation tests, controller save/reload round-trip, desktop markup structure tests for unequal 3- and 4-column cases; locale key parity test for new `portal_column_width*` strings.
- Tri-suite gate at close: `yarn run lint` ✓ · 416 Minitest 0 failures · 25 Cucumber 0 failed (first run; documented order flake on rerun).
- Post-ship fix (quick task 20260518): `<template>` element placed outside root div in ERB partial — moved inside root so `rebuildControls` finds it on column-count dropdown change.

**Archives:** [ROADMAP snapshot](milestones/v1.25-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.25-REQUIREMENTS.md)

---

## v1.24 — Mobile Column Lazy Loading (shipped 2026-05-17)

**Scope:** Phases 76–79 (4 phases, 4 plans) — `portal_lazy.js` coordinator, gadget partial wiring, contract tests, note gadget AJAX extraction.

**Key accomplishments:**

- Created parse-time `window.portalLazy` IIFE coordinator with `register(columnIndex, loadFn)` + `loadColumn(index)` API — guarantees ordering before any gadget ready-handler fires; desktop pass-through; mobile queue-and-drain.
- Wired all 4 AJAX gadget partials (`_feed`, `_mastodon_account`, `_x_account`, `_calendar_gadget`) to `portalLazy.register` with `column_index` propagated from `_portal_column_section.html.erb`; `activateColumn` extended to call `portalLazy.loadColumn(index)` in all three activation paths (tab click, swipe, localStorage restore).
- Fixed critical PTM-fires-first race: `register()` now checks `loadedColumns[columnIndex]` before push — without this fix, all gadget registers hit the already-loaded no-op path.
- Added 9 Minitest contract tests for `portal_lazy.js` API; `activateColumn`→`portalLazy.loadColumn` integration assertion; existing `@mobile_portal` Cucumber scenarios confirmed passing (25/25).
- Extracted note gadget from SSR: `NotesController#gadget` at `GET /notes/gadget` (authenticated, `layout: false`); `WelcomeController#index` no longer assigns `@note`/`@notes`; loading placeholder + AJAX injection for all themes; `noteGadgetLoaded` event re-initializes handlers via `initNoteGadget()` factory.
- Tri-suite gate at final close: `yarn run lint` ✓ · 407 Minitest 0 failures · 25 Cucumber 0 failed.

**Archives:** [ROADMAP snapshot](milestones/v1.24-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.24-REQUIREMENTS.md) · [Audit](milestones/v1.24-MILESTONE-AUDIT.md) (tech_debt: 14/15 requirements, TEST-02 behavioral Cucumber scenario deferred)

---

## v1.23 — Icon Display Preference (shipped 2026-05-17)

**Scope:** Phases 73–75 (3 phases, 5 plans) — boolean `show_icons` preference, CSS icon suppression, preferences UI toggle.

**Key accomplishments:**

- Added `show_icons boolean NOT NULL DEFAULT true` to `preferences` table; DB default backfills existing rows with no separate migration needed.
- `Preference` model validates `show_icons` via `inclusion: { in: [true, false] }`; `SHOW_ICONS_DEFAULT` constant; `default_preference` sets it explicitly.
- `WelcomeHelper#no_icons_class` emits `body.no-icons` when preference off; guards unauthenticated requests; wired into layout `<body>` class alongside theme and font-size.
- CSS rules in `common.css.scss` suppress `.gadget-title-icon` and `.drawer-nav-icon` under `body.no-icons` with `!important` to override theme-scoped specificity; covers all authenticated pages via shared partial.
- Preferences UI checkbox with ja: 「アイコンを表示する」 / en: "Show Icons"; i18n parity test; save round-trip Minitest; `body.no-icons` dashboard integration test.
- Tri-suite gate: `yarn run lint` ✓ · 389 Minitest ✓ · 25 Cucumber ✓

**Archives:** [ROADMAP snapshot](milestones/v1.23-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.23-REQUIREMENTS.md) · [Audit](milestones/v1.23-MILESTONE-AUDIT.md)

---

## v1.22 — Landing at Root (shipped 2026-05-17)

**Scope:** Phases 70–72 (3 phases, 3 plans) — inline landing for guests, `/landing` route removal, Twitter uid lookup fix.

**Key accomplishments:**

- Unauthenticated `/` now renders landing content inline via `WelcomeController#index` guest branch — no HTTP redirect to `/landing`.
- `/landing` route, `LandingController`, and `redirect_guest_to_landing` before_action removed entirely from the app.
- `User.from_omniauth` Twitter branch switched from `name` to `uid` lookup — fixes deferred XAUTH-FUT-01 bug from v1.18.
- All test contracts updated: redirect assertions replaced with 200 + inline content assertions; regression coverage added for both auth states at `/`.
- Tri-suite gate: `yarn run lint` ✓ · 384 Minitest ✓ · 25 Cucumber ✓

**Archives:** [ROADMAP snapshot](milestones/v1.22-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.22-REQUIREMENTS.md)

---

## v1.21 — X Gadget Tweet Count Preference (shipped 2026-05-16)

**Scope:** Phase 69 — per-account tweet display count UI, persistence, and tests.

**Key accomplishments:**

- Added `display_count` number input to each X account card on `/x_accounts`; value bound to persisted `x_accounts.display_count` (DB-default 5).
- Permitted `:display_count` in `x_account_params` strong params, enabling PATCH persistence.
- Fixed `XClient#fetch_recent_tweets`: requests `max(limit, 5)` from X API (API minimum constraint), then slices result to user's exact preference — resolves API error for display_count < 5.
- Controller test verifies PATCH persists changed display_count; model tests cover numericality validation + `set_display_count_default` callback.
- Tri-suite gate: `yarn run lint` ✓ · 382 Minitest ✓ · 25 Cucumber ✓

**Archives:** [ROADMAP snapshot](milestones/v1.21-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.21-REQUIREMENTS.md) · [Milestone audit](milestones/v1.21-MILESTONE-AUDIT.md)

---

## v1.20 Column Count Preference (Shipped: 2026-05-15)

**Phases completed:** 2 phases, 4 plans, 2 tasks

**Key accomplishments:**

- One-liner:
- Added `test_デフォルトのポータル列数は3` to preference_test.rb to assert DB default value of 3, completing all plan 02 must_haves against Wave 1's pre-built portal and preference tests.
- Task 1 — Strong params + locale files:
- Task 1 — Minitest layout tests (welcome_controller/layout_structure_test.rb):

---

## v1.20 — Column Count Preference (active 2026-05-15)

**Scope:** Phases 67–68 — `preferences.portal_column_count` migration; `Preference` validation; `Portal#portal_columns` driven by preference; downgrade safety (skip `column_no >= column_count`, redistribute); preferences select control + ja/en locale; welcome-page 4-column layout; SCSS for 4th column across themes; Minitest + tri-suite gate.

**Status:** Roadmap created. Phase 67 (Data + Model Layer) next.

---

## v1.19 — HTTP test stubs → WebMock (shipped 2026-05-14)

**Scope:** Phases 64–66 — add WebMock to `:test`; migrate Minitest + Cucumber off `test/http_client_test_stubs.rb` prepend accessors; delete stub loader from `config/environments/test.rb`; document new contract in PROJECT / CLAUDE; tri-suite gate.

**Key accomplishments:**

- WebMock added to `:test` group; `WebMock.disable_net_connect!` configured globally in `test/test_helper.rb` and Cucumber `env.rb`.
- All Minitest HTTP stubs migrated to WebMock (`stub_request`) and Faraday `:test` adapter; `XClient#fetch_recent_tweets` uses WebMock directly (bypasses Faraday connection injection).
- `test/http_client_test_stubs.rb` deleted; `config/environments/test.rb` stub loader removed.
- Tri-suite gate at close: `yarn run lint` — green; `bin/rails test` — 363 runs, 0 failures; `bundle exec rake dad:test` — 24 scenarios, 0 failed.

**Audit:** [Milestone audit](milestones/v1.19-MILESTONE-AUDIT.md) — `tech_debt`; 5/5 requirements satisfied; 0 integration blockers. Process debt: Phases 65–66 inline (no per-phase GSD artifacts); Phase 64 VALIDATION.md draft state; HTTP-FUT-01 deferred.

**Archives:** [ROADMAP snapshot](milestones/v1.19-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.19-REQUIREMENTS.md) · [Milestone audit](milestones/v1.19-MILESTONE-AUDIT.md)

---

## v1.18 — X (Twitter) Account Following (shipped 2026-05-14)

**Scope:** Phases 60–63 — OAuth 1.0a token persistence on `users`, `XClient` Faraday service, `x_accounts` cache table + management UI, welcome-page AJAX gadgets, ja/en localization, Minitest + Cucumber tri-suite gate.

**Key accomplishments:**

- OAuth 1.0a credentials (`uid`/`token`/`token_secret`) persisted on Twitter sign-in and encrypted at rest; `require_twitter_linked` gate on `uid + token` (not `name`) applied to all X surfaces.
- `XClient` service with `fetch_following` / `fetch_recent_tweets`, 7-symbol error contract, t.co URL expansion before truncation, following pagination, and class-level stub accessors mirroring MastodonClient pattern.
- `/x_accounts` management page: diff-upsert refresh (all-soft-delete semantics — intentional safer deviation), per-row gadget selection capped at 12 (warn at 9), 🔒 protected-account confirmation toggle, last-refreshed timestamp, ja/en.
- Selected X accounts render as individual AJAX-loaded welcome gadgets via `Portal#get_gadgets`; tweet text never `html_safe`; click-through URLs constructed server-side; `:unauthorized` error state includes re-sign-in CTA.
- Full ja/en coverage (`x_accounts.*`, `welcome.x_account.*`, `errors.x_client.*`) enforced by parity test; `features/06.X.feature` with `@x_gadget` Before/After hooks + global state-isolation Before hook.
- Tri-suite gate green at close: `yarn run lint`, `bin/rails test` (364/364), `bundle exec rake dad:test` (24 scenarios).

**Audit:** [Milestone audit](milestones/v1.18-MILESTONE-AUDIT.md) — `tech_debt`; 31/31 requirements satisfied; no requirement/integration/flow gaps. Tech debt: no per-phase GSD artifact files (accepted pattern, same as v1.16/v1.17); XACCT-06 intentional all-soft-delete deviation; XAUTH-FUT-01 deferred to v1.19+.

**Archives:** [ROADMAP snapshot](milestones/v1.18-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.18-REQUIREMENTS.md) · [Milestone audit](milestones/v1.18-MILESTONE-AUDIT.md)

---

## v1.17 — Email Registration for X/Twitter Users (shipped 2026-05-13)

**Scope:** Phases 57–59 — `User` dummy-pattern email validator `on: :update`; `Users::EmailRegistrationsController` with dummy-only guard, collision handling, and `RecordNotUnique` rescue; preferences entry row; ja/en locales + i18n parity test; Minitest across model, controller, and preferences.

**Key accomplishments:**

- Dummy-email Twitter users can submit a real address via `users/email_registration` without affecting `from_omniauth` create path.
- Security: duplicate-email and unique-index race paths return user-visible errors; real-email users cannot open the registration form.
- Preferences surfaces a localized registration link only when `!has_valid_email?`; success flash localized (ja/en).
- Tri-suite gate at close: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (Cucumber second run per flake policy in `CLAUDE.md`).

**Audit:** [Milestone audit](milestones/v1.17-MILESTONE-AUDIT.md) — `passed`; documented process debt includes missing per-phase `*-SUMMARY.md` / Nyquist VALIDATION artifacts (evidence in `*-VERIFICATION.md` + tests + audit).

**Archives:** [ROADMAP snapshot](milestones/v1.17-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.17-REQUIREMENTS.md) · [Milestone audit](milestones/v1.17-MILESTONE-AUDIT.md)

---

## v1.16 — Mastodon Account Following (shipped 2026-05-12)

**Scope:** Phases 52–56 — `mastodon_accounts` data layer, CRUD UI (ja/en), `MastodonClient` + `show` with Faraday timeouts and HTML stripping, welcome-page AJAX gadgets (`Portal#get_gadgets`), Minitest + Cucumber (`@mastodon_gadget` stub).

**Key accomplishments:**

- `MastodonAccount` model with URL parsing (`before_validation`), soft-delete, and model tests.
- `/mastodon_accounts` CRUD, navigation links, locale coverage for forms and gadget chrome.
- `MastodonClient` two-step public API (lookup + statuses), ~100 char plain-text previews with links to source toots; graceful error rendering on `show`.
- Welcome dashboard gadgets load via jQuery XHR mirroring the RSS feed pattern; portal loop extended.
- Tri-suite gate at close: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (known flake rerun policy).

**Audit:** [Milestone audit](milestones/v1.16-MILESTONE-AUDIT.md) — `passed`; accepted process debt is missing Nyquist `*-VALIDATION.md` artifacts for Phases 52–56 (evidence in tests + audit narrative).

**Archives:** [ROADMAP snapshot](milestones/v1.16-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.16-REQUIREMENTS.md) · [Milestone audit](milestones/v1.16-MILESTONE-AUDIT.md) · [Phase archive](milestones/v1.16-phases/)

---

## v1.15 — CSS & UI Polish (shipped 2026-05-11)

**Scope:** Phases 49–51 (3 plans) — CSS architecture audit, cross-theme visual QA, mobile responsive layout, and PREFS-01 specificity regression fix.

**Key accomplishments:**

- CSS architecture audit confirmed 0 violations across all 9 non-theme SCSS files. ARCH-01/02/03 satisfied.
- Cross-theme visual QA complete: `.modern .actions a` blue-accent override added (CONS-02); preferences form verified across all 3 themes; flash messages and form controls confirmed consistent.
- Mobile responsive layout for preferences table (stacked rows) and bookmarks table (URL column hidden) at ≤767px in `common.css.scss`; all 3 themes inherit with no per-theme duplication. MOB-01/02 satisfied.
- PREFS-01 specificity regression resolved: `.preferences-table > tbody > tr > th` (0,1,3) beats `.modern table th` (0,1,2) without a theme-scoped override.
- 30 new regression-guard contract tests added. 298 total Minitest tests, 0 failures.

**Archives:** [ROADMAP snapshot](milestones/v1.15-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.15-REQUIREMENTS.md) · [Milestone audit](milestones/v1.15-MILESTONE-AUDIT.md)

---

## v1.14 — Landing Page Changelog (shipped 2026-05-10)

**Scope:** Phases 46–48 (3 plans) — changelog data layer, changelog section view, and verification gate.

**Key accomplishments:**

- Locale-YAML-backed `ApplicationHelper#changelog_entries` (no DB table); sorted by date, capped at 10.
- Changelog section rendered on `/landing` with VIEW-01–VIEW-04 Minitest coverage; tri-suite green.

**Archives:** [ROADMAP snapshot](milestones/v1.14-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.14-REQUIREMENTS.md)

---

## v1.13 — Root Entry Redirect to Landing for Guests (shipped 2026-05-08)

**Scope:** Phases 43–45 (3 plans) — guest root-entry redirect, conversion/locale guardrails, and verification hardening.

**Key accomplishments:**

- **Phase 43:** Updated root entry behavior so unauthenticated requests to `/` redirect to `/landing`, while authenticated users continue to receive existing dashboard behavior.
- **Phase 44:** Preserved landing conversion CTAs and locale-safe rendering contracts for ja/en under the new entry behavior.
- **Phase 45:** Expanded regression coverage for auth-state-aware entry routing and locale-aware landing contracts.
- Tri-suite gate green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`).

**Audit:** [Milestone audit](milestones/v1.13-MILESTONE-AUDIT.md) — `tech_debt`, no requirement/integration blockers; accepted debt is missing phase-level GSD artifact decomposition for 43–45 under manual orchestration.

**Archives:** [ROADMAP snapshot](milestones/v1.13-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.13-REQUIREMENTS.md) · [Milestone audit](milestones/v1.13-MILESTONE-AUDIT.md)

---

## v1.12 — Landing Page for User Acquisition (Phase 1) (shipped 2026-05-08)

**Scope:** Phases 40–42 (3 plans) — landing page delivery, conversion/auth-entry tone alignment, and regression hardening.

**Key accomplishments:**

- **Phase 40:** Added public `/landing` route + controller/view with acquisition-focused hero/value sections and localized ja/en copy.
- **Phase 41:** Unified CTA and auth-entry messaging tone across landing, sign-in, sign-up, and sign-in/out flash messages while preserving existing root behavior.
- **Phase 42:** Expanded controller-level regression coverage for landing route/render/CTA contracts and auth-copy paths.
- Tri-suite gate green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`).

**Audit:** [Milestone audit](milestones/v1.12-MILESTONE-AUDIT.md) — `passed`, no critical requirement/integration/flow gaps.

**Archives:** [ROADMAP snapshot](milestones/v1.12-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.12-REQUIREMENTS.md) · [Milestone audit](milestones/v1.12-MILESTONE-AUDIT.md) · [Phase archive](phases/040-landing-structure-and-messaging/) / [Phase archive](phases/041-conversion-cta-and-compatibility-guardrails/) / [Phase archive](phases/042-landing-verification-gate/)

---

## v1.11 — Device-aware Font Size Baseline (shipped 2026-05-06)

**Scope:** Phases 37–39 (3 plans) — device-aware typography baseline, legacy-user migration, and verification hardening.

**Key accomplishments:**

- **Phase 37:** Implemented body-authoritative font-size contract with desktop/mobile medium baselines (`14px`/`16px`) and relative small/large scaling (`0.875x`/`1.125x`).
- **Phase 38:** Added idempotent legacy migration (`font_size: nil|medium -> small`) and one-time in-app notice delivery for affected users.
- **Phase 39:** Expanded automated coverage for normalization, migration/notice behavior, and cross-theme readability contracts.
- Tri-suite gate green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` with known flake rerun policy).

**Audit:** [Milestone audit](milestones/v1.11-MILESTONE-AUDIT.md) — `passed`, no critical requirement/integration/flow gaps.

**Archives:** [ROADMAP snapshot](milestones/v1.11-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.11-REQUIREMENTS.md) · [Milestone audit](milestones/v1.11-MILESTONE-AUDIT.md) · [Phase archive](milestones/v1.11-phases/)

---

## v1.9 — Mobile Regression Hardening (shipped 2026-05-05)

**Scope:** Phases 33–33.2 (3 plans) — TEST-02 contract hardening, baseline traceability closure, and Cucumber scenario-state isolation.

**Key accomplishments:**

- **Phase 33:** Established explicit TEST-02 baseline hardening lane and linked fulfillment evidence to executed Phase 33.1 artifacts.
- **Phase 33.1:** Hardened JS/Minitest tab-click contracts in `portal_mobile_tabs.js` path (index resolution, container/portal resolution, shared `activateColumn(...)` call, UI/state sync assertions).
- **Phase 33.2:** Added centralized Cucumber `Before` hook in `features/support/hooks.rb` to reset session and shared preference defaults per scenario, reducing order-dependent `dad:test` flakiness.
- Tri-suite gate green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` first-run pass after 33.2).

**Audit:** [Milestone audit](milestones/v1.9-MILESTONE-AUDIT.md) — `tech_debt`, no critical requirement/integration/flow gaps; residual debt limited to ongoing verification-infrastructure hygiene.

**Archives:** [ROADMAP snapshot](milestones/v1.9-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.9-REQUIREMENTS.md) · [Milestone audit](milestones/v1.9-MILESTONE-AUDIT.md)

---

## v1.6 — Note Gadget for All Themes (shipped 2026-05-04)

**Scope:** Phases 23–25 — welcome/layout integration for modern and classic themes, `#notes-tab-panel` styling, ja/en verification tests, Cucumber modern-theme note capture.

**Key accomplishments:**

- **Phase 23:** Mutual exclusive Home vs Note panels on modern/classic via SSR + `welcome-tab-panel--hidden`; drawer Note link when `use_note`; `/?tab=notes` routing unchanged from simple-theme semantics.
- **Phase 24:** `#notes-tab-panel` SCSS aligned with modern and classic theme tokens; locale assertions for `_note_gadget` chrome on both themes (`nav.note` →「ノート」).
- **Phase 25:** `welcome_controller_test` + `layout_structure_test` coverage for panel visibility and drawer link; Cucumber scenario「モダンテーマでドロワーのノートリンクからメモを保存する」with disambiguated sign-in steps.
- Tri-suite gate (lint + Minitest + Cucumber with project flake rerun policy) green at milestone archive.

**Audit:** [Milestone audit](milestones/v1.6-MILESTONE-AUDIT.md) — `tech_debt`, no requirement gaps; accepted debt is absence of formal per-phase `.planning/phases/` VERIFICATION/Nyquist artifacts for Phases 23–25 (traceability via roadmap + archived REQUIREMENTS + tests).

**Known deferred items at close:** carry-forward v1.5 verification-wrapper/normalization tasks listed in `.planning/STATE.md` (not blocking v1.6).

**Archives:** [ROADMAP snapshot](milestones/v1.6-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.6-REQUIREMENTS.md) · [Milestone audit](milestones/v1.6-MILESTONE-AUDIT.md)

---

## v1.5 — Verification Debt Cleanup (shipped 2026-05-04)

**Scope:** Phases 19–22 (7 plans) — shared verification rubric (Phase 19), Phase 05 closure (Phase 20), Phase 06 closure (Phase 21), Phase 09 closure + milestone sync (Phase 22).

**Key accomplishments:**

- Phase 19: Shared verification rubric (`19-VERIFICATION-RUBRIC.md`) defining baseline tri-suite runs, hybrid claim table + per-claim evidence blocks, fail-first / minimal-fix / one-rerun policy. Closes VERF-01, VERF-02.
- Phase 20: `05-VERIFICATION.md` closure-ready with `P05-C01..C03` PASS for THEME-01/02/03, including THEME-03 drawer-contract alignment (modern + classic, simple excluded by `drawer_ui?`). Closes P05V-01, P05V-02.
- Phase 21: `06-VERIFICATION.md` closure-ready with `P06-C01..C03` PASS for NAV-01/02 plus non-modern (classic + simple) unaffected contract per Phase 6 success criterion 4. Modern + classic + simple interaction evidence captured. Closes P06V-01, P06V-02.
- Phase 22: `09-VERIFICATION.md` closure-ready with `P09-C01..C04` PASS for STYLE-01..04, anchored to `modern_full_page_theme_contract_test.rb` selectors (`.modern #header .head-box`, `font-size: 16px` + `-apple-system`, `.modern table` + `nth-child`, `.modern .actions` + `input[type="`). STYLE-05 explicitly out of scope. Closes P09V-01, P09V-02.
- Cross-document milestone sync (`ROADMAP.md`, `STATE.md`, `MILESTONES.md`, `PROJECT.md`) consistently reflects v1.5 closure. Closes MSYN-01.
- Tri-suite gate (lint + Minitest + Cucumber with one-rerun policy) green at v1.5 closure commit.

**Audit:** [Milestone audit](milestones/v1.5-MILESTONE-AUDIT.md) — `tech_debt`, no blockers; accepted follow-ups are Phase 19 verification wrapper normalization, rubric backlinks, stale requirements-path cleanup, and optional Nyquist validation artifacts.

**Archives:** [ROADMAP snapshot](milestones/v1.5-ROADMAP.md) · [REQUIREMENTS snapshot](milestones/v1.5-REQUIREMENTS.md) · [Milestone audit](milestones/v1.5-MILESTONE-AUDIT.md)

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

*Last updated: 2026-05-16 — v1.21 X Gadget Tweet Count Preference shipped (Phase 69)*
