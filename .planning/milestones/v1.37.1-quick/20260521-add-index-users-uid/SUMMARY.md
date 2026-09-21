---
slug: add-index-users-uid
date: "2026-05-21"
status: complete
commit: 8889a6c
---

# Summary: Add unique index on users.uid

Two migrations: first added a plain index, then replaced it with a unique index after user confirmed uid must be unique.

`destroy_account!` now nullifies `uid` on soft-delete so deleted users release the OAuth uid slot, allowing re-registration with the same Twitter account. Tests updated to match: `assert_nil u.uid` after delete; operational-restore test explicitly restores uid in the un-delete step.

Files changed: `db/migrate/20260521065458_add_index_uid_on_users.rb`, `db/migrate/20260521070921_change_index_uid_on_users_to_unique.rb`, `app/models/user.rb`, `test/models/user_test.rb`

All suites green: lint ✓ · minitest 517/517 ✓ · dad:test 30/30 ✓
