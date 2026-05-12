---
phase: 58
name: Controller, Route, and Guards
date: 2026-05-13
status: discussed
mode: autonomous (self-discuss)
---

# Phase 58 Context: Controller, Route, and Guards

## Domain

Build `Users::EmailRegistrationsController` with `new` and `create` actions that allow dummy-email users to register a real email address. Guard the controller so only dummy-email users (those where `has_valid_email?` is false) can access it — real-email users are redirected away. Handle the collision guard (CTRL-02) inline, rescuing `ActiveRecord::RecordNotUnique` races on the unique index and re-rendering the form with an error. Authentication guard (unauthenticated redirect) is provided by `ApplicationController`'s `before_action :authenticate_user!` — no extra wiring needed.

## Decisions

### Route structure and path helper naming

**Decision:** Under the `users/` prefix with explicit named routes, matching the `two_factor_setup` convention already in `config/routes.rb`.

```ruby
get  'users/email_registration', to: 'users/email_registrations#new',    as: :users_email_registration
post 'users/email_registration', to: 'users/email_registrations#create'
```

Path helper: `users_email_registration_path` (GET → new form; POST → create action — same path, different verb, single named helper following the two_factor_setup pattern).

Controller file: `app/controllers/users/email_registrations_controller.rb`
Class: `Users::EmailRegistrationsController < ApplicationController`

Do NOT use `resource :email_registration` (resourceful routing) — the existing two_factor_setup sets the explicit-route precedent and keeps route naming flat and predictable.

### Save mechanism and validation feedback

**Decision:** Use `save` (not `save!`) in `create` and branch on the return value. Validation failures (bad format, dummy-pattern, Devise uniqueness) are expected user-facing errors that must re-render the form.

```ruby
def create
  @user = current_user
  @user.email = email_registration_params[:email]
  if @user.save
    flash[:notice] = t('email_registrations.saved')
    redirect_to preferences_path
  else
    render :new, status: :unprocessable_entity
  end
rescue ActiveRecord::RecordNotUnique
  @user.errors.add(:email, :taken)
  render :new, status: :unprocessable_entity
end
```

The `save!` pattern used elsewhere in the project (`MastodonAccountsController`, `PreferencesController`) is for flows where validation failure would be a programming error. Email registration is a user-data-entry flow — failure is the happy path for bad input.

`rescue ActiveRecord::RecordNotUnique` is inline in `create` only (not `rescue_from` at class level) — narrowest scope for the narrowest failure mode.

### Dummy-email guard (CTRL-03)

**Decision:** `before_action :require_dummy_email` without `only:` — both `new` and `create` require the same guard. Redirect to `preferences_path`.

```ruby
before_action :require_dummy_email

private

def require_dummy_email
  redirect_to preferences_path if current_user.has_valid_email?
end
```

`has_valid_email?` already exists on User (`/^dummy_.+@example.com$/` check). This guard does NOT need to be duplicated in the view — the controller guard is the authoritative gate.

### Strong params wrapper

**Decision:** Use `:email_registration` as the form param namespace (not `:user`).

```ruby
def email_registration_params
  params.require(:email_registration).permit(:email)
end
```

Using `:user` would collide with Devise's own user param handling and create ambiguity about what the controller manages. A dedicated `:email_registration` wrapper makes the form and controller intent clear. The form will use `name="email_registration[email]"` (or a Rails form builder with `url: users_email_registration_path, scope: :email_registration`).

### Redirect after success

**Decision:** Redirect to `preferences_path` after successful email registration.

This lands the user at their preferences page where they can see their updated email. It is consistent with PreferencesController success redirects. Do NOT redirect to `root_path` or an interstitial — the preferences page is the natural continuation for account settings flows.

### Test file

**Decision:** Create `test/controllers/users/email_registrations_controller_test.rb` (class `Users::EmailRegistrationsControllerTest < ActionDispatch::IntegrationTest`).

Minimum test cases required by Phase 58 success criteria and CTRL-01/02/03:
1. `test_ダミーメールユーザーがメールアドレスを登録できる` — sign in as `twitter_user`, POST valid email, assert redirect to preferences, assert `user.reload.email` equals submitted address
2. `test_衝突するメールアドレスはエラーを返す` — sign in as `twitter_user`, POST email already held by fixture user `1`, assert re-renders form with error (Devise "has already been taken")
3. `test_実メールユーザーはフォームにアクセスできない` — sign in as regular user (fixture `1`), GET new form, assert redirect to preferences
4. `test_未認証ユーザーはサインインにリダイレクトされる` — GET new form without sign_in, assert redirect to sign-in path
5. `test_楽観的ロック競合はフォームを再描画する` — simulate `ActiveRecord::RecordNotUnique`, assert re-render with error (tested via stub or by triggering the duplicate insert)

The `twitter_user` fixture (added in Phase 57) provides the dummy-email user needed for tests 1 and 2.

## Canonical Refs

- `app/controllers/users/email_registrations_controller.rb` — new controller (created in this phase)
- `app/controllers/application_controller.rb` — parent class; `authenticate_user!` provides auth guard
- `app/models/user.rb` — `has_valid_email?` used by guard; `on: :update` validator (Phase 57)
- `config/routes.rb` — route added here; two_factor_setup routes show the naming convention
- `test/fixtures/users.yml` — `twitter_user` fixture (Phase 57) used by tests
- `test/controllers/users/email_registrations_controller_test.rb` — new test file (created in this phase)
- `.planning/REQUIREMENTS.md` — CTRL-01, CTRL-02, CTRL-03 requirements
- `.planning/ROADMAP.md` — Phase 58 success criteria
