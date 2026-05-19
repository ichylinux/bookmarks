# Phase 90: OAuth2 Email Scope Wiring — Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

X OAuth2 re-authentication captures and persists the user's real email address for users who previously received a dummy-pattern email. New user creation already stores the real email. This phase closes OAUTH-03 (re-auth email update) and verifies OAUTH-01 and OAUTH-02.

</domain>

<decisions>
## Implementation Decisions

### OAUTH-01 — Scope (already done, verify only)
The `users.email` scope is already configured in `config/initializers/devise.rb` line 267:
```
scope: 'tweet.read users.read follows.read users.email offline.access'
```
No code change needed. Phase 90 should add a comment or test assertion confirming the scope is present.

### OAUTH-02 — New user email (already done, verify only)
The `:twitter2` create branch in `User.from_omniauth` already stores `data['email'].presence || "dummy_...@example.com"`. Test `test_twitter2_from_omniauth_creates_new_user_with_email_when_provided` already covers this. No code change needed.

### OAUTH-03 — Re-auth email update (real change)
In the `:twitter2` re-auth branch of `User.from_omniauth`, add email overwrite under two conditions:
- `data['email'].present?` — X provides a real email
- `user.email =~ /\Adummy_.+@example\.com\z/` — user currently has a dummy email

Append `email: data['email']` to the `assign_attributes` attrs hash when both conditions are met.
Use the same `save(validate: false)` path — no change to the save call. Collision handling: skip silently (accept the `save(validate: false)` behavior which skips uniqueness — this matches the existing pattern for all other re-auth attribute updates in this branch).

**Exact insertion point:** Inside the `if user` block, before `user.assign_attributes(attrs)`.

### Test fixtures and scenarios
All OAUTH-03 tests go in the existing `test/models/user_test.rb` file.

**Fixture:** `:twitter_user` — temporarily set `email` to a dummy pattern in the test body using `update_columns`; restore in `ensure`.

**Three required scenarios:**
1. `test_twitter2_from_omniauth_updates_dummy_email_on_reauth` — existing user has `dummy_uuid@example.com`, X provides real email, re-auth → `user.email` is updated to real email
2. `test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth` — existing user has real (non-dummy) email, X provides email on re-auth → email unchanged
3. `test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none` — existing user has dummy email, X provides no email (nil/absent from `data`), re-auth → email unchanged

### Dummy email pattern
Use `/\Adummy_.+@example\.com\z/` consistently — the same pattern used in the model validation.

</decisions>

<code_context>
## Existing Code Insights

**`app/models/user.rb`** — `User.from_omniauth` `:twitter2` branch (lines ~60-85):
- `if user` (re-auth): only updates `oauth2_token`, `oauth2_refresh_token`, `oauth2_token_expires_at` — does NOT touch email
- `else` (create): stores `data['email'].presence || "dummy_..."` — already correct
- `save(validate: false)` is used for the re-auth save

**`config/initializers/devise.rb`** line 264-267:
```ruby
config.omniauth :twitter2,
    Rails.application.config.app_config.omniauth_twitter2_client_id,
    Rails.application.config.app_config.omniauth_twitter2_client_secret,
    scope: 'tweet.read users.read follows.read users.email offline.access'
```
`users.email` is already present.

**`test/models/user_test.rb`** — existing twitter2 tests:
- `test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user` — re-auth without email, uses `:twitter_user`
- `test_twitter2_from_omniauth_creates_new_user_with_email_when_provided` — create with email
- Template for new tests: use `users(:twitter_user)`, `update_columns` in setup, restore in `ensure`

**Dummy email pattern (authoritative):** `/\Adummy_.+@example\.com\z/` (from `validates :email, format: { without: ... }`)

</code_context>

<specifics>
## Specific Implementation Notes

- The OAUTH-03 change is ~5 lines inside the existing `if user` block in `from_omniauth`
- Do NOT change the `save(validate: false)` call — adding email to attrs is sufficient
- Three new test methods in `user_test.rb`, no new files
- No migrations, no routes, no view changes
- Tri-suite gate required: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`

</specifics>

<canonical_refs>
## Canonical References

- `app/models/user.rb` — `User.from_omniauth` method (lines ~28-90)
- `config/initializers/devise.rb` — twitter2 OmniAuth config (lines ~264-267)
- `test/models/user_test.rb` — existing twitter2 test methods (~lines 108-155)
- `.planning/REQUIREMENTS.md` — OAUTH-01, OAUTH-02, OAUTH-03 definitions

</canonical_refs>

<deferred>
## Deferred Ideas

None identified.

</deferred>
