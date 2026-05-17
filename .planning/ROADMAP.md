# Roadmap: Bookmarks

## Milestones

- [x] **v1.23 — Icon Display Preference** — Phases 73–75 (active)
- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04) — [archived](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ⚠️ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (deferred 2026-05-06)
- ✅ **v1.11 — Device-aware Font Size Baseline** — Phases 37–39 (shipped 2026-05-06) — [archived](milestones/v1.11-ROADMAP.md)
- ✅ **v1.12 — Landing Page for User Acquisition (Phase 1)** — Phases 40–42 (shipped 2026-05-08) — [archived](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08) — [archived](milestones/v1.13-ROADMAP.md)
- ✅ **v1.14 — Landing Page Changelog** — Phases 46–48 (shipped 2026-05-10) — [archived](milestones/v1.14-ROADMAP.md)
- ✅ **v1.15 — CSS & UI Polish** — Phases 49–51 (shipped 2026-05-11) — [archived](milestones/v1.15-ROADMAP.md)
- ✅ **v1.16 — Mastodon Account Following** — Phases 52–56 (shipped 2026-05-12) — [archived](milestones/v1.16-ROADMAP.md)
- ✅ **v1.17 — Email Registration for X/Twitter Users** — Phases 57–59 (shipped 2026-05-13) — [archived](milestones/v1.17-ROADMAP.md)
- ✅ **v1.18 — X (Twitter) Account Following** — Phases 60–63 (shipped 2026-05-14) — [archived](milestones/v1.18-ROADMAP.md)
- ✅ **v1.19 — HTTP test stubs → WebMock** — Phases 64–66 (shipped 2026-05-14) — [archived](milestones/v1.19-ROADMAP.md)
- ✅ **v1.20 — Column Count Preference** — Phases 67–68 (shipped 2026-05-15) — [archived](milestones/v1.20-ROADMAP.md)
- ✅ **v1.21 — X Gadget Tweet Count Preference** — Phase 69 (shipped 2026-05-16) — [archived](milestones/v1.21-ROADMAP.md)
- ✅ **v1.22 — Landing at Root** — Phases 70–72 (shipped 2026-05-17) — [archived](milestones/v1.22-ROADMAP.md)

## Phases

### v1.23 — Icon Display Preference

- [x] **Phase 73: Data + Model Layer** - Migration, model constant, default_preference, validation
- [x] **Phase 74: CSS + View Layer** - Body class in layout, CSS hide rules in SCSS
- [x] **Phase 75: Preferences UI + Locale + Tests** - Toggle control, ja/en strings, Minitest, tri-suite gate

## Phase Details

### Phase 73: Data + Model Layer
**Goal**: The application has a persisted, validated `show_icons` preference that defaults to true for all users
**Depends on**: Nothing (data foundation)
**Requirements**: ICON-01
**Success Criteria** (what must be TRUE):
  1. `preferences` table has a `show_icons` boolean column with NOT NULL constraint and DB-level default of true
  2. New users (created via `default_preference`) get `show_icons: true` without explicit assignment
  3. `Preference` model rejects `show_icons: nil` with a validation error
  4. Existing users' preferences rows are migrated without error (migration is idempotent)
**Plans**: TBD
**UI hint**: no

### Phase 74: CSS + View Layer
**Goal**: Users who have `show_icons: false` see no icons on gadget titles or the drawer navigation, with no change to the landing page
**Depends on**: Phase 73
**Requirements**: ICON-02, ICON-03
**Success Criteria** (what must be TRUE):
  1. When `show_icons` is false, the application layout emits `body.no-icons` (matching the `body.modern` pattern)
  2. When `body.no-icons` is present, all `.gadget-title-icon` elements are hidden via CSS (welcome gadgets, mastodon/x/feeds/calendars detail pages)
  3. When `body.no-icons` is present, all `.drawer-nav-icon` elements in the modern-theme drawer are hidden via CSS
  4. When `show_icons` is true (default), icons display normally — no visual regression for existing users
  5. Unauthenticated `/` (landing content) is unaffected: landing page icons render regardless of any preference
**Plans**: TBD
**UI hint**: yes

### Phase 75: Preferences UI + Locale + Tests
**Goal**: Users can toggle icon display from `/preferences` with correct ja/en labels, and the full test suite is green
**Depends on**: Phase 74
**Requirements**: ICON-04, ICON-05
**Success Criteria** (what must be TRUE):
  1. `/preferences` shows a checkbox or toggle for icon display with a Japanese label (e.g. 「アイコンを表示する」) and an English equivalent
  2. Saving the preference with icons off persists `show_icons: false` and the page reloads without icons (body.no-icons present)
  3. Saving the preference with icons on persists `show_icons: true` and icons are visible again
  4. i18n parity test passes: every `show_icons`-related key present in `ja.yml` also exists in `en.yml` and vice versa
  5. Minitest covers: `Preference` model default (show_icons true), validation (nil rejected), and `PreferencesController` save round-trip (on→off, off→on)
  6. `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test` all pass (tri-suite green gate)
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 73. Data + Model Layer | 2/2 | Complete | 2026-05-17 |
| 74. CSS + View Layer | 2/2 | Complete | 2026-05-17 |
| 75. Preferences UI + Locale + Tests | 1/1 | Complete | 2026-05-17 |

---

<details>
<summary>✅ v1.22 — Landing at Root (Phases 70–72) — SHIPPED 2026-05-17</summary>

Full goals, success criteria, and notes: [milestones/v1.22-ROADMAP.md](milestones/v1.22-ROADMAP.md).

- [x] Phase 70: Routing Refactor & Code Cleanup — 2026-05-17
- [x] Phase 71: Test Contracts — 2026-05-17
- [x] Phase 72: Twitter uid Lookup Fix — 2026-05-17

</details>

<details>
<summary>✅ v1.21 — X Gadget Tweet Count Preference (Phase 69) — SHIPPED 2026-05-16</summary>

Full goals, success criteria, and notes: [milestones/v1.21-ROADMAP.md](milestones/v1.21-ROADMAP.md).

- [x] Phase 69: Tweet Count UI, Persistence & Tests — 2026-05-16

</details>

<details>
<summary>✅ v1.20 — Column Count Preference (Phases 67–68) — SHIPPED 2026-05-15</summary>

Full goals, success criteria, and notes: [milestones/v1.20-ROADMAP.md](milestones/v1.20-ROADMAP.md).

- [x] Phase 67: Data + Model Layer — Migration, Preference validation, Portal model column distribution — 2026-05-15
- [x] Phase 68: Preferences UI + View + SCSS + Tri-suite Gate — Select control, locale strings, welcome page 4-column layout, SCSS, full test sweep, gate — 2026-05-15

</details>

<details>
<summary>✅ v1.19 — HTTP test stubs → WebMock (Phases 64–66) — SHIPPED 2026-05-14</summary>

Full goals, success criteria, and notes: [milestones/v1.19-ROADMAP.md](milestones/v1.19-ROADMAP.md).

- [x] Phase 64: WebMock gem + global test configuration — 2026-05-14
- [x] Phase 65: Minitest — replace stub accessors with WebMock and/or Faraday `:test` — 2026-05-14
- [x] Phase 66: Cucumber hooks + delete stub file + cleanup + docs — 2026-05-14

</details>

<details>
<summary>✅ v1.18 — X (Twitter) Account Following (Phases 60–63) — SHIPPED 2026-05-14</summary>

Full goals, success criteria, and notes: [milestones/v1.18-ROADMAP.md](milestones/v1.18-ROADMAP.md).

- [x] Phase 60: User OAuth Token Persistence
- [x] Phase 61: XClient Service + Stub Contract
- [x] Phase 62: x_accounts Model + Management UI + Refresh Diff
- [x] Phase 63: Welcome Gadget + Show Action + Tri-Suite Gate

</details>

<details>
<summary>✅ v1.17 — Email Registration for X/Twitter Users (Phases 57–59) — SHIPPED 2026-05-13</summary>

Full goals, success criteria, and notes: [milestones/v1.17-ROADMAP.md](milestones/v1.17-ROADMAP.md).

- [x] Phase 57: Model Validation Foundation
- [x] Phase 58: Controller, Route, and Guards
- [x] Phase 59: View, Preferences Entry, Locale, and Tests

</details>

<details>
<summary>✅ v1.16 — Mastodon Account Following (Phases 52–56) — SHIPPED 2026-05-12</summary>

Full goals, success criteria, and notes: [milestones/v1.16-ROADMAP.md](milestones/v1.16-ROADMAP.md).

- [x] Phase 52: MastodonAccount Data Layer
- [x] Phase 53: CRUD Controller and Views
- [x] Phase 54: MastodonClient API Service and Show Action
- [x] Phase 55: Welcome Page Gadget Integration
- [x] Phase 56: Test Sweep and Verification Gate

</details>

---

*Last updated: 2026-05-17 — v1.23 roadmap created (Icon Display Preference, Phases 73–75)*
