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
- 🚧 **v1.14 — Landing Page Changelog** — Phases 46–48 (active)

## Phases

### v1.14 — Landing Page Changelog

- [ ] **Phase 46: Changelog Data Layer** — Define YAML locale structure and loading logic for curated changelog entries
- [ ] **Phase 47: Changelog Section View** — Render the "What's New" card section on `/landing` for all visitors
- [ ] **Phase 48: Changelog Verification Gate** — Test coverage for changelog rendering and locale key parity

## Phase Details

### Phase 46: Changelog Data Layer
**Goal**: Changelog entries exist as bilingual locale YAML and can be loaded in the correct sorted order
**Depends on**: Nothing (builds on existing i18n infrastructure)
**Requirements**: CLOG-01, CLOG-02, CLOG-03, CLOG-04
**Success Criteria** (what must be TRUE):
  1. `ja.yml` and `en.yml` each contain a `changelog` key with at least one entry having date, headline, tag, and description fields
  2. Tags (UX, Fix, Performance, etc.) are represented as locale keys so they render in the active locale
  3. The localized section heading key exists in both ja.yml and en.yml (`landing.changelog.heading` or equivalent)
  4. A helper or controller method returns the entries sorted by date descending, capped at 10
**Plans**: TBD

### Phase 47: Changelog Section View
**Goal**: Visitors to `/landing` see a "What's New" section below the value grid with dated, tagged, localized changelog cards
**Depends on**: Phase 46
**Requirements**: VIEW-01, VIEW-02, VIEW-03
**Success Criteria** (what must be TRUE):
  1. The changelog section appears below the existing value-grid on `/landing` when viewed as a guest
  2. Each card displays date, tag label, headline, and description — four distinct visual elements
  3. A signed-in user redirected to `/landing` sees the same changelog section as a guest
  4. The section heading renders as 「新着情報」 in Japanese locale and "What's New" in English locale
**Plans**: TBD
**UI hint**: yes

### Phase 48: Changelog Verification Gate
**Goal**: Automated tests confirm changelog rendering correctness and locale key parity is enforced across ja/en
**Depends on**: Phase 47
**Requirements**: VERF-01, VERF-02
**Success Criteria** (what must be TRUE):
  1. A controller or view test asserts the changelog section is present on `GET /landing` for unauthenticated requests
  2. A test asserts the localized section heading key resolves to a non-blank string in both `ja` and `en`
  3. The existing locale key parity test (or an extension of it) covers all new changelog locale keys in ja.yml and en.yml
  4. Tri-suite gate passes: `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test` all green
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 46. Changelog Data Layer | 1/1 | Complete | 2026-05-10 |
| 47. Changelog Section View | 0/? | Not started | - |
| 48. Changelog Verification Gate | 0/? | Not started | - |

---
*Last updated: 2026-05-10 — v1.14 roadmap created.*
