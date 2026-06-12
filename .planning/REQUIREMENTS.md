# Requirements: Bookmarks — v1.35

**Defined:** 2026-06-12
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.35 Requirements

### Strategy

- [ ] **STRAT-01**: `omniauth-oauth2` gem added explicitly; custom `OmniAuth::Strategies::Mastodon` registered in Devise as `:mastodon` provider
- [ ] **STRAT-02**: Strategy resolves authorization and token endpoints against the user-selected instance domain stored in session
- [ ] **STRAT-03**: Strategy obtains account info from `/api/v1/accounts/verify_credentials` after token exchange
- [ ] **STRAT-04**: OAuth client credentials obtained via dynamic app registration (`POST /api/v1/apps`) on the selected instance before authorization redirect

### Instance Selection

- [ ] **INST-01**: User can enter a Mastodon instance domain on sign-in and sign-up pages before starting the OAuth flow
- [ ] **INST-02**: Invalid instance domain input is rejected with a localized error before OAuth redirect (hostname format only; no open redirect)

### Identity

- [ ] **IDNT-01**: `oauth_identities.uid` for provider `mastodon` stores composite key `instance_domain:account_id`
- [ ] **IDNT-02**: `User.from_omniauth` handles `:mastodon` — finds existing user by composite uid or creates new user with dummy email when no email returned
- [ ] **IDNT-03**: Re-auth with the same Mastodon account updates the existing `OauthIdentity` row via `upsert_for!`

### View

- [ ] **VIEW-01**: Mastodon OAuth button rendered on sign-in and sign-up pages alongside existing OAuth providers
- [ ] **VIEW-02**: Connected Accounts preferences section shows a Mastodon row with linked/unlinked status and disconnect button
- [ ] **VIEW-03**: Bilingual (ja/en) labels for Mastodon auth UI (button, instance input, connected accounts row)

### Controller

- [ ] **CTRL-01**: `Users::OmniauthCallbacksController#mastodon` handles callback via shared `handle_callback`
- [ ] **CTRL-02**: `DELETE /oauth_identities/mastodon` works with existing last-auth-method safety guard

### Test

- [ ] **TEST-01**: Minitest covers strategy uid format, instance validation, `from_omniauth` create/re-auth paths, callback, and disconnect guard
- [ ] **TEST-02**: Cucumber extends connected-accounts coverage for Mastodon row presence (no live OAuth round-trip in CI)

## v2 Requirements

Deferred to future release.

### Identity

- **IDNT-FUT-01**: User can connect a new OAuth provider directly from the preferences page
- **FORM-FUT-01**: User can change their password from preferences without going through the reset flow

## Out of Scope

| Feature | Reason |
|---------|--------|
| Existing Mastodon OmniAuth gems (`omniauth-mastodon` etc.) | OAuth 1.0 only; do not support OAuth 2.0 |
| Connect Mastodon from preferences (without sign-in flow) | Deferred as IDNT-FUT-01 |
| OAuth access token storage for `MastodonClient` gadget API | Gadget uses public API; auth token is identity-only |
| Multiple Mastodon accounts per user | `oauth_identities` unique on `(user_id, provider)` |
| Live Mastodon OAuth round-trip in Cucumber CI | Facebook precedent: static presence check sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STRAT-01 | Phase 119 | Pending |
| STRAT-02 | Phase 119 | Pending |
| STRAT-03 | Phase 119 | Pending |
| STRAT-04 | Phase 119 | Pending |
| INST-01 | Phase 120 | Pending |
| INST-02 | Phase 120 | Pending |
| IDNT-01 | Phase 121 | Pending |
| IDNT-02 | Phase 121 | Pending |
| IDNT-03 | Phase 121 | Pending |
| VIEW-01 | Phase 122 | Pending |
| VIEW-02 | Phase 122 | Pending |
| VIEW-03 | Phase 122 | Pending |
| CTRL-01 | Phase 121 | Pending |
| CTRL-02 | Phase 123 | Pending |
| TEST-01 | Phase 123 | Pending |
| TEST-02 | Phase 123 | Pending |

**Coverage:**
- v1.35 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-12*
*Last updated: 2026-06-12 after roadmap creation*
