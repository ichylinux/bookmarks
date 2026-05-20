# Phase 96: Data Layer - Research

**Researched:** 2026-05-20
**Domain:** Rails migration + ActiveRecord model (logging/append-only table, class-method API, grouped aggregation)
**Confidence:** HIGH

## Summary

Phase 96 is a pure data-layer addition with no user-facing UI. It creates the `x_api_calls` table and the `XApiCall` model with two class methods: `record!` (insert a row) and `usage_summary` (grouped aggregate query). All design decisions were locked in CONTEXT.md via the discuss-phase.

The existing codebase provides clear analogues: `VisitedLink` is the closest structural reference — a logging model with no update path — but `XApiCall` diverges in three ways: (1) no `Crud::ByUser` concern, (2) no Rails timestamps (only explicit `called_at`), (3) a `usage_summary` class method returning a grouped AR relation. The composite `(user_id, called_at)` index mirrors the `notes` table pattern.

MySQL stores `boolean` columns as `TINYINT(1)`. The CONTEXT.md `error_count` SQL idiom — `SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END)` — correctly uses `0` (not `false`) for MySQL boolean false comparison. This is the critical correctness detail for the aggregation query.

**Primary recommendation:** Follow the `VisitedLink` + `CreateNotes` migration style exactly; use `Migration[8.1]` (newest migrations in the repo); write `usage_summary` as a single grouped `select(...)` returning an AR relation so Phase 99 can chain `.order()` and `.where()` without loading rows.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Migration Design**
- No Rails timestamps — only `called_at datetime NOT NULL` as the explicit time column; `x_api_calls` is an append-only logging table with immutable rows, so `created_at/updated_at` adds no value
- Null constraints: `endpoint string NOT NULL`, `success boolean NOT NULL`, `error_code string NULL`, `rate_limit_remaining integer NULL`
- `error_code` column: `varchar(32)` (maps to XClient 7-symbol error contract: `:timeout`, `:network`, `:api_error`, etc.)
- Index: composite `(user_id, called_at)` index supports the per-user time-range queries in Phase 99

**Model API Contract**
- `record!` signature: keyword args — `XApiCall.record!(user_id:, endpoint:, success:, error_code: nil, rate_limit_remaining: nil)` — matches the XClient `{ success:, error: }` return hash structure
- `usage_summary` return type: AR grouped select returning a relation with `user_id`, `total_calls`, `last_called_at`, `error_count` — keeps it filterable/sortable for Phase 99 controller
- No `Crud::ByUser` concern — `XApiCall` is a logging table, not a user CRUD resource; admin-visible via class methods only
- `belongs_to :user, optional: false` — enforce FK integrity; logging rows should never be orphaned

**Prior Decisions (from STATE.md research)**
- Schema: `success boolean + error_code varchar(32)` confirmed (maps to XClient `{ success:, error: }` contract)
- `record!` must be called OUTSIDE any transaction wrapper to avoid data loss on rollback

### Claude's Discretion

- Test method naming (use Japanese method names following project convention)
- `setup` block in test (use `XApiCall.delete_all` like `VisitedLinkTest`)

### Deferred Ideas (OUT OF SCOPE)

- Per-endpoint breakdown in `usage_summary` — Phase 99 REPORT-01 mentions "endpoint breakdown" but Phase 96 success criteria only needs totals; endpoint breakdown can be added in Phase 99 if needed
- Pruning/retention Rake task — future requirement (ACCT-FUT-01 pattern)
- Rate-limit window tracking — future requirement
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | `x_api_calls` table exists with columns `user_id`, `endpoint`, `success`, `error_code`, `called_at`; `(user_id, called_at)` index present | Migration pattern from `CreateNotes` + `CreateVisitedLinks`; no timestamps per lock |
| DATA-02 | `XApiCall` model with `record!` class method and aggregation scope for per-user summaries | `VisitedLink.record!` pattern + grouped `select(...)` with SQL aggregates |
| DATA-03 | `rate_limit_remaining` nullable integer column on `x_api_calls` captures X-Rate-Limit-Remaining header per call | Included in migration alongside other nullable columns; integer type confirmed |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema creation (migration) | Database / Storage | — | DDL-only change; no application tier involved |
| Row insertion (`record!`) | Database / Storage | API / Backend (caller) | `XApiCall` owns persistence; Phase 97 controllers own calling it |
| Per-user aggregation (`usage_summary`) | Database / Storage | API / Backend (consumer) | SQL grouping executes in DB; Phase 99 controller filters/sorts the returned relation |
| FK integrity (`belongs_to :user`) | Database / Storage | — | Enforced at AR model level; no controller involvement |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ActiveRecord migration | Rails 8.1 [VERIFIED: codebase] | Schema DDL | All recent migrations use `Migration[8.1]` |
| ActiveRecord model | Rails 8.1 [VERIFIED: codebase] | ORM + class methods | Project standard; `ApplicationRecord` base |
| ActiveSupport::TestCase | Rails 8.1 [VERIFIED: codebase] | Unit tests | All `test/models/` use this base class |

No new gems required. This phase is purely internal Rails + MySQL.

### Supporting

None — no new dependencies.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw `create!` in `record!` | `insert` / `upsert` | `create!` raises on failure (appropriate for append-only); `upsert` is for idempotent ops (not needed here) |
| `SUM(CASE WHEN success = 0 ...)` | `COUNT(*) FILTER (WHERE NOT success)` | `FILTER` is PostgreSQL-only; MySQL requires `CASE WHEN` idiom |
| `group(:user_id).select(...)` relation | `pluck` into Array | Relation is lazy and chainable; Phase 99 will add `.order()` and optional `.where()`; Array cannot be extended |

## Package Legitimacy Audit

No external packages are installed in this phase. All work uses existing Rails/Ruby standard library.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
XApiCall.record!(user_id:, endpoint:, success:, error_code:, rate_limit_remaining:)
  └─► INSERT INTO x_api_calls (user_id, endpoint, success, error_code, called_at, rate_limit_remaining)

XApiCall.usage_summary(since: nil)
  └─► SELECT user_id, COUNT(*), MAX(called_at), SUM(CASE ...) FROM x_api_calls
      [WHERE called_at >= since]  ← optional
      GROUP BY user_id
      └─► AR Relation (chainable for Phase 99 sort/filter)
```

### Recommended Project Structure

```
db/migrate/
└── 20260520XXXXXX_create_x_api_calls.rb   # new

app/models/
└── x_api_call.rb                           # new

test/models/
└── x_api_call_test.rb                      # new
```

### Pattern 1: Append-only logging migration (no timestamps)

**What:** Creates table with explicit `called_at` column; omits `t.timestamps`; uses `t.integer :user_id` style (alphabetical column ordering matches schema.rb convention).
**When to use:** Immutable logging tables where update time has no business meaning.

```ruby
# Source: codebase — db/migrate/20260518200000_create_visited_links.rb (adapted)
class CreateXApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :x_api_calls do |t|
      t.datetime :called_at,            null: false
      t.string   :endpoint,             null: false
      t.string   :error_code,           limit: 32
      t.integer  :rate_limit_remaining
      t.boolean  :success,              null: false
      t.integer  :user_id,              null: false
    end

    add_index :x_api_calls, %i[user_id called_at]
  end
end
```

Note: columns listed alphabetically — matches schema.rb output ordering seen across the project.

### Pattern 2: Class-method record! with keyword args

**What:** Class method that constructs and persists a row; raises on failure (bang method convention).
**When to use:** Append-only writes where the caller should not suppress exceptions.

```ruby
# Source: codebase — app/models/visited_link.rb (adapted for keyword args)
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

### Pattern 3: Grouped aggregate query returning chainable AR relation

**What:** `group(:user_id).select(...)` with SQL aggregate expressions; `since:` applied via `where` before grouping; returns relation (not Array).
**When to use:** Per-user summaries that the consuming controller needs to sort or paginate.

```ruby
# Source: [ASSUMED] — standard ActiveRecord grouped select pattern
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

Critical MySQL note: `success = 0` is the correct boolean false comparison. `success = false` also works in AR, but `0` is unambiguous at the SQL level.

### Anti-Patterns to Avoid

- **Using `t.timestamps` in the migration:** Locked out by CONTEXT.md. The table is immutable; `updated_at` is meaningless.
- **Returning an Array from `usage_summary`:** Using `.pluck` or `.to_a` breaks Phase 99's ability to chain `.order()` and `.where()`.
- **Calling `record!` inside a `transaction` block:** Per STATE.md lock — if the surrounding transaction rolls back, the log row is lost. Callers must invoke `record!` after the transaction closes.
- **Including `Crud::ByUser`:** Locked out by CONTEXT.md. `XApiCall` is not a user-owned CRUD resource.
- **`belongs_to :user, optional: true`:** The lock specifies `optional: false` to prevent orphaned log rows.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timestamp for insert time | Custom `before_create` callback | `t.datetime :called_at, null: false` + `Time.current` in `record!` | No callback overhead; simpler and auditable |
| Aggregate query | Ruby-side loop over all rows | `group(:user_id).select(...)` SQL aggregates | O(n) Ruby loop vs O(1) DB-side group; critical for large log tables |
| Boolean false count | Fetch all rows, filter in Ruby | `SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END)` | Single query; correct even on millions of rows |

**Key insight:** Aggregate queries must run in the database. For an append-only log table that may accumulate thousands of rows per user, fetching all rows to count errors in Ruby is a correctness and performance hazard.

## Common Pitfalls

### Pitfall 1: MySQL boolean false comparison in SQL strings

**What goes wrong:** Writing `SUM(CASE WHEN success = false ...)` works in PostgreSQL but MySQL evaluates `false` as the integer `0` only sometimes — raw SQL strings do not go through AR type casting, so `success = false` in a SQL fragment may behave unexpectedly depending on MySQL version.
**Why it happens:** MySQL stores booleans as `TINYINT(1)`. AR casts Ruby `false` to `0` for bound parameters but not in raw SQL string fragments.
**How to avoid:** Use `success = 0` in the SQL `CASE WHEN` fragment. This is unambiguous across MySQL versions.
**Warning signs:** `error_count` always returns 0 even when failures exist.

### Pitfall 2: `usage_summary` relation loses attributes on `.all` calls

**What goes wrong:** The grouped select returns a synthetic result set with virtual columns (`total_calls`, `last_called_at`, `error_count`). Calling `.first`, `.last`, or chaining `.includes` can strip or confuse these virtual columns.
**Why it happens:** AR doesn't know the virtual columns are part of the SELECT; some chain methods re-issue a `SELECT *`.
**How to avoid:** Access virtual columns only after `.to_a` or direct iteration. Do not chain `.includes` or `.joins` onto the result of `usage_summary`.
**Warning signs:** `NoMethodError: undefined method 'total_calls'` on result rows.

### Pitfall 3: `create!` called inside a transaction at the call site

**What goes wrong:** If a controller wraps its work in `ActiveRecord::Base.transaction { ... }` and calls `XApiCall.record!` inside that block, a subsequent rollback destroys the log row — making the tracking data incorrect.
**Why it happens:** `record!` itself doesn't wrap a transaction; the hazard is the caller's transaction.
**How to avoid:** Call `record!` after the transaction block returns (at controller level, not inside service transaction). This is a locked decision — tests do not need to exercise this boundary, but plans must note it in task descriptions.
**Warning signs:** Missing rows in `x_api_calls` when corresponding API calls fail.

### Pitfall 4: `add_index` order matters for MySQL query optimizer

**What goes wrong:** Using a single-column index on `user_id` instead of a composite `(user_id, called_at)` index causes a full table scan for the `since:` date-range filter in Phase 99.
**Why it happens:** MySQL uses only the leftmost prefix of a composite index. A `WHERE user_id = ? AND called_at >= ?` query benefits from `(user_id, called_at)` but not `(called_at, user_id)`.
**How to avoid:** Index is `add_index :x_api_calls, %i[user_id called_at]` — user_id first, called_at second.

## Code Examples

### Migration (complete)

```ruby
# Source: codebase — CreateNotes + CreateVisitedLinks patterns (adapted)
class CreateXApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :x_api_calls do |t|
      t.datetime :called_at,            null: false
      t.string   :endpoint,             null: false
      t.string   :error_code,           limit: 32
      t.integer  :rate_limit_remaining
      t.boolean  :success,              null: false
      t.integer  :user_id,              null: false
    end

    add_index :x_api_calls, %i[user_id called_at]
  end
end
```

### Model (complete)

```ruby
# Source: codebase — VisitedLink pattern (adapted) + CONTEXT.md decisions
class XApiCall < ApplicationRecord
  belongs_to :user, optional: false

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

  def self.usage_summary(since: nil)
    scope = since ? where('called_at >= ?', since) : all
    scope.group(:user_id).select(
      :user_id,
      'COUNT(*) AS total_calls',
      'MAX(called_at) AS last_called_at',
      'SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS error_count'
    )
  end
end
```

### Test structure pattern

```ruby
# Source: codebase — VisitedLinkTest + XAccountTest patterns
class XApiCallTest < ActiveSupport::TestCase
  def setup
    XApiCall.delete_all
  end

  def test_record_が行を作成する
    user = User.find(1)
    assert_difference -> { XApiCall.count }, 1 do
      XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    end
  end

  def test_record_が正しい値を保存する
    # ...
  end

  def test_usage_summaryが正しい集計を返す
    # ...
  end

  def test_usage_summaryのsinceフィルタが機能する
    # ...
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Migration[7.2]` (older migrations) | `Migration[8.1]` | Recent migrations | Use 8.1 for new migration |
| `t.timestamps` in all tables | Explicit columns only when needed | Project pattern | No `created_at/updated_at` on logging tables |

**Deprecated/outdated:**
- `Migration[7.2]`: Older migrations (e.g., `create_notes`) use this, but all migrations from 20260512 onward use `Migration[8.1]`. New migration should use `[8.1]`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END)` produces correct `error_count` for MySQL TINYINT boolean | Architecture Patterns, Code Examples | `error_count` always returns 0; would need `SUM(success = 0)` MySQL shorthand instead |
| A2 | AR grouped `select(...)` relation returns objects with virtual attribute accessors (`total_calls`, etc.) | Architecture Patterns | Phase 99 would fail with `NoMethodError`; would need `.map` with explicit attribute reads |

**If this table is empty:** N/A — two low-risk assumptions documented above.

## Open Questions

1. **Migration timestamp**
   - What we know: Filename should be `20260520XXXXXX_create_x_api_calls.rb`
   - What's unclear: Exact HHMMSS suffix — generator will assign this automatically
   - Recommendation: Use `bin/rails generate migration CreateXApiCalls` to get a valid timestamp, or use `20260520000000` as a deterministic value

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MySQL | Migration + tests | ✓ [VERIFIED: codebase] | running (schema.rb exists) | — |
| Rails 8.1 | Migration[8.1] | ✓ [VERIFIED: codebase] | 8.1.x (recent migrations confirm) | — |
| bin/rails test | Test suite | ✓ [VERIFIED: codebase] | standard | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (ActiveSupport::TestCase) |
| Config file | test/test_helper.rb |
| Quick run command | `bin/rails test test/models/x_api_call_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | `x_api_calls` table has correct columns and index | unit (schema assertion or migration smoke) | `bin/rails test test/models/x_api_call_test.rb` | ❌ Wave 0 |
| DATA-02 | `record!` inserts row with correct values; `usage_summary` returns correct aggregates | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ Wave 0 |
| DATA-03 | `rate_limit_remaining` column accepts integer value and nil | unit | `bin/rails test test/models/x_api_call_test.rb` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/models/x_api_call_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` (per CLAUDE.md)

### Wave 0 Gaps

- [ ] `test/models/x_api_call_test.rb` — covers DATA-01, DATA-02, DATA-03
- [ ] No framework install needed — Minitest already present

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (partial) | `null: false` constraints at DB level; `optional: false` FK enforcement |
| V6 Cryptography | no | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mass-assignment of sensitive columns | Tampering | `record!` uses explicit keyword args — no `params` exposure in this phase |
| FK orphan rows (user deleted, log rows remain) | Information disclosure | `belongs_to :user, optional: false` prevents orphan inserts; deletion cascade is a future concern |

Note: No user input reaches `XApiCall` in this phase — `record!` is called only from controller code with server-controlled values. SQL injection risk is zero (AR parameterized query).

## Sources

### Primary (HIGH confidence)
- Codebase: `app/models/visited_link.rb` — `record!` class method pattern
- Codebase: `db/migrate/20260518200000_create_visited_links.rb` — migration style
- Codebase: `db/migrate/20260430074727_create_notes.rb` — `add_index` composite index pattern
- Codebase: `db/schema.rb` — column ordering convention (alphabetical), boolean column type
- Codebase: `test/models/visited_link_test.rb` — test structure, `delete_all` in `setup`, Japanese method names
- Codebase: `app/services/x_client.rb` — error symbol contract confirming `error_code varchar(32)` sufficiency

### Secondary (MEDIUM confidence)
- CONTEXT.md: All locked decisions — migration columns, `record!` signature, `usage_summary` return type
- STATE.md: Cross-phase decisions — `record!` outside transaction, schema contract

### Tertiary (LOW confidence)
- [ASSUMED] AR grouped `select` returning virtual attribute accessors — standard Rails behavior, not verified via Context7 in this session

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools are existing project dependencies, no new packages
- Architecture: HIGH — patterns derived directly from codebase analogues
- Pitfalls: HIGH (MySQL boolean) / MEDIUM (AR virtual attributes) — MySQL behavior is well-understood; AR behavior is standard but untested in this session
- Test patterns: HIGH — direct codebase reference

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (stable — Rails + MySQL, no fast-moving ecosystem)
