# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.27 — Privacy Policy for X OAuth2 Email** — Phases 89–90 (active 2026-05-19)
- ✅ **v1.26 — Visited Link Tracking** — Phases 84–88 (shipped 2026-05-18) — [archived](milestones/v1.26-ROADMAP.md)
- ✅ **v1.25 — Portal Column Width Ratios** — Phases 80–83 (shipped 2026-05-18) — [archived](milestones/v1.25-ROADMAP.md)
- ✅ **v1.24 — Mobile Column Lazy Loading** — Phases 76–79 (shipped 2026-05-17) — [archived](milestones/v1.24-ROADMAP.md)
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

### v1.27 — Privacy Policy for X OAuth2 Email (Phases 89–90)

- [ ] **Phase 89: Static Policy Pages** — `/privacy` and `/terms` publicly accessible, bilingual, full content
- [ ] **Phase 90: OAuth2 Email Scope Wiring** — verify email scope in X OAuth2, store/overwrite real email in `from_omniauth`

## Phase Details

### Phase 89: Static Policy Pages
**Goal**: Unauthenticated users can read the privacy policy and terms of service in Japanese or English
**Depends on**: Nothing (no new data layer; public routes only)
**Requirements**: PRIV-01, PRIV-02, PRIV-03, TOS-01, TOS-02, TOS-03
**Success Criteria** (what must be TRUE):
  1. Visiting `/privacy` without signing in returns a 200 page with the privacy policy content
  2. Visiting `/terms` without signing in returns a 200 page with the terms of service content
  3. Both pages render content in Japanese when locale is `:ja` and in English when locale is `:en`
  4. The privacy policy content addresses data collected, purpose of X login, and email address handling
  5. The terms of service content addresses acceptable use, service availability, and account termination
**Plans**: TBD
**UI hint**: yes

### Phase 90: OAuth2 Email Scope Wiring
**Goal**: X OAuth2 sign-in captures and persists the user's real email address at sign-in and re-authentication
**Depends on**: Phase 89 (policy pages must exist for X Developer Portal approval before email scope is live)
**Requirements**: OAUTH-01, OAUTH-02, OAUTH-03
**Success Criteria** (what must be TRUE):
  1. The X OAuth2 authorization request includes the `users.email` scope (confirmed in OmniAuth config or X Developer Portal flow)
  2. A new user signing in via X OAuth2 has their real X email stored on `users.email` instead of a dummy address, when X provides one
  3. An existing user with a dummy-pattern email who re-authenticates via X OAuth2 has their `users.email` overwritten with the real X email
  4. An existing user with a real email who re-authenticates via X OAuth2 does not have their email changed
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 89. Static Policy Pages | 0/? | Not started | - |
| 90. OAuth2 Email Scope Wiring | 0/? | Not started | - |

---

<details>
<summary>✅ v1.26 — Visited Link Tracking (Phases 84–88) — SHIPPED 2026-05-18</summary>

Full goals, success criteria, and notes: [milestones/v1.26-ROADMAP.md](milestones/v1.26-ROADMAP.md).

- [x] Phase 84: Data Layer + Controller (2/2 plans) — 2026-05-18
- [x] Phase 85: CSS + View Helper (1/1 plan) — 2026-05-18
- [x] Phase 86: Gadget Controller + View Wiring (2/2 plans) — 2026-05-18
- [x] Phase 87: JS Click Handler (2/2 plans) — 2026-05-18
- [x] Phase 88: v1.26 closure — planning traceability sync (1/1 plan) — 2026-05-18

</details>

---

<details>
<summary>✅ v1.25 — Portal Column Width Ratios (Phases 80–83) — SHIPPED 2026-05-18</summary>

Full goals, success criteria, and notes: [milestones/v1.25-ROADMAP.md](milestones/v1.25-ROADMAP.md).

- [x] Phase 80: Column Width Data Model (1/1 plan) — 2026-05-18
- [x] Phase 81: Preferences Ratio Sliders (1/1 plan) — 2026-05-18
- [x] Phase 82: Desktop Portal Layout (1/1 plan) — 2026-05-18
- [x] Phase 83: Tests & Tri-suite Gate (1/1 plan) — 2026-05-18

</details>

---

<details>
<summary>✅ v1.24 — Mobile Column Lazy Loading (Phases 76–79) — SHIPPED 2026-05-17</summary>

Full goals, success criteria, and notes: [milestones/v1.24-ROADMAP.md](milestones/v1.24-ROADMAP.md).

- [x] Phase 76: `portal_lazy.js` Coordinator (1/1 plan) — 2026-05-17
- [x] Phase 77: Gadget Partial Wiring + Tab Hook (1/1 plan) — 2026-05-17
- [x] Phase 78: Contract Tests + Cucumber E2E (1/1 plan) — 2026-05-17
- [x] Phase 79: Note Gadget AJAX Extraction (1/1 plan) — 2026-05-17

</details>

*Last updated: 2026-05-19 — v1.27 roadmap created (Phases 89–90)*
