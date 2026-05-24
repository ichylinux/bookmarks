---
phase: 115
slug: 115-form-auth-data-layer
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
register_authored_at_plan_time: false
---

# Phase 115 — Security

> Form authentication data layer: `password_auth_enabled` flag, Devise password-reset lifecycle, `disconnect_form_auth!`. No controller or UI in this phase.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Devise password reset → `User#after_password_reset` | Reset flow enables form auth flag | `password_auth_enabled`, `encrypted_password`, `reset_password_token` |
| `User#disconnect_form_auth!` → DB | Clears form auth and invalidates stored password hash | `password_auth_enabled`, `encrypted_password` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-115-01 | Elevation | `password_auth_enabled` set on arbitrary password change | mitigate | `before_save :after_password_reset` only when `encrypted_password_changed? && reset_password_token_was.present?` (`user.rb:19-20`); Minitest confirms OAuth create and unrelated saves do not set flag (`user_password_auth_test.rb:19-35`) | closed |
| T-115-02 | Spoofing | Old password still valid after disconnect | mitigate | `disconnect_form_auth!` sets `encrypted_password` to `Devise::Encryptor.digest(..., SecureRandom.hex)` (`user.rb:169-173`); Minitest `test_disconnect_form_auth!_prevents_sign_in_with_old_password` (`user_password_auth_test.rb:48-57`) | closed |
| T-115-03 | Tampering | Flag toggled without explicit disconnect API | mitigate | No public setter; flag changed only via guarded `before_save` callback or `disconnect_form_auth!` (`user.rb:169-174,193-195`) | closed |
| T-115-04 | Information Disclosure | Column default leaks intent | mitigate | `NOT NULL DEFAULT false` (`db/schema.rb:134`, migration `20260524000003`); OAuth-only users remain `false` until verified reset | closed |
| T-115-SC | Tampering | Package installs | accept | No new npm/gem dependencies in this phase | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-115-01 | T-115-SC | No package manager changes in Phase 115 | gsd-secure-phase | 2026-05-24 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 5 | 5 | 0 | gsd-secure-phase (retroactive-STRIDE; register_authored_at_plan_time: false) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
