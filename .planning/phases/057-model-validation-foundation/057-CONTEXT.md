---
phase: 57
name: Model Validation Foundation
date: 2026-05-13
status: discussed
mode: autonomous (self-discuss)
---

# Phase 57 Context: Model Validation Foundation

## Domain

Add an on-update validator to the User model that rejects dummy-pattern email addresses (`dummy_<uuid>@example.com`). The validator must NOT fire on create — the Twitter `from_omniauth` path legitimately writes dummy addresses when creating new accounts. Devise `:validatable` already handles format and uniqueness; this phase adds the dummy-pattern rejection on top.

## Decisions

### Validator implementation style

**Decision:** Inline `validates` in User model.

All existing validators in this project are inline calls (`validates :email`, `validates :font_size`, etc.). No custom validator classes exist in `app/validators/`. Adding a separate class for a single regex would add file complexity without benefit.

Implementation:

```ruby
validates :email,
  format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
  on: :update
```

### Regex anchoring

**Decision:** Use `\A` and `\z` (string boundary anchors) with escaped `.` in `example\.com`.

The existing `has_valid_email?` uses `^`/`$` (line boundary). For a Rails validation, `\A`/`\z` is the correct choice — it prevents a multi-line bypass where `\nreal@other.com` would sneak past a `^`/`$` regex. The unescaped `.` in `example.com` is a minor imprecision; the new validator escapes it.

`has_valid_email?` is display logic (used in `display_name` and controller guards) — it is NOT changed in this phase. The two regexes serve different purposes and can diverge safely.

### Error message key

**Decision:** Use `message: :dummy_email` as the custom message key.

Rails resolves this to `activerecord.errors.models.user.attributes.email.dummy_email` in the locale YAML. If the key is absent, Rails falls back to the generic format error text — acceptable for Phase 57 tests which check only `errors[:email].present?`. Locale strings (`ja.yml` / `en.yml`) are added in Phase 59 (I18N-01).

### Twitter dummy-email fixture

**Decision:** Add a named YAML fixture `twitter_user` to `test/fixtures/users.yml`.

The users schema has:
- `otp_secret NOT NULL` — every fixture must include it
- `name` with a unique index — must use a unique value
- No NOT NULL constraint on `name`, `provider`, `uid` — omit for simplicity

Fixture spec:

```yaml
twitter_user:
  email: dummy_00000000-0000-0000-0000-000000000001@example.com
  name: twitter_test_user
  encrypted_password: $2a$10$JifTmwNy.DQ4Sbs.Y3xW.uVQ4xj54RWqL25AU0OR62WVug5Pz3Jy6
  otp_secret: KCWJDXNH2EJIHB7NUZL42TFZYDRWERPB
  otp_required_for_login: false
```

Using a deterministic UUID (all zeros + suffix `1`) keeps the fixture readable and avoids random values in version control. The bcrypt hash and otp_secret values are reused from existing fixtures (password: `password`, same TOTP secret for test convenience).

### Test file

**Decision:** Create `test/models/user_test.rb` (class `UserTest < ActiveSupport::TestCase`).

No `user_test.rb` exists; `user_two_factor_test.rb` shows the convention. Four tests are required by Phase 57 success criteria:

1. `test_dummy_email_rejected_on_update` — assign dummy pattern, call `valid?`, assert `errors[:email].present?`
2. `test_malformed_email_rejected_on_update` — assign `not-an-email`, call `valid?`, assert `errors[:email].present?` (Devise `:validatable` catches this)
3. `test_valid_real_email_accepted_on_update` — assign `real@example.com`, call `valid?`, assert `errors[:email].empty?`
4. `test_dummy_email_allowed_on_create` — `User.new` with dummy email + password, call `valid?`, assert `errors[:email].empty?` (on: :update means no firing on create)

Use the `twitter_user` fixture for tests 1 and 3 (already has a dummy email, saves a `User.new` call). Use `User.new` directly for test 4 to test the create path in isolation.

## Canonical Refs

- `app/models/user.rb` — User model; validator added here
- `test/fixtures/users.yml` — `twitter_user` fixture added here
- `test/models/user_test.rb` — new model test file
- `.planning/REQUIREMENTS.md` — EMAIL-01 requirement (dummy-pattern rejection on update path)
- `.planning/ROADMAP.md` — Phase 57 success criteria
