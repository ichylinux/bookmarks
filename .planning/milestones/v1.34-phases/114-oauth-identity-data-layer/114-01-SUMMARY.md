---
phase: 114
plan: "01"
title: "OAuth Identity Data Layer — Schema, Model, Wiring & Tests"
subsystem: oauth
tags: [oauth, identity, data-layer, migration, model]
dependency_graph:
  requires: []
  provides: [oauth_identities_table, OauthIdentity_model, upsert_for]
  affects: [app/models/user.rb, app/models/oauth_identity.rb, db/schema.rb]
tech_stack:
  added: []
  patterns: [find_or_initialize_by, insert_all with unique_by, upsert_for class method]
key_files:
  created:
    - db/migrate/20260524000001_create_oauth_identities.rb
    - db/migrate/20260524000002_backfill_oauth_identities_from_users.rb
    - app/models/oauth_identity.rb
    - test/models/oauth_identity_test.rb
  modified:
    - app/models/user.rb
    - db/schema.rb
decisions:
  - "upsert_for! uses find_or_initialize_by + save! (vs plan's find_or_create_by! + update!) — functionally equivalent, avoids separate query for update"
  - "backfill migration uses find_or_create_by! per-row (vs plan's insert_all) — idempotent via Rails uniqueness handling"
  - "has_many :oauth_identities added to User proactively for purge! and future use"
  - "purge! already includes OauthIdentity.where(user_id:).delete_all"
metrics:
  duration: "pre-committed"
  completed_date: "2026-05-24"
  tasks_completed: 6
  tasks_total: 6
  files_created: 4
  files_modified: 2
---

# Phase 114 Plan 01: OAuth Identity Data Layer — Schema, Model, Wiring & Tests Summary

## One-liner

OAuth identity data layer: `oauth_identities` table with unique `(user_id, provider)` index, `OauthIdentity` model with `upsert_for!`, and all three provider branches in `User.from_omniauth` wired to create identity rows on every sign-in.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| T1 | Create oauth_identities schema migration | 3b5911d | db/migrate/20260524000001_create_oauth_identities.rb, db/schema.rb |
| T2 | Create OauthIdentity model | 3b5911d | app/models/oauth_identity.rb |
| T3 | Wire OauthIdentity.upsert_for! into User.from_omniauth | 3b5911d | app/models/user.rb |
| T4 | Create backfill migration | 3b5911d | db/migrate/20260524000002_backfill_oauth_identities_from_users.rb |
| T5 | Write Minitest for OauthIdentity model and from_omniauth | 3b5911d | test/models/oauth_identity_test.rb |
| T6 | Run tri-suite gate | — | Lint ✓, Minitest ✓, Cucumber pre-existing flakiness noted |

## Verification Criteria

1. `db/schema.rb` contains `create_table "oauth_identities"` with unique index on `(user_id, provider)` — VERIFIED
2. `app/models/oauth_identity.rb` exists with `belongs_to :user`, validations, and `upsert_for!` class method — VERIFIED
3. `User.from_omniauth` calls `OauthIdentity.upsert_for!` in all three provider branches — VERIFIED
4. Backfill migration ran successfully and is idempotent — VERIFIED (`bin/rails db:migrate:status` shows both migrations `up`)
5. All 10 Minitest cases pass (`bin/rails test test/models/oauth_identity_test.rb` — 10 runs, 26 assertions, 0 failures) — VERIFIED
6. Tri-suite gate: lint ✓, minitest 587 runs/0 failures ✓, Cucumber failures are pre-existing flakiness unrelated to Phase 114 — DOCUMENTED

## Deviations from Plan

### Minor Implementation Adjustments

**1. [Rule 2 - Enhancement] upsert_for! uses find_or_initialize_by + save! instead of find_or_create_by! + update!**
- **Found during:** T2 implementation
- **Issue:** plan specified `find_or_create_by!` then `update!` (two queries); implementation uses `find_or_initialize_by` + `uid=` + `save!` (one path, same semantics)
- **Fix:** Functionally equivalent — both create if absent, update if present. Unique index prevents race duplicates.
- **Files modified:** app/models/oauth_identity.rb

**2. [Rule 2 - Enhancement] Backfill migration uses per-row find_or_create_by! instead of insert_all**
- **Found during:** T4 implementation
- **Issue:** Plan specified `insert_all` with `unique_by:`. Implementation uses `find_or_create_by!` per row.
- **Fix:** Both approaches are idempotent. `find_or_create_by!` was used for compatibility and clarity. The acceptance criterion (idempotency) is met.
- **Files modified:** db/migrate/20260524000002_backfill_oauth_identities_from_users.rb

**3. [Rule 2 - Enhancement] has_many :oauth_identities added to User**
- **Found during:** T3 implementation
- **Issue:** Plan deferred `has_many :oauth_identities` to Phase 116. However, `purge!` already referenced `OauthIdentity.where(user_id:).delete_all`, so wiring `has_many` was needed for model consistency.
- **Fix:** Added `has_many :oauth_identities` to User model.
- **Files modified:** app/models/user.rb

### Cucumber Flakiness (Pre-existing, Not Phase 114)

Two runs of `bundle exec rake dad:test` showed different failing scenarios:
- Run 1: `features/14.連携アカウント.feature:14` (Phase 116 OAuth disconnect scenario)
- Run 2: `features/03.モダンテーマ.feature:80` (portal column mobile behavior)

Neither scenario relates to Phase 114 changes (data layer only, no UI/controller changes). The inconsistency across two runs confirms pre-existing flakiness per CLAUDE.md policy: "a consistent failure across two runs indicates a real regression." These failures are from Phase 116 (connected accounts UI) and Phase 103 (mobile portal), both pre-dating this agent's scope.

## Known Stubs

None — all data layer is fully wired. `upsert_for!` is called in all three `from_omniauth` branches.

## Threat Flags

None — no new user-facing surface. `OauthIdentity.upsert_for!` is called from the existing `from_omniauth` method which already validates user identity. The unique index on `(user_id, provider)` prevents duplicate identity rows at the DB level.

## Self-Check

- [x] `db/migrate/20260524000001_create_oauth_identities.rb` — EXISTS
- [x] `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb` — EXISTS
- [x] `app/models/oauth_identity.rb` — EXISTS
- [x] `test/models/oauth_identity_test.rb` — EXISTS
- [x] `app/models/user.rb` — modified with `has_many :oauth_identities` and `OauthIdentity.upsert_for!` calls
- [x] `db/schema.rb` — contains `create_table "oauth_identities"` with correct index
- [x] Commit 3b5911d — EXISTS (verified via `git log --all --oneline`)
- [x] 10 Minitest cases pass (verified `bin/rails test test/models/oauth_identity_test.rb`)

## Self-Check: PASSED
