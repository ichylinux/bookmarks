# Architecture Research — Email Registration for X/Twitter Users

**Researched:** 2026-05-13
**Confidence:** HIGH (all findings from direct codebase inspection)

## Summary

Twitter/X users sign in via OmniAuth and are assigned a `dummy_<uuid>@example.com` email to satisfy Devise's `:validatable` uniqueness constraint. The email registration flow replaces that dummy email with a real one, which simultaneously unlocks Google OAuth account linking (because `User.from_omniauth` for the Google path matches on `email`). The feature is entirely self-contained within the existing Devise + preferences architecture — no new data model is needed, only a dedicated controller action, a model validation, locale keys, and a targeted view section.

## Integration Points

### 1. `User#has_valid_email?` (app/models/user.rb:43)

The sentinel already exists. It returns `false` when `email` matches `/^dummy_.+@example.com$/`. The preferences view already gates the `name` field on `has_valid_email?` (line 3). The email registration UI uses the same guard — show the registration link when `!@user.has_valid_email?`.

### 2. `User.from_omniauth` — Google branch (app/models/user.rb:29)

```ruby
user = User.where(email: data["email"]).first
user ||= User.create(email: data['email'], ...)
```

Google sign-in already does an exact-match lookup on `email`. Once the Twitter user's dummy email is replaced with a real email, this lookup will find and sign in the same `User` record. No change to `from_omniauth` is needed.

### 3. `PreferencesController` (app/controllers/preferences_controller.rb)

The controller drives the preferences page. The email update action belongs in a dedicated `EmailRegistrationsController` rather than in `PreferencesController`. The pattern in this app is controller-per-concern (2FA has its own `users/two_factor_setup_controller.rb`). Email registration has different concerns from preferences: it requires a uniqueness guard at update time, it conditionally shows/hides the form based on dummy-email status, and it should not intermix with the preferences `user_params` permitted list.

### 4. `users` table — no migration needed

The `users` table already has `email` (string, unique index, not null). There is no `provider`-type lock. The dummy email is just a string — overwriting it with a real email is a plain `user.update(email:)` call. The unique index provides DB-level uniqueness enforcement to back up Devise's application-level check.

### 5. Devise `:validatable` — existing validation surface

`:validatable` provides email format and uniqueness validation automatically. No custom uniqueness validator needs to be written. The key addition is a model-level guard that rejects updates to a new dummy-pattern email (defense against a user manually constructing `dummy_x@example.com` to revert their status).

### 6. `preferences/index.html.erb` — existing view touchpoint

The view already checks `@user.has_valid_email?` to decide whether to show the `name` field. The email registration entry point (a link to the registration page) is added as a new row in this view, gated on `!@user.has_valid_email?`.

### 7. Locale files (config/locales/en.yml, ja.yml)

The `preferences.index` namespace is where preferences-page labels live. New keys for the link text belong there. Keys for the standalone registration page belong under `email_registrations.*`.

### 8. Devise `:registerable` + `users/omniauth_callbacks_controller.rb`

`handle_callback` calls `sign_in_and_redirect` directly (bypasses password). After an email update, the next Google sign-in will hit `User.where(email: data["email"]).first` and find the existing account. No change to the callbacks controller is needed.

## New Components

### `EmailRegistrationsController`

```
app/controllers/email_registrations_controller.rb
```

Actions:
- `new` (GET `/email_registration/new`) — renders the email entry form; redirects users who already have a valid email back to preferences (guard against URL manipulation)
- `create` (POST `/email_registration`) — validates and saves the new email; on success, redirects to `preferences_path` with flash; on failure, re-renders form with errors

Strong params: permit only `:email`. Never include password, preference, or other User attributes.

### Route addition

```ruby
resource :email_registration, only: [:new, :create]
```

Singular resource — one email per user. Generates `GET /email_registration/new` and `POST /email_registration`.

### View: `app/views/email_registrations/new.html.erb`

A standalone page with a single email field and submit button. Inline error display using `@user.errors.full_messages` (consistent with Devise registration view pattern). The page is only reachable by authenticated users; `before_action :authenticate_user!` applies via `ApplicationController`.

### Partial or inline section in `preferences/index.html.erb`

A new table row visible only when `!@user.has_valid_email?`:

```erb
<% unless @user.has_valid_email? %>
  <tr>
    <th><%= t('preferences.index.email_registration.label') %></th>
    <td><%= link_to t('preferences.index.email_registration.link'), new_email_registration_path %></td>
  </tr>
<% end %>
```

This is a link only, not a form — the update happens on the dedicated page.

## Modified Components

### `app/models/user.rb`

Add a validation that rejects dummy-pattern emails on any update:

```ruby
validates :email, format: { without: /\Adummy_.+@example\.com\z/, message: :invalid }
```

This fires on all saves, preventing any path from storing a dummy email except the Twitter `from_omniauth` path which bypasses validations via `User.create` (which does run validations — so the `from_omniauth` Twitter branch must continue using a non-dummy-pattern email format or the validation must be scoped to `on: :update` only).

**Scoping decision:** Apply `on: :update` to avoid breaking the `from_omniauth` Twitter create path. The Twitter create path generates `dummy_<uuid>@example.com` on new record creation; `:validatable` uniqueness still applies. The new guard only needs to prevent a user from saving a dummy-pattern email via the registration form.

```ruby
validates :email, format: { without: /\Adummy_.+@example\.com\z/, message: :invalid }, on: :update
```

### `app/views/preferences/index.html.erb`

Add the email registration link row (see New Components above). This is the only change to the existing view template.

### `config/locales/en.yml` and `ja.yml`

New keys:

```yaml
# Under preferences.index:
email_registration:
  label: "Email address"
  link: "Register email address"

# Top-level controller namespace:
email_registrations:
  new:
    title: "Register email address"
    submit: "Save"
  saved: "Email address saved."
```

Japanese equivalents under the same key paths in `ja.yml`. Follow the parity enforcement contract already in place (locale key parity tests).

### `config/routes.rb`

Add one line inside the `unless ARGV.first =~ /^dad:setup/` block:

```ruby
resource :email_registration, only: [:new, :create]
```

## Data Flow

```
User (Twitter-signed-up, email = dummy_<uuid>@example.com)
  |
  | visits /preferences
  v
PreferencesController#index
  -> preferences/index.html.erb
  -> !@user.has_valid_email? is true
  -> shows "Register email address" link
  |
  | clicks link
  v
GET /email_registration/new
  -> EmailRegistrationsController#new
  -> Guard: current_user.has_valid_email? ? redirect to preferences : render form
  -> renders email_registrations/new.html.erb
  |
  | submits email
  v
POST /email_registration
  -> EmailRegistrationsController#create
  -> Guard: current_user.has_valid_email? → redirect (no-op)
  -> user = current_user
  -> user.email = permitted_params[:email]
  -> user.save
     -> Devise :validatable: format check + uniqueness check (unique index backed)
     -> new model validation: rejects dummy-pattern (on: :update)
  -> On failure: re-render form with user.errors.full_messages
  -> On success: flash[:notice] = t('email_registrations.saved')
               redirect_to preferences_path
  |
  v
preferences/index.html.erb (after redirect)
  -> @user.has_valid_email? is now true
  -> email registration row: HIDDEN
  -> name field row: NOW VISIBLE (was also gated on has_valid_email?)
```

No background jobs. No email confirmation (`:confirmable` not enabled). No DB migration required. The update is a single `users.email` column write within the standard ActiveRecord transaction.

## Google OAuth Linking

After the email update, the next Google OAuth sign-in automatically links to the same account:

```
User clicks "Sign in with Google" on sign-in page
  |
  v
OmniauthCallbacksController#google_oauth2
  -> handle_callback('Google')
  -> User.from_omniauth(request.env["omniauth.auth"])
     -> case :google_oauth2 (else branch in from_omniauth)
        -> User.where(email: data["email"]).first
           # data["email"] from Google == users.email set during registration
           # -> finds the Twitter user's existing record
        -> user.persisted? == true
        -> sign_in_and_redirect user
```

Zero code changes required to `from_omniauth` or `handle_callback`. The link is purely data-driven: matching string in `users.email`.

**Edge case — email collision:** If a separate account already holds the email the Twitter user wants to register, `User.where(email: data["email"]).first` during Google sign-in would return the other user's account. The Devise uniqueness validation on `user.save` in `EmailRegistrationsController#create` prevents this from happening — a taken email is rejected before it is stored. This provides safe protection at the registration step.

**Edge case — `provider`/`uid` columns:** The `users` table has `provider` and `uid` columns (from an OmniAuth migration). Neither `from_omniauth` branch sets these on create. They appear unused in the current codebase. No change needed.

**Consequence for `display_name`:** `User#display_name` returns `email` when `has_valid_email?` and `name` otherwise (app/models/user.rb:35-41). After registering an email, the display name shown in the UI will switch from the Twitter display name to the email address. This is existing designed behavior — no change needed, but it should be noted in phase verification.

## Suggested Build Order

### Phase 1 — Model validation hardening

Add `validates :email, format: { without: /\Adummy_.+@example\.com\z/, message: :invalid }, on: :update` to `User`. Add Minitest unit tests covering: `has_valid_email?` returns false for dummy pattern, true for real email; the new validation blocks dummy-pattern saves on update while allowing create. This phase has no UI surface and cannot be broken by view/route churn.

### Phase 2 — Route + Controller

Add `resource :email_registration` to routes. Create `EmailRegistrationsController` with `new` and `create`. The `create` action performs the update, handles validation errors, redirects on success. Minitest integration tests (subclassing `ActionDispatch::IntegrationTest` with `Devise::Test::IntegrationHelpers`) covering: success path updates email and redirects to preferences, duplicate email rejected with error, dummy-pattern rejected, guard redirect when user already has valid email.

### Phase 3 — Views + Locale keys

Add `app/views/email_registrations/new.html.erb`. Add the link row to `preferences/index.html.erb` inside the `<% unless @user.has_valid_email? %>` guard. Add ja/en locale keys under `preferences.index.email_registration` and `email_registrations.*`. Minitest view-contract tests: link present when dummy email, link absent when valid email; form renders with email field and submit; display name changes after registration.

### Phase 4 — Cucumber E2E + tri-suite gate

Add `features/06.メール登録.feature` (or appended to an existing file) covering: sign in as a Twitter user (dummy email fixture), visit preferences, follow registration link, submit real email, verify preferences shows no registration link and shows name field. Run full tri-suite (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`) to close the phase.

**Rationale for ordering:** Model validation first prevents invalid state at any point. Controller before views means integration tests can run headlessly before the view is complete. Locale keys are wired in Phase 3 alongside views to avoid missing-key I18n errors during Phase 2 controller tests (controller tests that redirect do not render views, so missing keys are not hit). Cucumber last because it requires the full integrated stack.
