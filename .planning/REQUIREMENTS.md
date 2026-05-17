# Requirements: Bookmarks v1.24 — Mobile Column Lazy Loading

**Defined:** 2026-05-17
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### Mobile Lazy Loading

- [x] **LAZY-01**: On mobile (≤768px), only gadgets in the initially active column are AJAX-loaded on page load
- [x] **LAZY-02**: When the user switches to a new column tab, that column's gadgets are loaded on first visit
- [x] **LAZY-03**: Revisiting an already-loaded column does not trigger another AJAX request
- [x] **LAZY-04**: Load state resets on each page load — gadgets reload fresh on explicit page refresh

### Desktop Compatibility

- [x] **DESKTP-01**: Desktop behavior is unchanged — all gadgets in all columns load on page load as today
- [x] **DESKTP-02**: Feature works correctly across all themes (modern/classic/simple) and both column counts (3 and 4)

### Implementation Contract

- [x] **IMPL-01**: A new `portal_lazy.js` coordinator module exposes `window.portalLazy` with `register(columnIndex, loadFn)` and `loadColumn(index)` API
- [x] **IMPL-02**: All AJAX gadget partials (`_feed`, `_mastodon_account`, `_x_account`, `_calendar_gadget`) register with the coordinator instead of firing unconditionally on `$(document).ready` on mobile
- [x] **IMPL-03**: `activateColumn()` in `portal_mobile_tabs.js` triggers `portalLazy.loadColumn(index)` — covering tab-click, swipe, and localStorage-restore activation paths
- [x] **IMPL-04**: Load state is marked synchronously before any `$.get` fires, preventing duplicate in-flight requests on rapid tab switching

### Test Coverage

- [x] **TEST-01**: Minitest contract tests verify the `portal_lazy.js` coordinator's register/load-once behavior
- [x] **TEST-02**: Existing `@mobile_portal` Cucumber scenarios pass; new scenario verifies that only the active column loads on page init and that switching to a new column triggers exactly one load

### Note Gadget AJAX Extraction

- [ ] **NOTE-01**: `NotesController` exposes a `gadget` collection action at `GET /notes/gadget` that authenticates the user, assigns `@note` (new Note) and `@notes` (user's active recent notes), and renders `notes/gadget` with `layout: false`
- [ ] **NOTE-02**: `WelcomeController#index` no longer assigns `@note` or `@notes` — the note gadget queries execute only on `GET /notes/gadget`, not on every dashboard page load
- [ ] **NOTE-03**: The `#notes-tab-panel` placeholder in `_dashboard.html.erb` is populated via a single AJAX request on first visit (simple theme: first tab click; modern/classic: on page load if `?tab=notes`); subsequent visits use the cached DOM

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
| LAZY-01 | Phase 76 | Complete |
| LAZY-02 | Phase 76 | Complete |
| LAZY-03 | Phase 76 | Complete |
| LAZY-04 | Phase 76 | Complete |
| DESKTP-01 | Phase 76 | Complete |
| DESKTP-02 | Phase 76 | Complete |
| IMPL-01 | Phase 76 | Complete |
| IMPL-02 | Phase 77 | Complete |
| IMPL-03 | Phase 77 | Complete |
| IMPL-04 | Phase 77 | Complete |
| TEST-01 | Phase 78 | Complete |
| TEST-02 | Phase 78 | Complete |
| NOTE-01 | Phase 79 | Not started |
| NOTE-02 | Phase 79 | Not started |
| NOTE-03 | Phase 79 | Not started |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-17*
*Last updated: 2026-05-17 — NOTE-01/02/03 added for Phase 79 (note gadget AJAX extraction)*
