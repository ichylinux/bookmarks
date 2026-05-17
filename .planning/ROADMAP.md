# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.24 — Mobile Column Lazy Loading** — Phases 76–78 (in progress)
- ✅ **v1.23 — Icon Display Preference** — Phases 73–75 (shipped 2026-05-17) — [archived](milestones/v1.23-ROADMAP.md)
- ✅ **v1.22 — Landing at Root** — Phases 70–72 (shipped 2026-05-17) — [archived](milestones/v1.22-ROADMAP.md)
- ✅ **v1.21 — X Gadget Tweet Count Preference** — Phase 69 (shipped 2026-05-16) — [archived](milestones/v1.21-ROADMAP.md)
- ✅ **v1.20 — Column Count Preference** — Phases 67–68 (shipped 2026-05-15) — [archived](milestones/v1.20-ROADMAP.md)
- ✅ **v1.19 — HTTP test stubs → WebMock** — Phases 64–66 (shipped 2026-05-14) — [archived](milestones/v1.19-ROADMAP.md)
- ✅ **v1.18 — X (Twitter) Account Following** — Phases 60–63 (shipped 2026-05-14) — [archived](milestones/v1.18-ROADMAP.md)
- ✅ **v1.17 — Email Registration for X/Twitter Users** — Phases 57–59 (shipped 2026-05-13) — [archived](milestones/v1.17-ROADMAP.md)
- ✅ **v1.16 — Mastodon Account Following** — Phases 52–56 (shipped 2026-05-12) — [archived](milestones/v1.16-ROADMAP.md)
- ✅ **v1.15 — CSS & UI Polish** — Phases 49–51 (shipped 2026-05-11) — [archived](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Landing Page Changelog** — Phases 46–48 (shipped 2026-05-10) — [archived](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08) — [archived](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Landing Page for User Acquisition (Phase 1)** — Phases 40–42 (shipped 2026-05-08) — [archived](milestones/v1.12-ROADMAP.md)
- ✅ **v1.11 — Device-aware Font Size Baseline** — Phases 37–39 (shipped 2026-05-06) — [archived](milestones/v1.11-ROADMAP.md)
- ⚠️ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (deferred 2026-05-06)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04) — [archived](milestones/v1.7-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)

## Phases

### 🚧 v1.24 — Mobile Column Lazy Loading (In Progress)

**Milestone Goal:** On mobile, only load gadgets for the initially active column on page load; load each other column's gadgets exactly once when first switched to — never re-fetching within the same page session. Desktop behavior is completely unchanged.

- [ ] **Phase 76: `portal_lazy.js` Coordinator** — New coordinator module establishing `window.portalLazy`; zero behavior change on desktop or mobile yet
- [ ] **Phase 77: Gadget Partial Wiring + Tab Hook** — All AJAX partials register with the coordinator; `activateColumn` triggers lazy loads; mobile deferral active
- [ ] **Phase 78: Contract Tests + Cucumber E2E + Tri-suite Gate** — Minitest JS contracts; `@mobile_portal` Cucumber scenarios pass; tri-suite green gate

## Phase Details

### Phase 76: `portal_lazy.js` Coordinator
**Goal**: A new `portal_lazy.js` coordinator module exists and is available at `window.portalLazy` with the full public API, but causes zero visible behavior change — all gadgets still load immediately because no partial calls `register` yet
**Depends on**: Phase 75 (previous milestone)
**Requirements**: LAZY-01, LAZY-02, LAZY-03, LAZY-04, DESKTP-01, DESKTP-02, IMPL-01
**Success Criteria** (what must be TRUE):
  1. `window.portalLazy.register(columnIndex, loadFn)` and `window.portalLazy.loadColumn(index)` are callable from the browser console after page load
  2. On desktop (viewport >= 768px), calling `register` causes `loadFn` to fire immediately (pass-through behavior)
  3. On mobile, the coordinator reads the initial active column index synchronously at file parse time (before any `$(document).ready` fires)
  4. All three suites pass (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`) — no behavior regression
**Plans**: TBD

### Phase 77: Gadget Partial Wiring + Tab Hook
**Goal**: All AJAX gadget partials register their load functions with the coordinator instead of firing unconditionally on `$(document).ready`; `activateColumn` in `portal_mobile_tabs.js` drains each column's queue on first visit; mobile lazy loading is now live
**Depends on**: Phase 76
**Requirements**: IMPL-02, IMPL-03, IMPL-04
**Success Criteria** (what must be TRUE):
  1. On mobile page load, only AJAX requests for gadgets in the initially active column are fired — gadgets in other columns show "Loading..." until their column is visited
  2. Switching to a new column tab triggers exactly one round of AJAX requests for that column's gadgets; the content appears and is retained
  3. Switching back to an already-loaded column fires no new AJAX requests — the previously loaded content is displayed immediately
  4. On desktop, all gadget AJAX requests fire on page load as before — no change to desktop behavior
  5. Load state is marked synchronously before any `$.get` fires, so rapid tab switching never triggers duplicate in-flight requests for the same column
**Plans**: TBD

### Phase 78: Contract Tests + Cucumber E2E + Tri-suite Gate
**Goal**: Automated contract tests lock in the public shape of `window.portalLazy` and the `activateColumn` integration hook; existing `@mobile_portal` Cucumber scenarios confirm E2E correctness; all three suites pass cleanly
**Depends on**: Phase 77
**Requirements**: TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. A new `test/assets/portal_lazy_js_contract_test.rb` asserts that `window.portalLazy`, `register`, `loadColumn`, the mobile guard, and `STORAGE_KEY` are present in the source
  2. The extended `portal_mobile_tabs_js_contract_test.rb` asserts that `portalLazy.loadColumn` appears inside the `activateColumn` function body
  3. Existing `@mobile_portal` Cucumber scenarios (tab switch, swipe, localStorage restore) pass without modification
  4. `yarn run lint` green, `bin/rails test` green, `bundle exec rake dad:test` green (0 failed scenarios, confirmed stable across two runs per flake policy)
**Plans**: TBD
**UI hint**: yes

<details>
<summary>✅ v1.23 — Icon Display Preference (Phases 73–75) — SHIPPED 2026-05-17</summary>

Full goals, success criteria, and notes: [milestones/v1.23-ROADMAP.md](milestones/v1.23-ROADMAP.md).

- [x] Phase 73: Data + Model Layer (2/2 plans) — 2026-05-17
- [x] Phase 74: CSS + View Layer (2/2 plans) — 2026-05-17
- [x] Phase 75: Preferences UI + Locale + Tests (1/1 plan) — 2026-05-17

</details>

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
- [x] Phase 68: Preferences UI + View + SCSS + Tri-suite Gate — 2026-05-15

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

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 76. `portal_lazy.js` Coordinator | 0/TBD | Not started | - |
| 77. Gadget Partial Wiring + Tab Hook | 0/TBD | Not started | - |
| 78. Contract Tests + Cucumber E2E | 0/TBD | Not started | - |

---

*Last updated: 2026-05-17 — v1.24 roadmap created (Mobile Column Lazy Loading, Phases 76–78)*
