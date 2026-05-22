# Phase 109: Model Layer — Purge Predicate & Cascade - Research

**Researched:** 2026-05-22
**Domain:** Ruby on Rails model layer — hard-delete cascade, predicate method, custom error class
**Confidence:** HIGH

## Summary

Phase 109 is a pure model-layer addition to `user.rb`. It introduces three closely related capabilities: a constant `PURGE_AFTER_DAYS`, a predicate `purgeable?`, a class scope `User.purgeable`, a custom error `User::NotPurgeableError`, and a mutating method `purge!` that hard-deletes a soft-deleted user together with all 11 associated tables inside a single transaction.

The codebase already has all prerequisite infrastructure: the `deleted` boolean and `deleted_at` datetime columns exist on `users` (schema confirmed), `ApplicationRecord.transaction {}` is available, and the `XAccount.where(user_id: user.id).delete_all` pattern is established in both production models and test teardowns. No migration is needed. No new gem dependencies are needed.

The single highest-risk correctness gap is the nil-guard in `purgeable?`: `deleted_at` is nullable (`t.datetime "deleted_at"` with no `null: false`), so `deleted_at <= PURGE_AFTER_DAYS.days.ago` would raise `NoMethodError` on nil if not guarded. The CONTEXT.md decision `deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago` correctly chains these in short-circuit order.

The second risk is `portal_layouts`: confirmed no `has_many :portal_layouts` on User anywhere in the codebase — `PortalLayout` must be addressed explicitly as `PortalLayout.where(user_id: id).delete_all`.

**Primary recommendation:** Add all new code to `app/models/user.rb` only (constant, error class, scope, predicate, mutating method). Pair with a new `test/models/user_purge_test.rb` covering all boundary cases and the full cascade assertion.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- `purge!` checks `purgeable?` internally and raises `User::NotPurgeableError` if false — defensive, callers do not need to guard first
- `User::NotPurgeableError < StandardError` defined inside `user.rb` — no separate file
- `User.purgeable` class scope defined in Phase 109 alongside `purgeable?` — Phase 110 needs it for the admin list view
- `PURGE_AFTER_DAYS = 90` constant on User (mirrors `PORTAL_COLUMN_COUNTS` pattern) — used by both `purgeable?` and `User.purgeable` scope
- All deletes + final `user.delete` wrapped in `ApplicationRecord.transaction { }` — atomic, rollback if any delete fails
- Final step is `user.delete` (not `user.destroy!`) — explicit pre-deletes already handle x_accounts and x_api_calls; avoids double-running `dependent: :destroy` callbacks
- `x_accounts` deleted explicitly via `XAccount.where(user_id: id).delete_all` first — consistent with all other tables, no AR callback overhead
- Minitest: create user inline with `User.create!` + `update_columns(deleted_at: 91.days.ago)` — no new fixture

### Claude's Discretion

- Deletion order within `purge!`: bookmarks → feeds → mastodon_accounts → notes → portal_layouts → portals → preferences → todos → visited_links → x_accounts → x_api_calls → user.delete
- `purgeable?` nil-guard: `deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago`
- `User.purgeable` scope: `where(deleted: true).where.not(deleted_at: nil).where('deleted_at <= ?', PURGE_AFTER_DAYS.days.ago)`
- `Preference.where(user_id: id).delete_all` not `user.preference.destroy` (unsaved default raises error)
- `portal_layouts` explicitly via `PortalLayout.where(user_id: id).delete_all` (no `has_many` on User)

### Deferred Ideas (OUT OF SCOPE)

- Background scheduled purge job (ACCT-FUT-01b) — not in this phase
- Bulk purge (PURGE-FUT-01) — not in this phase
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PURGE-01 | Admin can check if a soft-deleted user is eligible for purge (deleted_at >= 90 days ago, nil-safe) | `User#purgeable?` + `User.purgeable` scope; `deleted_at` confirmed nullable — nil-guard required |
| PURGE-02 | `User#purge!` permanently deletes the user row and all associated records across 11 tables in a single transaction | `ApplicationRecord.transaction {}` confirmed available; all 11 tables confirmed in schema with `user_id`; no FK constraints — ordering is logical not enforced |
| TEST-01 | Minitest covers `purgeable?` edge cases (not deleted, deleted_at nil, < 90 days, >= 90 days) and `purge!` verifies all 11 tables are empty after execution | New `test/models/user_purge_test.rb`; User.create! + update_columns pattern confirmed in existing tests |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Purge eligibility predicate (`purgeable?`) | Model | — | Pure domain logic on User; no HTTP, no view |
| Purge eligibility scope (`User.purgeable`) | Model | — | AR scope used by controller (Phase 110) and view to gate UI |
| Hard-delete cascade (`purge!`) | Model | — | Mutation must be in a single transaction at the model layer; controller delegates entirely |
| Custom error class (`NotPurgeableError`) | Model | — | Defined where it is raised; controller rescues it |
| Test boundary cases + cascade assertion | Test (Minitest) | — | `bin/rails test` gate; no Cucumber in Phase 109 |

## Standard Stack

No new gems are needed. Phase 109 uses only:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ActiveRecord | Rails 7.2 bundled | `transaction {}`, `delete_all`, `where` | Already in app |
| Ruby stdlib | Ruby 3.4 | `StandardError` subclass | No gem needed |
| Minitest | Rails 7.2 bundled | Test framework | Project standard (CLAUDE.md) |

[VERIFIED: codebase grep — db/schema.rb, app/models/user.rb, Gemfile]

## Package Legitimacy Audit

Not applicable. This phase installs zero external packages.

## Architecture Patterns

### System Architecture Diagram

```
User model (user.rb)
  |
  +-- PURGE_AFTER_DAYS = 90          (constant)
  +-- User::NotPurgeableError        (error class, inner)
  +-- scope :purgeable               (AR scope, class-level)
  |      where(deleted: true)
  |        .where.not(deleted_at: nil)
  |        .where('deleted_at <= ?', 90.days.ago)
  |
  +-- #purgeable?                    (predicate)
  |      deleted? && deleted_at.present? && deleted_at <= 90.days.ago
  |
  +-- #purge!                        (mutating method)
         raise NotPurgeableError unless purgeable?
         ApplicationRecord.transaction do
           [11 x delete_all calls in order]
           user.delete
         end
```

### Recommended Project Structure

No new directories needed. All changes to one file + one new test file:

```
app/models/
└── user.rb          # PURGE_AFTER_DAYS, NotPurgeableError, purgeable?, User.purgeable, purge!

test/models/
└── user_purge_test.rb   # all purge-related Minitest cases (new file)
```

Keeping purge tests in a dedicated file (rather than appending to `user_test.rb`) keeps the existing test file readable and is consistent with the project pattern of separate focused test files (e.g., `user_two_factor_test.rb`).

### Pattern 1: Inner Error Class

```ruby
# Source: codebase — existing pattern confirmed in Rails / project conventions [ASSUMED: inner class placement]
class User < ApplicationRecord
  class NotPurgeableError < StandardError; end
  # ...
end
```

Defining the error class inside User means callers reference it as `User::NotPurgeableError`, which is self-documenting and matches how Phase 110 will rescue it in the controller.

### Pattern 2: Class-level Constant (mirrors Preference)

```ruby
# Source: app/models/preference.rb — PORTAL_COLUMN_COUNTS = [3, 4].freeze [VERIFIED: codebase]
PURGE_AFTER_DAYS = 90
```

No `.freeze` needed for an Integer. The constant is used in both the predicate and the scope, ensuring the threshold is defined once.

### Pattern 3: ActiveRecord Scope

```ruby
# Source: app/models/user.rb — scope :active [VERIFIED: codebase]
scope :purgeable, -> {
  where(deleted: true)
    .where.not(deleted_at: nil)
    .where('deleted_at <= ?', PURGE_AFTER_DAYS.days.ago)
}
```

The `.where.not(deleted_at: nil)` excludes NULL rows explicitly before the `<=` comparison. Without it, MySQL/MariaDB will silently exclude NULL rows from the `where('deleted_at <= ?')` clause anyway, but the explicit guard makes intent clear and prevents potential edge cases with string interpolation.

### Pattern 4: Transaction + delete_all Cascade

```ruby
# Source: app/models/x_account.rb — user.transaction do [VERIFIED: codebase]
def purge!
  raise NotPurgeableError unless purgeable?

  ApplicationRecord.transaction do
    Bookmark.where(user_id: id).delete_all
    Feed.where(user_id: id).delete_all
    MastodonAccount.where(user_id: id).delete_all
    Note.where(user_id: id).delete_all
    PortalLayout.where(user_id: id).delete_all
    Portal.where(user_id: id).delete_all
    Preference.where(user_id: id).delete_all
    Todo.where(user_id: id).delete_all
    VisitedLink.where(user_id: id).delete_all
    XAccount.where(user_id: id).delete_all
    XApiCall.where(user_id: id).delete_all
    delete
  end
end
```

Key points:
- `delete` (not `destroy!`) as the final step — avoids re-triggering `dependent: :delete_all` on `x_api_calls` and `dependent: :destroy` on `x_accounts` which have already been explicitly deleted.
- `ApplicationRecord.transaction` rather than `transaction` — equivalent when called from an instance method on a model, but more explicit.
- `Preference.where(user_id: id).delete_all` is correct; `user.preference` invokes `Preference.default_preference(self)` when no row exists, returning an unsaved object — calling `.destroy` on it would raise or no-op unpredictably.

### Anti-Patterns to Avoid

- **Calling `user.destroy!` as final step:** Would re-trigger `x_accounts` `dependent: :destroy` callback after rows are already gone, causing a no-op but potentially logging N+1 queries or triggering callbacks on nil records. Use `delete` instead.
- **Using `user.x_api_calls.delete_all` (association proxy):** The `has_many :x_api_calls, dependent: :delete_all` scope on User has no `where(deleted: false)` filter, so `XApiCall.where(user_id: id).delete_all` is equivalent and avoids loading the association.
- **`user.preference.destroy` for preferences:** `User#preference` is overridden to return an unsaved default object if no DB row exists — calling `destroy` on an unsaved object raises `ActiveRecord::RecordNotSaved` in Rails 7. Use `Preference.where(user_id: id).delete_all`.
- **`portals` association for Portal deletion:** `has_many :portals, -> { where(deleted: false) }` on User has a scope filter — it would miss soft-deleted portals. Use `Portal.where(user_id: id).delete_all` to get all rows.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomicity | Manual begin/rescue/rollback | `ApplicationRecord.transaction {}` | Rails wraps in savepoint with automatic rollback on exception |
| Bulk delete without callbacks | Loop + `record.destroy` | `Model.where(...).delete_all` | `delete_all` issues a single DELETE SQL; avoids N callbacks and is O(1) queries |

## Runtime State Inventory

Not applicable — this is a greenfield model addition, not a rename/refactor/migration phase.

## Common Pitfalls

### Pitfall 1: nil `deleted_at` Comparison Crash

**What goes wrong:** `deleted_at <= PURGE_AFTER_DAYS.days.ago` raises `NoMethodError: undefined method '<=' for nil` when `deleted_at` is nil.

**Why it happens:** The column is declared `t.datetime "deleted_at"` without `null: false` — users who have not been soft-deleted have `deleted_at: nil`. An active user passed to `purgeable?` would crash.

**How to avoid:** Guard with `deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago` — short-circuit evaluation means the third clause only runs when the first two are true.

**Warning signs:** Test `test_purgeable_active_user_returns_false` (not deleted, deleted_at nil) would raise instead of returning false.

### Pitfall 2: Missing portal_layouts

**What goes wrong:** `portal_layouts` has no `has_many` on User (confirmed by codebase grep). If the planner naively generates delete calls by reading User associations, this table would be skipped.

**Why it happens:** `PortalLayout` is managed entirely through `Portal#update_layout` — it is a child of `portal_layouts.user_id` but not exposed as a User association.

**How to avoid:** Explicitly include `PortalLayout.where(user_id: id).delete_all` in the cascade, between `Note` and `Portal` deletes. The Minitest cascade assertion must verify this table explicitly.

**Warning signs:** After `purge!`, `PortalLayout.where(user_id: u.id).count` is non-zero.

### Pitfall 3: Portal Association Scope Misses Soft-Deleted Portals

**What goes wrong:** `user.portals.delete_all` deletes only non-deleted portals because `has_many :portals, -> { where(deleted: false) }` has a default scope.

**Why it happens:** The association adds a `WHERE deleted = false` to all queries through it.

**How to avoid:** Use `Portal.where(user_id: id).delete_all` directly (not `user.portals.delete_all`) to bypass the scope and catch all portal rows.

**Warning signs:** Soft-deleted portals survive the purge. The cascade test should seed both a deleted and non-deleted portal for the test user.

### Pitfall 4: double-delete via dependent: callbacks

**What goes wrong:** Using `user.destroy!` as the final step re-fires `dependent: :delete_all` (x_api_calls) and `dependent: :destroy` (x_accounts). By this point those rows are already gone. With MySQL, the extra DELETE is a no-op, but it is wasteful and triggers XAccount callbacks unnecessarily.

**How to avoid:** Use `delete` (the low-level AR method) as the final step — it issues `DELETE FROM users WHERE id = ?` with no callbacks.

### Pitfall 5: Preference default_preference returns unsaved object

**What goes wrong:** `user.preference` is overridden to return `Preference.default_preference(self)` (an unsaved `Preference.new`) when no preference row exists. Calling `user.preference.destroy` or `user.preference.delete` on that unsaved object either raises or silently does nothing.

**How to avoid:** Always use `Preference.where(user_id: id).delete_all` — if no row exists, this is a safe no-op.

### Pitfall 6: Test user triggers after_save :create_default_portal

**What goes wrong:** `User.create!` fires `after_save :create_default_portal`, which inserts a Portal row automatically. The cascade test must account for this: after `purge!`, `Portal.where(user_id: u.id).count` should be 0, but the Portal was created by the callback — not manually seeded.

**Why it matters:** The test correctly exercises the cascade even when the only Portal is the auto-created default. No special setup needed — just be aware the Portal row exists for assertion purposes.

### Pitfall 7: XApiCall dependent: :delete_all vs explicit delete_all ordering

**What goes wrong:** User has `has_many :x_api_calls, dependent: :delete_all`. If `user.delete` is called and then something triggers the association (possible in some Rails internals), the dependent hook may fire again. With `delete` (not `destroy!`) the dependent hooks do NOT fire — `delete` bypasses all callbacks. This is the correct behavior: the explicit `XApiCall.where(user_id: id).delete_all` in purge! handles these rows before `delete` is called.

**How to avoid:** Keep the explicit `XApiCall.where(user_id: id).delete_all` in the cascade and use `delete` as the final step. Do not switch to `destroy!`.

## Code Examples

Verified patterns from official sources:

### Full purge! implementation

```ruby
# Source: pattern derived from app/models/x_account.rb (user.transaction) [VERIFIED: codebase]
#         and app/models/preference.rb (PORTAL_COLUMN_COUNTS constant pattern) [VERIFIED: codebase]

PURGE_AFTER_DAYS = 90

class NotPurgeableError < StandardError; end

scope :purgeable, -> {
  where(deleted: true)
    .where.not(deleted_at: nil)
    .where('deleted_at <= ?', PURGE_AFTER_DAYS.days.ago)
}

def purgeable?
  deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago
end

def purge!
  raise NotPurgeableError unless purgeable?

  ApplicationRecord.transaction do
    Bookmark.where(user_id: id).delete_all
    Feed.where(user_id: id).delete_all
    MastodonAccount.where(user_id: id).delete_all
    Note.where(user_id: id).delete_all
    PortalLayout.where(user_id: id).delete_all
    Portal.where(user_id: id).delete_all
    Preference.where(user_id: id).delete_all
    Todo.where(user_id: id).delete_all
    VisitedLink.where(user_id: id).delete_all
    XAccount.where(user_id: id).delete_all
    XApiCall.where(user_id: id).delete_all
    delete
  end
end
```

### Minitest structure pattern

```ruby
# Source: test/models/x_account_test.rb (User.create! + ensure cleanup) [VERIFIED: codebase]
#         test/models/user_test.rb (update_columns pattern) [VERIFIED: codebase]

class UserPurgeTest < ActiveSupport::TestCase
  def setup
    @u = User.create!(
      email: 'purge_test@example.com',
      password: Devise.friendly_token[0, 20],
      otp_secret: User.generate_otp_secret
    )
  end

  def teardown
    # Cleanup in case purge! was not called (error path tests)
    User.where(email: 'purge_test@example.com').each do |u|
      Bookmark.where(user_id: u.id).delete_all
      # ... all 11 tables ...
      u.delete
    end
  end

  def test_purgeable_returns_false_for_active_user
    assert_not @u.purgeable?
  end

  def test_purgeable_returns_false_when_deleted_at_nil
    @u.update_columns(deleted: true, deleted_at: nil)
    assert_not @u.purgeable?
  end

  def test_purgeable_returns_false_when_deleted_89_days_ago
    @u.update_columns(deleted: true, deleted_at: 89.days.ago)
    assert_not @u.purgeable?
  end

  def test_purgeable_returns_true_when_deleted_exactly_90_days_ago
    @u.update_columns(deleted: true, deleted_at: 90.days.ago)
    assert_predicate @u, :purgeable?
  end

  def test_purge_raises_when_not_purgeable
    assert_raises(User::NotPurgeableError) { @u.purge! }
  end

  def test_purge_cascade_deletes_all_associated_tables
    uid = @u.id
    @u.update_columns(deleted: true, deleted_at: 91.days.ago)
    # Seed data across all tables
    Bookmark.create!(user_id: uid, title: 'b', url: 'http://ex.com')
    # ... seed all 11 tables ...
    @u.purge!
    assert_equal 0, Bookmark.where(user_id: uid).count
    # ... assert all 11 tables ...
    assert_equal 0, User.where(id: uid).count
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `user.destroy!` for hard-delete | Explicit `delete_all` per table + `user.delete` | v1.32 design decision | Avoids N+1 callback overhead; avoids re-triggering dependent hooks |
| Fixture-based user state | `User.create!` + `update_columns` for boundary states | Established in v1.28 (soft-delete) | Allows arbitrary `deleted_at` timestamps without fixture encoding |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `User::NotPurgeableError < StandardError; end` inner class syntax is idiomatic and placed at top of class body | Architecture Patterns | Syntax error; easy to fix if wrong |
| A2 | MySQL `WHERE deleted_at <= ?` with a nil binding does NOT silently include nil rows (NULLs are excluded) | Common Pitfalls | Could cause false positives in purgeable scope — mitigated by explicit `.where.not(deleted_at: nil)` guard |

## Open Questions

1. **Where to place `PURGE_AFTER_DAYS` and `NotPurgeableError` in user.rb**
   - What we know: CONTEXT.md says inside `user.rb`, no separate file; `PORTAL_COLUMN_COUNTS` in preference.rb is at top of class body
   - What's unclear: Whether constant and error class go before or after `devise` declaration
   - Recommendation: Place constant and error class immediately after `devise` line, before `encrypts` — constants first, then error classes, then scopes

2. **Seeding all 11 tables in the cascade test without fixtures**
   - What we know: Some tables require non-null columns (e.g., `bookmarks.title` NOT NULL, `feeds.feed_url` NOT NULL, `mastodon_accounts.instance/profile_url/username` NOT NULL, `x_accounts.x_user_id/username` NOT NULL)
   - What's unclear: Whether any table has additional validation-level constraints that block a bare `create!`
   - Recommendation: Use `Model.create!` with all required attributes; use `update_columns` to bypass callbacks if needed for state setup; consult schema for each table's NOT NULL columns

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MySQL (test DB) | ActiveRecord transactions | Confirmed (schema.rb shows MySQL) | — | — |
| bin/rails test | Minitest gate | Confirmed (CLAUDE.md) | Rails 7.2 | — |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 7.2 bundled) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/models/user_purge_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PURGE-01 | `purgeable?` returns false for active user | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-01 | `purgeable?` returns false when deleted_at nil | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-01 | `purgeable?` returns false when 89 days ago | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-01 | `purgeable?` returns true when exactly 90 days ago | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-01 | `User.purgeable` scope returns only eligible users | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-02 | `purge!` raises NotPurgeableError for non-purgeable user | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| PURGE-02 | `purge!` deletes rows from all 11 tables + user row | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |
| TEST-01 | All boundary cases + cascade pass | unit | `bin/rails test test/models/user_purge_test.rb` | Wave 0 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/models/user_purge_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

- [ ] `test/models/user_purge_test.rb` — covers all PURGE-01, PURGE-02, TEST-01 cases (does not yet exist)

## Security Domain

Not applicable. This phase is an internal model-layer admin operation with no HTTP surface, no authentication changes, no user-supplied input, and no cryptographic operations. Security review belongs to Phase 110 (controller access control gate).

## Project Constraints (from CLAUDE.md)

- **Test suites:** `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` — all three must be green before phase is complete
- **Cucumber command:** `bundle exec rake dad:test` (NOT `bundle exec cucumber` directly)
- **Phase 109 scope:** Minitest only; Cucumber E2E is Phase 111
- **Encoding:** No precompiled assets; no `assets:precompile` needed for this phase
- **No git push:** All push operations manual by user

## Sources

### Primary (HIGH confidence)
- `app/models/user.rb` — confirmed `deleted`/`deleted_at` columns, `scope :active`, `has_many` associations, `destroy_account!` pattern, `ApplicationRecord` availability [VERIFIED: codebase]
- `db/schema.rb` — confirmed all 11 table schemas with `user_id` columns; no FK constraints; `deleted_at` nullable [VERIFIED: codebase]
- `app/models/preference.rb` — confirmed `PORTAL_COLUMN_COUNTS` constant pattern [VERIFIED: codebase]
- `app/models/x_account.rb` — confirmed `user.transaction do` pattern [VERIFIED: codebase]
- `app/models/portal_layout.rb` — confirmed no associations at all (empty model body) [VERIFIED: codebase]

### Secondary (MEDIUM confidence)
- `test/models/x_account_test.rb` — established `User.create!` + `ensure cleanup` test pattern [VERIFIED: codebase]
- `test/models/user_test.rb` — established `update_columns(deleted: true, deleted_at: ...)` pattern [VERIFIED: codebase]

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new gems; all infrastructure confirmed in codebase
- Architecture: HIGH — all patterns verified against existing code; no speculation
- Pitfalls: HIGH — nil-guard, portal_layouts exclusion, Preference override, Portal scoped association all confirmed by direct code inspection

**Research date:** 2026-05-22
**Valid until:** Stable (pure model layer, no external APIs or fast-moving ecosystem)
