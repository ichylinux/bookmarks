# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.29 — Admin X API Usage Report** — Phases 96–100 (in progress)
- ✅ **v1.28 — Account Self-Service Deletion** — Phases 91–95 (shipped 2026-05-20) — [archived](milestones/v1.28-ROADMAP.md)
- ✅ **v1.27 — Privacy Policy for X OAuth2 Email** — Phases 89–90 (shipped 2026-05-19) — [archived](milestones/v1.27-ROADMAP.md)
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

### 🚧 v1.29 — Admin X API Usage Report (In Progress)

**Milestone Goal:** Give admins a view of X (Twitter) API usage across all users — request counts, rate-limit consumption, per-user breakdowns — using the existing Rails stack with no new gems.

- [ ] **Phase 96: Data Layer** — `x_api_calls` table, `XApiCall` model, `rate_limit_remaining` column (2 plans ready)
- [ ] **Phase 97: Instrumentation + Cucumber Isolation** — XClient instrumentation hooks and `Before` hook cleanup (atomic unit)
- [ ] **Phase 98: Admin Access Gate** — `Admin::BaseController` with `require_admin` before_action and negative integration tests
- [ ] **Phase 99: Report View + Locale + Drawer Nav** — per-user report table, date-range filter, sort toggle, ja/en locale strings, drawer nav link
- [ ] **Phase 100: Tri-Suite Verification Closure** — full `yarn run lint && bin/rails test && bundle exec rake dad:test` gate

## Phase Details

### Phase 96: Data Layer
**Goal**: The `x_api_calls` schema and `XApiCall` model exist and can record and aggregate X API call events
**Depends on**: Nothing (extends existing schema)
**Requirements**: DATA-01, DATA-02, DATA-03
**Success Criteria** (what must be TRUE):
  1. Migration creates `x_api_calls` table with `user_id`, `endpoint`, `success`, `error_code`, `called_at`, `rate_limit_remaining` columns and the `(user_id, called_at)` composite index
  2. `XApiCall.record!` creates a row with correct values when called with a user_id, endpoint, success flag, and optional error_code/rate_limit_remaining
  3. `XApiCall.usage_summary` returns per-user aggregates (total calls, last called_at, error count) correctly filtering by `since:` date parameter
  4. Minitest model unit tests are green for all three behaviors above
**Plans**: 2 plans
Plans:
- [ ] 96-01-PLAN.md — Migration + Model (x_api_calls table, XApiCall record! and usage_summary)
- [ ] 96-02-PLAN.md — Minitest model tests (DATA-01/02/03 coverage)

### Phase 97: Instrumentation + Cucumber Isolation
**Goal**: Every X API call made through `XAccountsController` writes an `XApiCall` row, and Cucumber scenarios are isolated from row accumulation
**Depends on**: Phase 96
**Requirements**: INST-01, INST-02, INST-03
**Success Criteria** (what must be TRUE):
  1. `XAccountsController#refresh` writes an `XApiCall` row on both the success path and the error path after `fetch_following` returns
  2. `XAccountsController#show` writes an `XApiCall` row on both the success path and the error path after `fetch_recent_tweets` returns
  3. The Cucumber `Before` hook in `features/support/hooks.rb` includes `XApiCall.delete_all` so no rows from one scenario are visible in the next
  4. Existing `@x_gadget` Cucumber scenarios continue to pass with the instrumentation in place
**Plans**: TBD

### Phase 98: Admin Access Gate
**Goal**: Admin-namespaced routes exist and are protected — non-admins and guests cannot reach them
**Depends on**: Phase 96
**Requirements**: ADMIN-01
**Success Criteria** (what must be TRUE):
  1. An unauthenticated request to `GET /admin/x_api_usages` redirects to the sign-in page (Devise default)
  2. An authenticated request from a non-admin user to `GET /admin/x_api_usages` receives a 404 response
  3. An authenticated request from an admin user to `GET /admin/x_api_usages` receives a 200 response
  4. Both negative cases are covered by dedicated Minitest integration tests that assert the correct response codes
**Plans**: TBD

### Phase 99: Report View + Locale + Drawer Nav
**Goal**: Admin can view, filter, and sort the X API usage report in their preferred language, and the drawer nav provides a link when signed in as admin
**Depends on**: Phase 97, Phase 98
**Requirements**: REPORT-01, REPORT-02, REPORT-03, LOCALE-01, ADMIN-02
**Success Criteria** (what must be TRUE):
  1. Admin visiting `/admin/x_api_usages` sees a table of per-user rows with: email (or Twitter handle for dummy-email accounts), total call count, last called at timestamp, and error count
  2. Admin can submit a date-range filter (from/to date inputs) and the table updates to show only calls within that range, with no schema changes required
  3. Admin can click a column header (total calls or last called at) to toggle sort order between ascending and descending
  4. All report UI strings — page title, table headers, filter labels, empty-state message — have corresponding ja and en locale keys, and the i18n parity test passes
  5. The drawer nav shows a link to `/admin/x_api_usages` only when `user_signed_in? && current_user.admin?` is true; non-admin and guest users see no admin link
**Plans**: TBD
**UI hint**: yes

### Phase 100: Tri-Suite Verification Closure
**Goal**: All three test suites pass with v1.29 changes in place, confirming no regressions
**Depends on**: Phase 99
**Requirements**: (no new requirements — verification gate)
**Success Criteria** (what must be TRUE):
  1. `yarn run lint` exits 0 with no new ESLint violations
  2. `bin/rails test` runs all Minitest cases with 0 failures
  3. `bundle exec rake dad:test` runs all Cucumber scenarios with 0 failed scenarios on first run
  4. A Cucumber scenario exercises the full admin report path: sign in as admin, visit `/admin/x_api_usages`, assert per-user row is present; a second scenario confirms non-admin gets 404
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 96. Data Layer | 0/2 | Planned | - |
| 97. Instrumentation + Cucumber Isolation | 0/TBD | Not started | - |
| 98. Admin Access Gate | 0/TBD | Not started | - |
| 99. Report View + Locale + Drawer Nav | 0/TBD | Not started | - |
| 100. Tri-Suite Verification Closure | 0/TBD | Not started | - |

---

<details>
<summary>✅ v1.28 — Account Self-Service Deletion (Phases 91–95) — SHIPPED 2026-05-20</summary>

Full goals, success criteria, and notes: [milestones/v1.28-ROADMAP.md](milestones/v1.28-ROADMAP.md).

- [x] Phase 91: Policy Wording — 90-Day Retention — 2026-05-20
- [x] Phase 92: User Soft-Delete Data Layer — 2026-05-20
- [x] Phase 93: Preferences Deletion UI + Flow — 2026-05-20
- [x] Phase 94: Tests & Tri-suite Gate — 2026-05-20
- [x] Phase 95: Closure: retroactive verification artifacts for Phases 92–94 — 2026-05-20

</details>

---

<details>
<summary>✅ v1.27 — Privacy Policy for X OAuth2 Email (Phases 89–90) — SHIPPED 2026-05-19</summary>

- [x] Phase 89: Static Policy Pages (2/2 plans) — 2026-05-19
- [x] Phase 90: OAuth2 Email Scope Wiring (1/1 plan) — 2026-05-19

</details>

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

*Last updated: 2026-05-20 — Phase 96 planned (2 plans: 96-01, 96-02)*
