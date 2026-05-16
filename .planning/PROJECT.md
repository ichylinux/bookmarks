# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI, with a per-user quick note gadget on the welcome page. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework. The app is fully bilingual in Japanese and English, with per-account language preference and Accept-Language fallback.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## Current Milestone: v1.22 Landing at Root

**Goal:** Move the landing page inline to `/`, remove the separate `/landing` route, and fix the deferred Twitter uid lookup bug.

**Target features:**
- Unauthenticated `/` renders landing content inline (no redirect to `/landing`)
- Authenticated `/` unchanged (dashboard)
- `/landing` route removed entirely
- `from_omniauth` Twitter lookup switched from `name` → `uid` (XAUTH-FUT-01)

## Current State

**Status:** v1.21 complete (2026-05-16); v1.22 planning in progress

v1.21 delivered per-account tweet display count: `display_count` integer column (DB-default 5) on `x_accounts`; number input on `/x_accounts` management card; `display_count` permitted in strong params; `XClient#fetch_recent_tweets` clamps API `max_results` to minimum 5 (X API constraint) then slices result to user preference; `test_display_countを変更できる` controller test + 3 model tests (default callback, numericality validation). Tri-suite green (382 Minitest, 25 Cucumber).

**Previously shipped:** v1.18 — X (Twitter) Account Following (2026-05-14)

v1.18 delivered X (Twitter) Account Following: `users.token_secret` column + `encrypts :token, :token_secret`; `User.from_omniauth` persists `uid`/`token`/`token_secret` on create + re-auth; `TwitterLinkRequirement#require_twitter_linked` gate on `uid + token`; `XClient` Faraday service (OAuth1, timeouts, 7-symbol error contract, t.co expansion, pagination, stub accessors); `x_accounts` cache table + `XAccount` model (`Crud::ByUser`, soft-delete, selection cap 12 / warn 9, protected-account confirmation); `/x_accounts` management UI (refresh diff-upsert, per-row toggle, last-refreshed timestamp); welcome-page AJAX gadgets via `Portal#get_gadgets` with per-error-symbol localized states + `:unauthorized` re-sign-in CTA; `features/06.X.feature` with `@x_gadget` hooks + global state-isolation Before hook; ja/en across `x_accounts.*`, `welcome.x_account.*`, `errors.x_client.*`; Minitest (364/364) + Cucumber (24 scenarios) tri-suite green.

**Previously shipped:** v1.17 — Email Registration for X/Twitter Users (2026-05-13)

v1.17 delivered email registration for X/Twitter dummy-email users: `User` validates dummy-pattern emails `on: :update` only; `Users::EmailRegistrationsController` (`users/email_registration`) with `require_dummy_email`, collision handling and `ActiveRecord::RecordNotUnique` rescue; preferences entry row and ja/en strings (`email_registrations.*`, parity test); Minitest (`user_test`, `email_registrations_controller_test`, `preferences_controller_test`, i18n test). Tri-suite green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` with documented Cucumber flake rerun).

**Previously shipped:** v1.16 — Mastodon Account Following (2026-05-12)

v1.16 delivered read-only Mastodon account following: `mastodon_accounts` table and model, CRUD at `/mastodon_accounts`, `MastodonClient` service with explicit Faraday timeouts, `MastodonAccountsController#show` for HTML + XHR fragments, welcome-page gadgets wired through `Portal#get_gadgets`, Japanese/English strings, Minitest (including Faraday test adapter / stub paths) and Cucumber (`features/05.Mastodon.feature`). Tri-suite green at close (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` with documented Cucumber flake rerun).

**Previously shipped:** v1.15 — CSS & UI Polish (2026-05-11)

v1.15 delivered CSS architecture audit (0 violations across 9 non-theme SCSS files), cross-theme visual QA with consistency fixes, and mobile responsive layout for preferences/bookmarks tables. Post-audit PREFS-01 specificity regression resolved: `common.css.scss` now uses `.preferences-table > tbody > tr > th` (specificity 0,1,3) which correctly beats `.modern table th` (0,1,2). 30 new regression-guard contract tests added.

**Previously shipped:** v1.14 — Landing Page Changelog (2026-05-10)

Changelog entries rendered on `/landing` via locale-YAML-backed `ApplicationHelper#changelog_entries`; VIEW-01–VIEW-04 Minitest coverage; tri-suite green.

**Previously shipped:** v1.13 — Root Entry Redirect to Landing for Guests (2026-05-08)

Auth-state-based entry routing: guests are redirected from `/` to `/landing`, while signed-in users continue to use the existing dashboard at `/`.

**Earlier:** v1.4 — Internationalization (2026-05-03)

The app is bilingual end-to-end. All UI chrome (navigation, drawer, menus, flash messages, Devise auth, 2FA OTP challenge, preferences, bookmarks/notes/todos/feeds/calendar surfaces) renders in Japanese or English. Locale is persisted per account on `preferences.locale`, with a three-stage resolution (saved preference → Accept-Language → `:ja` default) wired through a thread-safe `Localization` controller concern using `around_action` + `I18n.with_locale`. The pending 2FA OTP challenge honors saved locale before sign-in completes. Preferences save flash translates under the just-saved locale via a whitelist-gated `I18n.with_locale`, so language-change redirects render chrome and notice in the new locale together. Locale key parity between `ja.yml` and `en.yml` is enforced by tests; user content (bookmark/folder names, note bodies, Todo titles, feed/calendar external data) remains untranslated by design.

## Requirements

### Validated

- ✓ User authentication and per-user data isolation (Devise) — **v1.1 Phase 4**
- ✓ In-repo JavaScript uses consistent modern style (`const`/`let`, no globals, Sprockets/jQuery/Babel-compatible) — **v1.1 Phases 3–4**
- ✓ JS lint/style baseline (`yarn run lint`, ESLint 9 flat config, Prettier) and contributor docs (`CONVENTIONS.md`) — **v1.1 Phase 2**
- ✓ No regressions in existing behaviour; automated tests and manual smoke paths pass — **v1.1 Phase 4**
- ✓ Modern theme selectable from preferences, activates `body.modern` — **v1.2 Phase 5**
- ✓ Hamburger drawer nav with all links, WCAG reduced-motion support — **v1.2 Phases 6–8**
- ✓ Full-page visual polish: header, typography, tables, action buttons, form controls — **v1.2 Phase 9**
- ✓ Simple-theme tab navigation (Home/Note) on welcome page — **v1.3 Phase 12**
- ✓ Note capture: textarea + Save → persisted note owned by `current_user` — **v1.3 Phase 11**
- ✓ Note list: reverse-chronological, per-user isolated, with timestamp — **v1.3 Phase 13**
- ✓ Persisted per-user `locale` (ja/en) on `preferences`, three-stage resolution (saved → Accept-Language → :ja default), `<html lang>` rendered from resolved locale, including pending 2FA OTP challenge requests — **v1.4 Phases 14 + 18.1**
- ✓ Preferences language switcher persists `locale`, translates the preferences page, and renders the post-change save flash in the newly active locale — **v1.4 Phases 15 + 18.2**
- ✓ Core shell (navigation, drawer/menu chrome) and shared flash messages render through ja/en locale keys with locale-change correctness on the preferences flow — **v1.4 Phases 16 + 18.2**
- ✓ Core feature surfaces for bookmarks, notes, todos, feeds, calendars, and JavaScript-visible feed messages render through ja/en locale keys while user/external content remains unchanged — **v1.4 Phase 17**
- ✓ Auth and 2FA surfaces render in Japanese and English; failed sign-in and invalid OTP alerts use shared localized flash rendering; pending OTP challenge honors saved locale — **v1.4 Phases 18 + 18.1**
- ✓ Translation verification: representative ja/en paths covered, locale key parity enforced, native/external-data exceptions documented, saved-locale OTP and locale-change save-flash regression tests in place — **v1.4 Phases 18 + 18.1 + 18.2**
- ✓ Phase 05 verification closure complete with THEME-03 drawer-contract alignment (modern/classic) and reproducible evidence (`05-VERIFICATION.md`) — **v1.5 Phase 20**
- ✓ Phase 06 verification closure complete with modern/non-modern (classic + simple) interaction and structural evidence (`06-VERIFICATION.md`) — **v1.5 Phase 21**
- ✓ Phase 09 verification closure complete with reproducible STYLE-01..04 selector evidence (`09-VERIFICATION.md`) — **v1.5 Phase 22**
- ✓ v1.5 verification debt cleanup milestone closed; `ROADMAP.md`, `STATE.md`, `MILESTONES.md`, `PROJECT.md` consistently reflect v1.2 phase 05/06/09 closure — **v1.5 Phase 22**
- ✓ Note gadget on modern theme (`/?tab=notes`, drawer link when `use_note`, integration + E2E coverage) — **v1.6 Phases 23–25**
- ✓ Note gadget on classic theme (same contracts and tests as modern for panel visibility and drawer link) — **v1.6 Phases 23–25**
- ✓ Mobile portal column tabs on welcome (`$portal-mobile-breakpoint` 768px; tab strip + `portal--column-active-N`; modern/classic/simple) — **v1.7 Phases 26–28**
- ✓ Public landing page is available at `/landing` for unauthenticated visitors, with localized acquisition messaging and clear sign-up/sign-in CTAs — **v1.12 Phases 40–42**
- ✓ Existing `/` behavior remains unchanged while landing is introduced; auth-entry and sign-in/out messaging tone is consistent in ja/en — **v1.12 Phases 41–42**
- ✓ Unauthenticated users are redirected from `/` to `/landing`, while signed-in users keep existing dashboard behavior at `/` — **v1.13 Phases 43–45**
- ✓ Entry-routing and landing CTA regression contracts are verified under Japanese and English locale contexts with tri-suite green — **v1.13 Phases 43–45**
- ✓ All non-theme SCSS files audited for misplaced theme-specific selectors (0 violations found) — **v1.15 Phase 49**
- ✓ Theme-specific styles confirmed in correct theme files; CSS architecture contract tests guard against regressions — **v1.15 Phase 49**
- ✓ Preferences page visually verified across all 3 themes; PREFS-01 specificity regression resolved — **v1.15 Phases 50 + post-audit fix**
- ✓ Shared components (form controls, action links, flash messages) verified for cross-theme consistency — **v1.15 Phase 50**
- ✓ Mobile/responsive layout fixed for preferences and bookmarks tables at ≤767px across all themes — **v1.15 Phase 51**
- ✓ Mastodon account persistence with profile URL parsing (`MastodonAccount`) and soft-delete — **v1.16 Phase 52**
- ✓ Mastodon CRUD UI at `/mastodon_accounts` with ja/en chrome — **v1.16 Phase 53**
- ✓ `MastodonClient` + `show` action: Faraday timeouts, HTML strip + truncate, linked previews, graceful API error states — **v1.16 Phase 54**
- ✓ Welcome-page Mastodon gadgets (portal + AJAX load, RSS-style pattern) — **v1.16 Phase 55**
- ✓ Minitest + Cucumber coverage for Mastodon surfaces; tri-suite gate — **v1.16 Phase 56**
- ✓ Dummy-pattern email rejected on user update; Twitter OAuth create path unchanged — **v1.17 Phase 57**
- ✓ Dedicated email registration controller, routes, dummy-only and collision guards, `RecordNotUnique` rescue — **v1.17 Phase 58**
- ✓ Preferences registration entry, localized form and flash (ja/en), Minitest + i18n parity — **v1.17 Phase 59**
- ✓ Twitter OAuth 1.0a credentials (`uid`/`token`/`token_secret`) persisted on sign-in and encrypted at rest; `require_twitter_linked` gate on `uid + token` — **v1.18 Phase 60**
- ✓ `XClient` Faraday service with `fetch_following` / `fetch_recent_tweets`, 7-symbol error contract, t.co expansion, pagination, stub accessors — **v1.18 Phase 61**
- ✓ `x_accounts` cache table + `/x_accounts` management UI: refresh diff-upsert, per-row selection (cap 12, warn 9), protected-account confirmation, last-refreshed timestamp, ja/en — **v1.18 Phase 62**
- ✓ Welcome-page X account gadgets (AJAX via `Portal#get_gadgets`, per-error localized states, `:unauthorized` re-sign-in CTA, tweet text never `html_safe`, URL server-constructed) + Cucumber `@x_gadget` + tri-suite gate — **v1.18 Phase 63**
- ✓ `webmock` gem in `:test` group; `test/support/webmock.rb` with `disable_net_connect!(allow_localhost: true)` + fixture feed stubs auto-loaded by both Minitest and Cucumber — **v1.19 Phase 64**
- ✓ All Minitest HTTP stubs migrated to Faraday `:test` (service tests with `connection:` injection) and WebMock `stub_request` (controller integration tests, `fetch_recent_tweets`); no class-level stub accessors remain — **v1.19 Phase 65**
- ✓ Cucumber gadget hooks (`@mastodon_gadget`, `@x_gadget`) migrated to `WebMock.stub_request` / `WebMock.remove_request_stub`; `test/http_client_test_stubs.rb` deleted (133 lines); stub loader removed from `config/environments/test.rb` — **v1.19 Phase 66**
- ✓ User can select portal column count (3 or 4) from the preferences screen (ja/en locale strings, `PORTAL_COLUMN_COUNTS` constant) — **v1.20 Phase 68**
- ✓ Portal renders user-chosen column count on desktop; `Portal#portal_columns` parameterized via stored preference; mobile tab strip unchanged; downgrade 4→3 redistributes gracefully — **v1.20 Phases 67–68**
- ✓ Per-account tweet display count configurable from `/x_accounts`; persisted on `x_accounts.display_count`; welcome gadget honours per-account value via `XClient#fetch_recent_tweets(limit:)` — **v1.21 Phase 69**

### Active

- [ ] ROOT-01: Unauthenticated `/` renders landing content inline; no redirect to `/landing` — **v1.22**
- [ ] ROOT-02: `/landing` route removed; authenticated `/` unchanged — **v1.22**
- [ ] XAUTH-01: `from_omniauth` Twitter branch looks up by `uid` instead of `name` — **v1.22**

### Out of Scope (revisit when planning)

- Introducing a new frontend framework, npm-heavy bundler migration, or replacing the asset pipeline
- Large UX redesigns unrelated to current milestone scope
- TypeScript conversion
- Delete individual notes — deferred until core capture flow proves out on all themes
- Rich text / markdown editor — conflicts with no-new-JS-deps constraint
- Real-time autosave — explicit save is the correct UX for deliberate capture
- Locale beyond ja/en — not planned; `Preference::SUPPORTED_LOCALES` whitelist + `enforce_available_locales` keep the surface explicit
- `?locale=` URL parameter override — intentionally absent (Phase 14 D-04); can be added if a use case emerges

## Context

- **Shipped v1.19 (2026-05-14):** HTTP test stubs → WebMock — `webmock 3.26.2` in `:test` group; `test/support/webmock.rb` global config; Minitest service/controller tests migrated to Faraday `:test` + WebMock; Cucumber hooks migrated to per-scenario `WebMock.stub_request`; 133-line prepend stub file deleted. Tri-suite green (363 Minitest, 24 Cucumber). Details: `.planning/milestones/v1.19-ROADMAP.md`. Audit: `.planning/milestones/v1.19-MILESTONE-AUDIT.md` (`tech_debt`; 5/5 requirements; accepted: no per-phase artifacts for Phases 65–66).
- **Shipped v1.17 (2026-05-13):** Email registration for dummy-email (X/Twitter) users — model update validation, `Users::EmailRegistrationsController`, preferences link, ja/en, Minitest. Details: `.planning/milestones/v1.17-ROADMAP.md`. Audit: `.planning/milestones/v1.17-MILESTONE-AUDIT.md`.
- **Shipped v1.16 (2026-05-12):** Mastodon account following — data model, CRUD, `MastodonClient`, welcome gadgets, locales, tests. Details: `.planning/milestones/v1.16-ROADMAP.md`. Audit: `.planning/milestones/v1.16-MILESTONE-AUDIT.md`.
- **Shipped v1.15 (2026-05-11):** CSS architecture audit (0 violations), cross-theme visual QA, mobile responsive layout, PREFS-01 specificity regression fix, 30 new contract tests. Details: `.planning/milestones/v1.15-ROADMAP.md`.
- **Shipped v1.14 (2026-05-10):** Changelog section on `/landing` with YAML-backed data layer and VIEW test coverage. Details: `.planning/milestones/v1.14-ROADMAP.md`.
- **Shipped v1.7 (2026-05-04):** Mobile portal layout — CSS breakpoint variable in `welcome.css.scss`, `portal_column_section` partial + `portal_mobile_tabs.js`, theme-scoped tab styling, Minitest + Cucumber. Gate: tri-suite green.
- **Shipped v1.13 (2026-05-08):** Root entry now redirects unauthenticated users to `/landing`, preserves signed-in dashboard behavior at `/`, and adds regression coverage for auth-state + locale entry contracts.
- **Shipped v1.6 (2026-05-04):** Note gadget extended to modern and classic themes per `.planning/milestones/v1.6-ROADMAP.md`. Audit: `.planning/milestones/v1.6-MILESTONE-AUDIT.md` (`tech_debt`: no formal per-phase `.planning/phases/` VERIFICATION/Nyquist artifacts; traceability via roadmap success criteria, REQUIREMENTS archive, tests).
- **Shipped v1.5 (2026-05-04):** verification debt cleanup for v1.2 phases 05/06/09 — shared rubric (Phase 19), per-phase verification closures (Phases 20–22), and cross-document milestone sync. Details: `.planning/milestones/v1.5-ROADMAP.md`. Audit: `.planning/milestones/v1.5-MILESTONE-AUDIT.md` (`tech_debt`, no blockers).
- Stack and architecture: see `.planning/codebase/STACK.md` and `ARCHITECTURE.md`
- JavaScript (post–v1.1): first-party `app/assets/javascripts/` follows ESLint + `CONVENTIONS.md`; Sprockets + Babel + jQuery 4 + Rails UJS unchanged
- **Shipped v1.1 (2026-04-27):** tooling baseline, script modernization (Phases 2–3), full test + smoke verification (Phase 4). Details: `.planning/milestones/v1.1-ROADMAP.md`
- **Shipped v1.2 (2026-04-29):** modern theme with hamburger drawer nav and full-page CSS polish (Phases 5–9). Details: `.planning/milestones/v1.2-ROADMAP.md`
- **Shipped v1.3 (2026-04-30):** quick note gadget — data layer, controller, tab UI, note gadget partial, Cucumber E2E, drawer-gating helper (Phases 10–13). Details: `.planning/milestones/v1.3-ROADMAP.md`
- **Shipped v1.4 (2026-05-03):** end-to-end Japanese/English localization across infrastructure (Phase 14), preferences UI (15), core shell (16), feature surfaces (17), auth/2FA (18), pending-OTP locale (18.1), and locale-change save flash (18.2). Final gate green: `yarn run lint`, `bin/rails test` 191/1101, `bundle exec rake dad:test` 9/28. Details: `.planning/milestones/v1.4-ROADMAP.md`. Audit: `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.

## Constraints

- **Stack**: Sprockets + jQuery + existing gem pipeline — new JS must not break asset compilation or production minification
- **Browsers**: Target environments implied by Babel `preset-env` and project policy
- **Compatibility**: Preserve behaviour of `.js.erb` and controller-driven JS responses where used
- **Locale resolution**: All locale candidates must pass `Preference::SUPPORTED_LOCALES.include?(...)` before reaching `I18n.with_locale`; `before_action` is forbidden for locale-setting (Puma thread reuse leaks); `around_action` + `I18n.with_locale` is the contract.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Sprockets for v1.1 | Minimize risk; style modernization is the goal, not a framework migration | ✓ Good — asset pipeline unchanged; bundler/SPA still out of scope |
| Hamburger/drawer in layout, hidden by CSS outside modern | Simpler than conditional render; CSS hides cost is negligible | ✓ Good — clean separation; `drawer_ui?` helper added in v1.3 for explicit gating |
| Full-page POST for note create (not AJAX) | Consistent with bookmarks and preferences forms; no new JS complexity | ✓ Good — redirect + `?tab=notes` param round-trips cleanly |
| Tab state via query param (`?tab=notes`) not History API | Survives POST/redirect cycle; no pushState complexity | ✓ Good — simple and reliable |
| `user_id` never in strong params — merged server-side | Security: never trust client for ownership | ✓ Good — matches todos_controller pattern |
| `Note.where(user_id: ...).delete_all` in tests | Rails 8.1 association `delete_all` issues nullifying UPDATE; NOT NULL constraint rejects it | ✓ Good — pragmatic workaround documented |
| `locale` column on `preferences`, not `users` (Phase 14 D-01) | All per-user UI prefs already aggregate on `Preference`; same pattern keeps Phase 15 form addition trivial | ✓ Good — model validation matches FONT_SIZES pattern |
| `around_action` (not `before_action`) for `set_locale` (Phase 14 D-04) | `I18n.locale` is thread-local; Puma reuses threads. `with_locale` saves/restores atomically per request | ✓ Good — locale bleed across requests prevented |
| Whitelist guard before every `I18n.with_locale` (Phase 14 D-04) | Defense in depth: model validation rejects bad writes; whitelist guard rejects bad reads (stale DB / malformed Accept-Language); `enforce_available_locales` is the last line | ✓ Good — `I18n::InvalidLocale` impossible by construction |
| No `?locale=` URL parameter (Phase 14 D-04) | I18N-02 spec doesn't include URL parameter; not reading params makes I18N-03 trivially satisfied | ✓ Good — testable surface stays minimal; can be added later if needed |
| Pending-OTP saved locale via `session[:otp_user_id]` (Phase 18.1) | Resolves saved locale before Devise sign-in completes, without signing in early; respects existing whitelist gate | ✓ Good — fixes pending-OTP locale gap with no surface area increase |
| Translate save flash under saved candidate locale (Phase 18.2) | Pre-redirect flash materialization happens under the OLD locale; translating under `I18n.with_locale(saved)` after `@user.save!` aligns flash with chrome | ✓ Good — closes locale-change save flash gap; whitelist-gated, falls through cleanly for non-locale saves |
| Native labels for locale select (`自動 / 日本語 / English`) (Phase 15 D-02) | Language names are conventionally shown in their own script regardless of UI locale | ✓ Good — pattern reused for any future native-label UIs |
| Modern/classic note panels via SSR + CSS visibility classes | Matches simple-theme `?tab=notes` pattern without new client-side tab framework; `#welcome-home-panel` / `#notes-tab-panel` mutual exclusion via `welcome-tab-panel--hidden` | ✓ Good — POST/redirect friendly; `notes_tabs.js` remains simple-only |
| Drawer Note link gated by `use_note` | Avoids surprising navigation when gadget disabled; uses `t('nav.note')` for ja/en parity | ✓ Good — aligns with existing gadget preference model |
| Cucumber step naming for modern + `use_note` | Disambiguates “modern theme sign-in” steps from scenarios that must enable the note preference | ✓ Good — reduces ambiguous step matching |
| Child-combinator selector for `.preferences-table th` (v1.15) | `.preferences-table > tbody > tr > th` (0,1,3) beats `.modern table th` (0,1,2) without a theme-scoped override; MOB-03 contract prohibits per-theme duplication | ✓ Good — single source of truth in `common.css.scss`; mobile media query uses same specificity for `text-align: left` |
| `MastodonClient.stub_fetch_result` / `XClient.stub_fetch_*` (prepend in `test/http_client_test_stubs.rb`, v1.18) | Short-term: kept HTTP out of `app/services` | ✓ Superseded — removed in v1.19; replaced by WebMock + Faraday `:test` |
| WebMock + Faraday `:test` for external HTTP in tests (v1.19) | Standard layer for stubbing when `:test` injection is impossible (full stack); avoids prepend/class accessors on service classes | ✓ Done — Phases 64–66: `webmock` gem, `test/support/webmock.rb`, service tests use Faraday `:test`, controller/Cucumber tests use WebMock; `test/http_client_test_stubs.rb` deleted |
| Dedicated `Users::EmailRegistrationsController` (not preferences) | Avoids widening writable-email surface; keeps `save` vs `save!` control for validation UX | ✓ Good — aligns with CTRL/VIEW split |
| Dummy email validator `on: :update` only | `from_omniauth` create legitimately sets dummy addresses | ✓ Good — no regression on Twitter sign-up |
| Email registration strong params under `:email_registration` | Avoids collision with Devise `:user` param expectations | ✓ Good — explicit contract |
| `faraday-oauth1` with `:header` signing for X API v2 (v1.18) | X API v2 Basic supports OAuth 1.0a User Context; same OmniAuth adapter already in use | ✓ Good — no new auth infra; `f.request :oauth1, 'header', consumer_key:, …` wires cleanly |
| All-soft-delete on refresh diff for missing rows (v1.18 XACCT-06) | Developer judgment: safer to always preserve for recovery; original spec said hard-delete `selected:false` rows | ✓ Good — intentional deviation documented in audit; tests validate new behavior |
| `require_twitter_linked` gates on `uid + token`, not `name` (v1.18) | `users.name` is user-editable; `uid + token` is the OAuth identity predicate | ✓ Good — aligns gate with actual credential availability |
| Reuse existing `users.{provider, uid, token}` dead columns + add only `token_secret` (v1.18 Q8=1) | Avoids schema-level column rename/migration risk; keeps column footprint minimal | ✓ Good — no migration rollback risk; `encrypts :token, :token_secret` on User |
| Selection cap 12 / soft-warning 9 (v1.18 Q9=1) | Welcome page performance bound; arbitrary but explicit and user-adjustable via deselect | ✓ Good — cap enforced at model + controller; warning surfaced in view |
| CSS `max(100%, min-content)` → `width: 100%` in `feeds.css.scss` (v1.18) | Dart Sass interprets CSS `max()` as Sass `max()` during `application` bundle compile in test | ✓ Good — pragmatic fix; avoids Sass/CSS function ambiguity |
| `PORTAL_COLUMN_COUNTS = [3, 4]` constant on Preference model (v1.20) | Matches `FONT_SIZES` pattern; single source of truth for valid values used by validation, view `map`, and `default_preference` | ✓ Good — consistent with existing model constants |
| `portal--4col` modifier class + SCSS `@media` rule (v1.20) | Isolates 4-column width override to desktop breakpoint; theme files unchanged | ✓ Good — no per-theme duplication; mobile tab strip unaffected |
| Cucumber step uses `form.preferences-form` not `form.edit_user` (v1.20) | `form_with` with explicit `html: { class: }` doesn't append the default `edit_user` class unlike `form_for` | ✓ Good — correct selector; documented deviation from initial 068-01 implementation |
| `before_save` callback as nil-guard only for display_count (v1.21) | Validation fires before `before_save`; callback protects against nil only (DB default handles this in practice) | ✓ Good — redundancy harmless; documented in audit |
| XClient requests `max(limit, 5)` for X API constraint (v1.21) | X API v2 requires `max_results >= 5`; slicing result after fetch honours exact user preference | ✓ Good — fixes `display_count < 5` API error without any UX change |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

## Shipped

### v1.21 — X Gadget Tweet Count Preference (2026-05-16)

**Delivered:** Per-account tweet display count on `/x_accounts`: `display_count` integer column (DB-default 5); number input on management card; `:display_count` permitted in strong params; `XClient` requests `max(limit, 5)` from X API then slices to user preference (fixes API error for display_count < 5); controller + model tests. Tri-suite green (382 Minitest, 25 Cucumber).

### v1.20 — Column Count Preference (2026-05-15)

**Delivered:** `preferences.portal_column_count` integer column (default 3, NOT NULL); `PORTAL_COLUMN_COUNTS = [3, 4]` with inclusion validation; `Portal#portal_columns` fully parameterized (no hardcoded 3); downgrade guard (`next if pl.column_no >= count`); preferences select control with ja/en locale strings (`3列`/`4列`); `portal--4col` conditional class + `.portal--4col .gadgets { width: 25% }` SCSS rule; Cucumber `features/07.設定.feature` scenario; Minitest controller save/render and layout 3/4-column tests. Tri-suite green (377 Minitest, 25 Cucumber scenarios, 0 failures).

### v1.19 — HTTP test stubs → WebMock (2026-05-14)

**Delivered:** WebMock gem + global `disable_net_connect!` config; service tests migrated to Faraday `:test` adapter; controller tests and Cucumber hooks migrated to `WebMock.stub_request`; `test/http_client_test_stubs.rb` deleted (133 lines); `config/environments/test.rb` loader removed. No class-level stub accessors remain. Tri-suite green (lint ✓ · 363 Minitest ✓ · 24 Cucumber ✓).

### v1.18 — X (Twitter) Account Following (2026-05-14)

**Delivered:** OAuth 1.0a token persistence + encryption; `XClient` Faraday service (OAuth1, error contract, stubs); `x_accounts` cache + `/x_accounts` management UI (refresh diff, selection cap, protected toggle); welcome AJAX gadgets via `Portal#get_gadgets` (per-error states, no `html_safe`); Cucumber `@x_gadget`; ja/en (`x_accounts.*`, `welcome.x_account.*`, `errors.x_client.*`). Tri-suite green (364 Minitest, 24 Cucumber scenarios).

### v1.17 — Email Registration for X/Twitter Users (2026-05-13)

**Delivered:** Update-only dummy email rejection; `Users::EmailRegistrationsController` + `users/email_registration` routes; collision + `RecordNotUnique` handling; preferences entry; `config/locales` ja/en; Minitest + tri-suite green at close (Cucumber flake rerun policy).

### v1.16 — Mastodon Account Following (2026-05-12)

**Delivered:** `mastodon_accounts` migration/model, CRUD controller + views, `MastodonClient` (lookup + statuses, strip/truncate, timeouts), `show` for gadget HTML, `Portal` gadget registration, welcome partial + jQuery AJAX, ja/en locales, Minitest + Cucumber (`@mastodon_gadget`). Tri-suite green at close.

### v1.15 — CSS & UI Polish (2026-05-11)

**Delivered:** CSS architecture audit confirmed 0 violations across 9 non-theme SCSS files; cross-theme visual QA fixed action link colors and PREFS-01 specificity regression; mobile responsive stacking for preferences/bookmarks tables at ≤767px added to `common.css.scss`; 30 regression-guard contract tests added. Tri-suite green.

### v1.14 — Landing Page Changelog (2026-05-10)

**Delivered:** Changelog YAML data layer and `ApplicationHelper#changelog_entries` helper; changelog section rendered on `/landing`; VIEW-01–VIEW-04 Minitest coverage; tri-suite green.

### v1.13 — Root Entry Redirect to Landing for Guests (2026-05-08)

**Delivered:** Root entry behavior now routes unauthenticated visitors to `/landing` while keeping authenticated dashboard rendering unchanged at `/`; landing CTA and locale contracts remain intact, backed by integration tests and green tri-suite verification (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`).

### v1.12 — Landing Page for User Acquisition (Phase 1) (2026-05-08)

**Delivered:** Added a new public `/landing` page with localized value messaging and clear conversion CTAs, introduced consistent tone across landing/auth entry and sign-in/out messages, and locked contracts with route/view/CTA regression tests while preserving existing root behavior.

### v1.11 — Device-aware Font Size Baseline (2026-05-06)

**Delivered:** Device-aware medium font baseline (`PC=14px`, `mobile=16px`) with relative small/large scaling (`0.875x`/`1.125x`), safe fallback handling, idempotent migration for existing `nil/medium` users to `small`, and one-time in-app notice coverage through model/controller/theme verification contracts.

### v1.6 — Note Gadget for All Themes (2026-05-04)

**Delivered:** Modern and classic themes render the shared `_note_gadget` on `/?tab=notes` with home/note panel exclusivity; drawer Note link when `use_note`; SCSS for `#notes-tab-panel` in theme files; ja/en verification tests; Cucumber modern-theme capture scenario. Phases 23–25 (plans tracked inline on roadmap). Milestone audit records accepted process debt (no per-phase VERIFICATION dirs).

### v1.5 — Verification Debt Cleanup (2026-05-04)

**Delivered:** Carry-forward verification closure for v1.2 phases 05/06/09 — shared Phase 19 rubric, `05-VERIFICATION.md`, `06-VERIFICATION.md`, and `09-VERIFICATION.md` with reproducible evidence; cross-document milestone sync and archive snapshots. Phases 19–22, 7 plans.

### v1.4 — Internationalization (2026-05-03)

**Delivered:** End-to-end Japanese/English bilingual UI. Locale infrastructure (DB column + thread-safe `Localization` concern + `<html lang>` + Accept-Language fallback), preferences language switcher, core shell + feature surface translation, auth/2FA localization, pending-OTP saved-locale resolution, and locale-change save flash correctness. 7 phases, 19 plans, 32 tasks, ~3 days.

### v1.3 — Quick Note Gadget (2026-04-30)

**Delivered:** Notes table + model (`Crud::ByUser`, soft-delete, validations), `NotesController#create`, simple-theme tab strip (Home/Note), `_note_gadget` partial with empty-state and reverse-chrono list, `WelcomeControllerTest` coverage, Cucumber E2E feature, `drawer_ui?` layout helper. Human UAT 5/5.

### v1.2 — Modern Theme (2026-04-29)

**Goal achieved:** Selectable "Modern" theme with hamburger side-drawer nav and clean, full-page styling.

### v1.1 — Modern JavaScript (2026-04-27)

**Goal achieved:** In-repo JavaScript is maintainable and lint-consistent without replacing Sprockets or jQuery.

---
*Last updated: 2026-05-17 — v1.22 Landing at Root planning started*
