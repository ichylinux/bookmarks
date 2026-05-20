# Roadmap: Bookmarks

## Milestones

- 🚧 **v1.28 — Account Self-Service Deletion** — Phases 91–95 (in progress) — see Phases below
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

### v1.28 — Account Self-Service Deletion (Phases 91–95)

- [x] Phase 91: Policy Wording — 90-Day Retention — 2026-05-20
- [x] Phase 92: User Soft-Delete Data Layer — 2026-05-20
- [x] Phase 93: Preferences Deletion UI + Flow — 2026-05-20
- [x] Phase 94: Tests & Tri-suite Gate — 2026-05-20
- [ ] Phase 95: Closure: retroactive verification artifacts for Phases 92–94

## Phase Details (v1.28)

### Phase 91: Policy Wording — 90-Day Retention

**Goal:** Public privacy policy and terms (ja/en) accurately describe two-stage deletion: immediate deactivation, permanent erasure within 90 days.
**Depends on:** Nothing
**Requirements:** POLICY-01, POLICY-02

**Success Criteria:**
1. `/privacy` data retention section mentions immediate access stop and 90-day permanent erasure window (ja + en)
2. `/terms` termination section matches: immediate deactivation, 90-day purge, no access during retention (ja + en)
3. Wording no longer claims instantaneous deletion of all bookmarks/feeds at button press
4. Locale key parity test still passes

### Phase 92: User Soft-Delete Data Layer

**Goal:** `users` table supports soft-delete timestamp; `User` can be deactivated with PII stripped while related rows remain.
**Depends on:** Phase 91 (policy must match behavior before UI ships)
**Requirements:** ACCT-03, ACCT-04, ACCT-05, ACCT-06

**Success Criteria:**
1. Migration adds `deleted` (boolean, default false) and `deleted_at` (datetime, nullable) on `users`
2. `User#destroy_account!` (or equivalent) sets deleted flags, clears OAuth tokens and anonymizes email
3. Deleted user fails `active_for_authentication?` / OAuth lookup treats as absent for sign-in
4. `Bookmark` / `Note` / etc. row counts unchanged after user deletion in tests

### Phase 93: Preferences Deletion UI + Flow

**Goal:** User can request account deletion from `/preferences` with confirmation and lands signed out.
**Depends on:** Phase 92
**Requirements:** ACCT-01, ACCT-02

**Success Criteria:**
1. Preferences page shows a danger-zone section with delete action and warning copy (ja/en)
2. Confirmation step required before `destroy_account!` runs
3. Successful deletion signs user out and redirects to guest-visible page (e.g. `/`)
4. Deleted user cannot reach `/preferences` or dashboard when attempting sign-in

### Phase 94: Tests & Tri-suite Gate

**Goal:** Automated coverage and green lint / Minitest / Cucumber.
**Depends on:** Phase 93
**Requirements:** ACCT-07, ACCT-08

**Success Criteria:**
1. Minitest: deletion, auth block, PII anonymization, transactional data retained
2. Cucumber: end-to-end delete from preferences
3. `yarn run lint && bin/rails test && bundle exec rake dad:test` green

### Phase 95: Closure: retroactive verification artifacts for Phases 92–94

**Goal:** Phases 92–94 each have a retroactive VERIFICATION.md and the v1.28 requirements traceability is fully synced, clearing the milestone audit's artifact-debt gap.
**Depends on:** Phase 94
**Requirements:** (closure — verifies POLICY-01/02, ACCT-01..08)
**Plans:** 1 plan

Plans:
- [x] 95-01-PLAN.md — Create VERIFICATION.md for Phases 92–94 and sync REQUIREMENTS.md / ROADMAP.md

---

<details>
<summary>✅ v1.27 — Privacy Policy for X OAuth2 Email (Phases 89–90) — SHIPPED 2026-05-19</summary>

- [x] Phase 89: Static Policy Pages (2/2 plans) — 2026-05-19
- [x] Phase 90: OAuth2 Email Scope Wiring (1/1 plan) — 2026-05-19

</details>

## Phase Details

*(v1.27 phases archived — see [milestones/v1.27-ROADMAP.md](milestones/v1.27-ROADMAP.md))*

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

*Last updated: 2026-05-20 — v1.28 milestone: Phase 95 (artifact closure) planned*
