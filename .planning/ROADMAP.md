# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.26 — Visited Link Tracking** — Phases 84–87 (active 2026-05-18)
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

### v1.26 — Visited Link Tracking (Phases 84–87)

- [x] **Phase 84: Data Layer + Controller** — `visited_links` migration, `VisitedLink` model with `record!`/`urls_for`/`normalize_url`, `POST /visited_links` endpoint, Cucumber `Before` hook update
- [x] **Phase 85: CSS + View Helper** — `.link--visited` in `common.css.scss`, `ApplicationHelper#visited_link_class`, unit + contract tests
- [ ] **Phase 86: Gadget Controller + View Wiring** — `@visited_urls` Set in 3 show actions, `class:` in 3 show partials, controller tests for class presence/absence
- [ ] **Phase 87: JS Click Handler** — `visited_links.js` IIFE with namespaced delegated click handler, optimistic `addClass`, fire-and-forget `$.post`, E2E verification

## Phase Details

### Phase 84: Data Layer + Controller
**Goal**: The server can persist and retrieve visited URLs for a user with no race conditions or duplicates
**Depends on**: Nothing (first phase of milestone)
**Requirements**: DAT-01, DAT-02, DAT-03, DAT-04
**Success Criteria** (what must be TRUE):
  1. A migration creates `visited_links` with `(user_id, url varchar(2083), visited_at)` and a unique index on `(user_id, url(768))`
  2. `VisitedLink.record!(user, url)` stores a visit idempotently — calling it twice for the same user+URL results in exactly one row
  3. `VisitedLink.normalize_url(url)` strips the fragment portion and is called identically in `record!` and `urls_for`
  4. `POST /visited_links` with a valid `url` param returns 204 and records a visit; unauthenticated requests return 401
  5. The Cucumber `Before` hook calls `VisitedLink.delete_all` so visited-state does not leak between scenarios
**Plans**: 2 plans
Plans:
- [x] 84-01-PLAN.md — Migration + VisitedLink model + model unit tests (DAT-01, DAT-02, DAT-03)
- [x] 84-02-PLAN.md — Controller + route + Cucumber hook + controller integration tests (DAT-04)
**UI hint**: no

### Phase 85: CSS + View Helper
**Goal**: The visual vocabulary for visited links exists and is verifiable before any gadget wires it in
**Depends on**: Phase 84
**Requirements**: VIS-01, VIS-02
**Success Criteria** (what must be TRUE):
  1. `.link--visited` is defined in `common.css.scss` with a specificity high enough to override existing theme `:visited` rules across all three themes (classic, modern, simple)
  2. `ApplicationHelper#visited_link_class(visited_set, url)` returns `"link--visited"` when the normalized URL is a member of the set and returns an empty string otherwise
  3. A contract test asserts the CSS selector exists in `common.css.scss`; a unit test covers both truthy and falsy branches of the helper
**Plans**: 1 plan
Plans:
- [ ] 85-01-PLAN.md — CSS `.link--visited` rule + `visited_link_class` helper + unit tests + contract test (VIS-01, VIS-02)
**UI hint**: yes

### Phase 86: Gadget Controller + View Wiring
**Goal**: Gadget AJAX responses render visited links with the CSS class based on server-side state, without N+1 queries
**Depends on**: Phase 85
**Requirements**: GAD-01, GAD-02, GAD-03, GAD-04
**Success Criteria** (what must be TRUE):
  1. After recording a visit, reloading the feed gadget renders the visited link's `<a>` tag with `class="link--visited"`
  2. After recording a visit, reloading the Mastodon gadget renders the toot link's `<a>` tag with `class="link--visited"`
  3. After recording a visit, reloading the X gadget renders the tweet link's `<a>` tag with `class="link--visited"`
  4. Each of the three show actions issues exactly one `VisitedLink.urls_for` query per request — not one per link — and unvisited links carry no visited class
**Plans**: 2 plans
Plans:
- [ ] 86-01-PLAN.md — Helper nil-guard + before_action in 3 controllers + class: in 3 views (GAD-01, GAD-02, GAD-03, GAD-04)
- [ ] 86-02-PLAN.md — Controller integration tests: visited class present/absent + N+1 query guard for all 3 gadgets (GAD-01, GAD-02, GAD-03, GAD-04)
**UI hint**: yes

### Phase 87: JS Click Handler
**Goal**: Clicking a content link in any gadget immediately applies the visited style and records the visit server-side, completing the end-to-end feature
**Depends on**: Phase 86
**Requirements**: JS-01, JS-02
**Success Criteria** (what must be TRUE):
  1. Clicking a gadget `ol li a` link triggers a fire-and-forget `$.post` to `POST /visited_links` — the click is not blocked and the link navigates normally
  2. The clicked link element gains the `.link--visited` CSS class optimistically at click time (before the POST completes)
  3. JS URL normalization strips the fragment from `this.href` before posting, matching `VisitedLink.normalize_url` behavior
  4. The handler uses `$(document).on('click.visitedLinks', ...)` delegation so it fires correctly on AJAX-injected gadget content without rebinding
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 84. Data Layer + Controller | 0/2 | Planned | - |
| 85. CSS + View Helper | 0/1 | Not started | - |
| 86. Gadget Controller + View Wiring | 0/1 | Not started | - |
| 87. JS Click Handler | 0/1 | Not started | - |

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

---

*Last updated: 2026-05-18 — Phase 84 planned (2 plans: migration+model, controller+tests)*
