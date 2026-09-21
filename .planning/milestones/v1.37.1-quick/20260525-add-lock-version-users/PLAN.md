---
slug: add-lock-version-users
date: "2026-05-25"
status: in_progress
---

# Quick Task: Add lock_version to users table

## Goal

Add Rails optimistic-locking column `lock_version` to `users` so concurrent updates raise `ActiveRecord::StaleObjectError` instead of silently overwriting.

## Tasks

1. Migration: `add_lock_version_to_users` — integer, default 0, null: false
2. Run `bin/rails db:migrate` and confirm `db/schema.rb`
3. Minitest: stale `lock_version` on `update!` raises `StaleObjectError`

## Notes

- ActiveRecord enables optimistic locking automatically when `lock_version` exists — no model change required
- Existing `update_columns` call sites intentionally bypass locking (unchanged)
