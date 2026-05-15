# Roadmap: Bookmarks

## Milestones

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
- ✅ **v1.21 — X Gadget Tweet Count Preference** — Phase 69 (shipped 2026-05-16)

## Phases

### v1.21 — X Gadget Tweet Count Preference

- [x] **Phase 69: Tweet Count UI, Persistence & Tests** - Add display_count number field to /x_accounts form, permit in strong params, and cover with controller + model tests — 2026-05-16

## Phase Details

### Phase 69: Tweet Count UI, Persistence & Tests
**Goal**: Users can view and change the per-account tweet display count on the /x_accounts management page, with the count persisted and honored by the welcome page X gadget
**Depends on**: Nothing (single-phase milestone; schema column, model callback, validation, locale keys, and XClient limit wiring are already in place)
**Requirements**: XCNT-01, XCNT-02, XCNT-03, XCNT-04, XCNT-05, XCNT-06
**Success Criteria** (what must be TRUE):
  1. The /x_accounts management page displays the current display_count value for each X account card
  2. User can edit the display_count via a number input on the /x_accounts page, submit the form, and the new value is saved to the database
  3. The welcome page X gadget fetches and renders the number of tweets matching the saved per-account display_count (not a hardcoded default)
  4. PATCH /x_accounts/:id with a valid display_count param succeeds — display_count is permitted in x_account_params strong params
  5. A Minitest controller test asserts that PATCH /x_accounts/:id persists a changed display_count value
  6. A Minitest model test covers the display_count numericality validation (integer, greater than 0) and the set_display_count_default before_save callback
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 69. Tweet Count UI, Persistence & Tests | 1/1 | Complete | 2026-05-16 |

---

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

*Last updated: 2026-05-16 — v1.21 shipped (X Gadget Tweet Count Preference, Phase 69 complete)*
