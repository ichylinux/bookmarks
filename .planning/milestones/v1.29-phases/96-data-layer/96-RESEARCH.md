# Phase 96: Data Layer - Research

**Researched:** 2026-05-20
**Domain:** Rails ActiveRecord migration + model class methods + Minitest unit testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Schema: `success boolean + error_code varchar(32)` — maps directly to XClient `{ success:, error: }` return contract
- `rate_limit_remaining` is nullable integer (DATA-03)
- `called_at` is NOT NULL — all recorded calls have a timestamp
- `(user_id, called_at)` composite index for per-user time-range queries
- `XApiCall.record!` is a class method (VisitedLink pattern)
- `XApiCall.usage_summary(since:)` returns per-user aggregates: total calls, last called_at, error count
- `endpoint` column: string, not null
- No `timestamps` helper — `called_at` is the primary timestamp column; skip `created_at`/`updated_at`
- `usage_summary` groups by `user_id`, joins `users` for email, accepts `since:` keyword

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions.

### Deferred Ideas (OUT OF SCOPE)
None — discuss phase skipped (infrastructure). Phase 97 handles instrumentation wiring.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | `x_api_calls` table with columns `user_id`, `endpoint`, `success`, `error_code`, `called_at`; `(user_id, called_at)` index present | Migration pattern from `CreateVisitedLinks`; column types verified in schema.rb |
| DATA-02 | `XApiCall` model with `record!` class method and aggregation scope for per-user summaries | `VisitedLink.record!` pattern; `group/select` AR aggregation with `users` join |
| DATA-03 | `rate_limit_remaining` nullable integer column on `x_api_calls` captures X-Rate-Limit-Remaining header per call | Nullable integer column; no default needed |
</phase_requirements>

---

## Summary

Phase 96 is a pure data layer phase: create one migration, one model, and one model test file. All three deliverables follow patterns already established in the codebase, specifically `visited_links` / `VisitedLink`. No new gems, no controllers, no views.

The migration creates `x_api_calls` with six columns (`user_id`, `endpoint`, `success`, `error_code`, `called_at`, `rate_limit_remaining`) and a composite index on `(user_id, called_at)`. The model exposes two class methods: `record!` for inserting a single tracking row, and `usage_summary(since:)` for returning per-user aggregates via a GROUP BY query joined to `users`. The test file covers both class methods plus nil/default handling for optional columns, following the `VisitedLinkTest` structure.

The implementation requires zero external dependencies beyond what is already in the Gemfile. All patterns are directly observable in the codebase at the commit referenced in STATE.md.

**Primary recommendation:** Mirror `CreateVisitedLinks` + `VisitedLink` + `VisitedLinkTest` exactly, adapting for the different column set and the `usage_summary` aggregation method.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema definition | Database / Storage | — | Migration creates table; schema.rb updated automatically |
| Event recording | API / Backend (Model) | — | `XApiCall.record!` called from controller (Phase 97); model owns persistence logic |
| Aggregation query | API / Backend (Model) | — | `usage_summary` is a model-level class method; controller layer consumes result (Phase 99) |
| Unit tests | Test layer | — | Minitest model test verifies all three behaviors in isolation |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ActiveRecord | bundled (Rails 7.2) | ORM, migrations, query building | Project standard; all models inherit `ApplicationRecord` |
| Minitest | bundled (Rails 7.2) | Unit testing | Project standard test framework |

[VERIFIED: codebase] — confirmed via `db/schema.rb`, `Gemfile`, and existing model/test files.

No new gems required for this phase.

### Supporting

N/A — no external libraries needed.

### Alternatives Considered

N/A — all choices are locked by project conventions and CONTEXT.md.

---

## Package Legitimacy Audit

> No external packages are installed in this phase. All functionality is implemented with bundled Rails/ActiveRecord and Ruby stdlib.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
[Phase 97 caller]
      |
      v
XApiCall.record!(user_id:, endpoint:, success:, error_code:, rate_limit_remaining:)
      |
      v
INSERT INTO x_api_calls (user_id, endpoint, success, error_code, called_at, rate_limit_remaining)
      |
      v
[x_api_calls table]  <----  XApiCall.usage_summary(since: date)
                                  |
                                  v
                             GROUP BY user_id
                             JOIN users ON users.id = x_api_calls.user_id
                             SELECT user_id, users.email,
                                    COUNT(*) AS total_calls,
                                    MAX(called_at) AS last_called_at,
                                    SUM(CASE WHEN success = false THEN 1 ELSE 0 END) AS error_count
                                  |
                                  v
                             Array of result rows (Phase 99 consumes)
```

### Recommended Project Structure

```
app/models/
└── x_api_call.rb          # new model

db/migrate/
└── 20260520HHMMSS_create_x_api_calls.rb   # new migration

test/models/
└── x_api_call_test.rb     # new Minitest model test

test/fixtures/
└── x_api_calls.yml        # empty fixture (comment only — programmatic test data)
```

### Pattern 1: Migration — `CreateXApiCalls`

**What:** Create the `x_api_calls` table with explicit column types and NOT NULL constraints; add composite index separately using `add_index`.

**When to use:** Any new tracking/log table in this codebase.

**Example (adapted from `CreateVisitedLinks`):**

```ruby
# Source: db/migrate/20260518200000_create_visited_links.rb (VERIFIED: codebase)
class CreateXApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :x_api_calls do |t|
      t.integer  :user_id,              null: false
      t.string   :endpoint,             null: false
      t.boolean  :success,              null: false
      t.string   :error_code,           limit: 32
      t.datetime :called_at,            null: false
      t.integer  :rate_limit_remaining
    end

    add_index :x_api_calls, %i[user_id called_at]
  end
end
```

Key decisions:
- `error_code` — nullable string (limit: 32); no NOT NULL because success calls have no error code [ASSUMED from CONTEXT.md]
- `rate_limit_remaining` — nullable integer; no default [VERIFIED: CONTEXT.md decision]
- No `timestamps` helper — `called_at` is the only timestamp column [VERIFIED: CONTEXT.md decision]
- Migration version `[8.1]` — consistent with all other migrations [VERIFIED: codebase]

### Pattern 2: Model — `XApiCall`

**What:** Class with `belongs_to :user`, `record!` class method, and `usage_summary` class method.

**When to use:** Append-only tracking model (not CRUD); no validation needed on insert (record! controls input).

**Example:**

```ruby
# Source: app/models/visited_link.rb pattern (VERIFIED: codebase)
class XApiCall < ApplicationRecord
  belongs_to :user

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

  def self.usage_summary(since:)
    joins(:user)
      .where('called_at >= ?', since)
      .group(:user_id)
      .select(
        :user_id,
        'users.email AS email',
        'COUNT(*) AS total_calls',
        'MAX(called_at) AS last_called_at',
        'SUM(CASE WHEN success = FALSE THEN 1 ELSE 0 END) AS error_count'
      )
  end
end
```

Design notes:
- `record!` uses keyword arguments with defaults for optional params — callers in Phase 97 pass `error_code:` only on error paths [ASSUMED from CONTEXT.md]
- `create!` (not `upsert`) — calls are not unique events; every call appends a new row [VERIFIED: CONTEXT.md — "no upsert needed (calls are not unique)"]
- `usage_summary` returns an ActiveRecord::Relation of model instances (with virtual attributes) — the report controller (Phase 99) iterates them directly [ASSUMED]
- `joins(:user)` works because `belongs_to :user` is declared above [VERIFIED: codebase AR pattern]

### Pattern 3: Minitest Model Test

**What:** `ActiveSupport::TestCase` subclass with `delete_all` in `setup`, covering `record!` and `usage_summary`.

**When to use:** All model unit tests in this project.

**Example (adapted from `VisitedLinkTest`):**

```ruby
# Source: test/models/visited_link_test.rb (VERIFIED: codebase)
require 'test_helper'

class XApiCallTest < ActiveSupport::TestCase
  def setup
    XApiCall.delete_all
    @user  = User.find(1)
    @user2 = User.find(2)
  end

  # record!
  def test_record_inserts_row
    assert_difference -> { XApiCall.count }, 1 do
      XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    end
  end

  def test_record_stores_correct_values
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: false,
                     error_code: 'unauthorized', rate_limit_remaining: 42)
    row = XApiCall.last
    assert_equal @user.id,      row.user_id
    assert_equal 'fetch_following', row.endpoint
    assert_equal false,         row.success
    assert_equal 'unauthorized', row.error_code
    assert_equal 42,            row.rate_limit_remaining
    assert_not_nil              row.called_at
  end

  def test_record_nil_error_code_when_success
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_recent_tweets', success: true)
    assert_nil XApiCall.last.error_code
  end

  def test_record_nil_rate_limit_remaining_when_omitted
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    assert_nil XApiCall.last.rate_limit_remaining
  end

  # usage_summary
  def test_usage_summary_counts_calls
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    results = XApiCall.usage_summary(since: 1.day.ago)
    row = results.find { |r| r.user_id == @user.id }
    assert_equal 2, row.total_calls.to_i
  end

  def test_usage_summary_counts_errors
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: false, error_code: 'rate_limited')
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    results = XApiCall.usage_summary(since: 1.day.ago)
    row = results.find { |r| r.user_id == @user.id }
    assert_equal 1, row.error_count.to_i
  end

  def test_usage_summary_filters_by_since
    XApiCall.record!(user_id: @user.id, endpoint: 'fetch_following', success: true)
    results = XApiCall.usage_summary(since: 1.hour.from_now)
    assert results.none? { |r| r.user_id == @user.id }
  end

  def test_usage_summary_segregates_users
    XApiCall.record!(user_id: @user.id,  endpoint: 'fetch_following', success: true)
    XApiCall.record!(user_id: @user2.id, endpoint: 'fetch_following', success: false, error_code: 'err')
    results = XApiCall.usage_summary(since: 1.day.ago)
    user1_row = results.find { |r| r.user_id == @user.id }
    user2_row = results.find { |r| r.user_id == @user2.id }
    assert_equal 1, user1_row.total_calls.to_i
    assert_equal 0, user1_row.error_count.to_i
    assert_equal 1, user2_row.error_count.to_i
  end
end
```

### Anti-Patterns to Avoid

- **Using `timestamps` helper:** This table uses only `called_at` — adding `created_at`/`updated_at` contradicts the tracking-record pattern and wastes storage. [VERIFIED: CONTEXT.md decision]
- **Using `upsert` in `record!`:** Calls are not unique events; upsert would collapse multiple calls into one row. Always use `create!`. [VERIFIED: CONTEXT.md]
- **Putting aggregation logic in the controller:** `usage_summary` belongs on the model; controllers (Phase 99) should only call it and pass results to views.
- **Skipping `delete_all` in test `setup`:** Without cleanup, test counts bleed between test methods. `VisitedLinkTest` demonstrates the correct pattern. [VERIFIED: codebase]
- **Omitting the fixture file:** Rails fixture loading will not fail without `x_api_calls.yml`, but some setups may warn. Add an empty/commented fixture file for consistency with `visited_links.yml`. [VERIFIED: codebase — visited_links.yml has comment-only content]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Aggregation query with GROUP BY | Custom SQL string in model | ActiveRecord `group` + `select` with `joins` | AR escapes properly, works with test DB; raw SQL skips query interface |
| Current timestamp | `Time.now` | `Time.current` | Respects Rails time zone config; consistent with `visited_at: Time.current` in VisitedLink |
| Test isolation | Before-each DB truncation | `delete_all` in `setup` | Existing pattern; faster than truncation for single-table isolation |

---

## Runtime State Inventory

> Not applicable — this is a greenfield table creation, not a rename/refactor phase. No existing runtime state references `x_api_calls`.

---

## Common Pitfalls

### Pitfall 1: `total_calls` / `error_count` returns String from GROUP BY

**What goes wrong:** MySQL returns aggregated `COUNT(*)` and `SUM(...)` as strings when accessed via virtual attribute on an AR model. `row.total_calls == 2` fails; `row.total_calls == "2"` passes (or needs `.to_i`).

**Why it happens:** ActiveRecord does not cast virtual `select` attributes through the type system automatically for aggregate expressions.

**How to avoid:** In tests, use `.to_i` when asserting counts: `assert_equal 2, row.total_calls.to_i`. In the view/controller (Phase 99), call `.to_i` or use `Integer(row.total_calls)`.

**Warning signs:** Assertion failures like `Expected "2", got 2` in the usage_summary tests.

### Pitfall 2: `success` boolean column default behavior on MySQL

**What goes wrong:** MySQL strict mode may reject an INSERT that omits `success` even if ActiveRecord doesn't raise. Or: `success` reads back as `0`/`1` (tinyint) rather than `true`/`false`.

**Why it happens:** MySQL stores boolean as TINYINT(1); ActiveRecord casts on read, but the `create!` call must always pass an explicit `success:` value — no default is set.

**How to avoid:** `record!` signature makes `success:` a required keyword argument (no default). Tests explicitly pass `success: true` or `success: false`.

**Warning signs:** `ActiveRecord::NotNullViolation` on success column, or test assertions on `row.success` failing with integer comparison.

### Pitfall 3: `usage_summary` returns empty when `since:` is a Date not a DateTime

**What goes wrong:** `where('called_at >= ?', Date.today)` works but `where('called_at >= ?', Date.today + 1)` excludes today's rows correctly. Confusion arises when `since:` receives a `Date` vs `Time`/`DateTime` object — MySQL datetime comparison with a date string may truncate.

**Why it happens:** `called_at` is a `datetime` column; comparing against a `Date` object causes Rails to cast to midnight, which is usually correct but can be surprising in tests that insert and immediately query.

**How to avoid:** Tests use `1.day.ago` (returns `ActiveSupport::TimeWithZone`) not `Date.today`. In production usage (Phase 99 date-range filter), parse to `DateTime` or `Time.zone.parse`.

**Warning signs:** `usage_summary(since: Date.today)` returns zero rows for records inserted in the test setup.

### Pitfall 4: Migration timestamp collision

**What goes wrong:** Two migrations with the same YYYYMMDDHHMMSS prefix fail to load.

**Why it happens:** Manually specified timestamps can collide with existing migrations.

**How to avoid:** Use `bin/rails generate migration CreateXApiCalls` to auto-generate the timestamp, or verify the chosen timestamp does not appear in `db/migrate/` already. The last migration is `20260519164758` — any timestamp on or after `20260520000000` is safe.

**Warning signs:** `ActiveRecord::DuplicateMigrationVersionError` on `bin/rails db:migrate`.

---

## Code Examples

### Full migration

```ruby
# Source: db/migrate/20260518200000_create_visited_links.rb adapted (VERIFIED: codebase)
class CreateXApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :x_api_calls do |t|
      t.integer  :user_id,              null: false
      t.string   :endpoint,             null: false
      t.boolean  :success,              null: false
      t.string   :error_code,           limit: 32
      t.datetime :called_at,            null: false
      t.integer  :rate_limit_remaining
    end

    add_index :x_api_calls, %i[user_id called_at]
  end
end
```

### Full model

```ruby
# Source: app/models/visited_link.rb adapted (VERIFIED: codebase)
class XApiCall < ApplicationRecord
  belongs_to :user

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

  def self.usage_summary(since:)
    joins(:user)
      .where('called_at >= ?', since)
      .group(:user_id)
      .select(
        :user_id,
        'users.email AS email',
        'COUNT(*) AS total_calls',
        'MAX(called_at) AS last_called_at',
        'SUM(CASE WHEN success = FALSE THEN 1 ELSE 0 END) AS error_count'
      )
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ActiveRecord::Migration[5.2]` | `ActiveRecord::Migration[8.1]` | Rails 8 upgrade | Version suffix must match current Rails; `[8.1]` used in all existing migrations |

**Deprecated/outdated:**
- `timestamps` in tracking/log tables: Still valid but not used in this codebase's tracking-record tables (`visited_links` uses it, but CONTEXT.md explicitly opts out for `x_api_calls`).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `error_code` is nullable (success calls have no error code) | Standard Stack / migration | If NOT NULL, migration fails on success rows; fix: add `default: nil` guard or change column |
| A2 | `record!` keyword argument signature with `success:` required, others optional | Code Examples | If caller passes positional args, `ArgumentError`; low risk — Phase 97 will adapt to signature |
| A3 | `usage_summary` returns AR relation of model instances (not plain hash array) | Code Examples | Phase 99 view must use `.to_i` on aggregate attrs; if Hash expected, adapt with `.map` |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions (RESOLVED)

1. RESOLVED: **`usage_summary` join behavior for users with zero calls** — Use INNER JOIN (`joins(:user)`). A usage report shows only users who have called the API; zero-call users are excluded. Phase 99 may revisit with LEFT JOIN if the requirement changes, but DATA-02 does not require showing zero-call users.

2. RESOLVED: **Fixture file requirement** — Create an empty/comment-only `test/fixtures/x_api_calls.yml` for consistency with `visited_links.yml`. Plan 96-01 includes this in `files_modified`.

---

## Environment Availability

> Step 2.6: SKIPPED for most dependencies (pure data layer, no new external dependencies).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MySQL | Migration execution | Confirmed (schema.rb exists, last migration ran) | 8.x | — |
| Rails bin/rails | Migration, test runner | Confirmed (existing project) | 7.2 | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (bundled Rails) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/models/x_api_call_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Migration creates table with correct columns and index | schema inspection (manual) + migration run | `bin/rails db:migrate` + `bin/rails db:schema:dump` | N/A — migration file |
| DATA-02a | `record!` inserts a row with correct values | unit | `bin/rails test test/models/x_api_call_test.rb` | Wave 0 |
| DATA-02b | `usage_summary` returns correct per-user aggregates | unit | `bin/rails test test/models/x_api_call_test.rb` | Wave 0 |
| DATA-03 | `rate_limit_remaining` nullable, stored and returned correctly | unit | `bin/rails test test/models/x_api_call_test.rb` | Wave 0 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/models/x_api_call_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

- [ ] `test/models/x_api_call_test.rb` — covers DATA-02a, DATA-02b, DATA-03
- [ ] `test/fixtures/x_api_calls.yml` — empty/comment-only file for fixture consistency

*(No framework install needed — Minitest already present)*

---

## Security Domain

> This phase has no user-facing HTTP surface, no authentication logic, and no input from untrusted sources. The model's `record!` method is called only from server-side controller code (Phase 97) with values sourced from the X API response and internal Rails objects.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | `endpoint` and `error_code` originate from XClient return values (server-side); no user-supplied input in this phase |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via aggregation query | Tampering | ActiveRecord parameterized `where('called_at >= ?', since)` — never string interpolation |

---

## Sources

### Primary (HIGH confidence)
- `app/models/visited_link.rb` [VERIFIED: codebase] — `record!` pattern, class method structure, `Time.current`, no-upsert
- `db/migrate/20260518200000_create_visited_links.rb` [VERIFIED: codebase] — migration version, column syntax, `add_index` pattern
- `test/models/visited_link_test.rb` [VERIFIED: codebase] — test structure, `delete_all` in setup, `assert_difference`, fixture user access
- `db/schema.rb` [VERIFIED: codebase] — current schema, all column types, index patterns
- `.planning/milestones/v1.29-phases/96-data-layer/96-CONTEXT.md` [VERIFIED: planning docs] — locked decisions on schema, method signatures, no-timestamps, usage_summary spec

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` [VERIFIED: planning docs] — DATA-01, DATA-02, DATA-03 requirement text
- `.planning/ROADMAP.md` [VERIFIED: planning docs] — success criteria for Phase 96

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries are bundled Rails; no external packages
- Architecture: HIGH — directly observable patterns in codebase
- Pitfalls: MEDIUM — MySQL aggregate casting pitfall from AR knowledge [ASSUMED]; others HIGH from codebase observation

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (stable Rails/MySQL stack — 30 days)
