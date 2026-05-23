# Requirements: Bookmarks v1.33

**Defined:** 2026-05-24
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.33 Requirements

### Gem & Config

- [x] **FB-01**: `omniauth-facebook` gem added and `bundle install` succeeds
- [x] **FB-02**: Devise initializer configures Facebook provider with `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET` ENV vars and `scope: 'email'` only
- [x] **FB-03**: `app_config.yml` references `ENV["FACEBOOK_APP_ID"]` and `ENV["FACEBOOK_APP_SECRET"]` for all environments

### Authentication

- [x] **FB-04**: User can sign in with Facebook — existing account matched by email and signed in
- [x] **FB-05**: User can sign up with Facebook — new account created with email from Facebook identity
- [x] **FB-06**: Deleted account cannot sign in via Facebook — `User.active` scope blocks soft-deleted users
- [x] **FB-07**: `User.from_omniauth` handles `:facebook` provider explicitly (email-based find-or-create, same pattern as google_oauth2)
- [x] **FB-08**: `Users::OmniauthCallbacksController#facebook` action added; delegates to `handle_callback`

### UI

- [x] **FB-09**: Facebook button appears in the OAuth section on sign-in and sign-up pages, after Google and X buttons
- [x] **FB-10**: Facebook button has branded styling (Facebook blue `#1877F2`) consistent with Google/X button visual style

### Locale

- [x] **FB-11**: `t('devise.shared.omniauth.facebook')` key exists in both ja.yml and en.yml; i18n parity test passes

### Testing

- [x] **FB-12**: Minitest covers `User.from_omniauth` for `:facebook` provider — sign-in (existing email), sign-up (new user), deleted-account guard
- [x] **FB-13**: Minitest covers `OmniauthCallbacksController#facebook` — persisted user signed in, failed create redirects to registration
- [x] **FB-14**: Cucumber E2E scenario verifies Facebook button is present on the sign-in page (static render check; no live OAuth round-trip in test); tri-suite gate green

## Future Requirements (deferred)

- FBFUT-01: Disconnect Facebook from account settings (link removal)
- FBFUT-02: Show connected providers in preferences page

## Out of Scope

- Fetching name/avatar from Facebook (`public_profile` scope) — email only, minimal footprint
- Live Facebook OAuth round-trip in Cucumber (requires Facebook sandbox; static presence check is sufficient)
- Facebook Login on mobile/native clients

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| FB-01  | 112   | open   |
| FB-02  | 112   | open   |
| FB-03  | 112   | open   |
| FB-04  | 112   | open   |
| FB-05  | 112   | open   |
| FB-06  | 112   | open   |
| FB-07  | 112   | open   |
| FB-08  | 112   | open   |
| FB-09  | 113   | open   |
| FB-10  | 113   | open   |
| FB-11  | 113   | open   |
| FB-12  | 112   | open   |
| FB-13  | 112   | open   |
| FB-14  | 113   | open   |
