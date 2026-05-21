# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.30 — Admin User Management Screen** — Phases 101–103 (active)
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

### v1.30 — Admin User Management Screen (Phases 101–103)

**Milestone goal:** Add an admin-only read-only user list at `/admin/users` showing all registered accounts with key identity and activity fields.

**3 phases** | **6 requirements** | All covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 101 | Admin Users Controller & Route | Gated route + controller for admin user list | USR-01 | 2 |
| 102 | User List View | Render all user rows with every required column | USR-02, USR-03, USR-04 | 3 |
| 103 | Navigation, Locale & Tri-suite Gate | Drawer nav, bilingual locale, green tri-suite closure | USR-05, USR-06 | 3 |

---

#### Phase 101: Admin Users Controller & Route

**Goal:** Create `Admin::UsersController#index`, route `/admin/users`, apply `require_admin` gate.

**Requirements:** USR-01

**Success criteria:**
1. `GET /admin/users` returns 200 for admin users, 404 for non-admins, redirect to sign-in for guests
2. Controller inherits from `Admin::BaseController` and reuses the `require_admin` gate from v1.29

**Key deliverables:**
- `app/controllers/admin/users_controller.rb`
- Route: `namespace :admin { resources :users, only: [:index] }`
- Placeholder view (populated in Phase 102)
- Minitest: 3 access-control scenarios

---

#### Phase 102: User List View

**Goal:** Render the user list table with all required columns, resolving `x_user_name` from XAccount and displaying `admin_flag` with a clear indicator.

**Requirements:** USR-02, USR-03, USR-04

**Success criteria:**
1. Table displays all user records including soft-deleted in columns: id, email, x_user_name, admin_flag, last_sign_in_at, created_at, updated_at
2. `x_user_name` shows `x_username` from `user.x_accounts.first` or blank; `User.all.includes(:x_accounts)` prevents N+1
3. `admin_flag` renders ✓ for admins and — for regular users

**Key deliverables:**
- View table with all 7 columns
- Controller: `@users = User.all.includes(:x_accounts).order(:id)`
- Helper or view logic for `x_user_name` and `admin_flag` display
- Minitest: column structure, data presence, soft-deleted visibility, blank fallback, flag indicator

---

#### Phase 103: Navigation, Locale & Tri-suite Gate

**Goal:** Add drawer nav link for admins, wire all UI strings through ja/en locale YAML, close with green tri-suite.

**Requirements:** USR-05, USR-06

**Success criteria:**
1. Drawer nav shows link to `/admin/users` for admins alongside `/admin/x_api_usages`; absent for non-admins
2. All column headers and UI chrome use locale YAML keys; i18n parity test passes
3. Tri-suite gate green: `yarn run lint` ✓ · `bin/rails test` ✓ · `bundle exec rake dad:test` ✓

**Key deliverables:**
- Drawer partial updated with admin users nav link
- `config/locales/ja.yml` and `en.yml` — `admin.users.*` keys
- i18n parity test for new keys
- Cucumber scenario: admin navigates to user list, sees user table
- Tri-suite closure

---

- [ ] Phase 101: Admin Users Controller & Route
- [ ] Phase 102: User List View
- [ ] Phase 103: Navigation, Locale & Tri-suite Gate

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

*Last updated: 2026-05-21 — v1.30 Admin User Management Screen roadmap created (Phases 101–103)*
