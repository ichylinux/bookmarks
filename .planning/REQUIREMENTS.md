# Requirements: Bookmarks v1.32

**Defined:** 2026-05-22
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.32 Requirements

### Model

- [ ] **PURGE-01**: Admin can check if a soft-deleted user is eligible for purge (deleted_at ≥ 90 days ago, nil-safe)
- [ ] **PURGE-02**: `User#purge!` permanently deletes the user row and all associated records across 11 tables in a single transaction

### Admin UI

- [ ] **ADMIN-01**: Admin sees a "Purge" action on `/admin/users` only for purgeable accounts (not active or recently-deleted users)
- [ ] **ADMIN-02**: Admin is shown a confirmation page before purge executes
- [ ] **ADMIN-03**: Purge action is server-side guarded by `purgeable?` — cannot be bypassed by direct HTTP request

### Locale

- [ ] **LOCALE-01**: All new purge labels and flash messages have bilingual ja/en strings; i18n parity test passes

### Tests

- [ ] **TEST-01**: Minitest covers `purgeable?` edge cases (not deleted, deleted_at nil, < 90 days, ≥ 90 days) and `purge!` verifies all 11 tables are empty after execution
- [ ] **TEST-02**: Minitest covers controller access control (guest redirect, non-admin 404, admin-only purge)
- [ ] **TEST-03**: Cucumber E2E scenario for the admin purge flow using a non-fixture soft-deleted user; tri-suite gate green

## Future Requirements

### v2+

- **ACCT-FUT-01b**: Scheduled background job purges all eligible accounts automatically after 90 days
- **ACCT-FUT-03**: Data export before purge (user can request their data)
- **PURGE-FUT-01**: Bulk purge of all eligible accounts from admin screen

## Out of Scope

| Feature | Reason |
|---------|--------|
| Scheduled/automatic purge job | No job infrastructure in app; manual admin-triggered purge is sufficient for personal app volume |
| Typed-token confirmation ("type DELETE") | Admin context makes this overkill; `data-confirm` is proportionate friction |
| Audit log of purge actions | Complexity without benefit for single-admin personal app |
| Undo/restore after purge | Hard-delete is intentionally irreversible |
| Bulk purge UI | Single-account purge is sufficient for current volume |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PURGE-01 | Phase 109 | Pending |
| PURGE-02 | Phase 109 | Pending |
| ADMIN-01 | Phase 110 | Pending |
| ADMIN-02 | Phase 110 | Pending |
| ADMIN-03 | Phase 110 | Pending |
| LOCALE-01 | Phase 110 | Pending |
| TEST-01 | Phase 109 | Pending |
| TEST-02 | Phase 110 | Pending |
| TEST-03 | Phase 111 | Pending |

**Coverage:**
- v1.32 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-22 after initial definition*
