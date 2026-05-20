# Phase 96: Data Layer - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous)

<domain>
## Phase Boundary

Create the `x_api_calls` table and `XApiCall` model so that X API call events can be recorded and aggregated for the admin report.

- Migration creates `x_api_calls` with: `user_id`, `endpoint`, `success`, `error_code`, `called_at`, `rate_limit_remaining` columns and composite `(user_id, called_at)` index
- `XApiCall.record!` creates a row with correct values
- `XApiCall.usage_summary` returns per-user aggregates (total calls, last called_at, error count) with optional `since:` filter
- Minitest model unit tests cover all three behaviors

No user-facing UI in this phase — pure data layer.

</domain>

<decisions>
## Implementation Decisions

### Migration Design
- **No Rails timestamps** — only `called_at datetime NOT NULL` as the explicit time column; `x_api_calls` is an append-only logging table with immutable rows, so `created_at/updated_at` adds no value
- **Null constraints:** `endpoint string NOT NULL`, `success boolean NOT NULL`, `error_code string NULL`, `rate_limit_remaining integer NULL`
- **`error_code` column:** `varchar(32)` (maps to XClient 7-symbol error contract: `:timeout`, `:network`, `:api_error`, etc.)
- **Index:** composite `(user_id, called_at)` index supports the per-user time-range queries in Phase 99

### Model API Contract
- **`record!` signature:** keyword args — `XApiCall.record!(user_id:, endpoint:, success:, error_code: nil, rate_limit_remaining: nil)` — matches the XClient `{ success:, error: }` return hash structure
- **`usage_summary` return type:** AR grouped select returning a relation with `user_id`, `total_calls`, `last_called_at`, `error_count` — keeps it filterable/sortable for Phase 99 controller
- **No `Crud::ByUser` concern** — `XApiCall` is a logging table, not a user CRUD resource; admin-visible via class methods only
- **`belongs_to :user, optional: false`** — enforce FK integrity; logging rows should never be orphaned

### Prior Decisions (from STATE.md research)
- Schema: `success boolean + error_code varchar(32)` confirmed (maps to XClient `{ success:, error: }` contract)
- `record!` must be called OUTSIDE any transaction wrapper to avoid data loss on rollback

</decisions>

<code_context>
## Existing Code Insights

### XClient return contract (app/services/x_client.rb)
- `fetch_following` / `fetch_recent_tweets` return `{ success: true, items: [...] }` or `{ success: false, error: :symbol }`
- Error symbols: `:timeout`, `:network`, `:parse_error`, `:api_error`, `:not_found`, `:unauthorized`, `:protected_account`
- `error_code varchar(32)` easily fits all of these (longest is `:protected_account` = 17 chars)

### Comparable model: VisitedLink (app/models/visited_link.rb)
- Simple logging model with `user_id`, `url`, `created_at/updated_at`
- Uses `Crud::ByUser` — but XApiCall should NOT (different access pattern)
- No validations beyond FK

### Comparable migration: 20260518200000_create_visited_links.rb
- Standard Rails migration style with `t.string`, `t.integer`, `t.datetime`

### Schema pattern for timestamps
- Most tables use explicit columns rather than `t.timestamps` (columns are listed alphabetically in schema.rb)

### users.admin column
- `boolean default: false, null: false` — confirms admin boolean exists

### Test patterns for models
- `test/models/` uses `ActiveSupport::TestCase`
- Method names in Japanese: `def test_レコードの作成`, `def test_集計`
- Service/model tests use `assert_difference`, `assert_equal` style assertions

</code_context>

<specifics>
## Specific Ideas

- `XApiCall.usage_summary(since: nil)` — default `since: nil` means all-time; Phase 99 will pass a date range
- `usage_summary` uses `group(:user_id).select(...)` with SQL aggregates: `COUNT(*) AS total_calls`, `MAX(called_at) AS last_called_at`, `SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS error_count`
- Migration filename: `20260520XXXXXX_create_x_api_calls.rb`
- Model file: `app/models/x_api_call.rb`
- Test files: `test/models/x_api_call_test.rb`

</specifics>

<deferred>
## Deferred Ideas

- Per-endpoint breakdown in `usage_summary` — Phase 99 REPORT-01 mentions "endpoint breakdown" but Phase 96 success criteria only needs totals; endpoint breakdown can be added in Phase 99 if needed
- Pruning/retention Rake task — future requirement (ACCT-FUT-01 pattern)
- Rate-limit window tracking — future requirement

</deferred>
