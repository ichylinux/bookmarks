# Phase 96: Data Layer - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 4 (1 migration, 1 model, 1 test, 1 fixture)
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `db/migrate/20260520XXXXXX_create_x_api_calls.rb` | migration | batch (DDL) | `db/migrate/20260518200000_create_visited_links.rb` | exact |
| `app/models/x_api_call.rb` | model | CRUD + batch | `app/models/visited_link.rb` | role-match |
| `test/models/x_api_call_test.rb` | test | request-response | `test/models/visited_link_test.rb` | exact |
| `test/fixtures/x_api_calls.yml` | config | — | `test/fixtures/visited_links.yml` | exact |

---

## Pattern Assignments

### `db/migrate/20260520XXXXXX_create_x_api_calls.rb` (migration, DDL)

**Analog:** `db/migrate/20260518200000_create_visited_links.rb`

**Migration version pattern** (line 1):
```ruby
class CreateVisitedLinks < ActiveRecord::Migration[8.1]
```
Use `Migration[8.1]` — all migrations from 20260512 onward use this. The older `CreateNotes` uses `[7.2]`; do not copy that.

**Column definition pattern** (lines 3-8 of visited_links migration):
```ruby
create_table :visited_links do |t|
  t.integer  :user_id,    null: false
  t.string   :url,        null: false, limit: 2083
  t.datetime :visited_at, null: false
  t.timestamps
end
```
For `x_api_calls`, omit `t.timestamps` (locked decision — immutable logging table). Columns go alphabetically per schema.rb convention. Apply `limit: 32` to `error_code` (varchar(32) per XClient error symbol contract).

**Index pattern** (line 10 of visited_links migration):
```ruby
add_index :visited_links, %i[user_id url], unique: true, length: { url: 767 }
```
For `x_api_calls`, the index is non-unique and has no length option:
```ruby
add_index :x_api_calls, %i[user_id called_at]
```
User_id first, called_at second — leftmost-prefix rule for MySQL range queries in Phase 99.

**Composite index precedent** (line 11 of `db/migrate/20260430074727_create_notes.rb`):
```ruby
add_index :notes, [:user_id, :created_at]
```
Same `(user_id, time_column)` pattern used in the notes table. Confirms this is a standard project pattern.

---

### `app/models/x_api_call.rb` (model, CRUD + batch)

**Analog:** `app/models/visited_link.rb`

**Base class and association pattern** (lines 1-2 of visited_link.rb):
```ruby
class VisitedLink < ApplicationRecord
  belongs_to :user
```
For `x_api_call.rb`, use `belongs_to :user, optional: false` (locked decision — enforce FK integrity; no orphaned log rows). Do NOT include `Crud::ByUser` (locked decision — this is not a user CRUD resource).

**`record!` class method pattern** (lines 5-10 of visited_link.rb):
```ruby
def self.record!(user, url)
  normalized = normalize_url(url)
  return if normalized.blank?

  upsert({ user_id: user.id, url: normalized, visited_at: Time.current })
end
```
`XApiCall.record!` differs in two ways: (1) uses keyword args not positional, (2) uses `create!` not `upsert` (rows are never de-duped — every API call gets its own row). Pattern to copy:
```ruby
def self.record!(user_id:, endpoint:, success:, error_code: nil, rate_limit_remaining: nil)
  create!(
    user_id: user_id,
    endpoint: endpoint,
    success: success,
    error_code: error_code,
    rate_limit_remaining: rate_limit_remaining,
    called_at: Time.current
  )
end
```
`Time.current` follows the same convention as `visited_link.rb` line 9.

**No validation pattern** — `visited_link.rb` line 3 has `validates :url, presence: true`, but `XApiCall` needs no AR validations beyond the FK (NOT NULL constraints enforce at DB level; `record!` uses explicit keyword args so mass-assignment is impossible).

**`usage_summary` class method** — no direct analog exists in the codebase for grouped aggregation. Use the standard ActiveRecord grouped select pattern verified in RESEARCH.md:
```ruby
def self.usage_summary(since: nil)
  scope = since ? where('called_at >= ?', since) : all
  scope.group(:user_id).select(
    :user_id,
    'COUNT(*) AS total_calls',
    'MAX(called_at) AS last_called_at',
    'SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS error_count'
  )
end
```
Critical: `success = 0` not `success = false` in the SQL fragment (MySQL stores booleans as TINYINT(1); AR does not cast raw SQL string fragments).

---

### `test/models/x_api_call_test.rb` (test, unit)

**Analog:** `test/models/visited_link_test.rb`

**Require and class declaration pattern** (lines 1-3):
```ruby
require 'test_helper'

class VisitedLinkTest < ActiveSupport::TestCase
```

**`setup` block pattern** (lines 4-8):
```ruby
def setup
  @user = User.find(1)
  @other_user = User.find(2)
  VisitedLink.delete_all
end
```
For `x_api_call_test.rb`, use `XApiCall.delete_all` in setup (no fixtures used — records are created programmatically, same pattern as `visited_links.yml` which is empty).

**Japanese method name pattern** (line 5 of x_account_test.rb):
```ruby
def test_display_countのデフォルト値が設定される
```
And from note_test.rb (line 5):
```ruby
def test_他人のメモは参照できない
```
All model tests in this project use Japanese method names. Follow this for `x_api_call_test.rb`.

**`assert_difference` pattern** (lines 31-33 of visited_link_test.rb):
```ruby
assert_difference -> { VisitedLink.count }, 1 do
  VisitedLink.record!(@user, 'https://example.com')
end
```
Use the lambda form `-> { XApiCall.count }` for `record!` count assertions.

**Multi-user fixture access pattern** (line 6 of visited_link_test.rb):
```ruby
@other_user = User.find(2)
```
`usage_summary` tests need two users to verify per-user grouping. Use `User.find(1)` and `User.find(2)` — both exist in `test/fixtures/users.yml`.

**Aggregate assertion pattern** — for `usage_summary`, access virtual columns on result rows after `.to_a`:
```ruby
results = XApiCall.usage_summary.to_a
row = results.find { |r| r.user_id == @user.id }
assert_equal 3, row.total_calls
assert_equal 1, row.error_count
```

---

### `test/fixtures/x_api_calls.yml` (fixture)

**Analog:** `test/fixtures/visited_links.yml`

**Empty fixture pattern** (entire file):
```yaml
# No fixture rows — model tests create records programmatically
```
`x_api_call_test.rb` will use `setup` + `delete_all` + `create!` in each test, same as `visited_link_test.rb`. The fixture file exists but is empty (required by Rails fixture loading, but no rows needed).

---

## Shared Patterns

### ApplicationRecord base class
**Source:** `app/models/application_record.rb` (lines 1-3)
**Apply to:** `app/models/x_api_call.rb`
```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
```
All models inherit from `ApplicationRecord`. No other base class is used in this project.

### Migration version
**Source:** `db/migrate/20260518200000_create_visited_links.rb` (line 1)
**Apply to:** `db/migrate/20260520XXXXXX_create_x_api_calls.rb`
```ruby
class CreateVisitedLinks < ActiveRecord::Migration[8.1]
```
Use `[8.1]`. The `create_notes` migration uses `[7.2]` but that is the older standard.

### Test helper require
**Source:** `test/models/visited_link_test.rb` (line 1)
**Apply to:** `test/models/x_api_call_test.rb`
```ruby
require 'test_helper'
```
Every model test file starts with this require.

### `delete_all` isolation in setup
**Source:** `test/models/visited_link_test.rb` (lines 4-8)
**Apply to:** `test/models/x_api_call_test.rb`
```ruby
def setup
  @user = User.find(1)
  VisitedLink.delete_all
end
```
Ensures test isolation without relying on fixtures. `x_api_call_test.rb` should call `XApiCall.delete_all` in `setup` to avoid cross-test row accumulation.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `usage_summary` method body | model (query) | batch aggregate | No grouped-select aggregate class method exists in codebase; RESEARCH.md verified the standard AR pattern to use |

---

## Metadata

**Analog search scope:** `db/migrate/`, `app/models/`, `test/models/`, `test/fixtures/`
**Files scanned:** 7 (2 migrations, 3 models, 2 test files, 1 fixture)
**Pattern extraction date:** 2026-05-20
