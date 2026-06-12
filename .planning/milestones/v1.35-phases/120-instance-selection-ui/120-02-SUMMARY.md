---
phase: 120-instance-selection-ui
plan: 02
status: complete
requirements:
  - INST-01
  - INST-02
---

# Plan 120-02 Summary

## Delivered

- Mastodon instance form in `_oauth_buttons.html.erb` (sign-in + sign-up via shared partial)
- SCSS for `.auth-oauth-mastodon` and `.auth-oauth-btn--mastodon`
- Sessions controller tests for ja/en rendering on sign-in and sign-up

## Key files

- `app/views/devise/shared/_oauth_buttons.html.erb`
- `app/assets/stylesheets/devise.css.scss`
- `test/controllers/sessions_controller_test.rb`

## Self-Check: PASSED
