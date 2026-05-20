---
phase: 96-data-layer
plan: "01"
subsystem: data-layer
tags: [migration, model, x-api, logging]
dependency_graph:
  requires: []
  provides: [XApiCall.record!, XApiCall.usage_summary, x_api_calls table]
  affects: [phases 97-99]
tech_stack:
  added: []
  patterns: [append-only logging table, grouped AR relation, keyword-arg class method]
key_files:
  created:
    - db/migrate/20260520000000_create_x_api_calls.rb
    - app/models/x_api_call.rb
  modified:
    - db/schema.rb
decisions:
  - "No timestamps on x_api_calls — append-only logging table; called_at is the only time column"
  - "belongs_to :user, optional: false — prevents orphaned log rows"
  - "SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) — MySQL-safe boolean false comparison"
  - "usage_summary returns AR relation (not Array) so Phase 99 can chain .order()/.where()"
  - "record! uses keyword args to match XClient { success:, error: } return hash structure"
metrics:
  duration: "~5 minutes"
  completed: "2026-05-20T14:56:33Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 96 Plan 01: x_api_calls Data Layer Summary

**One-liner:** x_api_calls table and XApiCall model with keyword-arg record! and grouped AR usage_summary for per-user X API call tracking.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create x_api_calls migration | 9aaa2c9 | db/migrate/20260520000000_create_x_api_calls.rb, db/schema.rb |
| 2 | Create XApiCall model | f3e0142 | app/models/x_api_call.rb |

## What Was Built

**Migration** (`db/migrate/20260520000000_create_x_api_calls.rb`): Creates `x_api_calls` table with 6 columns in alphabetical order — `called_at` (datetime NOT NULL), `endpoint` (string NOT NULL), `error_code` (varchar 32, nullable), `rate_limit_remaining` (integer, nullable), `success` (boolean NOT NULL), `user_id` (integer NOT NULL). No timestamps. Composite index `(user_id, called_at)` for per-user time-range queries.

**Model** (`app/models/x_api_call.rb`): XApiCall with:
- `belongs_to :user, optional: false` — FK integrity
- `record!(user_id:, endpoint:, success:, error_code: nil, rate_limit_remaining: nil)` — creates row via `create!` with `called_at: Time.current`
- `usage_summary(since: nil)` — returns AR relation grouped by `user_id` with `total_calls`, `last_called_at`, `error_count` aggregates; `since:` applies `WHERE called_at >= ?` before grouping

## Verification Results

- `bin/rails db:migrate` — exits 0
- `grep -A 20 'create_table "x_api_calls"' db/schema.rb` — all 6 columns + composite index present, no timestamps
- `bin/rails runner "puts XApiCall.usage_summary.class"` — prints `XApiCall::ActiveRecord_Relation`
- `yarn run lint` — exits 0

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced. SQL fragment in `usage_summary` uses literals only (`success = 0`); `since:` value is AR-parameterized.

## Self-Check: PASSED

- db/migrate/20260520000000_create_x_api_calls.rb: FOUND
- app/models/x_api_call.rb: FOUND
- db/schema.rb contains x_api_calls table: FOUND
- commit 9aaa2c9: FOUND
- commit f3e0142: FOUND
