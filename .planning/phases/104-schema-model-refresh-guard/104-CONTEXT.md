---
phase: 104
name: Schema, Model & Refresh Guard
status: context-captured
date: "2026-05-22"
---

# Phase 104: Schema, Model & Refresh Guard — Context

## Domain

Add `manually_added` boolean column to `x_accounts`, implement `XAccount.upsert_manual!` class method, and guard `refresh_cache_from_items!` so manually-added rows are never soft-deleted by follow-sync.

## Decisions

### Migration
- Add `manually_added boolean NOT NULL DEFAULT false` to `x_accounts`
- No data loss — existing rows default to `false`
- Add index is not required (low-cardinality boolean — query is user-scoped)

### `upsert_manual!` class method
- Signature: `XAccount.upsert_manual!(user:, x_user_id:, username:, display_name:, avatar_url: nil)`
- Uses `first_or_initialize` on `(user_id, x_user_id)` — the existing unique index covers this
- Always sets `manually_added: true, deleted: false` unconditionally regardless of `new_record?` state
- Does NOT set `selected:` — selection is a separate concern
- Returns the saved record

### `refresh_cache_from_items!` guard
- Soft-delete loop at bottom of method gains: `next if acc.manually_added?`
- The `assign_attributes` call inside the loop must NOT include `manually_added:` — this preserves the flag on overlap rows (accounts that are both follow-synced and manually added)
- No other changes to refresh logic

### Testing
- Minitest model test: `manually_added` account is NOT soft-deleted when missing from payload
- Minitest model test: overlap row (`manually_added: true`) survives refresh and `manually_added` stays `true`
- Minitest model test: `upsert_manual!` on a new record creates with `manually_added: true, deleted: false`
- Minitest model test: `upsert_manual!` on existing soft-deleted row restores it (sets `deleted: false, manually_added: true`)

## Canonical Refs

- `app/models/x_account.rb` — XAccount model with `refresh_cache_from_items!`
- `db/schema.rb` — current x_accounts table (no `manually_added` column yet)
- `db/migrate/20260514103200_create_x_accounts.rb` — original migration for reference style
- `test/models/x_account_test.rb` — existing model tests (follow existing patterns)
- `.planning/STATE.md` — accumulated decisions for v1.31

## Code Context

- `refresh_cache_from_items!` is a class method using `user.transaction` + `first_or_initialize` + `assign_attributes`
- The soft-delete loop iterates `XAccount.where(user_id: user.id).find_each` and calls `acc.update!(deleted: true)` on rows not in `seen`
- The unique index on `(user_id, x_user_id)` means `first_or_initialize` is safe for upsert
- Test pattern: create records in setup, call class method, reload and assert
