# Requirements: Bookmarks v1.24 — Mobile Column Lazy Loading

**Defined:** 2026-05-17
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### Mobile Lazy Loading

- [ ] **LAZY-01**: On mobile (≤768px), only gadgets in the initially active column are AJAX-loaded on page load
- [ ] **LAZY-02**: When the user switches to a new column tab, that column's gadgets are loaded on first visit
- [ ] **LAZY-03**: Revisiting an already-loaded column does not trigger another AJAX request
- [ ] **LAZY-04**: Load state resets on each page load — gadgets reload fresh on explicit page refresh

### Desktop Compatibility

- [ ] **DESKTP-01**: Desktop behavior is unchanged — all gadgets in all columns load on page load as today
- [ ] **DESKTP-02**: Feature works correctly across all themes (modern/classic/simple) and both column counts (3 and 4)

### Implementation Contract

- [ ] **IMPL-01**: A new `portal_lazy.js` coordinator module exposes `window.portalLazy` with `register(columnIndex, loadFn)` and `loadColumn(index)` API
- [ ] **IMPL-02**: All AJAX gadget partials (`_feed`, `_mastodon_account`, `_x_account`, `_calendar_gadget`) register with the coordinator instead of firing unconditionally on `$(document).ready` on mobile
- [ ] **IMPL-03**: `activateColumn()` in `portal_mobile_tabs.js` triggers `portalLazy.loadColumn(index)` — covering tab-click, swipe, and localStorage-restore activation paths
- [ ] **IMPL-04**: Load state is marked synchronously before any `$.get` fires, preventing duplicate in-flight requests on rapid tab switching

### Test Coverage

- [ ] **TEST-01**: Minitest contract tests verify the `portal_lazy.js` coordinator's register/load-once behavior
- [ ] **TEST-02**: Existing `@mobile_portal` Cucumber scenarios pass; new scenario verifies that only the active column loads on page init and that switching to a new column triggers exactly one load

## Future Requirements

*(None identified — this milestone is a self-contained optimization)*

## Out of Scope

| Feature | Reason |
|---------|--------|
| Server-side lazy rendering (only render active column HTML) | No server changes needed; all gadget HTML is already rendered SSR; only AJAX fetches are deferred |
| Prefetching adjacent columns | Adds complexity; contradicts the "load only on first visit" contract |
| Persisting loaded state across page loads (localStorage) | Defeats the "reload = fresh" contract; session memory only |
| Cancelling in-flight requests on fast tab switch | Complexity not justified; load-state marked synchronously prevents duplicate requests |
| Showing loading indicators per-column | No UI change needed; existing per-gadget loading state is sufficient |
| Sorting/reordering gadgets on mobile | Separate concern; `$.sortable` mobile guard is a safety fix, not a sort feature |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LAZY-01 | Phase 76 | Pending |
| LAZY-02 | Phase 76 | Pending |
| LAZY-03 | Phase 76 | Pending |
| LAZY-04 | Phase 76 | Pending |
| DESKTP-01 | Phase 76 | Pending |
| DESKTP-02 | Phase 76 | Pending |
| IMPL-01 | Phase 76 | Pending |
| IMPL-02 | Phase 77 | Pending |
| IMPL-03 | Phase 77 | Pending |
| IMPL-04 | Phase 77 | Pending |
| TEST-01 | Phase 78 | Pending |
| TEST-02 | Phase 78 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-17*
*Last updated: 2026-05-17 — traceability confirmed after roadmap creation (Phases 76–78)*
