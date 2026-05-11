---
phase: 52
name: MastodonAccount Data Layer
date: 2026-05-12
status: discussed
mode: autonomous (auto-answered)
---

# Phase 52 Context: MastodonAccount Data Layer

## Domain

Create the `mastodon_accounts` table migration, the `MastodonAccount` model with URL parsing and soft-delete, and Minitest coverage for URL parsing, validation, and soft-delete behavior.

## Decisions

### URL Parsing Callback Timing

Use `before_validation :parse_profile_url`, not `before_save`.

Reason: `instance` and `username` are populated by the callback. If validation checks their presence (which it does), parsing must run before validations fire — not after. Note uses `before_validation :strip_body` for the same structural reason. Using `before_save` would leave instance/username blank during validation, causing misleading errors.

### Validation Strategy

Three validates declarations, no custom validator:

```ruby
validates :profile_url, presence: true
validates :instance,    presence: true
validates :username,    presence: true
```

The `before_validation` callback attempts to parse `profile_url` and sets `instance` / `username`. If the URL is blank, all three fail. If the URL is present but unparseable (format doesn't match), the callback leaves `instance` / `username` blank and the two presence validations fire with meaningful messages. No explicit format validator on `profile_url` — the derived-field approach is sufficient and keeps the code flat.

### Supported URL Formats

Accept both path styles that Mastodon instances emit:
- `https://ruby.social/@FastRuby` — standard `@username` style
- `https://ruby.social/users/FastRuby` — `/users/` style used by some instances

Both `https://` and `http://` schemes are accepted. Reject Mastodon handle notation (`@FastRuby@ruby.social`) — the form label guides users to enter a URL.

Normalize trailing slashes before matching (browsers often append them):

```ruby
PROFILE_URL_PATTERN = %r{\A(?:https?://)?([^/]+)/(?:@|users/)([^/?#]+)\z}

def parse_profile_url
  return if profile_url.blank?
  m = PROFILE_URL_PATTERN.match(profile_url.strip.chomp('/'))
  return unless m
  self.instance = m[1].downcase
  self.username = m[2]
end
```

The constant lives inside `MastodonConst`.

### display_count Defaulting

Follow the Feed pattern exactly:

```ruby
module MastodonConst
  DEFAULT_DISPLAY_COUNT = 5
  PROFILE_URL_PATTERN = ...
end

class MastodonAccount < ApplicationRecord
  include MastodonConst
  include Crud::ByUser
  ...
  before_save :set_display_count
  ...
  private
  def set_display_count
    self.display_count = DEFAULT_DISPLAY_COUNT if display_count.to_i == 0
  end
end
```

`MastodonConst` is defined in the same file and included, matching `FeedConst` / `TodoConst` precedent.

### Soft-Delete

`destroy_logically!` and `.not_deleted` are both provided to all models by the daddy gem's railtie (`Daddy::Models::CrudExtension` and `Daddy::Models::QueryExtension` — included into `ActiveRecord::Base` at boot). No additional code needed in the model. The `deleted` column must exist in the migration with `null: false, default: false`.

`Crud::ByUser` provides user-scoped authorization predicates only (`readable_by?`, `updatable_by?`, `deletable_by?`) — it does not add soft-delete behavior.

Do NOT add a Rails `default_scope`. No other model in this codebase uses `default_scope` for soft-delete. Controllers and associations call `.not_deleted` explicitly (e.g., `MastodonAccount.where(user_id: user.id).not_deleted`). The model test for "削除済みレコードはデフォルトスコープで除外される" tests `.not_deleted` explicitly — the Japanese phrase "default scope" in the test name is informal, not a Rails `default_scope`.

### Migration Schema

Follow the Note migration pattern:

```ruby
class CreateMastodonAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :mastodon_accounts do |t|
      t.integer :user_id,      null: false
      t.string  :profile_url,  null: false
      t.string  :instance,     null: false, default: ''
      t.string  :username,     null: false, default: ''
      t.integer :display_count, null: false, default: 5
      t.boolean :deleted,      null: false, default: false
      t.timestamps
    end

    add_index :mastodon_accounts, [:user_id, :created_at]
  end
end
```

`instance` and `username` have DB-level defaults of `''` so they satisfy `NOT NULL` even before the before_validation callback populates them. Rails validation enforces non-blank at app level.

### User Association

Add to `MastodonAccount`:
```ruby
belongs_to :user
```

Add to `User` model:
```ruby
has_many :mastodon_accounts, -> { where(deleted: false) }
```

The User association scopes to non-deleted by default, matching the `has_many :portals` pattern in `User`.

### Test File Locations

- Model test: `test/models/mastodon_account_test.rb` (class `MastodonAccountTest < ActiveSupport::TestCase`)
- Fixture: `test/fixtures/mastodon_accounts.yml`
- Support helper: `test/support/mastodon_accounts.rb`

Test method names in Japanese per project convention:
- `test_URLからインスタンスとユーザー名を解析する`
- `test_無効なURLはバリデーションエラーになる`
- `test_論理削除でdeletedがtrueになる`
- `test_削除済みレコードはデフォルトスコープで除外される` (verify `.not_deleted` excludes deleted records)

Fixture entry: one valid `mastodon_account` tied to fixture user (id: 1), with known instance/username values for test assertions.

## Canonical Refs

- `app/models/feed.rb` — before_save / MastodonConst / display_count pattern
- `app/models/note.rb` — before_validation / Crud::ByUser / soft-delete pattern
- `db/migrate/20260430074727_create_notes.rb` — migration style reference
- `app/models/crud/by_user.rb` — authorization predicates only (no soft-delete)
- `app/models/user.rb` — has_many association target; add has_many :mastodon_accounts here
- `.planning/ROADMAP.md` — Phase 52 success criteria
- `.planning/REQUIREMENTS.md` — MAST-05 requirement

## Deferred Ideas

- Store resolved Mastodon numeric account ID in DB to skip the `/lookup` call on every page load (noted in REQUIREMENTS.md Future Requirements — not in scope for Phase 52).
