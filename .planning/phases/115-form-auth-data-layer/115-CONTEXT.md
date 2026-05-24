# Phase 115: Form Auth Data Layer - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Mode:** Retroactive (code already implemented in commit 17fbbbd)

<domain>
## Phase Boundary

Add `password_auth_enabled` boolean column to `users` table and implement the two-way lifecycle for it:
- `after_password_reset` callback sets it `true` when a user completes a Devise password reset flow
- `disconnect_form_auth!` sets it `false` and randomizes the encrypted password to revoke email/password sign-in

No UI changes. No OAuth changes. Pure data layer enabling the disconnect safety guard in Phase 116.

</domain>

<decisions>
## Implementation Decisions

### Schema
- **D-01:** Migration adds `password_auth_enabled boolean NOT NULL DEFAULT false` to `users` — existing rows default to `false` (no existing users have used the password reset flow in production)

### Callback Trigger
- **D-02:** `before_save :after_password_reset, if: -> { encrypted_password_changed? && reset_password_token_was.present? }` — fires only during the Devise password reset flow (reset_password_token_was is non-nil), not on normal password changes or OAuth user creation

### Disconnect Implementation
- **D-03:** `disconnect_form_auth!` uses `update_columns` (bypasses callbacks) to atomically set `password_auth_enabled: false` and randomize `encrypted_password` to a valid bcrypt hash of a random hex string — prevents valid_password? from matching any input

### Claude's Discretion
- `update_columns` chosen over `update!` to bypass the `after_password_reset` callback that would re-enable the flag

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Devise `encrypted_password` and `reset_password_token` columns already exist on users
- `Devise::Encryptor.digest(self.class, SecureRandom.hex)` produces a valid bcrypt hash for the randomized password

### Established Patterns
- `before_save` callbacks on User model follow existing pattern (e.g., `generate_otp_secret_if_missing`)
- `update_columns` used for bypassing callbacks in other parts of the app

### Integration Points
- `app/models/user.rb` — `after_password_reset` private method + `disconnect_form_auth!` public method
- `db/migrate/20260524000003_add_password_auth_enabled_to_users.rb`
- `test/models/user_password_auth_test.rb` — 5 Minitest cases

</code_context>

<specifics>
## Specific Ideas

- The flag is checked in Phase 116's safety guard: disconnect is blocked if `oauth_identities` is empty AND `password_auth_enabled: false`
- No UI for this phase — purely server-side data layer

</specifics>

<deferred>
## Deferred Ideas

- FORM-FUT-01: change password from preferences without reset flow — deferred to v2

</deferred>

---

*Phase: 115-Form Auth Data Layer*
*Context gathered: 2026-05-24 (retroactive)*
