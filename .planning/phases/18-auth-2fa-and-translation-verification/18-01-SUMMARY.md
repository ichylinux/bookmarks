---
phase: 18-auth-2fa-and-translation-verification
plan: 01
subsystem: auth
tags: [rails, devise, i18n, flash]
requires:
  - phase: 17-feature-surface-translation
    provides: locale-aware feature surfaces and key parity coverage
provides:
  - localized Devise failed sign-in flash messages for ja and en
  - alert flash rendering in the application layout
  - Bootstrap-style danger styling for alert flashes
affects: [auth, i18n, verification]
tech-stack:
  added: []
  patterns:
    - Devise flash messages use explicit interpolation options from controller code
key-files:
  created: []
  modified:
    - config/locales/ja.yml
    - config/locales/en.yml
    - app/views/layouts/application.html.erb
    - app/assets/stylesheets/common.css.scss
    - app/controllers/users/sessions_controller.rb
key-decisions:
  - "Kept the planned %{authentication_keys} interpolation and passed the value explicitly from Users::SessionsController."
patterns-established:
  - "Controller-set Devise flashes must pass every interpolation variable required by app-owned locale keys."
requirements-completed: [AUTHI18N-01, AUTHI18N-03, VERI18N-04]
duration: 15min
completed: 2026-05-02
---

# Phase 18: Auth, 2FA & Translation Verification Summary

**Localized failed sign-in alerts now render through the shared Rails layout in both Japanese and English**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-02T00:12:00+09:00
- **Completed:** 2026-05-02T00:27:00+09:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `devise.sessions.invalid` to both locale files with matching key structure.
- Rendered `flash[:alert]` in `app/views/layouts/application.html.erb` alongside existing notices.
- Added `.flash-alert` warning styles matching the existing flash notice pattern.
- Ensured the custom Devise session controller supplies `authentication_keys` for the new translation.

## Task Commits

1. **Task 1/2: Localized failed sign-in alerts** - `e382c66` (fix)

## Files Created/Modified

- `config/locales/ja.yml` - Adds Japanese `devise.sessions.invalid`.
- `config/locales/en.yml` - Adds English `devise.sessions.invalid`.
- `app/views/layouts/application.html.erb` - Displays alert flashes before page content.
- `app/assets/stylesheets/common.css.scss` - Styles `.flash-alert`.
- `app/controllers/users/sessions_controller.rb` - Supplies `authentication_keys` interpolation data to Devise flash lookup.

## Decisions Made

- Used the plan's `%{authentication_keys}` translation contract instead of switching to `%{resource_name}`, because Plan 18-02 test assertions depend on the authentication key label.

## Deviations from Plan

### Auto-fixed Issues

**1. Missing interpolation value in controller flash call**
- **Found during:** Task 1 verification (`two_factor_authentication_controller_test`)
- **Issue:** `set_flash_message!(:alert, :invalid)` only passed `resource_name`, causing `I18n::MissingInterpolationArgument` for `%{authentication_keys}`.
- **Fix:** Updated `Users::SessionsController#create` to pass `authentication_keys: User.human_attribute_name(:email)`.
- **Files modified:** `app/controllers/users/sessions_controller.rb`
- **Verification:** `bin/rails test test/i18n/locales_parity_test.rb && bin/rails test test/controllers/two_factor_authentication_controller_test.rb`
- **Committed in:** `e382c66`

---

**Total deviations:** 1 auto-fixed blocking issue
**Impact on plan:** Necessary for the planned locale key to work at runtime; no user-facing scope was added.

## Issues Encountered

- Existing 2FA invalid password test exposed the missing interpolation option before Plan 18-02 tests were added. Fixed in the same auth surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-02 can now assert localized sign-in failure flashes because the locale key, layout rendering, styling, and interpolation value are all wired.

---
*Phase: 18-auth-2fa-and-translation-verification*
*Completed: 2026-05-02*
