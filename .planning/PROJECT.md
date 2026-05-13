# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI, with a per-user quick note gadget on the welcome page. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework. The app is fully bilingual in Japanese and English, with per-account language preference and Accept-Language fallback.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## Current Milestone: v1.18 X (Twitter) Account Following

**Goal:** Twitter サインイン済みユーザー（`users.name` あり）が自分のフォロー中 X アカウントから選択した相手の最新ツイートを welcome ページのガジェットとして表示できる。

**Target features:**
- `User.from_omniauth` Twitter ブランチで `uid` / `token` / OAuth1 secret を保存（X API 呼び出しの前提、v1.17 PITFALL-02 解消も兼ねる）
- `XClient` サービス：`GET /2/users/:id/following`（管理画面）+ `GET /2/users/:id/tweets`（ガジェット）。Faraday + 明示タイムアウト、graceful なエラー処理、テスト用 `stub_fetch_result`（v1.16 と同流儀）
- `/x_accounts` 管理画面：`name` 入りユーザーのみアクセス可。フォロー中一覧を DB キャッシュ＋手動「再取得」、welcome 表示の選択／解除
- welcome ガジェット：選択された X アカウントの最新ツイート N 件を AJAX 遅延ロード（v1.16 Mastodon と同型、`Portal#get_gadgets` 経由）
- ja/en ローカライズ（管理画面・ガジェット・preferences エントリ・エラー表示）+ 鍵パリティテスト
- Minitest（モデル/コントローラ/サービス、Faraday test adapter）+ Cucumber（`@x_gadget` 流）+ tri-suite gate

**Key context:**
- X API v2 Basic プラン($200/月〜) 前提（既契約／契約予定）。テストは実 API を叩かずスタブ契約で動かす
- データ鮮度：フォロー一覧 = DB キャッシュ + 手動再取得 / ツイート = welcome 表示時ライブ取得（新規バックグラウンドインフラは入れない）
- 既存 `omniauth-twitter`（OAuth 1.0a User Context）を維持。X API v2 も同方式で動作
- v1.16 Mastodon の `MastodonAccount` / CRUD / `Portal#get_gadgets` / AJAX `show` パターンを最大限再利用。新規要素は「フォロー一覧 → 選択」フローのみ
- 管理画面 / preferences 入り口は `users.name` ガード（Google サインインのみのユーザーには出さない）

## Current State

**Status:** v1.17 shipped (2026-05-13)

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

### Active

- [ ] Decide whether `/landing` replaces `/` after conversion evaluation
- [ ] v1.18 X (Twitter) Account Following — Twitter サインインユーザーのフォロー一覧から選択 → welcome ガジェット表示（要件詳細は `.planning/REQUIREMENTS.md`）

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
| `MastodonClient.stub_fetch_result` for Cucumber + controller tests | Isolates acceptance tests from the public network without WebMock | ✓ Good — cleared in hooks/teardown; documents test contract |
| Dedicated `Users::EmailRegistrationsController` (not preferences) | Avoids widening writable-email surface; keeps `save` vs `save!` control for validation UX | ✓ Good — aligns with CTRL/VIEW split |
| Dummy email validator `on: :update` only | `from_omniauth` create legitimately sets dummy addresses | ✓ Good — no regression on Twitter sign-up |
| Email registration strong params under `:email_registration` | Avoids collision with Devise `:user` param expectations | ✓ Good — explicit contract |

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
*Last updated: 2026-05-14 after v1.18 milestone start*
