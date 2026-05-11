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
- 🚧 **v1.16 — Mastodon Account Following** — Phases 52–56 (in progress)

## Phases

### 🚧 v1.16 — Mastodon Account Following (In Progress)

**Milestone Goal:** Users can follow public Mastodon accounts and see a one-line preview of recent toots as live gadgets on the welcome page dashboard.

- [ ] **Phase 52: MastodonAccount Data Layer** - Migration, model, URL parsing, soft-delete, and model-level Minitest coverage
- [ ] **Phase 53: CRUD Controller and Views** - Index, new, edit, destroy UI for managing followed accounts with ja/en locale
- [ ] **Phase 54: MastodonClient API Service** - Faraday-based service fetching live toots with timeout, HTML stripping, and toot link wiring
- [ ] **Phase 55: Welcome Page Gadget Integration** - AJAX-loaded collapsible gadget panel per account on the welcome page
- [ ] **Phase 56: Test Sweep and Verification Gate** - Controller Minitest (stubbed API), Cucumber E2E, tri-suite green

## Phase Details

### Phase 52: MastodonAccount Data Layer
**Goal**: The MastodonAccount model exists, persists cleanly, and parses profile URLs automatically before save
**Depends on**: Phase 51 (v1.15 complete)
**Requirements**: MAST-05
**Success Criteria** (what must be TRUE):
  1. Migration runs cleanly — `mastodon_accounts` table exists with user_id, profile_url, instance, username, display_count, deleted columns
  2. Model parses a profile URL like `https://ruby.social/@FastRuby` before save, storing `ruby.social` as instance and `FastRuby` as username
  3. Model rejects a record with an unparseable profile URL (validation fails with a message)
  4. Soft-delete via `Crud::ByUser` works — `destroy` sets `deleted: true` and the default scope excludes deleted records
  5. Minitest covers URL parsing, validation, and soft-delete behavior
**Plans**: TBD

### Phase 53: CRUD Controller and Views
**Goal**: Users can add, view, edit, and delete followed Mastodon accounts through a conventional Rails CRUD interface
**Depends on**: Phase 52
**Requirements**: MAST-01, MAST-02, MAST-03, MAST-04, MAST-10
**Success Criteria** (what must be TRUE):
  1. User can visit `/mastodon_accounts` and see a list of their followed accounts (empty state when none)
  2. User can add a new account by entering a profile URL on the new account form — record is saved and URL is parsed
  3. User can edit an existing account's profile URL or display count and save the changes
  4. User can delete an account from the index — account is soft-deleted and no longer appears in the list
  5. All page headings, labels, buttons, and empty-state messages appear in both Japanese and English depending on locale
**Plans**: TBD
**UI hint**: yes

### Phase 54: MastodonClient API Service and Show Action
**Goal**: The app fetches live toots from the Mastodon public REST API and renders stripped, truncated previews linked to originals
**Depends on**: Phase 53
**Requirements**: MAST-06, MAST-07, MAST-09
**Success Criteria** (what must be TRUE):
  1. `MastodonClient` service calls the Mastodon `/api/v1/accounts/lookup` then `/api/v1/accounts/{id}/statuses` endpoints using Faraday with explicit connect and read timeouts
  2. Toot HTML content is stripped to plain text and truncated to approximately 100 characters for one-line display
  3. Each toot preview in the response carries a link to the original toot URL on the source Mastodon instance
  4. A network timeout or API error is handled gracefully — the show action renders an error state rather than raising an exception
**Plans**: TBD

### Phase 55: Welcome Page Gadget Integration
**Goal**: Each followed Mastodon account appears as a collapsible, AJAX-loaded gadget panel on the welcome page when accounts exist
**Depends on**: Phase 54
**Requirements**: MAST-08
**Success Criteria** (what must be TRUE):
  1. A user with followed accounts sees one collapsible gadget panel per account on the welcome page dashboard
  2. Each gadget loads its toot list via AJAX (XHR request to the show action) — the page does not full-reload to fetch toots
  3. A user with no followed accounts sees no Mastodon gadget panels — the welcome page is unchanged from its current state
  4. The gadget panel follows the same collapsible pattern as RSS feed gadgets
**Plans**: TBD
**UI hint**: yes

### Phase 56: Test Sweep and Verification Gate
**Goal**: Controller tests with stubbed API calls, Cucumber E2E for the gadget, and tri-suite green confirm the milestone is shippable
**Depends on**: Phase 55
**Requirements**: MAST-11, MAST-12
**Success Criteria** (what must be TRUE):
  1. `MastodonAccountsController` is covered by Minitest integration tests using Faraday test adapter stubs (no real HTTP calls)
  2. A Cucumber scenario navigates to the welcome page and asserts the Mastodon gadget panel appears and contains at least one toot preview
  3. `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test` all pass (zero failures, one rerun allowed for known Cucumber flake)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 52 → 53 → 54 → 55 → 56

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 52. MastodonAccount Data Layer | 0/TBD | Not started | - |
| 53. CRUD Controller and Views | 0/TBD | Not started | - |
| 54. MastodonClient API Service and Show Action | 0/TBD | Not started | - |
| 55. Welcome Page Gadget Integration | 0/TBD | Not started | - |
| 56. Test Sweep and Verification Gate | 0/TBD | Not started | - |

---

*Last updated: 2026-05-12 — v1.16 Mastodon Account Following roadmap created (Phases 52–56).*
