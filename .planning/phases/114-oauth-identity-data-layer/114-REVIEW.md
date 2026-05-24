---
phase: 114-oauth-identity-data-layer
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - db/migrate/20260524000001_create_oauth_identities.rb
  - db/migrate/20260524000002_backfill_oauth_identities_from_users.rb
  - app/models/oauth_identity.rb
  - test/models/oauth_identity_test.rb
  - app/models/user.rb
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
findings_fixed:
  critical: 2
  warning: 3
status: clean
fix_notes: "CR-01/WR-04 fixed (inline AR classes + IrreversibleMigration); CR-02 fixed (new migration 000005 adds provider+uid unique index); WR-01 fixed (rescue/retry); WR-03 fixed (dependent: :destroy). WR-02 intentionally skipped — create+persisted? guard is correct design for graceful OAuth failure handling."
---

# Phase 114: Code Review Report

**Reviewed:** 2026-05-24T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

This phase introduces the `oauth_identities` table and model as a normalized store for per-provider OAuth credentials, alongside a backfill migration and integration of `OauthIdentity.upsert_for!` into `User.from_omniauth`. The schema and model are structurally sound. Two critical issues were found: the backfill migration references the `OauthIdentity` ActiveRecord model directly (model-in-migration anti-pattern), which is fragile and can break silently, and there is a missing unique index on `oauth_identities.uid` that allows duplicate provider UIDs across users—a security-relevant constraint for OAuth identity binding. Four warnings cover a race condition window in `upsert_for!`, silent swallow of User.create failure in the facebook/google paths, a missing `dependent:` option on `has_many :oauth_identities`, and an untested error path. Two info items cover test coverage gaps.

## Critical Issues

### CR-01: Backfill Migration References AR Model Directly — Fragile and Can Silently Corrupt

**File:** `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb:3-15`

**Issue:** The migration calls `User.where(...)` and `OauthIdentity.find_or_create_by!` directly. ActiveRecord models are not safe to use inside migrations because the model class reflects the current schema at the time the migration runs, not the schema at the time the migration was written. If `OauthIdentity` is later renamed, gains new `null: false` columns without defaults, or has callbacks added, re-running `db:schema:load && db:migrate` (common in CI, new developer setup, or production recovery) will raise. Rails best practice is to define anonymous inline classes inside the migration:

```ruby
class BackfillOauthIdentitiesFromUsers < ActiveRecord::Migration[8.1]
  # Inline models — immune to future changes in the live model
  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class OauthIdentity < ActiveRecord::Base
    self.table_name = 'oauth_identities'
  end

  def up
    rows = User.where.not(provider: nil).where.not(uid: nil)
               .pluck(:id, :provider, :uid, :created_at)
    rows.each do |user_id, provider, uid, created_at|
      OauthIdentity.find_or_create_by!(user_id: user_id, provider: provider) do |i|
        i.uid        = uid
        i.created_at = created_at
        i.updated_at = created_at
      end
    end
  end

  def down; end
end
```

Additionally, because this migration uses model-level `find_or_create_by!`, it bypasses any pure-SQL idempotency guarantee and still carries the TOCTOU race described in WR-01.

### CR-02: No Unique Index on `oauth_identities.uid` — Same Provider UID Can Be Owned by Multiple Users

**File:** `db/migrate/20260524000001_create_oauth_identities.rb:10-12`

**Issue:** The unique index `(user_id, provider)` enforces that one user has at most one record per provider, but it does NOT prevent two different users from sharing the same `(provider, uid)` tuple. In OAuth, a provider UID is globally unique per provider; if two rows have `provider='google_oauth2', uid='abc'` for different user IDs, both users map to the same Google account. This violates the core invariant that an OAuth identity belongs to exactly one user and is a security issue: a timing or bug path in `from_omniauth` could silently link a provider identity to the wrong account.

A compound unique index on `(provider, uid)` is the correct database-level constraint:

```ruby
add_index :oauth_identities, [:provider, :uid],
          unique: true,
          name: 'index_oauth_identities_on_provider_and_uid'
```

This requires a new migration rather than modifying the existing one (which has already run in schema.rb).

## Warnings

### WR-01: `upsert_for!` Has a TOCTOU Race Condition — Not Safe Under Concurrent Requests

**File:** `app/models/oauth_identity.rb:8-13`

**Issue:** `find_or_initialize_by` + `save!` is a two-step read-then-write sequence. Under concurrent OAuth callbacks (e.g., user double-taps "Login with Google"), two requests can both reach `find_or_initialize_by` before either saves, resulting in a `ActiveRecord::RecordNotUnique` exception from the DB unique index. The exception is unhandled; it propagates through `from_omniauth` and surfaces as a 500 to the user.

The method also serves as an upsert (updates `uid` on existing records), but `ActiveRecord::Base.upsert` or a rescue-and-retry pattern would handle both semantics atomically:

```ruby
def self.upsert_for!(user:, provider:, uid:)
  # Atomic upsert; raises on unexpected DB errors only
  upsert(
    { user_id: user.id, provider: provider.to_s, uid: uid.to_s },
    unique_by: [:user_id, :provider],
    update_only: [:uid, :updated_at]
  )
  find_by!(user_id: user.id, provider: provider.to_s)
rescue ActiveRecord::RecordNotUnique
  retry
end
```

Alternatively, add `rescue ActiveRecord::RecordNotUnique => e; retry` around the current `save!`.

### WR-02: `User.from_omniauth` Silently Ignores Persisted Check After `User.create` (facebook/google paths)

**File:** `app/models/user.rb:91-98`

**Issue:** In the facebook and google_oauth2 paths, `User.create` (not `create!`) is called. If `create` fails validation (e.g., email already taken by a soft-deleted account, or format validation), it returns an unsaved `User` instance where `persisted?` is false. The `if user.persisted?` guard on line 92/97 prevents calling `upsert_for!`, but the method then silently returns the failed user object to the controller. The controller will call `sign_in_and_redirect` on a non-persisted user, which raises or silently corrupts session state depending on Devise version.

The twitter2 path correctly uses `create!` which raises on failure. The facebook and google paths should do the same, or check `user.errors` and raise explicitly:

```ruby
# Line 91 / 96
user ||= User.create!(email: data['email'], password: Devise.friendly_token[0, 20])
```

### WR-03: `has_many :oauth_identities` Missing `dependent:` Option

**File:** `app/models/user.rb:29`

**Issue:** `has_many :oauth_identities` has no `dependent:` option. The foreign key does have `on_delete: :cascade` at the DB level (schema.rb line 189), so rows are physically deleted when a user is hard-deleted via SQL. However, `purge!` also explicitly calls `OauthIdentity.where(user_id: user_id).delete_all` (line 137), so there is no functional gap in `purge!`. The risk is in other code paths that call `user.destroy` (e.g., Devise account deletion in tests or admin tooling): without `dependent: :destroy` or `:delete_all`, AR callbacks on `OauthIdentity` will not fire. While there are no callbacks today, adding them later would silently break unless this is fixed now.

```ruby
has_many :oauth_identities, dependent: :destroy
```

### WR-04: Backfill Migration `down` Is a No-op — Irreversible Without Warning

**File:** `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb:18`

**Issue:** `def down; end` silently succeeds when rolling back, leaving backfilled rows in `oauth_identities`. If a developer rolls back `20260524000001` (which drops the table) before rolling back `20260524000002`, they get a proper error from the FK drop. But rolling back only migration 2 leaves orphaned rows with no indication the rollback did nothing. Rails convention for truly irreversible migrations is to raise `ActiveRecord::IrreversibleMigration`:

```ruby
def down
  raise ActiveRecord::IrreversibleMigration,
        "Backfill cannot be automatically reversed; remove rows manually if needed."
end
```

## Info

### IN-01: No Fixture File for `oauth_identities` — Tests Use Live DB Writes, Risking Ordering Sensitivity

**File:** `test/models/oauth_identity_test.rb` (general)

**Issue:** There is no `test/fixtures/oauth_identities.yml`. All tests that need pre-existing records call `OauthIdentity.create!` in the test body. This is functionally fine for isolated unit tests, but `test_backfill_idempotency` simulates the migration logic by calling `find_or_create_by!` directly in the test (line 100-102), which couples the test to implementation detail of the migration. A fixture for `oauth_identities` would make the baseline state explicit and consistent across all tests.

### IN-02: `has_valid_email?` Uses `=~` with Anchored Regex but Wrong Anchor Notation

**File:** `app/models/user.rb:112`

**Issue:** The regex `/^dummy_.+@example.com$/` uses `^` and `$` (line-start/line-end), not `\A` and `\z` (string-start/string-end). In Ruby, `^` and `$` match per-line, so a value like `"real@address.com\ndummy_x@example.com"` would match, incorrectly classifying a real email as invalid. Rails' own validator already applies this protection, but the method is called from `from_omniauth` (line 69) to guard OAuth email overwrites and should be hardened:

```ruby
def has_valid_email?
  return false if email.blank?
  return false if email =~ /\Adummy_.+@example\.com\z/
  true
end
```

Note the `.` in `example.com` should also be escaped to `example\.com` to avoid matching `exampleXcom`.

---

_Reviewed: 2026-05-24T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
