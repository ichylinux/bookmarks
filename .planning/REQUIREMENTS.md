# Requirements: Bookmarks — v1.21 X Gadget Tweet Count Preference

**Defined:** 2026-05-16
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### Display Count UI & Persistence

- [ ] **XCNT-01**: User can see the current tweet display count for each X account on the /x_accounts management page
- [ ] **XCNT-02**: User can change the tweet display count per X account via a number input on the /x_accounts page and save it
- [ ] **XCNT-03**: The welcome page X gadget loads and renders the number of tweets matching the saved per-account display count
- [ ] **XCNT-04**: `display_count` is permitted in `x_account_params` strong params so the value persists on update

### Test Coverage

- [ ] **XCNT-05**: Controller test verifies `display_count` is updated and persisted on PATCH /x_accounts/:id
- [ ] **XCNT-06**: Model test covers `display_count` validation (integer, greater than 0) and `set_display_count_default` callback

## Future Requirements

### Enhancements

- **XCNT-FUT-01**: Per-account maximum cap (e.g. 20) — current model validation only requires > 0; an upper bound could prevent accidental large API calls
- **XCNT-FUT-02**: Inline display count update without full form submit (AJAX toggle, matching selected checkbox UX)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Global (preference-level) tweet count | Scope is per-account (x_accounts row), not global |
| Changing tweet count from the welcome gadget itself | Management happens at /x_accounts, not inline on the dashboard |
| Pagination or "load more" | Out of scope; display_count is a fixed ceiling |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| XCNT-01 | Phase 69 | Pending |
| XCNT-02 | Phase 69 | Pending |
| XCNT-03 | Phase 69 | Pending |
| XCNT-04 | Phase 69 | Pending |
| XCNT-05 | Phase 69 | Pending |
| XCNT-06 | Phase 69 | Pending |

**Coverage:**
- v1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-16*
*Last updated: 2026-05-16 after initial definition*
