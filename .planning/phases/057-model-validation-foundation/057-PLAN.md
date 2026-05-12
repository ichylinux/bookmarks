# Phase 57 Plan: Model Validation Foundation

**Phase**: 57
**Goal**: The User model safely rejects dummy-pattern and invalid email addresses on update, without affecting the Twitter OAuth account-creation path
**Requirement**: EMAIL-01
**Files changed**: 3 (user.rb, users.yml, user_test.rb)
**Verification gate**: `yarn run lint && bin/rails test`

---

## Locked Decisions (NON-NEGOTIABLE)

From `057-CONTEXT.md` — do not reinterpret:

- Validator is inline in `app/models/user.rb` — NO separate validator class
- Regex: `\A` / `\z` anchors, escaped `example\.com`; `on: :update` only
- Error message key: `message: :dummy_email` (locale key added in Phase 59 — not now)
- `has_valid_email?` is NOT modified (it is display/guard logic, not a validator)
- No migration, no new gems, no routes, no views

---

## Wave 1 — Parallel (no dependencies between tasks)

### Task A: Add dummy-email validator to User model

**File**: `app/models/user.rb`

**What to do**: Add one inline `validates` call immediately after the existing Devise `devise` declaration block (after line 6, before `before_create`). Do not move, reformat, or touch any other code.

**Exact change** — insert these 3 lines:

```ruby
validates :email,
  format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
  on: :update
```

Insert location: after the closing paren of the `devise` call (line 6), before `before_create :generate_otp_secret_if_missing` (line 8). Leave a blank line before and after the new block to match surrounding style.

**Done when**: `app/models/user.rb` contains the `validates :email, format: { without: ... }, on: :update` call and no other lines are changed.

---

### Task B: Add twitter_user fixture

**File**: `test/fixtures/users.yml`

**What to do**: Append the following entry at the end of the file. Do not modify existing fixtures.

```yaml
twitter_user:
  email: dummy_00000000-0000-0000-0000-000000000001@example.com
  name: twitter_test_user
  encrypted_password: $2a$10$JifTmwNy.DQ4Sbs.Y3xW.uVQ4xj54RWqL25AU0OR62WVug5Pz3Jy6
  otp_secret: KCWJDXNH2EJIHB7NUZL42TFZYDRWERPB
  otp_required_for_login: false
```

Field notes:
- `email`: deterministic UUID with suffix `1` — readable, stable in VCS
- `name`: `twitter_test_user` — unique; no conflict with existing fixtures (`1`, `2`, `3` have no name set)
- `encrypted_password`: same bcrypt hash used by existing fixtures (password: `password`)
- `otp_secret`: same value as existing fixtures (safe for test convenience)
- No `id` field — Rails assigns auto-increment (tests reference by label `users(:twitter_user)`)
- No `admin` field — defaults to false

**Done when**: `test/fixtures/users.yml` has the `twitter_user` entry appended and all existing entries are unchanged.

---

## Wave 2 — Depends on Wave 1

### Task C: Create User model test file

**File**: `test/models/user_test.rb` (create new — does not exist)

**Conventions** (from `test/models/user_two_factor_test.rb`):
- `require 'test_helper'` at top
- Class inherits `ActiveSupport::TestCase`
- `def test_*` methods (no `setup` block needed)
- Use `users(:twitter_user)` to load the fixture record
- `user` helper = `User.first` (available from `test/support/users.rb`) — use `users(:twitter_user)` directly instead

**Exact content**:

```ruby
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def test_dummy_email_rejected_on_update
    u = users(:twitter_user)
    u.email = "dummy_00000000-0000-0000-0000-000000000099@example.com"
    u.valid?
    assert u.errors[:email].present?
  end

  def test_malformed_email_rejected_on_update
    u = users(:twitter_user)
    u.email = "not-an-email"
    u.valid?
    assert u.errors[:email].present?
  end

  def test_valid_real_email_accepted_on_update
    u = users(:twitter_user)
    u.email = "real@example.com"
    u.valid?
    assert u.errors[:email].empty?
  end

  def test_dummy_email_allowed_on_create
    u = User.new(
      email: "dummy_00000000-0000-0000-0000-000000000099@example.com",
      password: "password123"
    )
    u.valid?
    assert u.errors[:email].empty?
  end
end
```

Test rationale:
1. `test_dummy_email_rejected_on_update` — custom validator fires; dummy pattern blocked
2. `test_malformed_email_rejected_on_update` — Devise `:validatable` format check fires
3. `test_valid_real_email_accepted_on_update` — passes both Devise and custom validator
4. `test_dummy_email_allowed_on_create` — `on: :update` scoping; validator does NOT fire on create

**Done when**: `test/models/user_test.rb` exists and all 4 tests are present.

---

## Verification Gate

Run after all three tasks are complete:

```
yarn run lint && bin/rails test
```

**Expected results**:
- `yarn run lint` — green (no Ruby files linted by ESLint; this just confirms no JS regressions)
- `bin/rails test` — all tests pass, including the 4 new `UserTest` tests

**Do NOT run** `bundle exec rake dad:test` for Phase 57 — no Cucumber scenarios are added or affected.

**Phase 57 is complete when**:
1. All 3 files are changed/created as specified above
2. `yarn run lint` passes
3. `bin/rails test` passes with 4 new `UserTest` tests green

---

## Success Criteria Traceability

| Success Criterion | Task | Test |
|-------------------|------|------|
| dummy-pattern address fails on update | Task A | `test_dummy_email_rejected_on_update` |
| malformed email fails on update | Task A (Devise) | `test_malformed_email_rejected_on_update` |
| Twitter `from_omniauth` create path unaffected | Task A (`on: :update`) | `test_dummy_email_allowed_on_create` |
| twitter_user fixture exists for controller tests | Task B | (fixture load validates it) |

---

## What This Phase Does NOT Do

- No locale keys — `dummy_email` key added in Phase 59
- No `has_valid_email?` change — it is display logic, not a validator
- No Cucumber scenarios
- No controller, route, or view changes
- No `preferences.yml` fixture for `twitter_user` — Phase 58/59 will add if needed
