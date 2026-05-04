# Requirements: Bookmarks — v1.7 Mobile Portal Layout

**Defined:** 2026-05-04
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.7 Requirements

### Layout — Responsive breakpoint

- [x] **LAYOUT-01**: On screens narrower than the mobile breakpoint, the portal columns display under a tab strip with one column visible at a time
- [x] **LAYOUT-02**: On screens at or above the mobile breakpoint (PC/tablet), the existing side-by-side multi-column layout is unchanged
- [x] **LAYOUT-03**: The mobile breakpoint is defined as a single SCSS variable (not hardcoded in multiple places)

### Tab — Column tab strip (mobile only)

- [x] **TAB-01**: A tab strip is shown on mobile with one tab per portal column (labeled by column number)
- [x] **TAB-02**: Selecting a tab shows that column's gadgets and hides the others
- [x] **TAB-03**: The first column tab is active by default on page load
- [x] **TAB-04**: The tab strip is hidden on PC/tablet (CSS media query)
- [x] **TAB-05**: Tab state is driven by CSS class toggling (JS sets active class; CSS controls visibility)

### Theme — All-theme coverage

- [x] **THEME-01**: Modern theme welcome page gets the mobile column tab strip
- [x] **THEME-02**: Classic theme welcome page gets the mobile column tab strip
- [x] **THEME-03**: Simple theme welcome page gets the mobile column tab strip (coexists with existing Home/Note tabs)

### Test — Verification

- [x] **TEST-01**: Minitest integration tests cover tab strip presence and column show/hide classes for each theme
- [x] **TEST-02**: Cucumber scenario covers mobile column tab switching (at least one theme)

## Future Requirements

### Enhancements

- **ENH-01**: User-configurable tab labels per column (currently generic numbers)
- **ENH-02**: Persist active column tab in URL param or localStorage so navigation preserves column position
- **ENH-03**: Drag-and-drop gadget reorder on mobile (sortable is currently desktop-only)

## Out of Scope

| Feature | Reason |
|---------|--------|
| User-configurable tab labels per column | Complexity deferred to future milestone; generic numbers sufficient |
| Changing the number of columns | Driven by `portal_column_count`; unchanged in this milestone |
| Drag-and-drop reorder on mobile | Sortable stays desktop-only; touch-drag complexity is high |
| Any page other than the welcome/portal page | Only the portal home screen has the column layout |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LAYOUT-01 | Phase 27 | Complete |
| LAYOUT-02 | Phase 26 | Complete |
| LAYOUT-03 | Phase 26 | Complete |
| TAB-01 | Phase 27 | Complete |
| TAB-02 | Phase 27 | Complete |
| TAB-03 | Phase 27 | Complete |
| TAB-04 | Phase 26 | Complete |
| TAB-05 | Phase 27 | Complete |
| THEME-01 | Phase 26 | Complete |
| THEME-02 | Phase 26 | Complete |
| THEME-03 | Phase 26 | Complete |
| TEST-01 | Phase 28 | Complete |
| TEST-02 | Phase 28 | Complete |

**Coverage:**
- v1.7 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-04*
*Last updated: 2026-05-04 — v1.7 requirements marked complete after ship.*
