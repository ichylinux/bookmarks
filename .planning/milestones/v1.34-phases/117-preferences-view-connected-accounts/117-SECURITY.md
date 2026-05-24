---
phase: 117
slug: 117-preferences-view-connected-accounts
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
register_authored_at_plan_time: false
---

# Phase 117 — Security

> Connected Accounts preferences UI and form-auth disconnect path (`provider=form`) in `OauthIdentitiesController`.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Authenticated user → preferences page | Renders linked/unlinked status and disconnect controls | `oauth_identities`, `password_auth_enabled` |
| Browser `button_to` → `DELETE /oauth_identities/:provider` | Disconnect OAuth or form auth | CSRF token, provider param |
| `provider=form` → `destroy_form_auth` | Clears form auth via Phase 115 API | `password_auth_enabled`, `encrypted_password` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-117-01 | Information Disclosure | Account linkage status on preferences | mitigate | `PreferencesController < ApplicationController` inherits `authenticate_user!`; partial receives `user` and `oauth_identities` from authenticated session only | closed |
| T-117-02 | Elevation of Privilege | Form-auth disconnect without OAuth fallback | mitigate | `destroy_form_auth` blocks when `oauth_identities.count == 0` (`oauth_identities_controller.rb:38-40`); symmetric to OAuth last-method guard (Phase 116) | closed |
| T-117-03 | Tampering | CSRF on disconnect `button_to` forms | mitigate | `protect_from_forgery with: :exception` (`application_controller.rb:2`); `button_to` with `method: :delete` emits authenticity token (`_connected_accounts.html.erb:21-24,43-46,65-68,87-90`) | closed |
| T-117-04 | Tampering | Disconnect UI for unlinked provider | mitigate | Disconnect buttons rendered only when `linked_providers.include?(...)` or `password_auth_enabled?` (`_connected_accounts.html.erb:19-27,41-49,63-71,85-93`); server-side guards unchanged from Phase 116/115 | closed |
| T-117-05 | Spoofing | Form disconnect when already disabled | mitigate | `unless current_user.password_auth_enabled?` → `not_connected` redirect, no `disconnect_form_auth!` call (`oauth_identities_controller.rb:33-35`) | closed |
| T-117-SC | Tampering | Package installs | accept | No new npm/gem dependencies in this phase | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-117-01 | T-117-SC | No package manager changes in Phase 117 | gsd-secure-phase | 2026-05-24 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 6 | 6 | 0 | gsd-secure-phase (retroactive-STRIDE; register_authored_at_plan_time: false) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
