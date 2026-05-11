# Research: Phase 52 — MastodonAccount Data Layer

**Phase goal:** MastodonAccount model exists, persists cleanly, and parses profile URLs automatically before save.
**Requirements covered:** MAST-05
**Research date:** 2026-05-12

---

## 1. Migration Pattern

**Confidence: HIGH** [VERIFIED: db/schema.rb, db/migrate/]

The existing convention for soft-deletable models (Note, Feed, Todo) is:

```ruby
class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.integer :user_id,       null: false
      t.text    :body,          null: false
      t.boolean :deleted,       null: false, default: false
      t.timestamps
    end
    add_index :notes, [:user_id, :created_at]
  end
end
```

**For `mastodon_accounts` table, apply this pattern with these columns:**

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `user_id` | integer | null: false | ownership FK |
| `profile_url` | string | null: false | raw input from user |
| `instance` | string | null: false | parsed from profile_url (e.g. `ruby.social`) |
| `username` | string | null: false | parsed from profile_url (e.g. `FastRuby`) |
| `display_count` | integer | null: false, default: 5 | matches Feed convention |
| `deleted` | boolean | null: false, default: false | soft-delete flag |
| timestamps | | | |

**Index:** `[user_id, created_at]` — consistent with Note; Feed omits it but Note adds it.

**No explicit FK constraint** in migration (no `add_foreign_key`) — consistent with all existing tables. [VERIFIED: db/schema.rb — no `add_foreign_key` calls for feeds, notes, or todos]

**Migration filename convention:** `YYYYMMDDHHMMSS_create_mastodon_accounts.rb`, Rails 7.2 style.

---

## 2. Model Structure

**Confidence: HIGH** [VERIFIED: app/models/note.rb, app/models/feed.rb, app/models/crud/by_user.rb]

### Crud::ByUser concern

Located at `app/models/crud/by_user.rb`. Provides ownership-check methods only:

```ruby
module Crud::ByUser
  def readable_by?(user)   = user.id == user_id
  def updatable_by?(user)  = readable_by?(user)
  def deletable_by?(user)  = readable_by?(user)
end
```

**Key finding:** `Crud::ByUser` does NOT implement soft-delete itself. Soft-delete (`destroy_logically!`, `not_deleted` scope) comes from the **daddy gem** (`daddy-0.12.0`). [VERIFIED: agent confirmed daddy gem provides `destroy_logically!`]

### Soft-delete: default scope vs named scope

**Important ambiguity to resolve with planner:**

- Phase 52 success criteria says "the default scope excludes deleted records"
- Existing models use a **named scope** (`scope :active, -> { where(deleted: false) }`) rather than Rails `default_scope`
- The Note model test calls `Note.active`, not `Note.all`
- Daddy gem provides a `not_deleted` scope (exact name to verify)

**Recommendation:** Follow the `scope :active` named-scope pattern established by Note and Feed. Do NOT use Rails `default_scope` — it causes surprising behavior on `destroy`, `update_all`, etc. The success criteria's "default scope" language likely means the scope used by default in controllers, not a Rails `default_scope`.

### Model skeleton

```ruby
class MastodonAccount < ApplicationRecord
  include Crud::ByUser

  belongs_to :user

  before_validation :parse_profile_url

  validates :profile_url, presence: true
  validates :instance,    presence: true
  validates :username,    presence: true
  validates :display_count, numericality: { greater_than: 0 }

  scope :active, -> { where(deleted: false) }

  private

  def parse_profile_url
    # URI-based parsing of https://{instance}/@{username}
  end
end
```

---

## 3. Profile URL Parsing

**Confidence: HIGH** [VERIFIED: no existing URI utility in app — VERIFIED: codebase grep found no URI.parse usage]

### Mastodon profile URL format

Standard format: `https://{instance}/@{username}`

Examples:
- `https://ruby.social/@FastRuby` → instance: `ruby.social`, username: `FastRuby`
- `https://mastodon.social/@johndoe` → instance: `mastodon.social`, username: `johndoe`

### Recommended parsing approach

Use Ruby's built-in `URI` module — no new dependency needed:

```ruby
def parse_profile_url
  return if profile_url.blank?
  uri = URI.parse(profile_url.strip)
  path_parts = uri.path.split('/')          # ["", "@FastRuby"]
  at_segment = path_parts.find { |p| p.start_with?('@') }
  self.instance = uri.host
  self.username = at_segment&.delete_prefix('@')
rescue URI::InvalidURIError
  self.instance = nil
  self.username = nil
end
```

### Validation behavior on parse failure

If `parse_profile_url` sets `instance` and `username` to nil, the `presence: true` validations on those fields fire and produce validation errors. The validation error should be added to `:profile_url` (user-visible field), not `:instance` or `:username` (internal fields).

**Pattern consideration:** Add a custom validation `validate :profile_url_parseable` that adds an error to `:profile_url` with a human-readable message, rather than surfacing raw errors on `:instance`/`:username`.

### Edge cases to handle

| Input | Expected behavior |
|-------|-------------------|
| `https://ruby.social/@FastRuby` | instance: `ruby.social`, username: `FastRuby` |
| `https://mastodon.social/@user` | instance: `mastodon.social`, username: `user` |
| `http://ruby.social/@user` (http not https) | [ASSUMED] accept — URI.parse handles both |
| `ruby.social/@FastRuby` (no scheme) | URI.parse may raise or return nil host — treat as invalid |
| `https://ruby.social/` (no @-segment) | path has no @-segment — treat as invalid |
| `not_a_url` | URI::InvalidURIError raised — rescue → invalid |
| Trailing whitespace | Strip before parsing |

**No existing URL validation utility in the app.** Feed model uses crude string splitting, not URI — do not follow that pattern for MastodonAccount.

---

## 4. Soft-Delete Behavior

**Confidence: HIGH** [VERIFIED: test/models/note_test.rb, daddy gem discovery]

### How destroy_logically! works

- Sets `deleted = true` and saves the record (row remains in DB)
- Provided by daddy gem — no implementation needed in the model
- Existing models call it directly; controllers use it instead of `destroy`

### Test pattern for soft-delete

```ruby
def test_destroy_logically_soft_deletes
  account = mastodon_accounts(:one)
  account.destroy_logically!
  reloaded = MastodonAccount.find(account.id)
  assert reloaded.deleted
end

def test_active_scope_excludes_deleted
  account = mastodon_accounts(:one)
  account.destroy_logically!
  assert_not_includes MastodonAccount.active, account
end
```

---

## 5. Minitest Patterns

**Confidence: HIGH** [VERIFIED: test/models/note_test.rb, test/fixtures/notes.yml]

### Test file location

`test/models/mastodon_account_test.rb` — consistent with `test/models/note_test.rb`.

### Fixture file

`test/fixtures/mastodon_accounts.yml`

```yaml
one:
  id: 1
  user_id: 1
  profile_url: 'https://ruby.social/@FastRuby'
  instance: ruby.social
  username: FastRuby
  display_count: 5
  deleted: false

two:
  id: 2
  user_id: 2
  profile_url: 'https://mastodon.social/@johndoe'
  instance: mastodon.social
  username: johndoe
  display_count: 5
  deleted: false
```

**Note:** Fixtures bypass `before_validation` callbacks (raw SQL insert), so `instance` and `username` must be set explicitly in the fixture.

### Test naming convention

Japanese method names: `test_URLを解析する`, `test_不正なURLは無効`, `test_ソフトデリート`, etc. [VERIFIED: note_test.rb, feed_test.rb use Japanese names]

### Tests to write for Phase 52

| Test | What it covers |
|------|---------------|
| `test_正常なURLを解析する` | Happy-path URL parsing (profile_url → instance + username) |
| `test_スキームなしURLは無効` | `ruby.social/@user` (no scheme) → validation error on profile_url |
| `test_パスにアットマークなしURLは無効` | `https://ruby.social/` → validation error |
| `test_不正なURLは無効` | `not_a_url` → validation error |
| `test_自分のアカウントは参照できる` | `readable_by?(user)` for owner |
| `test_他人のアカウントは参照できない` | `readable_by?(other_user)` returns false |
| `test_ソフトデリートで削除フラグが立つ` | `destroy_logically!` sets `deleted: true` |
| `test_activeスコープは削除済みを除外する` | `MastodonAccount.active` excludes deleted |

---

## 6. Display Count Default

**Confidence: HIGH** [VERIFIED: db/schema.rb feeds table, app/models/feed.rb]

Feed model uses `display_count` with:
- DB default: 5 (`null: false, default: 5`)
- Model sets it via `before_save :set_display_count` if value is 0

For MastodonAccount, set the same DB-level default (`default: 5`) and add a validation `numericality: { greater_than: 0 }`. No need for a before_save callback since the DB default handles the nil/zero case — or mirror Feed's pattern for consistency.

---

## 7. Potential Pitfalls

**Confidence: HIGH** [VERIFIED via code inspection]

### Pitfall 1: Fixture bypass of before_validation

Fixtures insert raw SQL, so `parse_profile_url` never runs during fixture loading. Always set `instance` and `username` explicitly in the fixture. Tests that create records in memory (`MastodonAccount.new(profile_url: '...')`) will trigger the callback correctly.

### Pitfall 2: Validation error on internal fields

Adding `validates :instance, presence: true` will show `:instance can't be blank` to users, which is confusing. Instead: add a custom `validate :profile_url_parseable` that adds the error to `:profile_url`.

### Pitfall 3: URI::InvalidURIError vs bad-but-parseable URLs

`URI.parse("not_a_url")` does NOT raise — it returns a `URI::Generic` with nil host. Only raises on truly malformed strings (e.g. with illegal characters). The parse callback must check `uri.host.present?` and that a `@`-segment exists, not just rescue the exception.

### Pitfall 4: `default_scope` anti-pattern

Do not use Rails `default_scope { where(deleted: false) }`. It silently excludes deleted records from `update_all`, `count`, and `find` by ID, causing confusing test failures. Use named `scope :active` like Note does.

### Pitfall 5: No `dependent: :destroy` on User

Existing models (Note, Feed) do not add `dependent: :destroy` on the `belongs_to :user` side. The `has_many` on `User` model should add `dependent: :destroy` for `mastodon_accounts`. Check `app/models/user.rb` to see if other associations follow this pattern. [ASSUMED — User model not read in this session; verify before implementing]

---

## 8. Open Questions for Planner

1. **Scope name**: Use `scope :active` (matches Note) or `scope :not_deleted` (matches daddy gem's provided scope)? Recommendation: `scope :active` for consistency with Note.

2. **Validation message for bad URL**: Should the error on `:profile_url` be a generic "is invalid" or a more descriptive message like "must be a valid Mastodon profile URL (e.g. https://ruby.social/@username)"? Locale key needed in both ja.yml and en.yml.

3. **HTTP vs HTTPS**: Accept `http://` profile URLs or require `https://`? Recommendation: accept both — URI scheme validation is not needed for data-layer purposes; the API client will handle the actual request.

4. **`display_count` range**: Any upper bound (e.g. max 20)? Feed doesn't validate an upper bound. Recommendation: follow Feed — no upper bound validation at model level.

---

## Summary

Phase 52 is a straightforward data-layer phase. The codebase has a clear pattern (Note model + migration) to follow. The only non-trivial implementation is the URL parser — use `URI.parse`, check for host and `@`-prefixed path segment, and wire validation errors to `:profile_url`. The soft-delete mechanism comes from daddy gem (`destroy_logically!`); the model only needs a named `scope :active`. Fixtures must pre-populate `instance` and `username` since callbacks don't run during fixture loading.

**Estimated complexity:** Low — 1 migration, 1 model, 1 fixture file, 1 test file (~8 test cases).
