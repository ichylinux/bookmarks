# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04)
- 🟡 **v1.8 — Mobile UX Enhancement** — Phases 29–31 (planning)

## Phases

- [ ] **Phase 29: Swipe Navigation Foundation** - Unify mobile column switching so swipe and tab interactions share one consistent state transition flow
- [ ] **Phase 30: Persisted Mobile Column State** - Persist and restore the last selected column with consistent behavior across all three themes
- [ ] **Phase 31: Verification Gate** - Lock down v1.8 mobile UX contracts with automated regression coverage

## Phase Details

### Phase 29: Swipe Navigation Foundation
**Goal**: Enable left/right swipe switching between adjacent columns on mobile, reflected through the same state flow as tab interaction  
**Depends on**: Phase 28  
**Requirements**: SWIPE-01, SWIPE-02, SWIPE-03, STATE-01, UXA-01, UXA-02  
**Success Criteria** (what must be TRUE):
  1. On mobile, left/right swipes move exactly one column to the adjacent column.
  2. Vertical scrolling gestures do not trigger column switching.
  3. At first/last column boundaries, out-of-range swipes do not change the active column.
  4. Whether the user taps tabs or swipes, the same active-column state is updated and tab UI stays synchronized with `portal--column-active-N`.
**Plans**: TBD  
**UI hint**: yes

### Phase 30: Persisted Mobile Column State
**Goal**: Restore the last selected column on revisit for mobile users, with consistent behavior on modern/classic/simple  
**Depends on**: Phase 29  
**Requirements**: STATE-02, STATE-03, UXA-03  
**Success Criteria** (what must be TRUE):
  1. When a mobile user changes columns, the last selected column is persisted to `localStorage`.
  2. On revisit, if the saved value is valid, that column is shown first.
  3. If the saved value is missing or invalid, the app safely falls back to column 1 and remains usable.
  4. Save/restore and UI sync behavior match across modern/classic/simple themes.
**Plans**: TBD  
**UI hint**: yes

### Phase 31: Verification Gate
**Goal**: Guarantee v1.8 swipe, persistence/restore, and cross-theme behavior with regression-ready tests  
**Depends on**: Phase 30  
**Requirements**: TEST-01, TEST-02  
**Success Criteria** (what must be TRUE):
  1. `bin/rails test` passes with coverage for state sync, restore fallback, and cross-theme behavior.
  2. `bundle exec rake dad:test` passes with scenarios for swipe transition, no-switch during vertical scroll intent, and revisit restore (following the known flake policy).
  3. Automated tests confirm no regression for existing tab-based column switching behavior from v1.7.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. Swipe Navigation Foundation | 0/0 | Not started | - |
| 30. Persisted Mobile Column State | 0/0 | Not started | - |
| 31. Verification Gate | 0/0 | Not started | - |

---
*Last updated: 2026-05-05 — v1.8 Mobile UX Enhancement roadmap created (Phases 29–31).*
