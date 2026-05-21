---
slug: add-index-users-uid
date: "2026-05-21"
status: in_progress
---

# Quick Task: Add index to users on uid

## Goal

Add a non-unique index on `users.uid` to speed up `User.active.find_by(uid: uid)` OAuth lookups.

## Why non-unique

`uid` is NULL for email/password-only users. A plain index is correct — uniqueness is enforced at the application layer by the OAuth flow.

## Tasks

1. Generate migration: `add_index_uid_on_users`
2. Run `bin/rails db:migrate`
3. Verify `db/schema.rb` shows the new index
