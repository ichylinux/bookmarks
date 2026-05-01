---
phase: 18-auth-2fa-and-translation-verification
status: clean
reviewed: 2026-05-02
review_type: standard
reviewer: gsd-code-review
---

# Phase 18 Code Review

## Result

Clean after two duplicate-alert warnings were fixed.

## Scope Reviewed

- `app/controllers/users/sessions_controller.rb`
- `app/views/layouts/application.html.erb`
- `app/views/users/two_factor_authentication/show.html.erb`
- `app/views/users/two_factor_setup/setup.html.erb`
- `app/assets/stylesheets/common.css.scss`
- `config/locales/ja.yml`
- `config/locales/en.yml`
- `test/controllers/sessions_controller_test.rb`
- `test/controllers/two_factor_authentication_controller_test.rb`
- `test/controllers/two_factor_setup_controller_test.rb`
- `features/support/reset_state.rb`
- `features/step_definitions/bookmarks.rb`

## Findings

### Fixed During Review

**Warning: duplicate 2FA alert rendering**

- **File:** `app/views/users/two_factor_authentication/show.html.erb`
- **Issue:** Phase 18 added global `flash[:alert]` rendering in the application layout, while the 2FA OTP page still rendered `flash[:alert]` inline. Invalid OTP responses could show the same alert twice.
- **Fix:** Removed the inline 2FA alert block and added a controller test assertion that invalid OTP renders exactly one `.flash-alert`.
- **Commit:** `8bdcd57`

**Warning: duplicate 2FA setup alert rendering**

- **File:** `app/views/users/two_factor_setup/setup.html.erb`
- **Issue:** The 2FA setup page also rendered `flash[:alert]` inline while the layout now owns alert display.
- **Fix:** Removed the inline setup alert block and added a controller test assertion that invalid setup OTP renders exactly one `.flash-alert`.
- **Commit:** `76c4345`

### Verification Stability Fix

- **File:** `features/step_definitions/bookmarks.rb`
- **Issue:** The bookmark Cucumber scenario depended on `http://example.com` returning a title during the full gate.
- **Fix:** Use the local Capybara server URL for title auto-fill coverage, preserving the AJAX path without external network dependency.
- **Commit:** `d081bbf`

## Residual Risks

- `features/support/reset_state.rb` intentionally resets browser session, cached test helper state, OTP state, and mutable user preferences. It does not truncate every domain table; future Cucumber scenarios that depend on additional persisted domain data may need broader cleanup.

## Verification After Review Fix

- `bin/rails test test/controllers/two_factor_setup_controller_test.rb test/controllers/two_factor_authentication_controller_test.rb` — 16 runs, 67 assertions, 0 failures, 0 errors.
- `DRIVER=chrome HEADLESS=true bundle exec cucumber features/01.ブックマーク.feature` — 1 scenario, 3 steps, 0 failures.
- `yarn run lint` — passed.
- `bin/rails test` — 187 runs, 1069 assertions, 0 failures, 0 errors.
- `bundle exec rake dad:test` — 9 scenarios, 28 steps, 0 failures.
