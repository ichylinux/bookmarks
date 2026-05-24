---
phase: 116
slug: 116-disconnect-controller-routes
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
register_authored_at_plan_time: false
---

# Phase 116 — Security

> `OauthIdentitiesController#destroy` for OAuth providers, route, and Minitest coverage. Form-auth disconnect (`provider=form`) added in Phase 117.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Authenticated user → `DELETE /oauth_identities/:provider` | Disconnect OAuth identity | Provider string, `OauthIdentity` row |
| Unauthenticated client → controller | Blocked by Devise | Session cookie |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-116-01 | Spoofing | Unauthenticated disconnect | mitigate | `ApplicationController` `before_action :authenticate_user!` (`application_controller.rb:3`); Minitest `test_destroy_requires_authentication` (`oauth_identities_controller_test.rb:8-10`) | closed |
| T-116-02 | Elevation of Privilege | IDOR via `params[:provider]` | mitigate | `current_user.oauth_identities.find_by(provider:)` scopes lookup to session user (`oauth_identities_controller.rb:15`); no user_id param | closed |
| T-116-03 | Denial of Service | Last-auth-method lockout | mitigate | Blocks when `remaining_oauth == 0 && !password_auth_enabled?` (`oauth_identities_controller.rb:22-26`); Minitest `test_destroy_blocks_disconnect_of_last_auth_method` and `test_destroy_allows_disconnect_when_password_auth_enabled` (`oauth_identities_controller_test.rb:28-51`) | closed |
| T-116-04 | Tampering | CSRF on DELETE | mitigate | `protect_from_forgery with: :exception` (`application_controller.rb:2`); Rails `button_to` / integration tests use session auth | closed |
| T-116-05 | Tampering | Unlinked provider deletes row | mitigate | `find_by` nil → redirect with `not_connected`, no destroy (`oauth_identities_controller.rb:17-19`); Minitest `test_destroy_handles_unlinked_provider_gracefully` (`oauth_identities_controller_test.rb:53-62`) | closed |
| T-116-SC | Tampering | Package installs | accept | No new npm/gem dependencies in this phase | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-116-01 | T-116-SC | No package manager changes in Phase 116 | gsd-secure-phase | 2026-05-24 |

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
