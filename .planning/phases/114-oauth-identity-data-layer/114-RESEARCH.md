# Phase 114: OAuth Identity Data Layer — Research

## Key Findings

### Existing OAuth flow
- `User.from_omniauth` in `app/models/user.rb` has three branches:
  - `:twitter2` — finds by `uid`, then by email (when uid blank); saves `provider: 'twitter2'`, `uid:` on user row
  - `:facebook` — finds by email only; uses `User.create` (not `create!`) — returns invalid user if creation fails
  - `else` (`:google_oauth2`) — same pattern as facebook; uses `User.create`
- Upsert point: after user is found/created and `user.persisted?`, call `OauthIdentity.upsert_for!`
- twitter2 `User.create!` always persists if no exception; facebook/google may return unpersisted user on failure

### Backfill scope
- `users` table has `provider` (string) and `uid` (string, unique index)
- Only twitter2 users historically saved `provider`/`uid` to users table
- Backfill: `WHERE provider IS NOT NULL AND uid IS NOT NULL`

### Test patterns
- `OmniAuth::AuthHash.new(...)` used in existing user_test.rb
- twitter_user fixture: `provider: twitter2`, `uid: fixture_twitter_uid`
- New oauth_identity tests: use fixtures or create records inline
- `insert_all` with `unique_by:` is Rails 6+ feature — available in Rails 7.2

### Migration pattern
- `add_column :table, :col, :type, null: false, default: false` (additive)
- `create_table` with `t.references`, `t.string`, `t.timestamps`
- Foreign key via `add_foreign_key` or `t.references ..., foreign_key: true`

## Validation Architecture
Not applicable — no external HTTP calls in this phase.
