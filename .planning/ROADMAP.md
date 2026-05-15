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
- ✅ **v1.20 — Column Count Preference** — Phases 67–68 (shipped 2026-05-15)

## Phases

### v1.20 — Column Count Preference

- [x] **Phase 67: Data + Model Layer** — Migration, Preference validation, Portal model column distribution — 2026-05-15
- [x] **Phase 68: Preferences UI + View + SCSS + Tri-suite Gate** — Select control, locale strings, welcome page 4-column layout, SCSS, full test sweep, gate — 2026-05-15

## Phase Details

### Phase 67: Data + Model Layer
**Goal**: The portal column count is stored per user and drives column distribution in the model — no hardcoded 3
**Depends on**: Nothing (first phase of v1.20)
**Requirements**: COL-01, COL-04, COL-06
**Success Criteria** (what must be TRUE):
  1. A new `preferences.portal_column_count` column exists (integer, NOT NULL, default 3); existing users' rows are migrated without error
  2. `Preference` model rejects any value outside [3, 4] and accepts 3 and 4 as valid
  3. `Portal#portal_columns` returns an array of 3 or 4 sub-arrays driven by the user's stored preference, not a hardcoded 3
  4. When a user's preference is 4 but a `PortalLayout` record has `column_no >= 3`, `portal_columns` skips that record and redistributes it via `i % column_count` fallback — original column-3 positions are preserved and restored when preference switches back to 4
  5. `bin/rails test` is green after Phase 67 changes (model validation, portal distribution, downgrade path all covered by Minitest)
**Plans**: 2 plans
Plans:
- [ ] 067-01-PLAN.md — Migration + Preference validation + Portal model parameterization
- [ ] 067-02-PLAN.md — Minitest coverage (portal_test.rb + preference_test.rb additions)

### Phase 68: Preferences UI + View + SCSS + Tri-suite Gate
**Goal**: Users can select and save a column count from the preferences screen; the welcome page renders 3 or 4 columns correctly across all themes; tri-suite is green
**Depends on**: Phase 67
**Requirements**: COL-02, COL-03, COL-05, COL-07, COL-08
**Success Criteria** (what must be TRUE):
  1. The preferences page shows a select control with "3列 / 4列" (ja) or "3 columns / 4 columns" (en) options; the label renders in both locales
  2. Submitting the preferences form with a new column count persists the value; reloading the preferences page shows the saved selection
  3. The welcome page renders exactly 3 or 4 `portal-column` section elements matching the user's preference; switching from 3 to 4 leaves columns 0–2 unchanged and column 3 empty
  4. Portal column CSS in all applicable theme files supports 4-column desktop layout without breaking 3-column or mobile tab-strip behavior
  5. `yarn run lint` + `bin/rails test` (preference validation, controller save, portal distribution, locale key parity) + `bundle exec rake dad:test` all green
**Plans**: 2 plans
Plans:
- [ ] 068-01-PLAN.md — Controller strong params + locale keys + preferences view + portal SCSS + partial class + default_preference fix + hooks reset
- [ ] 068-02-PLAN.md — Minitest controller + layout tests + preference_params helper + Cucumber scenario + tri-suite gate
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 67. Data + Model Layer | 2/2 | ✅ Complete | 2026-05-15 |
| 68. Preferences UI + View + SCSS + Tri-suite Gate | 2/2 | ✅ Complete | 2026-05-15 |

---

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

*Last updated: 2026-05-15 — Phase 68 planned (2 plans, 2 waves)*
