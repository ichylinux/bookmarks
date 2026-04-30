---
phase: 10-data-layer
plan: 01
subsystem: data-layer
tags: [rails, activerecord, migration, mysql, schema, notes]
requirements: [NOTE-03]
dependency_graph:
  requires: []
  provides:
    - "notes table in db/schema.rb"
    - "composite index (user_id, created_at)"
  affects:
    - "10-02 (Note model — depends on table existing)"
    - "10-03 (User has_many :notes — depends on table existing)"
tech_stack:
  added: []
  patterns:
    - "ActiveRecord::Migration[7.2] (matches all 2024+ migrations in repo)"
    - "Composite index on (user_id, created_at) for current_user.notes.recent"
    - "Soft-delete column boolean deleted default false (matches Todo/Bookmark)"
key_files:
  created:
    - "db/migrate/20260430074727_create_notes.rb"
  modified:
    - "db/schema.rb"
decisions:
  - "Used [7.2] migration header (not [8.1]) per repo convention — all 2024+ migrations use [7.2]"
  - "No DB-level foreign key on user_id — matches existing schema convention; integrity enforced at Rails layer in Plan 02/03"
  - "body column type text (MySQL TEXT, ~64KB) — length cap deferred to model-layer validation in Plan 02"
metrics:
  duration: "~10 minutes"
  completed: "2026-04-30T07:50:19Z"
  tasks_completed: 2
  files_changed: 2
---

# Phase 10 Plan 01: Notes Table Migration Summary

Created `notes` table via ActiveRecord migration with composite `(user_id, created_at)` index, applied cleanly via `bin/rails db:migrate`, and verified `db/schema.rb` reflects the new table with all required columns and the composite index.

## What Was Built

A single ActiveRecord migration (`CreateNotes`) that establishes the persistence foundation for the v1.3 Quick Note Gadget. The table mirrors the column shape of `todos` (the closest analog) with two deliberate modernizations:

1. `body` is `text` (not `string`) — supports longer note content up to MySQL's TEXT limit (~64KB).
2. Composite index `(user_id, created_at)` — supports `current_user.notes.recent` queries that Phase 13 will use for reverse-chronological listing. Older tables in this codebase lack such indexes; this is the deliberate modern default noted in CONTEXT.md and PATTERNS.md.

The migration uses `ActiveRecord::Migration[7.2]` to match the repo convention (every migration since 2024 uses `[7.2]`).

## Tasks Completed

| Task | Name                                | Commit  | Files                                              |
| ---- | ----------------------------------- | ------- | -------------------------------------------------- |
| 1    | Create CreateNotes migration file   | 5d818dc | db/migrate/20260430074727_create_notes.rb          |
| 2    | Run migration and verify schema     | 8990ec9 | db/schema.rb                                       |

## Verification Results

- `bin/rails db:migrate` exited 0 — migration applied successfully (CreateNotes: migrated (0.0523s)).
- `db/schema.rb` contains `create_table "notes"` block with:
  - `t.text "body", null: false`
  - `t.boolean "deleted", default: false, null: false`
  - `t.integer "user_id", null: false`
  - `t.datetime "created_at", null: false` / `t.datetime "updated_at", null: false`
  - `t.index ["user_id", "created_at"], name: "index_notes_on_user_id_and_created_at"`
- Migration class header: `class CreateNotes < ActiveRecord::Migration[7.2]` ✓
- All `verify` automated checks for both tasks passed.

## Decisions Made

1. **Migration header `[7.2]`**: Verified against `db/migrate/20260429025517_set_modern_theme_for_non_simple_users.rb` and other 2024+ migrations. Plan and PATTERNS.md mandated this — followed without deviation.
2. **No `foreign_key: true` on `user_id`**: Per CONTEXT.md decision, matches every other table in the schema. Referential integrity is deferred to the Rails layer (`belongs_to :user` in Plan 02, `has_many :notes, dependent: :destroy` in Plan 03).
3. **Composite index in this phase (not later)**: Added in the create_table migration rather than as a follow-up. Avoids a second migration round-trip and ensures Phase 13's query will not regress to a table-scan during early development.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree environment setup for db:migrate**

- **Found during:** Task 2
- **Issue:** The parallel-executor worktree had no installed gems (Bundler::GemNotFound for ~40 gems including bootsnap, devise, puma, etc.) and the dockerized MySQL on port 13308 had no `bookmarks` user or `bookmarks_dev` database. Without addressing both, `bin/rails db:migrate` could not execute.
- **Fix:**
  1. Ran `bundle install` to install gems into the worktree's gem path.
  2. Created MySQL user and databases via `docker exec mysql84 mysql -uroot ...`:
     - `CREATE USER 'bookmarks'@'%' IDENTIFIED BY 'bookmarks'`
     - `CREATE DATABASE bookmarks_dev` and `bookmarks_test` (utf8mb4)
     - Granted all privileges on those DBs to the user
  3. Ran the migration with `MYSQL_PORT=13308 bin/rails db:migrate` (Docker maps 13308 → container 3306; the `MYSQL_PORT` env override is supported by `config/database.yml`).
- **Files modified:** None in the repo. Side effects: gem installation under bundler's local path, MySQL user/database creation in the running `mysql84` container.
- **Commit:** N/A — environment setup, not a code change.

This was Rule 3 (auto-fix blocking issue) — without these the plan could not be completed. No structural decisions were made; the changes follow the existing `config/database.yml` configuration and standard Rails dev-database conventions.

### Rule 2 / Rule 1 / Rule 4

None.

## Authentication Gates

None — the only "auth" issue was a development-time MySQL user creation, handled inline as a Rule 3 blocker (no human input required, no secrets exchanged).

## Threat Surface Scan

No new threat surface introduced beyond what the plan's `<threat_model>` already documents (T-10-01, T-10-02, T-10-03 — all mitigated or accepted as planned, with mitigations deferred to Plans 02/03 per the disposition table).

## Self-Check: PASSED

Verified files exist:

- FOUND: db/migrate/20260430074727_create_notes.rb
- FOUND: db/schema.rb (with `create_table "notes"` block)

Verified commits exist:

- FOUND: 5d818dc (feat(10-01): add CreateNotes migration)
- FOUND: 8990ec9 (feat(10-01): apply CreateNotes migration to schema)

Plan-level success criteria:

- [x] Migration file with `[7.2]` header exists
- [x] Migration declares all required columns with correct nullability/defaults
- [x] Composite index `(user_id, created_at)` declared
- [x] `bin/rails db:migrate` ran cleanly
- [x] `db/schema.rb` reflects the new table
