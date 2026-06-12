# Phase 122 Plan 01 — Summary

**Completed:** 2026-06-12

## Delivered

- Branded Mastodon OAuth submit on sign-in/sign-up: icon + purple `#6364ff` button styling
- Connected Accounts Mastodon row (icon, linked/unlinked badge, disconnect button)
- `preferences.index.connected_accounts.mastodon` locale keys (ja/en)
- Integration tests: preferences 5-row render, sessions branded button assertions

## Files Changed

- `app/views/devise/shared/_oauth_buttons.html.erb`
- `app/views/preferences/_connected_accounts.html.erb`
- `app/assets/stylesheets/devise.css.scss`
- `config/locales/en.yml`, `config/locales/ja.yml`
- `test/controllers/preferences_controller_test.rb`
- `test/controllers/sessions_controller_test.rb`

## Notes

- Cucumber connected-accounts scenario still asserts 4 legacy rows; Mastodon row is additive and does not break existing steps (Phase 123 extends Cucumber).
