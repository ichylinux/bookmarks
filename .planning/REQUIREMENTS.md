# Requirements: Bookmarks — v1.35.1

**Defined:** 2026-06-16
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.35.1 Requirements

### Handle

- [ ] **HDL-01**: User can save `mastodon_handle` from the preferences page (`/preferences`) via the existing preferences form
- [ ] **HDL-02**: Input is normalized to canonical `localpart@instance` form (strip leading `@`, downcase instance hostname, reject paths/schemes)
- [ ] **HDL-03**: Invalid handle format shows a localized validation error on save (ja/en)
- [ ] **HDL-04**: Non-blank `mastodon_handle` is unique across users (DB unique index; multiple blank allowed)

### Identity

- [ ] **IDNT-04**: `User.from_omniauth` `:mastodon` branch finds an active existing user by `mastodon_handle` when no `oauth_identities` row matches the composite uid
- [ ] **IDNT-05**: Handle-based sign-in only proceeds when OAuth-verified `username` + session `instance` exactly match the stored canonical handle (prevents handle squatting)
- [ ] **IDNT-06**: Successful handle-based match upserts `OauthIdentity` with composite uid `instance:account_id` (same as v1.35)
- [ ] **IDNT-07**: When handle match fails, behavior unchanged from v1.35 — create new user with dummy email and link identity

### View

- [ ] **VIEW-04**: Preferences page shows a `mastodon_handle` text field with label, placeholder (`user@mastodon.social`), and brief help text in ja/en

### Test

- [ ] **TEST-03**: Minitest covers `MastodonHandleNormalizer`, model validation/uniqueness, `from_omniauth` handle match, instance mismatch rejection, and create fallback
- [ ] **TEST-04**: Preferences controller integration test saves and reloads `mastodon_handle`; tri-suite gate green at milestone close

## v2 Requirements

Deferred to future release.

### Identity

- **IDNT-FUT-01**: User can connect a new OAuth provider directly from the preferences page (unchanged from v1.35)
- **HDL-FUT-01**: Auto-populate `mastodon_handle` after first successful Mastodon OAuth when field is blank

## Out of Scope

| Feature | Reason |
|---------|--------|
| Connect Mastodon from preferences without OAuth | Deferred as IDNT-FUT-01 |
| Match by username only (ignore instance) | Federated Mastodon — ambiguous across instances |
| WebFinger validation at preferences save | Network dependency; OAuth callback provides proof |
| Multiple Mastodon handles per user | Single `users.mastodon_handle` column |
| Live Mastodon OAuth round-trip in Cucumber | v1.35 precedent — Minitest + static UI checks |
| Admin UI for mastodon_handle | Personal app; not needed |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HDL-01 | — | Pending |
| HDL-02 | — | Pending |
| HDL-03 | — | Pending |
| HDL-04 | — | Pending |
| IDNT-04 | — | Pending |
| IDNT-05 | — | Pending |
| IDNT-06 | — | Pending |
| IDNT-07 | — | Pending |
| VIEW-04 | — | Pending |
| TEST-03 | — | Pending |
| TEST-04 | — | Pending |

**Coverage:**
- v1.35.1 requirements: 11 total
- Mapped to phases: 0
- Unmapped: 11 ⚠️

---
*Requirements defined: 2026-06-16*
*Last updated: 2026-06-16 after initial definition*
