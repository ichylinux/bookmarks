# Requirements: Bookmarks v1.34

**Defined:** 2026-05-24
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### Identity

- [x] **IDNT-01**: `oauth_identities(user_id, provider, uid)` table stores one row per linked OAuth provider per user
- [x] **IDNT-02**: `from_omniauth` creates or updates an `OauthIdentity` row on each successful sign-in (all 3 providers: google_oauth2, twitter2, facebook)
- [x] **IDNT-03**: Existing X-linked accounts backfilled from `users.provider` / `users.uid` via migration

### Form Auth

- [x] **FORM-01**: `password_auth_enabled boolean NOT NULL DEFAULT false` column on `users` tracks whether the user has set a real password
- [x] **FORM-02**: `password_auth_enabled` set to `true` after user completes Devise password reset flow (via `after_password_reset` callback)
- [x] **FORM-03**: User can disconnect form auth from Connected Accounts (sets `password_auth_enabled: false`, randomizes password)

### View

- [x] **VIEW-01**: Preferences page shows "Connected Accounts" section listing all 4 auth methods (Google, X, Facebook, Email & Password) with icons and linked/unlinked status
- [x] **VIEW-02**: Linked providers show a Disconnect button; unlinked providers show a "Not connected" state
- [x] **VIEW-03**: Bilingual (ja/en) labels for section heading, provider names, disconnect button, and status text

### Controller

- [x] **CTRL-01**: `DELETE /oauth_identities/:provider` unlinks the named OAuth provider from the current user's account
- [x] **CTRL-02**: Disconnect blocked with a localized error flash if it would leave the user with no remaining auth method (no other OAuth provider linked and `password_auth_enabled: false`)

### Test

- [x] **TEST-01**: Minitest covers `OauthIdentity` model, `password_auth_enabled` tracking, disconnect controller (success + guard block), and preferences page Connected Accounts rendering
- [x] **TEST-02**: Cucumber E2E covers connected accounts view in preferences, OAuth provider disconnect success, and last-auth-method guard

## v2 Requirements

### Identity

- **IDNT-FUT-01**: User can connect a new OAuth provider directly from the preferences page (currently only possible via sign-in)

### Form Auth

- **FORM-FUT-01**: User can change their password from preferences without going through the reset flow

## Out of Scope

| Feature | Reason |
|---------|--------|
| Connect new provider from preferences | Sign-in pages are the only linking surface for this milestone |
| Multiple linked accounts from the same provider | Schema constraint: one row per (user_id, provider) |
| Token refresh / credential update for connected providers | Out of scope; providers manage their own token lifecycle |
| Password strength meter on reset form | Devise default is sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IDNT-01 | Phase 114 | Complete |
| IDNT-02 | Phase 114 | Complete |
| IDNT-03 | Phase 114 | Complete |
| FORM-01 | Phase 115 | Complete |
| FORM-02 | Phase 115 | Complete |
| FORM-03 | Phase 115 | Complete |
| CTRL-01 | Phase 116 | Complete |
| CTRL-02 | Phase 116 | Complete |
| VIEW-01 | Phase 117 | Complete |
| VIEW-02 | Phase 117 | Complete |
| VIEW-03 | Phase 117 | Complete |
| TEST-01 | Phase 118 | Complete |
| TEST-02 | Phase 118 | Complete |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after roadmap creation (all 13 requirements mapped)*
