# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI, with a per-user quick note gadget on the welcome page. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework. The app is fully bilingual in Japanese and English, with per-account language preference and Accept-Language fallback.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## Current Milestone: v1.6 — Note Gadget for All Themes

**Goal:** Extend the quick Note gadget from the simple theme to modern and classic themes so all users can capture and view notes from the welcome page.

**Target features:**
- Note gadget (textarea + Save + note list) accessible on modern theme
- Note gadget accessible on classic theme
- Theme-appropriate presentation for each theme layout

## Current State

**Shipped:** v1.5 — Verification Debt Cleanup (2026-05-04)

v1.5 closed carry-forward verification debt for v1.2 phases 05/06/09. Each phase has a closure-ready verification document anchored to test methods and code references per the shared Phase 19 rubric. Phase 05 closes THEME-01/02/03 (`P05-C01..C03` PASS), Phase 06 closes NAV-01/02 with non-modern unaffected contract (`P06-C01..C03` PASS), Phase 09 closes STYLE-01..04 (`P09-C01..C04` PASS) anchored to `test/assets/modern_full_page_theme_contract_test.rb` selectors. Tracking documents (ROADMAP, STATE, MILESTONES, PROJECT) and milestone snapshots are consistent.

**Previously shipped:** v1.4 — Internationalization (2026-05-03)

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

### Active

- Note gadget available on modern theme (tab or integrated section) — **v1.6**
- Note gadget available on classic theme (tab or integrated section) — **v1.6**

### Out of Scope (revisit when planning)

- Introducing a new frontend framework, npm-heavy bundler migration, or replacing the asset pipeline
- Large UX redesigns unrelated to current milestone scope
- TypeScript conversion
- Delete individual notes — deferred until core capture flow proves out
- Note gadget on modern and classic themes — **moved to v1.6 Active** (simple theme proven out in v1.3–v1.5)
- Rich text / markdown editor — conflicts with no-new-JS-deps constraint
- Real-time autosave — explicit save is the correct UX for deliberate capture
- Locale beyond ja/en — not planned; `Preference::SUPPORTED_LOCALES` whitelist + `enforce_available_locales` keep the surface explicit
- `?locale=` URL parameter override — intentionally absent (Phase 14 D-04); can be added if a use case emerges

## Context

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
*Last updated: 2026-05-04 — v1.6 Note Gadget for All Themes started.*
