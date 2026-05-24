---
plan_id: 115-01
phase: 115
status: complete
commit: 17fbbbd
completed: 2026-05-24
---

# Summary: Plan 115-01 — Form Auth Data Layer

## What Was Done

- Added `password_auth_enabled boolean NOT NULL DEFAULT false` to `users` table via migration `20260524000003`
- Implemented `before_save :after_password_reset` callback on `User` — fires when `encrypted_password_changed? && reset_password_token_was.present?`, sets `password_auth_enabled = true`
- Implemented `User#disconnect_form_auth!` — uses `update_columns` to atomically set `password_auth_enabled: false` and randomize `encrypted_password` via `Devise::Encryptor.digest`
- 5 Minitest cases: reset flow sets flag, OAuth user creation does not, other-attr save does not, disconnect clears flag, disconnect prevents `valid_password?`

## Files Changed

- `app/models/user.rb`
- `db/migrate/20260524000003_add_password_auth_enabled_to_users.rb`
- `db/schema.rb`
- `test/models/user_password_auth_test.rb`
