---
plan_id: 117-01
phase: 117
status: complete
commit: a559ca1
completed: 2026-05-24
---

# Summary: Plan 117-01 — Preferences View — Connected Accounts

## What Was Done

- Created `app/views/preferences/_connected_accounts.html.erb` (97 lines) — renders Google, X, Facebook, and Email & Password rows with provider icons, linked/unlinked badges, and disconnect buttons
- Rendered partial in `preferences/index.html.erb`
- Extended `OauthIdentitiesController#destroy` to handle `provider='form'`: calls `user.disconnect_form_auth!`, safety guard checks `oauth_identities.count`, graceful no-op if already disabled
- Added 9 locale keys × 2 languages = 18 new locale entries

## Files Changed

- `app/controllers/oauth_identities_controller.rb`
- `app/views/preferences/_connected_accounts.html.erb` (new)
- `app/views/preferences/index.html.erb`
- `config/locales/ja.yml`, `config/locales/en.yml`
