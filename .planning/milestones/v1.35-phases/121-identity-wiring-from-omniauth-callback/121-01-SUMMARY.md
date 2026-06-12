---
phase: 121-identity-wiring-from-omniauth-callback
plan: 01
status: complete
completed: 2026-06-12
requirements: [IDNT-01, IDNT-02, IDNT-03, CTRL-01]
---

# Phase 121 Plan 01 Summary

## Delivered

- `OmniAuth::Strategies::Mastodon` adds `info[:instance]` from `session[:mastodon_instance]` for composite uid assembly
- `User.from_omniauth` `:mastodon` branch: find by `oauth_identities` composite uid, create with dummy email, `upsert_for!`
- `Users::OmniauthCallbacksController#mastodon` delegates to `handle_callback('Mastodon')`
- Minitest: composite uid create/re-auth, strategy info.instance, callback integration (with routes preload fix)

## Files Changed

- `lib/omniauth/strategies/mastodon.rb`
- `app/models/user.rb`
- `app/controllers/users/omniauth_callbacks_controller.rb`
- `test/models/oauth_identity_test.rb`
- `test/controllers/users/omniauth_callbacks_controller_test.rb`
- `test/lib/omniauth/strategies/mastodon_test.rb`

## Notes

- `:mastodon` was already in `omniauth_providers` (Phase 119) — verified, not duplicated
- Callback integration test loads routes when `OmniAuth.config.path_prefix` is nil so Mastodon middleware matches `/users/auth/mastodon/callback`
