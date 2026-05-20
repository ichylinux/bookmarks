# Phase 96: Data Layer - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Create the `x_api_calls` table (migration) and `XApiCall` model (record! + usage_summary) so that X API call events can be persisted and aggregated.

**Must satisfy:** DATA-01, DATA-02, DATA-03

No user-facing behavior — pure data layer.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

**Key decisions from STATE.md research context:**
- Schema: `success boolean + error_code varchar(32)` — maps directly to XClient `{ success:, error: }` return contract
- `rate_limit_remaining` is nullable integer (DATA-03)
- `called_at` nullable: no — all recorded calls have a timestamp
- `(user_id, called_at)` composite index for per-user time-range queries
- `XApiCall.record!` is a class method (VisitedLink pattern)
- `XApiCall.usage_summary(since:)` returns per-user aggregates: total calls, last called_at, error count

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VisitedLink.record!` pattern: class method, insert with `Time.current`, no upsert needed (calls are not unique)
- Migration pattern: `CreateVisitedLinks` — `null: false` on required columns, explicit index with `add_index`
- `XClient` return contract: `{ success: Boolean, error: Symbol }` → maps to `success` boolean + `error_code` string

### Established Patterns
- Models inherit from `ApplicationRecord`
- Migrations inherit from `ActiveRecord::Migration[8.1]`
- Model tests: `class XApiCallTest < ActiveSupport::TestCase`, `delete_all` in `setup`, English/Japanese method names
- Test assertions: `assert_difference`, `assert_equal`, `assert_nil`

### Integration Points
- New model file: `app/models/x_api_call.rb`
- New migration: `db/migrate/YYYYMMDDHHMMSS_create_x_api_calls.rb`
- New test: `test/models/x_api_call_test.rb`
- `belongs_to :user` (not included in concerns — tracking record, not user-owned CRUD)

</code_context>

<specifics>
## Specific Ideas

- `endpoint` column: string, not null — captures the API endpoint called (e.g., "fetch_following", "fetch_recent_tweets")
- `usage_summary` should group by `user_id` and join with `users` table to get email; accept `since:` keyword for date-range filtering
- No `timestamps` helper — `called_at` is the primary timestamp column; skip `created_at`/`updated_at` (reduces table width, matches tracking-record pattern)

</specifics>

<deferred>
## Deferred Ideas

None — discuss phase skipped (infrastructure). Phase 97 handles instrumentation wiring.

</deferred>
