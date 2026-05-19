# Phase 90: OAuth2 Email Scope Wiring — Research

**Researched:** 2026-05-19
**Domain:** Rails model — `User.from_omniauth` X OAuth2 re-authentication email update
**Confidence:** HIGH (all findings verified from codebase — no web research required)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- OAUTH-01 (scope): `users.email` is already in devise.rb — verify only, no code change
- OAUTH-02 (new user creation): `data['email'].presence || "dummy_..."` is already in the `else` branch — verify only, no code change
- OAUTH-03 (re-auth email update): Add conditional email overwrite inside the `if user` block of the `:twitter2` case, before `assign_attributes`, using `save(validate: false)` path unchanged
- Collision handling: skip silently — `save(validate: false)` already skips uniqueness validation, consistent with all other re-auth attribute updates
- Dummy pattern: `/\Adummy_.+@example\.com\z/` — authoritative regex, used in both validation and new test conditions
- Three new test methods only in `test/models/user_test.rb` — no new files
- No migrations, routes, or view changes

### Claude's Discretion

None specified.

### Deferred Ideas (OUT OF SCOPE)

None identified.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OAUTH-01 | X OAuth2 sign-in requests the `email` scope | Verified at devise.rb line 267: `users.email` present in scope string |
| OAUTH-02 | `User.from_omniauth` stores real X email on new user creation | Verified at user.rb line 82: `data['email'].presence \|\| "dummy_..."` in `else` branch |
| OAUTH-03 | On re-authentication, overwrite dummy-pattern email with real X email | NOT YET implemented — current re-auth branch (lines 67-71) updates only token fields, never email |
</phase_requirements>

---

## Summary

Phase 90 is a narrow, high-confidence model change. The `:twitter2` re-authentication branch in `User.from_omniauth` currently updates only `oauth2_token`, `oauth2_refresh_token`, and `oauth2_token_expires_at`, leaving the user's email untouched even when X provides a real address. Users created before email scope was wired up hold a `dummy_UUID@example.com` address that is never corrected on subsequent sign-ins.

The fix is roughly five lines: build an attrs hash, conditionally merge `email: data['email']` when the user currently holds a dummy-pattern email and X supplies a real one, then pass the hash to `assign_attributes`. The `save(validate: false)` call is unchanged. The email validation (`on: :update, format: { without: /\Adummy_.../ }`) is irrelevant because the update uses `save(validate: false)`.

Three new test methods cover the three meaningful scenarios (dummy email updated, real email preserved, no email from X leaves dummy unchanged). The fixture `:twitter_user` already holds a dummy email and is the correct vehicle for all three tests; each test temporarily overwrites the email via `update_columns` and restores it in `ensure`.

**Primary recommendation:** Edit lines 66-73 of `app/models/user.rb`; add three test methods to `test/models/user_test.rb`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OAuth2 re-auth email capture | API / Backend (model) | — | `User.from_omniauth` is a class-method on the model; all OAuth user-record mutations happen here |
| Email validation (no dummy on update) | API / Backend (model) | — | `validates :email, format: { without: ... }, on: :update` lives in User model |
| Dummy email detection at sign-in | API / Backend (model) | — | Condition `user.email =~ /\Adummy_/` evaluated in model code |
| Email scope request | Config (Devise initializer) | — | `scope:` option on `config.omniauth :twitter2` in devise.rb |

---

## Requirement Status — Verification

### OAUTH-01: Email scope in devise.rb
[VERIFIED: codebase]

`config/initializers/devise.rb` lines 264-267:
```ruby
config.omniauth :twitter2,
    Rails.application.config.app_config.omniauth_twitter2_client_id,
    Rails.application.config.app_config.omniauth_twitter2_client_secret,
    scope: 'tweet.read users.read follows.read users.email offline.access'
```
`users.email` is present. No code change needed. The plan should add a comment assertion in the corresponding test or a comment in the code to make the intent explicit.

### OAUTH-02: New user creation stores real email
[VERIFIED: codebase]

`app/models/user.rb` line 82, inside the `:twitter2` `else` branch:
```ruby
email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
```
Already correct. Test `test_twitter2_from_omniauth_creates_new_user_with_email_when_provided` (lines 142-156) covers this path and passes.

### OAUTH-03: Re-auth email overwrite — NOT YET IMPLEMENTED
[VERIFIED: codebase]

`app/models/user.rb` lines 66-73, the `if user` branch:
```ruby
if user
  user.assign_attributes(
    oauth2_token: creds['token'],
    oauth2_refresh_token: creds['refresh_token'],
    oauth2_token_expires_at: expires_at
  )
  user.save(validate: false)
  user
```
No email field is present. This is the exact insertion point.

---

## Exact Insertion Point

**File:** `app/models/user.rb`
**Lines to change:** 66-73 (the `if user` block inside `when :twitter2`)

**Current code (lines 66-73):**
```ruby
      if user
        user.assign_attributes(
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        )
        user.save(validate: false)
        user
```

**Changed code:**
```ruby
      if user
        attrs = {
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        }
        if data['email'].present? && user.email =~ /\Adummy_.+@example\.com\z/
          attrs[:email] = data['email']
        end
        user.assign_attributes(attrs)
        user.save(validate: false)
        user
```

No other lines in user.rb change. Line count increases by approximately 5.

---

## Fixture: `:twitter_user`

[VERIFIED: codebase — `test/fixtures/users.yml` lines 23-33]

| Field | Value |
|-------|-------|
| label | `twitter_user` |
| `email` | `dummy_00000000-0000-0000-0000-000000000001@example.com` |
| `name` | `twitter_test_user` |
| `provider` | `twitter` |
| `uid` | `fixture_twitter_uid` |
| `token` | `fixture_plain_token` |
| `token_secret` | `fixture_plain_secret` |

The fixture email already matches `/\Adummy_.+@example\.com\z/` — no `update_columns` required for scenario 1 (dummy email update). However, for scenario 2 (real email must NOT be overwritten), the test must temporarily set the email to a real address before calling `from_omniauth`, then restore in `ensure`.

---

## Test Pattern Analysis

[VERIFIED: codebase — `test/models/user_test.rb`]

### Existing `:twitter2` re-auth test (lines 108-126) — canonical pattern

```ruby
def test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user
  u = users(:twitter_user)
  expires_ts = Time.now.to_i + 7200
  auth = OmniAuth::AuthHash.new(
    'provider' => 'twitter2',
    'uid' => u.uid,
    'info' => { 'name' => u.name },
    'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => expires_ts, 'expires' => true }
  )
  result = User.from_omniauth(auth)
  assert_equal u.id, result.id
  u.reload
  assert_equal 'bearer-tok', u.oauth2_token
  # ...
ensure
  u = users(:twitter_user)
  u.update_columns(oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil)
end
```

Key observations:
- `users(:twitter_user)` is the fixture vehicle — UID is `fixture_twitter_uid`, provider is `twitter`; the `:twitter2` lookup in `from_omniauth` uses `where(uid:).where(provider: %w[twitter twitter2])` so the fixture is found correctly
- `OmniAuth::AuthHash.new` with string keys throughout
- `'info'` hash contains email when testing email paths (`'email' => 'real@example.com'`)
- `ensure` calls `update_columns` to restore mutated fields
- `u = users(:twitter_user)` is re-fetched inside `ensure` (pattern from line 124) because `save(validate: false)` may have changed the in-memory object

### Three new test scenarios

**Scenario 1 — dummy email updated:**
```ruby
def test_twitter2_from_omniauth_updates_dummy_email_on_reauth
  u = users(:twitter_user)
  # u.email is already dummy_00000000-0000-0000-0000-000000000001@example.com
  auth = OmniAuth::AuthHash.new(
    'provider' => 'twitter2',
    'uid' => u.uid,
    'info' => { 'name' => u.name, 'email' => 'real-x-email@example.com' },
    'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
  )
  User.from_omniauth(auth)
  u.reload
  assert_equal 'real-x-email@example.com', u.email
ensure
  u = users(:twitter_user)
  u.update_columns(
    email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
    oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
  )
end
```

**Scenario 2 — real email preserved:**
```ruby
def test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth
  u = users(:twitter_user)
  u.update_columns(email: 'already-real@example.com')
  auth = OmniAuth::AuthHash.new(
    'provider' => 'twitter2',
    'uid' => u.uid,
    'info' => { 'name' => u.name, 'email' => 'new-x-email@example.com' },
    'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
  )
  User.from_omniauth(auth)
  u.reload
  assert_equal 'already-real@example.com', u.email
ensure
  u = users(:twitter_user)
  u.update_columns(
    email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
    oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
  )
end
```

**Scenario 3 — no email from X, dummy stays:**
```ruby
def test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none
  u = users(:twitter_user)
  # u.email is already dummy — X sends no email
  auth = OmniAuth::AuthHash.new(
    'provider' => 'twitter2',
    'uid' => u.uid,
    'info' => { 'name' => u.name },
    'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
  )
  User.from_omniauth(auth)
  u.reload
  assert_match /\Adummy_/, u.email
ensure
  u = users(:twitter_user)
  u.update_columns(
    email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
    oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
  )
end
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dummy email detection | Custom helper method | Inline regex `/\Adummy_.+@example\.com\z/` | Already the pattern used in model validation; a new helper would be premature for a 5-line change |
| Collision handling | Rescue/retry logic | `save(validate: false)` — existing pattern | Skips uniqueness check, consistent with all other fields in this branch; CONTEXT.md accepts this |

---

## Common Pitfalls

### Pitfall 1: Regex consistency — `has_valid_email?` uses non-anchored pattern
**What goes wrong:** `has_valid_email?` at line 103 uses `/^dummy_.+@example.com$/` (not `\A`/`\z`, no backslash-escaping on `.`). If new code copies this regex instead of the validation regex, subtle mismatches arise.
**Why it happens:** Two independently written regex literals for the same concept.
**How to avoid:** Use `/\Adummy_.+@example\.com\z/` — the anchored, dot-escaped version from the `validates` call at line 12. This is the authoritative pattern per CONTEXT.md.
**Warning signs:** Test for `dummyXfoo@exampleXcom` unexpectedly passing the guard.

### Pitfall 2: `ensure` block uses stale `u` reference
**What goes wrong:** After `save(validate: false)`, the in-memory `u` object has updated attributes. Calling `u.update_columns(...)` on the stale reference is fine for `update_columns` (it goes to DB by id), but if the ensure restores `oauth2_token` without re-fetching, encrypted-attribute caching can cause inconsistency.
**Why it happens:** ActiveRecord Encryption caches decrypted values on the model instance.
**How to avoid:** Re-fetch inside `ensure` with `u = users(:twitter_user)` before `update_columns` — this is the pattern already used in line 124.

### Pitfall 3: `data['email']` is `nil` vs absent vs empty string
**What goes wrong:** When X does not grant email, `data['email']` may be `nil` or the key may be absent entirely. `nil.present?` is `false`, `"".present?` is also `false`, so `.present?` is the correct guard. Using `!= nil` would allow empty string through.
**Why it happens:** OmniAuth info hash sometimes omits keys rather than setting them to nil.
**How to avoid:** Use `data['email'].present?` — already the pattern in the `else` (create) branch at line 82.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (`ActiveSupport::TestCase`) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/models/user_test.rb` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OAUTH-01 | `users.email` scope present in devise.rb | unit (assertion or comment) | `bin/rails test test/models/user_test.rb` | Wave 0: add assertion |
| OAUTH-02 | New user creation stores real email | unit | `bin/rails test test/models/user_test.rb` | Yes — `test_twitter2_from_omniauth_creates_new_user_with_email_when_provided` |
| OAUTH-03 (scenario 1) | Dummy email overwritten on re-auth when X provides real email | unit | `bin/rails test test/models/user_test.rb` | No — add `test_twitter2_from_omniauth_updates_dummy_email_on_reauth` |
| OAUTH-03 (scenario 2) | Real email NOT overwritten on re-auth | unit | `bin/rails test test/models/user_test.rb` | No — add `test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth` |
| OAUTH-03 (scenario 3) | Dummy email unchanged when X provides no email | unit | `bin/rails test test/models/user_test.rb` | No — add `test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none` |

### Sampling Rate
- **Per task commit:** `bin/rails test test/models/user_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` — all green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Three new test methods in `test/models/user_test.rb` covering OAUTH-03 scenarios
- [ ] Optional: add a test assertion (or comment) confirming OAUTH-01 scope — low priority, scope is already verified by reading code

*(No new test files needed — existing infrastructure covers all requirements)*

---

## Environment Availability

Step 2.6: SKIPPED — this phase is a pure code change to an existing model and test file. No external dependencies, runtimes, databases, or CLI tools beyond the project's existing Rails stack.

---

## Runtime State Inventory

Step 2.5: SKIPPED — this is not a rename/refactor/migration phase. The change adds logic to an existing method; no stored keys, collection names, or OS-registered state are affected.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims in this research were verified directly from the codebase. No assumed claims.**

---

## Open Questions

None. All code locations, fixture values, regex patterns, and test structures are confirmed from codebase inspection.

---

## Sources

### Primary (HIGH confidence)
- `app/models/user.rb` — `User.from_omniauth` method (lines 28-91); email validation (lines 11-13); `has_valid_email?` (lines 101-105)
- `config/initializers/devise.rb` — twitter2 OmniAuth config (lines 264-267)
- `test/models/user_test.rb` — all twitter2 test methods (lines 108-156) and encryption tests (lines 158-186)
- `test/fixtures/users.yml` — `:twitter_user` fixture (lines 23-33)
- `app/controllers/users/email_registrations_controller.rb` — confirms `has_valid_email?` is the production gate for email registration flow

## Metadata

**Confidence breakdown:**
- Requirement status (OAUTH-01, 02, 03): HIGH — direct codebase read
- Insertion point (exact lines): HIGH — direct codebase read
- Fixture values: HIGH — direct fixture read
- Test pattern: HIGH — copied from existing test methods in same file
- Regex pattern: HIGH — sourced from model validation, confirmed by CONTEXT.md

**Research date:** 2026-05-19
**Valid until:** stable — this is internal Rails code with no external dependencies
