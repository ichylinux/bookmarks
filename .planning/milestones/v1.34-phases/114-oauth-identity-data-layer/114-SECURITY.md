---
phase: 114
slug: 114-oauth-identity-data-layer
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
register_authored_at_plan_time: false
---

# Phase 114 — Security

> OAuth identity data layer: `oauth_identities` table, `OauthIdentity` model, `User.from_omniauth` upsert wiring. No new user-facing routes or controllers.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| OmniAuth callback → `User.from_omniauth` | Existing sign-in flow now persists provider UIDs | `provider`, `uid`, `user_id` |
| `OauthIdentity.upsert_for!` → DB | Upsert on each successful OAuth sign-in | OAuth provider UID strings |
| User purge → `oauth_identities` | FK `on_delete: :cascade` | Identity rows deleted with user |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-114-01 | Tampering | Duplicate rows per user+provider | mitigate | Unique index `index_oauth_identities_on_user_id_and_provider` (`db/schema.rb:64`); model `validates :provider, uniqueness: { scope: :user_id }` (`oauth_identity.rb:6`) | closed |
| T-114-02 | Spoofing | Cross-user OAuth account binding | mitigate | Global unique index `index_oauth_identities_on_provider_and_uid` (`db/schema.rb:63`); `test_allows_same_provider_for_different_users` confirms different UIDs per user (`oauth_identity_test.rb:27-31`) | closed |
| T-114-03 | Tampering | `upsert_for!` race duplicate insert | mitigate | `rescue ActiveRecord::RecordNotUnique` + `retry` (`oauth_identity.rb:13-14`) | closed |
| T-114-04 | Elevation | Upsert on unpersisted user | mitigate | All three `from_omniauth` branches guard with `if user.persisted?` (`user.rb:72,92,97`); twitter2 new-user path calls upsert only after `User.create!` (`user.rb:86`) | closed |
| T-114-05 | Repudiation | Backfill migration non-reversible | accept | `down` is empty by design; one-time data migration; no runtime attack surface | closed |
| T-114-SC | Tampering | Package installs | accept | No new npm/gem dependencies in this phase | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-114-01 | T-114-05 | Backfill migration intentionally non-reversible; operators re-run forward migration only; no user-triggered `down` path | gsd-secure-phase | 2026-05-24 |
| AR-114-02 | T-114-SC | No package manager changes in Phase 114 | gsd-secure-phase | 2026-05-24 |

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
