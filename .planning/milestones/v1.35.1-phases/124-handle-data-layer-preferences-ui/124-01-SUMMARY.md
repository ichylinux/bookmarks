# Plan 124-01 Summary

**Completed:** 2026-06-16

## Changes

- Added `MastodonHandleNormalizer` service with URL/@user@instance parsing
- Added unique index on `users.mastodon_handle`
- User model normalization + uniqueness validation
- Preferences form field, controller permit, ja/en locales
- Minitest for normalizer, model, preferences integration

## Files Modified

- `app/services/mastodon_handle_normalizer.rb`
- `db/migrate/20260616130000_add_unique_index_on_users_mastodon_handle.rb`
- `app/models/user.rb`
- `app/controllers/preferences_controller.rb`
- `app/views/preferences/index.html.erb`
- `config/locales/en.yml`, `config/locales/ja.yml`
- `test/services/mastodon_handle_normalizer_test.rb`
- `test/models/user_mastodon_handle_test.rb`
- `test/controllers/preferences_controller_test.rb`
