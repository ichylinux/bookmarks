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
- ✅ **v1.21 — X Gadget Tweet Count Preference** — Phase 69 (shipped 2026-05-16) — [archived](milestones/v1.21-ROADMAP.md)
- 🔄 **v1.22 — Landing at Root** — Phases 70–72 (active)

## Phases

### v1.22 — Landing at Root (Phases 70–72)

- [ ] **Phase 70: Routing Refactor & Code Cleanup** — Inline landing for guests at `/`, remove `/landing` route and `LandingController`, remove `redirect_guest_to_landing` guard
- [ ] **Phase 71: Test Contracts** — Update existing redirect assertions, add regression coverage for both auth states at `/`
- [ ] **Phase 72: Twitter uid Lookup Fix** — Switch `from_omniauth` Twitter branch from name to uid lookup, Minitest coverage

## Phase Details

### Phase 70: Routing Refactor & Code Cleanup
**Goal**: Unauthenticated users see landing content inline at `/` with no redirect; `/landing` route and supporting code removed
**Depends on**: Nothing (Phase 69 complete)
**Requirements**: ROOT-01, ROOT-02, ROOT-03, ROOT-04
**Success Criteria** (what must be TRUE):
  1. An unauthenticated browser request to `/` receives a 200 response with landing page HTML — no 302 to `/landing`
  2. An authenticated browser request to `/` still receives the dashboard with a 200 response (behavior unchanged)
  3. Requesting `/landing` returns a routing error (no route match) — the URL is gone from the app
  4. `WelcomeController` contains no `redirect_guest_to_landing` callback; `LandingController` file and its route entry are deleted
**Plans**: TBD

### Phase 71: Test Contracts
**Goal**: All tests reflect inline rendering; regression contracts confirm both auth states at `/` in both locales
**Depends on**: Phase 70
**Requirements**: ROOT-05
**Success Criteria** (what must be TRUE):
  1. No existing test asserts a redirect from `/` to `/landing`; any such assertions are updated to assert 200 + inline content
  2. Integration tests assert that an unauthenticated request to `/` renders landing content (not a redirect)
  3. Integration tests assert that an authenticated request to `/` renders the dashboard (unchanged)
  4. Tri-suite gate passes: `yarn run lint` green, `bin/rails test` green, `bundle exec rake dad:test` green (0 failed scenarios)
**Plans**: TBD

### Phase 72: Twitter uid Lookup Fix
**Goal**: `User.from_omniauth` Twitter branch identifies existing users by `uid`, eliminating the deferred name-based lookup bug
**Depends on**: Nothing (independent of Phases 70–71)
**Requirements**: XAUTH-01, XAUTH-02
**Success Criteria** (what must be TRUE):
  1. `User.from_omniauth` for Twitter finds an existing user record by `uid` (not `name`)
  2. Minitest covers the found-by-uid path: existing user is returned without creating a duplicate
  3. Minitest covers the not-found path: a new user record is created when no uid match exists
  4. `bin/rails test` remains green with the new coverage included
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 70. Routing Refactor & Code Cleanup | 0/? | Not started | - |
| 71. Test Contracts | 0/? | Not started | - |
| 72. Twitter uid Lookup Fix | 0/? | Not started | - |

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

*Last updated: 2026-05-17 — v1.22 roadmap created (Landing at Root, Phases 70–72)*
