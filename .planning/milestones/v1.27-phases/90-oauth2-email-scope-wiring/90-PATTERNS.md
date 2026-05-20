# Phase 90: oauth2-email-scope-wiring - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/models/user.rb` | model | request-response | same file — `:twitter` re-auth branch (lines 46-50) | exact |
| `test/models/user_test.rb` | test | CRUD | same file — `test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user` (lines 108-126) | exact |

---

## Pattern Assignments

### `app/models/user.rb` — `:twitter2` re-auth branch (lines 66-73)

**Change site:** inside the `if user` block of the `:twitter2` case, `assign_attributes` call needs an additional `email:` key when the incoming auth carries a real email and the stored email is a dummy.

**Existing `:twitter2` re-auth block** (lines 66-73):
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

**Analog — `:twitter` re-auth block** (lines 47-50):
```ruby
if user
  user.assign_attributes(attrs)
  user.save(validate: false)
  user
```

**Dummy-email guard — `has_valid_email?`** (lines 101-105):
```ruby
def has_valid_email?
  return false if email.blank?
  return false if email =~ /^dummy_.+@example.com$/
  true
end
```

**Validation regex (on `:update` only)** (lines 11-13):
```ruby
validates :email,
          format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
          on: :update
```

**Email fallback on create** (lines 82-82):
```ruby
email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
```

**Pattern to apply in the change:**
```ruby
if user
  new_attrs = {
    oauth2_token: creds['token'],
    oauth2_refresh_token: creds['refresh_token'],
    oauth2_token_expires_at: expires_at
  }
  if data['email'].present? && !user.has_valid_email?
    new_attrs[:email] = data['email']
  end
  user.assign_attributes(new_attrs)
  user.save(validate: false)
  user
```

---

### `test/models/user_test.rb` — new twitter2 re-auth email test

**Closest analog — `test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user`** (lines 108-126):
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
  assert_equal 'ref-tok', u.oauth2_refresh_token
  assert_in_delta expires_ts, u.oauth2_token_expires_at.to_i, 1
ensure
  u = users(:twitter_user)
  u.update_columns(oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil)
end
```

**Fixture state** (`test/fixtures/users.yml`, lines 23-32):
```yaml
twitter_user:
  email: dummy_00000000-0000-0000-0000-000000000001@example.com
  name: twitter_test_user
  provider: twitter
  uid: fixture_twitter_uid
  token: fixture_plain_token
  token_secret: fixture_plain_secret
```

**`ensure` restore pattern** — always use `update_columns` (bypasses validations and callbacks) to restore all columns touched during the test:
```ruby
ensure
  u = users(:twitter_user)
  u.update_columns(email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
                   oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil)
```

**New test structure to mirror:**
- Load `users(:twitter_user)` (starts with dummy email — confirmed by fixture line 24)
- Build `OmniAuth::AuthHash` with `'info' => { 'email' => 'real@twitter.example.com' }` added
- Call `User.from_omniauth(auth)`, reload `u`
- Assert `u.email == 'real@twitter.example.com'`
- Also add a negative test: when user already has a real email, re-auth must NOT overwrite it
- `ensure`: restore email to fixture dummy value via `update_columns`

---

## Shared Patterns

### Dummy-email detection
**Source:** `app/models/user.rb` lines 101-105 (`has_valid_email?`)
**Apply to:** the new `if` guard in the `:twitter2` re-auth branch
```ruby
return false if email =~ /^dummy_.+@example.com$/
```
Use `user.has_valid_email?` (already defined) rather than inlining the regex.

### save without validation
**Source:** `app/models/user.rb` lines 49, 72
**Apply to:** all `assign_attributes` + persist paths
```ruby
user.save(validate: false)
```
Email column updates via `assign_attributes` must also go through `save(validate: false)` — the `validates :email, on: :update` guard would block a dummy-to-real transition because `format: { without: ... }` only rejects dummy patterns, but Devise's own email format validator may reject `nil` or unusual formats; keeping `validate: false` is consistent with the whole branch.

### Test fixture restore
**Source:** `test/models/user_test.rb` lines 66-72
**Apply to:** any test that mutates `twitter_user.email`
```ruby
ensure
  u.reload
  u.update_columns(
    email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
    # ...any other columns touched
  )
```

---

## No Analog Found

None — both files are fully covered by existing patterns in the same files.

---

## Metadata

**Analog search scope:** `app/models/user.rb`, `test/models/user_test.rb`, `test/fixtures/users.yml`
**Files scanned:** 3
**Pattern extraction date:** 2026-05-19
