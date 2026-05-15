# Phase 67: Data + Model Layer - Research

**Researched:** 2026-05-15
**Domain:** Rails migration, ActiveRecord model validation, Portal model parameterization
**Confidence:** HIGH

## Summary

This phase adds `portal_column_count` to the `preferences` table (integer, default 3, NOT NULL), validates the value in the Preference model using the established constant-array pattern, and replaces the hardcoded `3` in `Portal#portal_columns` and `Portal#portal_column_count` with the user's stored preference. No data migration is needed: the DB default handles all existing rows. No UI work is in scope.

All code patterns are directly observable in the codebase. Confidence is HIGH — every finding below was verified by reading actual source files, not assumed from training data.

**Primary recommendation:** Follow the `FONT_SIZES` / `validates :font_size, inclusion:` pattern exactly, but without `allow_nil: true` (column is NOT NULL with a DB default). Replace the three hardcoded `3` literals in `portal_columns` with a single `count` local derived from `user.preference.portal_column_count`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema column addition | Database / Storage | — | Migration owns schema shape |
| Preference validation | API / Backend (Model) | — | ActiveRecord validates at the model layer |
| Portal column distribution | API / Backend (Model) | — | Portal#portal_columns is pure Ruby, no DB write |
| Downgrade safety (skip column_no >= count) | API / Backend (Model) | — | Guard lives in Portal#portal_columns iteration |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Add `portal_column_count` integer column to `preferences` with `default: 3, null: false`
- No data migration needed: all existing rows get default 3 via `null: false, default: 3`
- Timestamp: next after `20260514200001`
- Add `PORTAL_COLUMN_COUNTS = [3, 4].freeze` constant (mirrors `FONT_SIZES` pattern)
- Add `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` — not allow_nil (column has DB default and is NOT NULL)
- `Portal#portal_column_count` returns `user.preference.portal_column_count` (not `portal_columns.size`)
- `Portal#portal_columns`: replace `@portal_columns = [[], [], []]` with `count = portal_column_count; @portal_columns = Array.new(count) { [] }`
- Replace `i % 3` fallback with `i % count` using the same `count` local
- Downgrade safety: skip `PortalLayout` records where `pl.column_no >= count`

### Claude's Discretion
- Test file placement and naming (follow existing `test/models/` conventions)
- Whether to add a nil-safe fallback on the preference delegation in Portal (nil is not expected given the DB default, but a nil guard is acceptable)

### Deferred Ideas (OUT OF SCOPE)
- CSS for 4-column layout — Phase 68
- Preferences UI select control — Phase 68
- Cucumber E2E for column count — Phase 68
- Column counts other than 3/4 — explicitly out of scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COL-01 | `preferences.portal_column_count` integer column (default 3, NOT NULL); validates inclusion in [3, 4] | Migration pattern confirmed; validation pattern confirmed via FONT_SIZES |
| COL-04 | `Portal#portal_columns` uses `user.preference.portal_column_count` instead of hardcoded 3; `Portal#portal_column_count` delegates to preference | Exact lines in portal.rb identified; Portal already calls `user.preference.*` elsewhere |
| COL-06 | Downgrade safe: skip PortalLayout records with `column_no >= column_count`; redistribute via `i % count` | Current fallback loop confirmed; guard placement identified |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ActiveRecord Migration | Rails 8.1 (schema version 2026_05_14_200001) | Add column to preferences table | Already in use |
| ActiveRecord Validation | Rails 8.1 | `validates :portal_column_count, inclusion:` | Already in use via FONT_SIZES pattern |

No new gems required.

**Installation:** None.

## Architecture Patterns

### Recommended Project Structure

Files touched in this phase:

```
db/migrate/
└── 20260515000000_add_portal_column_count_to_preferences.rb   # new

app/models/
├── preference.rb       # add constant + validation
└── portal.rb           # parameterize portal_columns

test/models/
├── preference_test.rb  # add portal_column_count tests
└── portal_test.rb      # new — Portal#portal_columns distribution tests
```

### Pattern 1: Migration — Add Integer Column with Default

Exact pattern from `20260514200000_add_show_column_nav_buttons_to_preferences.rb`:

```ruby
# Source: db/migrate/20260514200000_add_show_column_nav_buttons_to_preferences.rb (verified)
class AddPortalColumnCountToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :portal_column_count, :integer, default: 3, null: false
  end
end
```

Note: The prior migration uses `ActiveRecord::Migration[7.2]` but the update migration uses `[8.1]`. New migrations should use `[8.1]` (matches schema version).

### Pattern 2: Preference Constant + Validation

Exact pattern from `preference.rb` (FONT_SIZES):

```ruby
# Source: app/models/preference.rb (verified — lines 5-9, 20)
FONT_SIZES = [
  FONT_SIZE_LARGE,
  FONT_SIZE_MEDIUM,
  FONT_SIZE_SMALL
].freeze

validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true
```

New constant/validation (integers, NOT allow_nil):

```ruby
PORTAL_COLUMN_COUNTS = [3, 4].freeze

validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }
```

`allow_nil: true` is OMITTED because the column has `default: 3, null: false` — nil is not a valid state.

### Pattern 3: Portal#portal_columns Parameterization

Current code (lines 5-24 of `app/models/portal.rb`, verified):

```ruby
def portal_column_count
  portal_columns.size          # <-- currently computes from array, not from preference
end

def portal_columns
  return @portal_columns if @portal_columns

  gadgets = get_gadgets
  @portal_columns = [[], [], []]           # hardcoded 3

  PortalLayout.where(user_id: user.id).order('column_no, display_order').each do |pl|
    g = gadgets.delete(pl.gadget_id)
    @portal_columns[pl.column_no] << g if g  # no guard — column_no could be 3 when count=3
  end

  gadgets.each_with_index do |g, i|
    @portal_columns[i % 3].unshift(g[1])    # hardcoded 3
  end

  @portal_columns
end
```

After change:

```ruby
def portal_column_count
  user.preference.portal_column_count       # delegates to stored preference
end

def portal_columns
  return @portal_columns if @portal_columns

  gadgets = get_gadgets
  count = portal_column_count               # single source of truth
  @portal_columns = Array.new(count) { [] } # dynamic count

  PortalLayout.where(user_id: user.id).order('column_no, display_order').each do |pl|
    next if pl.column_no >= count           # downgrade safety: skip out-of-range records
    g = gadgets.delete(pl.gadget_id)
    @portal_columns[pl.column_no] << g if g
  end

  gadgets.each_with_index do |g, i|
    @portal_columns[i % count].unshift(g[1]) # parameterized fallback
  end

  @portal_columns
end
```

### Anti-Patterns to Avoid

- **`allow_nil: true` on `portal_column_count` validation:** The column is NOT NULL with a DB default. Adding `allow_nil: true` would silently permit nil at the model level, creating a mismatch with the DB constraint.
- **Calling `portal_columns.size` from `portal_column_count`:** Creates a circular dependency if `portal_columns` itself calls `portal_column_count`. After the change, `portal_column_count` must be independent (delegates to preference), and `portal_columns` calls it.
- **Omitting `next if pl.column_no >= count`:** Without this guard, `@portal_columns[3]` on a 3-column portal would silently append to `nil` (Array#[] returns nil for out-of-bounds) or raise, depending on usage.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Inclusion validation | Custom `validate` method checking allowed values | `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` | Rails built-in, matches FONT_SIZES pattern |
| Dynamic array initialization | Manual `[[], []]` building | `Array.new(count) { [] }` | Idiomatic Ruby, avoids array aliasing bugs |

## Common Pitfalls

### Pitfall 1: Migration Timestamp Collision

**What goes wrong:** Using a timestamp already in use (e.g., `20260514200001`) creates a migration conflict.
**Why it happens:** Timestamps must be unique; Rails raises if two migrations share a timestamp.
**How to avoid:** Use `20260515000000` (next day) — confirmed safe since the latest existing migration is `20260514200001`.
**Warning signs:** `rake db:migrate` raises "Multiple migrations have the same version number."

### Pitfall 2: Schema File Version Mismatch

**What goes wrong:** After running the migration, `db/schema.rb` version updates to the new timestamp — this is expected and correct. The planner should not attempt to manually edit schema.rb.
**How to avoid:** Run `bin/rails db:migrate` and commit the auto-updated schema.rb.

### Pitfall 3: Fixture Missing `portal_column_count`

**What goes wrong:** Fixture rows in `test/fixtures/preferences.yml` do not include `portal_column_count`, but after the migration the column has `default: 3` so this is safe — Rails fixture loading uses the DB default.
**Verification:** `preferences.yml` currently has 3 rows (user_id 1, 2, 3). No update needed. [VERIFIED: test/fixtures/preferences.yml]

### Pitfall 4: `portal_column_count` Nil in Portal if Preference Missing

**What goes wrong:** If a user somehow has no preference record, `user.preference` returns nil and `.portal_column_count` raises `NoMethodError`.
**Why it matters:** The existing Portal code already calls `user.preference.use_todo?` and `user.preference.use_calendar?` without nil guards — the codebase treats preference as always-present for authenticated users. Consistent with existing pattern; nil guard is optional per CONTEXT.md discretion.
**How to avoid:** If a nil guard is added: `user.preference&.portal_column_count || 3`.

### Pitfall 5: `@portal_columns` Memoization Stale After Preference Change

**What goes wrong:** Because `portal_columns` memoizes in `@portal_columns`, if preference changes after first call, the cached value reflects old count.
**Why it happens:** Memoization is instance-level. This is only relevant in tests that mutate preference mid-object-lifecycle.
**How to avoid:** In tests, instantiate a fresh Portal object after changing preference count.

## Runtime State Inventory

> This phase adds a DB column — not a rename/refactor. Standard inventory applies only to confirm no stored state references `portal_column_count` before it is added.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | No existing `portal_column_count` records (column does not yet exist) | None — DB default handles existing rows |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Code Examples

### Full `portal_columns` After Change

```ruby
# Source: derived from app/models/portal.rb lines 5-24 (verified)
def portal_column_count
  user.preference.portal_column_count
end

def portal_columns
  return @portal_columns if @portal_columns

  gadgets = get_gadgets
  count = portal_column_count
  @portal_columns = Array.new(count) { [] }

  PortalLayout.where(user_id: user.id).order('column_no, display_order').each do |pl|
    next if pl.column_no >= count
    g = gadgets.delete(pl.gadget_id)
    @portal_columns[pl.column_no] << g if g
  end

  gadgets.each_with_index do |g, i|
    @portal_columns[i % count].unshift(g[1])
  end

  @portal_columns
end
```

### Preference Model Addition

```ruby
# Source: derived from app/models/preference.rb lines 5-9, 20 (verified)
PORTAL_COLUMN_COUNTS = [3, 4].freeze

validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }
```

### Preference Test Pattern (new tests, mirrors `test_文字サイズは選択肢のみ有効`)

```ruby
# Source: derived from test/models/preference_test.rb lines 14-27 (verified)
def test_ポータル列数は3か4のみ有効
  p = Preference.default_preference(user)

  Preference::PORTAL_COLUMN_COUNTS.each do |count|
    p.portal_column_count = count
    assert p.valid?, "#{count} should be valid"
  end

  p.portal_column_count = 2
  assert_not p.valid?, "2 should be invalid"

  p.portal_column_count = 5
  assert_not p.valid?, "5 should be invalid"
end

def test_デフォルトのポータル列数は3
  p = user.preference
  assert_equal 3, p.portal_column_count
end
```

### Portal Test (new file `test/models/portal_test.rb`)

```ruby
require 'test_helper'

class PortalTest < ActiveSupport::TestCase

  def test_portal_columnsは列数に応じたサブ配列を返す
    portal = portals(:p_1)
    # Default preference has portal_column_count = 3 (DB default)
    assert_equal 3, portal.portal_columns.size
  end

  def test_portal_columnsは4列を返す
    portal = portals(:p_1)
    portal.user.preference.update!(portal_column_count: 4)
    # Reset memoization
    portal.instance_variable_set(:@portal_columns, nil)
    assert_equal 4, portal.portal_columns.size
  end

  def test_column_no_が列数以上のPortalLayoutはスキップされる
    portal = portals(:p_1)
    # Simulate downgrade: preference at 3, but a layout record has column_no=3
    portal.user.preference.update_columns(portal_column_count: 3)
    # PortalLayout with column_no=3 would be out-of-bounds for a 3-column portal
    # portal_columns should not raise and should return 3 sub-arrays
    portal.instance_variable_set(:@portal_columns, nil)
    result = portal.portal_columns
    assert_equal 3, result.size
    result.each { |col| assert_instance_of Array, col }
  end

end
```

Note: Exact test for skipping column_no >= count may need a PortalLayout fixture or inline creation depending on fixture state. The pattern above uses `update_columns` to bypass validation.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails default) |
| Config file | none (uses Rails test defaults) |
| Quick run command | `bin/rails test test/models/preference_test.rb test/models/portal_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COL-01 | Valid values [3, 4] accepted | unit | `bin/rails test test/models/preference_test.rb` | Exists (add tests) |
| COL-01 | Invalid value (e.g. 2, 5) rejected | unit | `bin/rails test test/models/preference_test.rb` | Exists (add tests) |
| COL-01 | Default value is 3 | unit | `bin/rails test test/models/preference_test.rb` | Exists (add tests) |
| COL-04 | `portal_column_count` delegates to preference | unit | `bin/rails test test/models/portal_test.rb` | Wave 0 gap |
| COL-04 | `portal_columns` returns N sub-arrays for N=3,4 | unit | `bin/rails test test/models/portal_test.rb` | Wave 0 gap |
| COL-06 | `column_no >= count` records skipped, no raise | unit | `bin/rails test test/models/portal_test.rb` | Wave 0 gap |

### Sampling Rate

- **Per task commit:** `bin/rails test test/models/preference_test.rb test/models/portal_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test` green before marking phase complete

### Wave 0 Gaps

- [ ] `test/models/portal_test.rb` — covers COL-04, COL-06 (file does not exist; must be created)

## Security Domain

No authentication, session management, or cryptography involved. Input validation (COL-01) is handled by ActiveRecord inclusion validation — no hand-rolled validation needed.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes (portal_column_count) | `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` |
| All others | no | — |

## Open Questions

1. **Nil guard on `user.preference.portal_column_count` in Portal**
   - What we know: Existing Portal code calls `user.preference.use_todo?` / `user.preference.use_calendar?` without nil guards; preference is always present for authenticated users.
   - What's unclear: Whether the planner wants to add `&.portal_column_count || 3` defensively.
   - Recommendation: Skip nil guard for consistency with existing pattern; note it as Claude's discretion per CONTEXT.md.

2. **Portal test fixture: PortalLayout records needed for downgrade test**
   - What we know: `test/fixtures/portals.yml` has `p_1` (user_id: 1). No portal_layouts fixture exists (not listed in fixtures dir).
   - What's unclear: Whether the downgrade test (COL-06) should create PortalLayout records inline in the test or rely on fixtures.
   - Recommendation: Create inline in the test using `PortalLayout.create!` — avoids fixture coupling.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — pure Rails model/migration work, no new gems, no external services).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | New migration should use `ActiveRecord::Migration[8.1]` (matching the most recent migration's version) | Standard Stack / Migration Pattern | Migration would still run; just cosmetically inconsistent |

All other claims were verified by reading source files directly.

## Sources

### Primary (HIGH confidence)

- `app/models/preference.rb` — FONT_SIZES constant pattern, validation pattern, `allow_nil: true` usage
- `app/models/portal.rb` — exact lines for portal_column_count (line 5-7) and portal_columns (lines 9-25)
- `db/schema.rb` — confirmed `preferences` table columns; `portal_column_count` absent; schema version `2026_05_14_200001`
- `db/migrate/20260514200000_add_show_column_nav_buttons_to_preferences.rb` — migration pattern for boolean column
- `db/migrate/20260514200001_update_show_column_nav_buttons_on_preferences.rb` — uses `ActiveRecord::Migration[8.1]`
- `test/models/preference_test.rb` — existing test patterns (Japanese method names, FONT_SIZES tests)
- `test/fixtures/preferences.yml` — 3 preference rows; no `portal_column_count` column (expected)
- `test/fixtures/portals.yml` — single fixture `p_1` (user_id: 1)
- `app/views/welcome/index.html.erb` — confirmed `portal_column_count` and `portal_columns` call sites

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use; no new dependencies
- Architecture: HIGH — exact source lines verified for every change
- Pitfalls: HIGH — derived from actual code paths; not from training data assumptions
- Migration timestamp: HIGH — latest migration is `20260514200001`; next safe timestamp is `20260515000000`

**Research date:** 2026-05-15
**Valid until:** 2026-06-15 (stable Rails codebase; no fast-moving dependencies)
