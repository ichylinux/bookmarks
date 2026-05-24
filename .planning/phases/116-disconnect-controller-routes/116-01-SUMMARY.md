---
plan_id: 116-01
phase: 116
status: complete
commit: dc82abe
completed: 2026-05-24
---

# Summary: Plan 116-01 — Disconnect Controller & Routes

## What Was Done

- Added `has_many :oauth_identities, dependent: :destroy` to `User`
- Created `OauthIdentitiesController#destroy` with three paths: success (delete + redirect), last_auth_method guard (redirect with alert), not_connected no-op (redirect with notice)
- Route: `resources :oauth_identities, only: [:destroy], param: :provider`
- 6 locale keys per language (3 flash messages × ja/en)
- 5 controller integration tests: success path, safety guard block (no password_auth), safety guard allow (with password_auth), unlinked provider no-op, unauthenticated redirect

## Files Changed

- `app/controllers/oauth_identities_controller.rb` (new)
- `app/models/user.rb`
- `config/routes.rb`
- `config/locales/ja.yml`, `config/locales/en.yml`
- `test/controllers/oauth_identities_controller_test.rb` (new)
