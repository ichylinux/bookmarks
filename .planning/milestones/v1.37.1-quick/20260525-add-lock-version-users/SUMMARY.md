---
status: complete
---

# Quick Task 20260525-add-lock-version-users: Add lock_version to users table

## Done

- Migration `20260525000001_add_lock_version_to_users` adds `lock_version` (integer, default 0, null: false)
- `db/schema.rb` updated
- Minitest: `test_stale_lock_version_raises_on_update` confirms `ActiveRecord::StaleObjectError` on stale writes

## Notes

- ActiveRecord optimistic locking is automatic — no `User` model change
- Existing `update_columns` call sites (`destroy_account!`, `disconnect_form_auth!`) intentionally bypass locking

## Verification

- `yarn run lint` ✓
- `bin/rails test test/models/user_test.rb` — 22 runs, 0 failures
