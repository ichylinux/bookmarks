---
phase: 118
slug: 118-tests-tri-suite-gate
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
register_authored_at_plan_time: false
---

# Phase 118 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Phase 118 adds Cucumber E2E coverage for v1.34 Connected Accounts; production controls live in Phases 115–117.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Authenticated user → `DELETE /oauth_identities/:provider` | Disconnect OAuth or form auth from preferences | Provider name, `OauthIdentity` rows, `password_auth_enabled` flag |
| Cucumber `@connected_accounts` hooks → test DB | Before hook seeds identities; After hook cleans up | Synthetic UIDs (`ca_google_uid`, `ca_twitter_uid`) — test env only |
| Browser form POST → Rails CSRF | `button_to` disconnect actions on preferences page | Session authenticity token |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-118-01 | Spoofing | `OauthIdentitiesController#destroy` | mitigate | `ApplicationController` enforces `authenticate_user!`; unauthenticated `DELETE` redirects to sign-in (`oauth_identities_controller_test.rb:8-10`); E2E steps call `sign_in user` before visiting preferences | closed |
| T-118-02 | Elevation of Privilege | `params[:provider]` / identity lookup | mitigate | `current_user.oauth_identities.find_by(provider:)` scopes deletion to session user only (`oauth_identities_controller.rb:15`); no cross-user IDOR path | closed |
| T-118-03 | Denial of Service | Last-auth-method disconnect | mitigate | Controller blocks when `remaining_oauth == 0 && !password_auth_enabled?` (`oauth_identities_controller.rb:22-26`) and symmetric guard for form auth (`oauth_identities_controller.rb:38-40`); Minitest `test_destroy_blocks_disconnect_of_last_auth_method`; E2E scenario「最後の認証方法は解除できない」(`features/14.連携アカウント.feature:14-17`) | closed |
| T-118-04 | Tampering | CSRF on disconnect forms | mitigate | `protect_from_forgery with: :exception` (`application_controller.rb:2`); `button_to` emits authenticity token (`_connected_accounts.html.erb:21-24`) | closed |
| T-118-05 | Tampering | Unlinked / unknown provider param | mitigate | `find_by` returns nil → redirect with `not_connected` notice, no row deleted (`oauth_identities_controller.rb:17-19`); Minitest `test_destroy_handles_unlinked_provider_gracefully` | closed |
| T-118-06 | Information Disclosure | `@connected_accounts` Cucumber hooks | accept | Hooks use `update_column` / direct `OauthIdentity.create!` for fixture speed; scoped to `@connected_accounts` tag; `After` hook deletes identities and resets `password_auth_enabled` — test-only, no production code path | closed |
| T-118-SC | Tampering | Package installs | accept | No new npm/gem dependencies in this phase — supply-chain gate N/A | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-118-01 | T-118-06 | Cucumber hooks bypass validations via `update_column` for deterministic E2E setup; data is synthetic and cleaned in `After('@connected_accounts')`; hooks do not ship to production | gsd-secure-phase | 2026-05-24 |
| AR-118-02 | T-118-SC | No package manager changes in Phase 118 | gsd-secure-phase | 2026-05-24 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 7 | 7 | 0 | gsd-secure-phase (retroactive-STRIDE; register_authored_at_plan_time: false) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
