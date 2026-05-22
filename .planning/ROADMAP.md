# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.31 — X Account Manual Add (Non-Following)** — Phases 104–108 (active)
- ✅ **v1.30 — Admin User Management Screen** — Phases 101–103.1 (shipped 2026-05-22) — [archived](milestones/v1.30-ROADMAP.md)
- ✅ **v1.29 — Admin X API Usage Report** — Phases 96–100 (shipped 2026-05-21) — [archived](milestones/v1.29-ROADMAP.md)
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

### v1.31 — X Account Manual Add (Non-Following)

- [x] **Phase 104: Schema, Model & Refresh Guard** — `manually_added` migration + `upsert_manual!` + refresh soft-delete protection
- [ ] **Phase 105: XClient Lookup Service** — `XClient#lookup_user_by_username` with full error-symbol coverage
- [x] **Phase 106: Controller Action, Routes & Locales** — `POST /x_accounts/lookup_and_add` with all 7 flash states in ja/en
- [x] **Phase 107: View Form & Manually-Added Badge** — inline handle input form + account card indicator
- [ ] **Phase 108: Full Test Coverage & Tri-suite Gate** — Minitest + Cucumber E2E + green gate

---

<details>
<summary>✅ v1.30 — Admin User Management Screen (Phases 101–103.1) — SHIPPED 2026-05-22</summary>

Full goals, success criteria, and notes: [milestones/v1.30-ROADMAP.md](milestones/v1.30-ROADMAP.md).

- [x] Phase 101: Admin Users Controller & Route (1/1 plan) — 2026-05-21
- [x] Phase 102: User List View (1/1 plan) — 2026-05-21
- [x] Phase 103: Navigation, Locale & Tri-suite Gate (1/1 plan) — 2026-05-21
- [x] Phase 103.1: Retroactive Verification Artifacts for Phases 101–103 (INSERTED) (1/1 plan) — 2026-05-22

</details>

---

<details>
<summary>✅ v1.29 — Admin X API Usage Report (Phases 96–100) — SHIPPED 2026-05-21</summary>

Full goals, success criteria, and notes: [milestones/v1.29-ROADMAP.md](milestones/v1.29-ROADMAP.md).

- [x] Phase 96: Data Layer (2/2 plans) — 2026-05-21
- [x] Phase 97: Instrumentation + Cucumber Isolation (1/1 plan) — 2026-05-21
- [x] Phase 98: Admin Access Gate (1/1 plan) — 2026-05-21
- [x] Phase 99: Report View + Locale + Drawer Nav (1/1 plan) — 2026-05-21
- [x] Phase 100: Tri-Suite Verification Closure (1/1 plan) — 2026-05-21

</details>

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

## Phase Details

### Phase 104: Schema, Model & Refresh Guard
**Goal**: The data layer correctly stores and protects manually-added accounts — `manually_added` column exists, `upsert_manual!` creates/restores accounts idempotently, and the refresh soft-delete loop never deletes manually-added rows
**Depends on**: Nothing (first phase of v1.31)
**Requirements**: XMAN-01, XMAN-02, XMAN-03
**Success Criteria** (what must be TRUE):
  1. A database migration adds `manually_added boolean NOT NULL DEFAULT false` to `x_accounts`; existing rows default to `false` with no data loss
  2. Calling `XAccount.upsert_manual!(user:, x_user_id:, ...)` on a new record creates a row with `manually_added: true, deleted: false`
  3. Calling `upsert_manual!` a second time (or on a soft-deleted row) restores it without creating a duplicate — `manually_added: true` is always set unconditionally
  4. Running `refresh_cache_from_items!` does not soft-delete rows where `manually_added: true`; a Minitest covering this guard passes
  5. Refreshing a follow-synced account that also matches a manually-added row does not flip `manually_added` to `false`
**Plans**: 2 plans
Plans:
- [x] 104-01-PLAN.md — Add manually_added migration to x_accounts (beebee2, 2026-05-22)
- [x] 104-02-PLAN.md — upsert_manual! + refresh guard + Minitest (bfacd43, a98b6f0, 2026-05-22)

### Phase 105: XClient Lookup Service
**Goal**: `XClient` can resolve a public X handle to a user record, returning a structured result or a typed error symbol, fully covered by isolated service tests
**Depends on**: Phase 104
**Requirements**: XSVC-01, XSVC-02
**Success Criteria** (what must be TRUE):
  1. `XClient#lookup_user_by_username(username: '@handle')` strips the leading `@` and calls `GET /2/users/by/username/handle` via the existing Bearer auth connection
  2. A successful 200 response returns `{ success: true, item: { ... } }` with the API-returned canonical `username` (not the raw user input)
  3. HTTP 404 or 400 maps to `{ success: false, error: :not_found }`; HTTP 403 maps to `:suspended`; HTTP 429 maps to `:rate_limited`; all other errors map to `:api_error`
  4. Minitest service tests covering all response codes (200, 404, 400, 403, 429, timeout, network error) pass using Faraday `:test` adapter stubs
**Plans**: 1 plan
Plans:
- [x] 105-01-PLAN.md — lookup_user_by_username + parse_lookup_response + 8 Minitest cases

### Phase 106: Controller Action, Routes & Locales
**Goal**: Users can POST a handle to `/x_accounts/lookup_and_add` and receive a localized flash response for every success and error state
**Depends on**: Phase 105
**Requirements**: XCTL-01, XCTL-02
**Success Criteria** (what must be TRUE):
  1. `POST /x_accounts/lookup_and_add` is routed to `XAccountsController#lookup_and_add` and is gated by `require_twitter_linked`
  2. A successful add redirects to `/x_accounts` with a success flash message in both Japanese and English
  3. Each of the 6 error states (not found, already active, rate limited, suspended, blank input, network error) redirects with a distinct localized flash alert in both ja and en
  4. Every API call from this action is instrumented via `record_x_api_call`
  5. Controller integration tests for all 7 flash states (1 success + 6 errors) pass
**Plans**: 1 plan
Plans:
- [ ] 108-01-PLAN.md — Add @x_manual_add hook + feature file + step definitions + run tri-suite gate
**UI hint**: yes

### Phase 107: View Form & Manually-Added Badge
**Goal**: The `/x_accounts` index page has a usable handle input form and every manually-added account card displays a visual indicator of its origin
**Depends on**: Phase 106
**Requirements**: XVIEW-01, XVIEW-02, XVIEW-03
**Success Criteria** (what must be TRUE):
  1. A `form_with` handle input form appears on the `/x_accounts` index page with a text field and submit button; no new JavaScript is required
  2. Submitting `@handle` (or `handle`) POSTs to `lookup_and_add_x_accounts_path` and the page redirects with a flash
  3. Each account card for a `manually_added: true` account shows a visible badge or label; the label is rendered in Japanese when the UI locale is `ja` and in English when `en`
  4. Follow-synced account cards do not show the manually-added badge
  5. All new locale keys for form labels, button text, and the badge pass the i18n parity test (ja/en key sets match)
**Plans**: 1 plan
Plans:
- [ ] 108-01-PLAN.md — Add @x_manual_add hook + feature file + step definitions + run tri-suite gate
**UI hint**: yes

### Phase 108: Full Test Coverage & Tri-suite Gate
**Goal**: All v1.31 behavior is verified end-to-end and the tri-suite gate is green
**Depends on**: Phase 107
**Requirements**: XTEST-01, XTEST-02
**Success Criteria** (what must be TRUE):
  1. Minitest: model tests for `manually_added` flag behavior + refresh guard, service tests for all `lookup_user_by_username` response codes, and controller integration tests for all error paths all pass
  2. A Cucumber E2E happy-path scenario (enter a handle → account appears in the list → click Refresh → account survives) passes
  3. A Cucumber not-found error scenario (enter a nonexistent handle → not-found flash appears) passes
  4. The WebMock stub for `/2/users/by/username/` is registered in the relevant Cucumber `Before` hook so no `NetConnectNotAllowedError` occurs
  5. `yarn run lint && bin/rails test && bundle exec rake dad:test` all exit 0 with 0 failures
**Plans**: 1 plan
Plans:
- [ ] 108-01-PLAN.md — Add @x_manual_add hook + feature file + step definitions + run tri-suite gate

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 104. Schema, Model & Refresh Guard | 2/2 | Complete | 2026-05-22 |
| 105. XClient Lookup Service | 1/1 | Complete    | 2026-05-22 |
| 106. Controller Action, Routes & Locales | 1/1 | Complete | 2026-05-22 |
| 107. View Form & Manually-Added Badge | 1/1 | Complete | 2026-05-22 |
| 108. Full Test Coverage & Tri-suite Gate | 0/1 | Not started | - |

*Last updated: 2026-05-22 — Phase 108 planned (1 plan, 1 wave)*
