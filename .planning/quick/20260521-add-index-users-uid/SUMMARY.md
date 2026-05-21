---
slug: add-index-users-uid
date: "2026-05-21"
status: complete
commit: 2977309
---

# Summary: Add index on users.uid

Added `index_users_on_uid` (non-unique) via migration `20260521065458`.

`uid` is NULL for email/password users, so a plain index was chosen over unique. Covers the hot `User.active.find_by(uid: uid)` OAuth lookup path.

All suites green: lint ✓ · minitest 517/517 ✓ · dad:test 30/30 ✓
