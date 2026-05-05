# Requirements: Bookmarks — v1.8 Mobile UX Enhancement

**Defined:** 2026-05-05
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.8 Requirements

### Swipe

- [ ] **SWIPE-01**: User can switch to adjacent portal columns with horizontal swipe on mobile
- [ ] **SWIPE-02**: Vertical scrolling gestures do not trigger column switching
- [ ] **SWIPE-03**: At first/last column, out-of-range swipe does not change active column

### State

- [ ] **STATE-01**: Active column updates through a single state flow for both tab tap and swipe
- [ ] **STATE-02**: Last active mobile column is persisted in `localStorage`
- [ ] **STATE-03**: On revisit, app restores saved column; invalid/missing storage falls back to first column

### UX and Accessibility

- [ ] **UXA-01**: Existing tab-based navigation remains available as a non-swipe interaction path
- [ ] **UXA-02**: Active tab UI and `portal--column-active-N` class state always stay in sync
- [ ] **UXA-03**: Same behavior is guaranteed across modern, classic, and simple themes

### Test

- [ ] **TEST-01**: Minitest verifies state sync, restore/fallback behavior, and theme coverage
- [ ] **TEST-02**: Cucumber verifies swipe transition, no-switch on vertical scroll intent, and revisit restore

## Future Requirements

### Enhancements

- **ENH-01**: User-configurable tab labels per column (deferred)
- **ENH-03**: Drag-and-drop gadget reorder on mobile (deferred)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Introducing frontend framework or build-system migration | Violates milestone constraint (Sprockets/jQuery continuity) |
| Full column-label editing UI | Deferred; requires additional persistence and settings UI |
| Mobile drag-and-drop reorder implementation | High touch interaction complexity; deferred |
| Expanding this UX beyond welcome/portal page | Milestone focus is portal column interaction only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SWIPE-01 | Phase 29 | Pending |
| SWIPE-02 | Phase 29 | Pending |
| SWIPE-03 | Phase 29 | Pending |
| STATE-01 | Phase 29 | Pending |
| STATE-02 | Phase 30 | Pending |
| STATE-03 | Phase 30 | Pending |
| UXA-01 | Phase 29 | Pending |
| UXA-02 | Phase 29 | Pending |
| UXA-03 | Phase 30 | Pending |
| TEST-01 | Phase 31 | Pending |
| TEST-02 | Phase 31 | Pending |

**Coverage:**
- v1.8 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05 — v1.8 roadmap created; traceability mapped to Phases 29–31.*
