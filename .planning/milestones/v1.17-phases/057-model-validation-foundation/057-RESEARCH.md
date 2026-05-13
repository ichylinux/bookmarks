# Phase 57 Research: Model Validation Foundation

**Phase**: 57 — Model Validation Foundation
**Requirement**: EMAIL-01
**Researched**: 2026-05-13

---

## Summary

Phase 57 is a pure model change: one inline validator added to `User`, one new fixture row, one new test file. No migrations, no routes, no views. All decisions were pre-resolved in `057-CONTEXT.md` (self-discuss session). This research confirms those decisions against the live codebase.

---

## 1. Current User Model State

**Confidence**: HIGH [VERIFIED: app/models/user.rb]

### Relevant existing code

- Devise modules: `:two_factor_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable` (line 4-6)
- `:validatable` provides: email format validation, email presence, email uniqueness, password presence/length/confirmation — fires on both create and update [ASSUMED: Devise `:validatable` behavior]
- `has_valid_email?` already exists (lines 43-47):
  ```ruby
  def has_valid_email?
    return false if email.blank?
    return false if email =~ /^dummy_.+@example.com$/
    true
  end
  ```
  This is **display/guard logic only** — it is not a model validation and does not block saves.

### What is missing

No validator currently blocks `dummy_<uuid>@example.com` from being written via the update path. Devise `:validatable` accepts it because it is a syntactically valid email address. A custom validator scoped to `on: :update` must be added.

### Twitter `from_omniauth` create path (lines 25-27)

```ruby
when :twitter
  user = User.where(name: data["name"]).first
  user ||= User.create(name: data['name'], email: "dummy_#{SecureRandom.uuid}@example.com", password: Devise.friendly_token[0,20])
```

This is a `User.create` call — Rails lifecycle triggers `on: :create` and `on: :create_or_update` validations, NOT `on: :update`. A validator scoped `on: :update` will not fire here. **This is the key correctness constraint for Phase 57.**

---

## 2. Validator Design

**Confidence**: HIGH [VERIFIED: 057-CONTEXT.md decisions + app/models/user.rb inspection]

### Implementation

Inline `validates` call in `user.rb` (no separate validator class):

```ruby
validates :email,
  format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
  on: :update
```

### Why inline, not a validator class

[VERIFIED: codebase has no `app/validators/` directory] No custom validator classes exist. All validation in this project uses inline `validates` calls. Adding a separate class for one regex rule would add file complexity without benefit.

### Regex anchoring: `\A`/`\z` vs `^`/`$`

[VERIFIED: existing `has_valid_email?` uses `^`/`$`]

The existing `has_valid_email?` uses `^`/`$` (line-boundary anchors). For a Rails validation, `\A`/`\z` (string-boundary anchors) is correct — it prevents a multi-line bypass where `\nreal@attacker.com` could match past a `^`/`$` anchor. The `.` in `example.com` is also escaped to `example\.com`.

`has_valid_email?` is NOT changed — it is display/guard logic used in controllers and views. The two regex instances serve different purposes.

### Error message key

`message: :dummy_email` — Rails resolves this to `activerecord.errors.models.user.attributes.email.dummy_email`. If the locale key is absent, Rails falls back to the generic format error. Phase 57 tests check only `errors[:email].present?`, so absent locale keys will not cause test failures. Locale strings are added in Phase 59 (I18N-01).

---

## 3. Fixture Design

**Confidence**: HIGH [VERIFIED: test/fixtures/users.yml, db/schema.rb]

### Current fixtures

| Label | ID | email |
|-------|----|-------|
| `1`   | 1  | `user@example.com` (admin) |
| `2`   | 2  | `user2@example.com` |
| `3`   | 3  | `user3@example.com` |

No Twitter dummy-email fixture exists.

### Schema constraints on users table

[VERIFIED: db/schema.rb lines 96-120]

- `email` — `default: ""`, NOT NULL
- `otp_secret` — NOT NULL (every fixture must include it)
- `name` — has unique index (`index_users_on_name, unique: true`); must be distinct
- `provider`, `uid` — nullable, can be omitted
- `encrypted_password` — NOT NULL (Devise requirement)

### New fixture

```yaml
twitter_user:
  email: dummy_00000000-0000-0000-0000-000000000001@example.com
  name: twitter_test_user
  encrypted_password: $2a$10$JifTmwNy.DQ4Sbs.Y3xW.uVQ4xj54RWqL25AU0OR62WVug5Pz3Jy6
  otp_secret: KCWJDXNH2EJIHB7NUZL42TFZYDRWERPB
  otp_required_for_login: false
```

- Deterministic UUID (all-zeros + `1`) — readable, no random values in VCS
- `bcrypt` hash and `otp_secret` reused from existing fixtures (password: `password`)
- No explicit `id` — Rails assigns next auto-increment (will be 4 in practice; tests reference it by label `users(:twitter_user)`, not by integer)
- No `admin` field — defaults to `false`

### Preference fixture dependency

[VERIFIED: test/fixtures/preferences.yml] Preferences exist for users 1, 2, 3 only. A `twitter_user` preference fixture is NOT needed for Phase 57 (model tests don't exercise preferences). Phase 58/59 controller tests may need it — note for future research.

---

## 4. Test File Design

**Confidence**: HIGH [VERIFIED: test/models/ directory listing, test/test_helper.rb, test/support/users.rb]

### Conventions

- Model tests: `class FooTest < ActiveSupport::TestCase` in `test/models/foo_test.rb`
- `user` helper = `User.first` (id=1, `user@example.com`) [VERIFIED: test/support/users.rb]
- `fixtures :all` loaded globally [VERIFIED: test/test_helper.rb]
- No existing `test/models/user_test.rb` — must be created

### Four required tests (from success criteria)

| Test name | What it tests | Fixture / setup |
|-----------|---------------|-----------------|
| `test_dummy_email_rejected_on_update` | Validator fires on update; `errors[:email]` present | `users(:twitter_user)` — assign dummy email, call `valid?` |
| `test_malformed_email_rejected_on_update` | Devise `:validatable` format check fires on update | `users(:twitter_user)` — assign `"not-an-email"`, call `valid?` |
| `test_valid_real_email_accepted_on_update` | Valid real email passes both Devise and custom validator | `users(:twitter_user)` — assign `"real@example.com"`, call `valid?` |
| `test_dummy_email_allowed_on_create` | `on: :update` scoping prevents validator from firing on create | `User.new(email: "dummy_...", password: "...")`, call `valid?` |

Tests 1 and 3 reuse `users(:twitter_user)` — it already has a dummy email, so no in-memory setup needed. Test 4 uses `User.new` to isolate the create path.

---

## 5. Devise `:validatable` Interaction

**Confidence**: MEDIUM [ASSUMED: Devise source behavior — not verified from gem source in this session]

Devise `:validatable` adds these validations:
- `validates_presence_of :email, if: :email_required?`
- `validates_uniqueness_of :email, allow_blank: true, if: :email_changed?`
- `validates_format_of :email, with: Devise.email_regexp, allow_blank: true, if: :email_changed?`

These fire on both create and update. The custom `on: :update` validator is additive — it does not interfere with Devise's validators. On create, only Devise validators run; on update, both Devise validators and the new custom validator run.

**Implication**: Test 2 (malformed email rejected on update) exercises Devise's format validator, not the custom one. Both validators can report errors simultaneously when an update has both a malformed and a dummy-pattern address — this is fine.

---

## 6. Files Changed in Phase 57

**Confidence**: HIGH [VERIFIED: codebase structure]

| File | Change |
|------|--------|
| `app/models/user.rb` | Add one `validates` call (inline, ~3 lines) |
| `test/fixtures/users.yml` | Add `twitter_user` fixture entry |
| `test/models/user_test.rb` | Create new file with 4 model tests |

**No other files change in Phase 57.** Routes, controllers, views, and locale files are Phase 58/59.

---

## 7. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Validator fires on create, breaking Twitter sign-up | LOW | HIGH | `on: :update` scoping; test 4 explicitly covers this |
| Existing tests broken by new fixture (name uniqueness conflict) | LOW | MEDIUM | `twitter_test_user` name is unique in fixture set |
| `otp_secret NOT NULL` causes fixture load failure | LOW | HIGH | Fixture includes `otp_secret` copied from existing rows |
| Devise `:validatable` already validates format on update — duplicate errors on malformed email | LOW | LOW | Acceptable; `errors[:email].present?` is sufficient check |

---

## 8. Canonical File Paths

[VERIFIED: codebase inspection]

- `app/models/user.rb` — User model, line 1-93
- `test/fixtures/users.yml` — user fixtures, currently lines 1-22
- `test/models/user_test.rb` — does not yet exist
- `test/support/users.rb` — `user` helper (User.first)
- `test/test_helper.rb` — test setup, `fixtures :all`
- `db/schema.rb` — users table definition, lines 96-120
