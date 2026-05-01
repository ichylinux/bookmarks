# Bookmarks

## What This Is

Bookmarks is a personal Rails 8.1 web app (Ruby 3.4, MySQL) for saving and organizing bookmarks, feeds, todos, and calendar-oriented UI. Users can also capture personal notes from the welcome page. The browser UI uses the classic Sprockets asset pipeline with jQuery and SCSS, not a SPA framework.

## Core Value

Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## Current Milestone: v1.4 Internationalization

**Goal:** Make the app fully bilingual (ja/en) with a per-user language preference and browser Accept-Language detection on first visit.

**Target features:**
- Extract all hardcoded UI strings to `config/locales/ja.yml` and `config/locales/en.yml`
- Add `locale` column to `preferences` table; persist selected language per account
- Detect `Accept-Language` header on first visit as fallback default
- Language switcher on `/preferences` page (ja / en selection)
- Coverage: navigation/layout, flash/error messages, bookmarks/notes/todos gadgets, Devise auth pages

## Current State

**Shipped:** v1.3 — Quick Note Gadget (2026-04-30)

Simple theme welcome page now has a "Home/Note" tab strip. Users can type notes and save them; the page returns to the Note tab after save and displays a reverse-chronological list of the user's notes. Notes are per-user isolated. All functionality tested by Minitest integration tests and a Japanese Cucumber E2E feature.

**Active milestone:** v1.4 — Internationalization (Phase 16 complete 2026-05-01: locale infrastructure, persisted language preference, preferences language switcher, and core shell/shared message translation are in place; Phase 17 will translate feature surfaces)

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
- ✓ Persisted per-user `locale` (ja/en) on `preferences`, three-stage resolution (saved → Accept-Language → :ja default), `<html lang>` rendered from resolved locale — **v1.4 Phase 14**
- ✓ Preferences language switcher persists `locale` and translates the preferences page labels/options — **v1.4 Phase 15**
- ✓ Core shell navigation, drawer/menu chrome, and shared generic flash fallback render through ja/en locale keys — **v1.4 Phase 16**

### Active (v1.4)

- [ ] All UI strings extracted to `ja.yml` / `en.yml` locale files
- [x] `locale` column added to `preferences` table; persists language preference per account — **v1.4 Phase 14**
- [x] `Accept-Language` header detection sets locale for unauthenticated / first visits — **v1.4 Phase 14**
- [x] Language switcher (ja / en) on `/preferences` page — **v1.4 Phase 15**
- [ ] All flash messages, validation errors, and Devise pages translated in both locales
- [ ] Navigation, layout labels, and gadget UIs (bookmarks, notes, todos) fully translated

### Out of Scope (revisit when planning)

- Introducing a new frontend framework, npm-heavy bundler migration, or replacing the asset pipeline
- Large UX redesigns unrelated to current milestone scope
- TypeScript conversion
- Delete individual notes — deferred until core capture flow proves out
- Note gadget on modern and classic themes — deferred until simple theme proves out
- Rich text / markdown editor — conflicts with no-new-JS-deps constraint
- Real-time autosave — explicit save is the correct UX for deliberate capture

## Context

- Stack and architecture: see `.planning/codebase/STACK.md` and `ARCHITECTURE.md`
- JavaScript (post–v1.1): first-party `app/assets/javascripts/` follows ESLint + `CONVENTIONS.md`; Sprockets + Babel + jQuery 4 + Rails UJS unchanged
- **Shipped v1.1 (2026-04-27):** tooling baseline, script modernization (Phases 2–3), full test + smoke verification (Phase 4). Details: `.planning/milestones/v1.1-ROADMAP.md`
- **Shipped v1.2 (2026-04-29):** modern theme with hamburger drawer nav and full-page CSS polish (Phases 5–9). Details: `.planning/milestones/v1.2-ROADMAP.md`
- **Shipped v1.3 (2026-04-30):** quick note gadget — data layer, controller, tab UI, note gadget partial, Cucumber E2E, drawer-gating helper (Phases 10–13). Details: `.planning/milestones/v1.3-ROADMAP.md`

## Constraints

- **Stack**: Sprockets + jQuery + existing gem pipeline — new JS must not break asset compilation or production minification
- **Browsers**: Target environments implied by Babel `preset-env` and project policy
- **Compatibility**: Preserve behaviour of `.js.erb` and controller-driven JS responses where used

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Sprockets for v1.1 | Minimize risk; style modernization is the goal, not a framework migration | ✓ Good — asset pipeline unchanged; bundler/SPA still out of scope |
| Hamburger/drawer in layout, hidden by CSS outside modern | Simpler than conditional render; CSS hides cost is negligible | ✓ Good — clean separation; `drawer_ui?` helper added in v1.3 for explicit gating |
| Full-page POST for note create (not AJAX) | Consistent with bookmarks and preferences forms; no new JS complexity | ✓ Good — redirect + `?tab=notes` param round-trips cleanly |
| Tab state via query param (`?tab=notes`) not History API | Survives POST/redirect cycle; no pushState complexity | ✓ Good — simple and reliable |
| `user_id` never in strong params — merged server-side | Security: never trust client for ownership | ✓ Good — matches todos_controller pattern |
| `Note.where(user_id: ...).delete_all` in tests | Rails 8.1 association `delete_all` issues nullifying UPDATE; NOT NULL constraint rejects it | ✓ Good — pragmatic workaround documented |
| `locale` column on `preferences`, not `users` (Phase 14 D-01) | All per-user UI prefs (theme/font_size/use_note/...) already aggregate on `Preference`; same pattern keeps Phase 15 form addition trivial | ✓ Good — model validation matches FONT_SIZES pattern |
| `around_action` (not `before_action`) for `set_locale` (Phase 14 D-04) | `I18n.locale` is thread-local; Puma reuses threads. `with_locale` saves/restores atomically per request | ✓ Good — locale bleed across requests prevented |
| Whitelist guard before every `I18n.with_locale` (Phase 14 D-04) | Defense in depth: model validation rejects bad writes; whitelist guard rejects bad reads (stale DB / malformed Accept-Language); `enforce_available_locales` is the last line | ✓ Good — `I18n::InvalidLocale` impossible by construction |
| No `?locale=` URL parameter (Phase 14 D-04) | I18N-02 spec doesn't include URL parameter; not reading params makes I18N-03 trivially satisfied | ✓ Good — testable surface stays minimal; can be added later if needed |

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

### v1.3 — Quick Note Gadget (2026-04-30)

**Delivered:** Notes table + model (`Crud::ByUser`, soft-delete, validations), `NotesController#create`, simple-theme tab strip (Home/Note), `_note_gadget` partial with empty-state and reverse-chrono list, `WelcomeControllerTest` coverage, Cucumber E2E feature, `drawer_ui?` layout helper. Human UAT 5/5.

### v1.2 — Modern Theme (2026-04-29)

**Goal achieved:** Selectable "Modern" theme with hamburger side-drawer nav and clean, full-page styling.

### v1.1 — Modern JavaScript (2026-04-27)

**Goal achieved:** In-repo JavaScript is maintainable and lint-consistent without replacing Sprockets or jQuery.

---
*Last updated: 2026-05-01 — Phase 16 complete (core shell/shared message translation: nav chrome, menu labels, generic flash fallback, ja/en parity and verification tests).*
