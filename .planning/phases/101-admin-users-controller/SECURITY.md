# Security Verification — Phase 101 (Admin Users Controller)

## STRIDE Threat Register

| Threat ID | Category | Component | Status | Mitigation | Verification |
|-----------|----------|-----------|--------|------------|--------------|
| T-101-01 | Elevation of Privilege | GET /admin/users | **PASS** | `require_admin` in `BaseController` returns 404 for non-admins; Devise `authenticate_user!` redirects guests. | Verified via `test/controllers/admin/users_controller_test.rb` (tests `test_未ログインはサインインページへリダイレクトされる` and `test_非管理者は404を返す`). |
| T-101-02 | Information Disclosure | User.all query | **PASS** | Endpoint is admin-only; non-admins receive 404 before query executes. | Verified by code inspection of `Admin::BaseController` inheritance and `Admin::UsersController#index`. |

## Audit Summary

The security boundaries for the Admin Users Controller have been verified. Access is strictly controlled via the `Admin::BaseController` gate, which returns a 404 Not Found for non-admin users, effectively hiding the existence of the endpoint to unauthorized parties. Guests are redirected to the sign-in page.

- [x] Controller inherits from `Admin::BaseController`
- [x] `Admin::BaseController` implements `require_admin`
- [x] Access-control tests pass
