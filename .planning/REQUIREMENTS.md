# Requirements — v1.30 Admin User Management Screen

**Milestone goal:** Add an admin-only read-only user list at `/admin/users` showing all registered accounts (including soft-deleted) with key identity and activity fields.

**Status:** Active

---

## Admin User Screen (USR)

- [ ] **USR-01**: Admin can access `/admin/users` — route exists, gated by `require_admin` (non-admins get 404, guests redirect to sign-in)
- [ ] **USR-02**: User list table displays all user records (including soft-deleted) with columns: id, email, x_user_name, admin_flag, last_sign_in_at, created_at, updated_at
- [ ] **USR-03**: `x_user_name` column shows `x_username` from the user's first `XAccount` record; blank when no account is linked
- [ ] **USR-04**: `admin_flag` column renders a clear boolean indicator (✓ for admin, — for regular user)
- [ ] **USR-05**: Drawer nav link for admin users points to `/admin/users`, appearing alongside the existing `/admin/x_api_usages` link
- [ ] **USR-06**: Column headers and all UI chrome are rendered via ja/en locale YAML keys; i18n parity test passes

---

## Future Requirements

- Pagination for large user tables (deferred — user count is small)
- Column sorting and filtering (deferred — not requested for this milestone)
- User role editing from admin screen (deferred — read-only for now)

---

## Out of Scope

- User editing or role promotion/demotion from this screen — read-only view only
- Pagination — deferred pending growth
- Column sorting/filtering — not in scope for v1.30

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| USR-01 | TBD   | —      |
| USR-02 | TBD   | —      |
| USR-03 | TBD   | —      |
| USR-04 | TBD   | —      |
| USR-05 | TBD   | —      |
| USR-06 | TBD   | —      |

*Traceability filled by roadmapper.*
