# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ⚠️ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (deferred 2026-05-06)
- ✅ **v1.11 — Device-aware Font Size Baseline** — Phases 37–39 (shipped 2026-05-06) — [archived](milestones/v1.11-ROADMAP.md)
- ✅ **v1.12 — Landing Page for User Acquisition (Phase 1)** — Phases 40–42 (shipped 2026-05-08) — [archived](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08) — [archived](milestones/v1.13-ROADMAP.md)
- ✅ **v1.14 — Landing Page Changelog** — Phases 46–48 (shipped 2026-05-10) — [archived](milestones/v1.14-ROADMAP.md)
- ✅ **v1.15 — CSS & UI Polish** — Phases 49–51 (shipped 2026-05-11) — [archived](milestones/v1.15-ROADMAP.md)
- ✅ **v1.16 — Mastodon Account Following** — Phases 52–56 (shipped 2026-05-12) — [archived](milestones/v1.16-ROADMAP.md)
- 🚧 **v1.17 — Email Registration for X/Twitter Users** — Phases 57–59 (active)

## Phases

### v1.17 — Email Registration for X/Twitter Users

- [ ] **Phase 57: Model Validation Foundation** — Add on-update email validator that blocks dummy-pattern addresses
- [ ] **Phase 58: Controller, Route, and Guards** — Dedicated EmailRegistrationsController with new/create, collision guard, and real-email redirect
- [ ] **Phase 59: View, Preferences Entry, Locale, and Tests** — Form view, preferences entry point, ja/en locale keys, and Minitest coverage

<details>
<summary>✅ v1.16 — Mastodon Account Following (Phases 52–56) — SHIPPED 2026-05-12</summary>

Full goals, success criteria, and notes: [milestones/v1.16-ROADMAP.md](milestones/v1.16-ROADMAP.md).

- [x] Phase 52: MastodonAccount Data Layer
- [x] Phase 53: CRUD Controller and Views
- [x] Phase 54: MastodonClient API Service and Show Action
- [x] Phase 55: Welcome Page Gadget Integration
- [x] Phase 56: Test Sweep and Verification Gate

</details>

## Phase Details

### Phase 57: Model Validation Foundation
**Goal**: The User model safely rejects dummy-pattern and invalid email addresses on update, without affecting the Twitter OAuth account-creation path
**Depends on**: Nothing (first phase of v1.17)
**Requirements**: EMAIL-01
**Success Criteria** (what must be TRUE):
  1. Submitting a `dummy_<uuid>@example.com` address via the update path fails with a validation error
  2. Submitting a malformed email address on update fails Devise format validation
  3. Creating a new user with a dummy email (Twitter `from_omniauth` path) succeeds without triggering the new validator
  4. A fixture representing a Twitter-style dummy-email user exists and is usable in controller integration tests
**Plans**: TBD

### Phase 58: Controller, Route, and Guards
**Goal**: A dedicated `EmailRegistrationsController` handles email registration exclusively for dummy-email users, with a collision guard that prevents silent account takeover
**Depends on**: Phase 57
**Requirements**: CTRL-01, CTRL-02, CTRL-03
**Success Criteria** (what must be TRUE):
  1. A dummy-email user can submit the form and have their email updated to a valid real address
  2. Submitting an email address already held by another account returns an error message — the existing account is not overwritten
  3. A user who already has a real email address is redirected away from the registration form with no form rendered
  4. The route is accessible only to authenticated users (unauthenticated requests redirect to sign-in)
  5. An `ActiveRecord::RecordNotUnique` race on the unique index is rescued and re-renders the form with a user-facing error rather than a 500
**Plans**: TBD

### Phase 59: View, Preferences Entry, Locale, and Tests
**Goal**: Users with dummy emails can discover and complete email registration via the preferences page, with fully localized UI in Japanese and English, and Minitest coverage across all critical paths
**Depends on**: Phase 58
**Requirements**: VIEW-01, VIEW-02, I18N-01, TEST-01
**Success Criteria** (what must be TRUE):
  1. The preferences page shows an email registration entry point (link) when the signed-in user has a dummy email, and hides it when the user has a real email
  2. After successfully registering an email, the user sees a localized success flash message
  3. All form labels, error messages, help text, and the success flash render correctly under both `ja` and `en` locales
  4. `ja.yml` and `en.yml` contain matching locale keys for email registration strings (parity enforced by test)
  5. Minitest integration tests cover: model validation paths (dummy reject, format reject, valid accept), controller guard (dummy-only access, real-email redirect), and collision scenario (duplicate email error returned)
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 57. Model Validation Foundation | 0/TBD | Not started | - |
| 58. Controller, Route, and Guards | 0/TBD | Not started | - |
| 59. View, Preferences Entry, Locale, and Tests | 0/TBD | Not started | - |

---

*Last updated: 2026-05-13 — v1.17 roadmap created (Phases 57–59)*
