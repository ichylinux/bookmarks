# Phase 10: Data Layer - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 6 (4 new, 2 edits)
**Analogs found:** 6 / 6 (all exact or strong role-match)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `db/migrate/<TS>_create_notes.rb` (NEW) | migration | schema-create | `db/migrate/20131015031309_create_todos.rb` (column shape) + `db/migrate/20260418120000_add_open_bookmarks_in_new_tab_to_preferences.rb` (modern `[7.2]` header) | exact (composite — older file for shape, recent file for header) |
| `app/models/note.rb` (NEW) | model | CRUD + soft-delete | `app/models/todo.rb` (shape) + `app/models/bookmark.rb` lines 22-24 (destroy override) | exact (composite) |
| `app/models/user.rb` (EDIT) | model (association add) | CRUD | `app/models/user.rb` line 13 (`has_many :portals`) | exact (same file, same kind of edit) |
| `config/routes.rb` (EDIT) | route declaration | request-response | `config/routes.rb` lines 35, 43-47 (`resources :preferences, only: [...]`, `resources :welcome, only: []`) | exact (same file, same DSL) |
| `test/fixtures/notes.yml` (NEW) | fixture stub | test infra | `test/fixtures/todos.yml` / `test/fixtures/bookmarks.yml` | role-match (will start empty, not populated) |
| `test/models/note_test.rb` (NEW, OPTIONAL) | unit test | assertion | `test/models/feed_test.rb` | exact (same `Crud::ByUser` ownership-test pattern) |

## Pattern Assignments

### `db/migrate/<YYYYMMDDHHMMSS>_create_notes.rb` (migration, schema-create)

**Analog A (column shape):** `db/migrate/20131015031309_create_todos.rb`

**Full source** (lines 1-11):
```ruby
class CreateTodos < ActiveRecord::Migration
  def change
    create_table :todos do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.integer :priority, null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end
  end
end
```

Copy: `t.integer :user_id, null: false`, `t.boolean :deleted, null: false, default: false`, `t.timestamps`. Replace `:title`/`:priority` columns with `t.text :body, null: false`.

**Analog B (modern migration class header):** `db/migrate/20260418120000_add_open_bookmarks_in_new_tab_to_preferences.rb`

**Header pattern** (line 1):
```ruby
class AddOpenBookmarksInNewTabToPreferences < ActiveRecord::Migration[7.2]
```

Copy verbatim: `< ActiveRecord::Migration[7.2]`. NOT `[8.1]`. Every 2024-2026 migration uses `[7.2]`.

**Composite index pattern** (no exact in-tree analog — older tables lack indexes; this is the deliberate modern departure noted in CONTEXT.md). Use the standard ActiveRecord migration DSL:
```ruby
add_index :notes, [:user_id, :created_at]
```

**Final composed shape:**
```ruby
class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.integer :user_id, null: false
      t.text    :body,    null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end

    add_index :notes, [:user_id, :created_at]
  end
end
```

---

### `app/models/note.rb` (model, CRUD + soft-delete)

**Analog A (model shape):** `app/models/todo.rb`

**Full source** (lines 9-19):
```ruby
class Todo < ActiveRecord::Base
  include TodoConst
  include Crud::ByUser

  belongs_to :user

  def priority_name
    PRIORITIES[self.priority]
  end

end
```

Copy: `class X < ActiveRecord::Base`, `include Crud::ByUser`, `belongs_to :user`. Drop the `TodoConst` include (not relevant). Note: `Todo` uses `ActiveRecord::Base`, NOT `ApplicationRecord`. Match the analog.

**Analog B (soft-delete destroy override):** `app/models/bookmark.rb`

**Override pattern** (lines 22-24):
```ruby
def destroy_logically!
  update!(deleted: true)
end
```

**IMPORTANT adaptation:** `Bookmark` overrides `destroy_logically!`. CONTEXT.md mandates that `Note` instead override `destroy` directly (so that `User.has_many :notes, dependent: :destroy` triggers the soft-delete via Rails' standard destroy callback). Method name change is the only diff — body is identical:
```ruby
def destroy
  update!(deleted: true)
end
```

**Validation pattern from `Bookmark`** (lines 10):
```ruby
validates :title, presence: true
```

Adapt to: `validates :body, presence: true, length: { maximum: 4000 }`.

**Scope pattern from `Bookmark`** (lines 7-8):
```ruby
scope :folders, -> { where(url: nil) }
scope :files, -> { where.not(url: nil) }
```

Adapt to: `scope :recent, -> { order(created_at: :desc) }`.

**before_validation strip — no in-tree analog.** Standard Rails idiom, supported by RESEARCH.md A2:
```ruby
before_validation :strip_body

private

def strip_body
  body&.strip!
end
```

**Final composed shape:**
```ruby
class Note < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 4000 }

  scope :recent, -> { order(created_at: :desc) }

  def destroy
    update!(deleted: true)
  end

  private

  def strip_body
    body&.strip!
  end
end
```

---

### `app/models/user.rb` (EDIT — add `has_many :notes`)

**Analog (same file, line 13):**
```ruby
has_many :portals, -> { where(deleted: false) }, inverse_of: 'user'
```

**Decision:** Do NOT mirror the `-> { where(deleted: false) }` scope on the `has_many` itself. CONTEXT.md success criterion #3 says only `has_many :notes, dependent: :destroy`. The soft-delete filtering is the responsibility of `Note.not_deleted` (provided by `daddy` gem) at query time, not the association definition.

**Pattern to insert** (place near line 13, after `has_many :portals`):
```ruby
has_many :notes, dependent: :destroy
```

**Edit point:** between line 13 (`has_many :portals, ...`) and line 14 (`after_save :create_default_portal`). Inserting on its own line keeps the `has_many` declarations grouped.

---

### `config/routes.rb` (EDIT — add `resources :notes`)

**Analog A (`only:` syntax):** Line 35:
```ruby
resources :preferences, only: ['index', 'create', 'update']
```

**Analog B (`only:` with array of symbols):** Lines 43-47:
```ruby
resources :welcome, only: [] do
  collection do
    post 'save_state'
  end
end
```

**Pattern to insert** (place near `resources :todos` lines 37-41 — these are the most semantically related sibling resources):
```ruby
resources :notes, only: [:create, :destroy]
```

Use symbol array `[:create, :destroy]` (CONTEXT.md success criterion #4 specifies this exact form). Both `[:create, :destroy]` and `['create', 'destroy']` are valid Rails; symbols match CONTEXT.md verbatim.

**Edit point:** Logical location is right after the `resources :todos do ... end` block (line 41), grouping with the user-data resources.

---

### `test/fixtures/notes.yml` (NEW — empty stub)

**Analog (one-per-table convention):** `test/fixtures/todos.yml`, `test/fixtures/bookmarks.yml`

**Existing populated example** (`todos.yml` lines 1-11):
```yaml
1:
  id: 1
  user_id: 1
  title: 原稿締切り
  priority: <%= Todo::PRIORITY_HIGH %>

2:
  id: 2
  user_id: 2
  title: 受験勉強
  priority: <%= Todo::PRIORITY_NORMAL %>
```

**Phase 10 deliverable:** the file should exist but be empty/stub (Phase 11/13 will populate). RESEARCH.md A3 confirms an empty YAML with header comments is treated as `{}` by Rails fixture loader.

**Pattern (full file):**
```yaml
# Phase 10: empty stub so the fixture loader does not break.
# Phase 11 / 13 will populate this as tests require.
```

---

### `test/models/note_test.rb` (NEW, OPTIONAL — Wave 0 recommended)

**Analog:** `test/models/feed_test.rb`

**Full source** (lines 1-14):
```ruby
require 'test_helper'

class FeedTest < ActiveSupport::TestCase

  def test_他人のフィードは参照できない
    assert user = User.find(2)
    assert feed = Feed.where('user_id <> ?', user).first
    assert ! feed.readable_by?(user)
    assert ! feed.creatable_by?(user)
    assert ! feed.updatable_by?(user)
    assert ! feed.deletable_by?(user)
  end

end
```

**Adaptation notes:**
- Replace `Feed` → `Note`, `フィード` → `ノート`/`メモ`.
- **Drop `creatable_by?`** — it is not defined in `Crud::ByUser` (see `app/models/crud/by_user.rb` lines 1-14: only `readable_by?`/`updatable_by?`/`deletable_by?` exist). The Feed test uses it but it is a no-op or method-missing equivalent — not a pattern to replicate.
- Test depends on a fixture being loaded — but Phase 10's `notes.yml` is empty. Either populate one or two fixture rows here, OR skip this test until Phase 11. Recommended: add 2 minimal fixture entries (mirroring `todos.yml` shape) only if also writing this test. Otherwise leave `notes.yml` empty per spec.
- A second test for validations is cheap to add (presence, length, whitespace strip):

**Suggested expansion (validation tests — no analog, standard Minitest):**
```ruby
def test_body_is_required
  note = Note.new(user_id: 1, body: '')
  assert ! note.valid?
  assert note.errors[:body].any?
end

def test_whitespace_only_body_fails_presence
  note = Note.new(user_id: 1, body: '   ')
  assert ! note.valid?
end

def test_destroy_soft_deletes
  note = notes(:one)
  note.destroy
  assert Note.find(note.id).deleted
end
```

If included, requires fixture entries → see fixture trade-off above.

---

## Shared Patterns

### Authorization (per-user data isolation, NOTE-03)
**Source:** `app/models/crud/by_user.rb`
**Apply to:** `Note` model
**Full source** (lines 1-14):
```ruby
module Crud::ByUser

  def readable_by?(user)
    user.id == user_id
  end

  def updatable_by?(user)
    readable_by?(user)
  end

  def deletable_by?(user)
    readable_by?(user)
  end
end
```

`Note` simply does `include Crud::ByUser`. The path `app/models/crud/by_user.rb` is autoloaded as `Crud::ByUser` (NOT `app/models/concerns/crud/...` — CONTEXT.md path is wrong; verified by RESEARCH.md).

### Soft-delete pattern (deleted boolean + override)
**Source:** `app/models/bookmark.rb` lines 22-24 (override) + `db/migrate/20131015031309_create_todos.rb` line 7 (column)
**Apply to:** `Note` model + `notes` migration
- Migration column: `t.boolean :deleted, null: false, default: false`
- Model override: `def destroy; update!(deleted: true); end` (note: `Note` uses `destroy`, not `destroy_logically!` — see CONTEXT.md rationale: triggered by `User`'s `dependent: :destroy`)
- Filtering: rely on `daddy` gem's auto-included `not_deleted` scope (`Note.not_deleted` works without per-model definition)

### Migration class header (modern convention)
**Source:** `db/migrate/20260418120000_*.rb`, `db/migrate/20260420000000_*.rb`, `db/migrate/20260429025517_*.rb`
**Apply to:** `db/migrate/<TS>_create_notes.rb`
```ruby
class X < ActiveRecord::Migration[7.2]
```
Always `[7.2]`, never `[8.1]`, despite project running Rails 8.1.

### Standard model imports/structure
**Source:** `app/models/todo.rb`, `app/models/bookmark.rb`
**Apply to:** `Note`
```ruby
class Note < ActiveRecord::Base
  include Crud::ByUser
  belongs_to :user
  # ... validations, scopes, methods
end
```
Use `ActiveRecord::Base` (matches `Todo`/`Bookmark`/`Calendar`), not `ApplicationRecord` (used by `Feed`/`Portal`). Either works; matching the closest analog `Todo` is cleaner.

---

## No Analog Found

| Pattern | Reason | Resolution |
|---------|--------|-----------|
| Composite index `[:user_id, :created_at]` | Older tables in this codebase lack indexes entirely | Use ActiveRecord standard `add_index` DSL — this is a deliberate modernization noted in CONTEXT.md; not an anti-pattern |
| `before_validation { body&.strip! }` | No model in-tree strips text fields before validation | Standard Rails idiom; RESEARCH.md A2 supports either inline-block or named-method form. Use `before_validation :strip_body` + private method for grep-ability |
| `validates :body, length: { maximum: 4000 }` on a `text` column | No analog (existing models with text use only presence validation if any) | Standard Rails `validates` DSL; CONTEXT.md mandates the cap |

The planner can use these patterns as-is — they are well-known Rails idioms and not codebase-specific.

---

## Metadata

**Analog search scope:** `app/models/`, `app/models/crud/`, `db/migrate/`, `test/fixtures/`, `test/models/`, `config/routes.rb`
**Files scanned (read for excerpts):** 11
- `app/models/todo.rb`, `app/models/bookmark.rb`, `app/models/user.rb`, `app/models/crud/by_user.rb`
- `db/migrate/20131015031309_create_todos.rb`, `db/migrate/20260418120000_*.rb`, `db/migrate/20260429025517_*.rb`
- `config/routes.rb`
- `test/fixtures/todos.yml`, `test/fixtures/bookmarks.yml`
- `test/models/feed_test.rb`

**Pattern extraction date:** 2026-04-30
