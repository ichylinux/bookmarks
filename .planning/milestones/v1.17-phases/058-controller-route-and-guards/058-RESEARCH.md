---
phase: 58
name: Controller, Route, and Guards
researcher: claude-sonnet-4-6
date: 2026-05-13
status: complete
---

# Phase 58 Research: Controller, Route, and Guards

## Summary

Phase 58 builds `Users::EmailRegistrationsController` with `new`/`create`, a `before_action` guard that limits access to dummy-email users, and an inline collision rescue. All architectural decisions are locked in `058-CONTEXT.md`. This research surfaces three implementation gaps the planner must resolve and confirms the existing conventions.

---

## BLOCKER: Phase 57 Was Never Executed

**Confidence: HIGH** [VERIFIED: codebase inspection + `057-VERIFICATION.md`]

Phase 58 depends on Phase 57. Phase 57 is **not done**:

| Artifact | Expected | Actual |
|----------|----------|--------|
| `app/models/user.rb` — inline `validates :email, format: { without: ... }, on: :update` | Present | **MISSING** |
| `test/fixtures/users.yml` — `twitter_user` entry | Present | **MISSING** (only fixtures 1, 2, 3 exist) |
| `test/models/user_test.rb` | Created | **MISSING** |

`057-VERIFICATION.md` confirms: "the phase was planned but not executed" (score 0/4). The `has_valid_email?` guard used by Phase 58's `before_action :require_dummy_email` exists in the model, but the on-update dummy-email validator and the `twitter_user` fixture (needed for Phase 58 tests) are both absent.

**Impact on Phase 58 plan:** The plan must either (a) include Phase 57 implementation as Wave 0 before Phase 58 work, or (b) be structured so Phase 57 is executed as a prerequisite before Phase 58 begins. Without the `twitter_user` fixture, every Phase 58 test that requires a dummy-email user will fail to load.

---

## GAP: Stub View Required in Phase 58

**Confidence: HIGH** [VERIFIED: codebase inspection of test cases 2 and 5]

The context doc describes Phase 58 as controller-only and defers the view to Phase 59. However, Phase 58 success criteria #2 and #5 both require `render :new, status: :unprocessable_entity` on validation failure. Without a view file at `app/views/users/email_registrations/new.html.erb`, these test cases raise `ActionView::MissingTemplate` and cannot pass.

**Required minimum for Phase 58:** Create `app/views/users/email_registrations/new.html.erb` with a minimal stub form — enough for tests to render and for POST params to work. The full form (labels, locale keys, error display) is Phase 59 scope.

The directory `app/views/users/email_registrations/` does not yet exist. [VERIFIED: `ls app/views/users/`]

Existing views confirm the directory convention: `app/views/users/two_factor_setup/` and `app/views/users/two_factor_authentication/` are the templates. [VERIFIED: codebase]

---

## DISCREPANCY: Test File Placement Convention

**Confidence: HIGH** [VERIFIED: `ls test/controllers/`]

The context doc specifies `test/controllers/users/email_registrations_controller_test.rb` (namespaced subdirectory). The actual codebase convention is **flat**:

| Controller | Test file |
|-----------|-----------|
| `Users::TwoFactorSetupController` | `test/controllers/two_factor_setup_controller_test.rb` |
| `Users::TwoFactorAuthenticationController` | `test/controllers/two_factor_authentication_controller_test.rb` |

There is no `test/controllers/users/` subdirectory. Class names in existing tests are non-namespaced (`TwoFactorSetupControllerTest`, not `Users::TwoFactorSetupControllerTest`).

**Planner must decide:** Follow existing flat convention (`test/controllers/email_registrations_controller_test.rb` / `EmailRegistrationsControllerTest`) or explicitly establish the `users/` subdirectory as the new convention. The flat approach has zero setup friction and matches all prior art in this codebase.

---

## Route Structure

**Confidence: HIGH** [VERIFIED: `config/routes.rb`]

Existing `users/` routes follow explicit get/post/delete style — no `resource` helper:

```ruby
get  'users/two_factor_setup', to: 'users/two_factor_setup#show', as: :users_two_factor_setup
post 'users/two_factor_setup', to: 'users/two_factor_setup#enable'
delete 'users/two_factor_setup', to: 'users/two_factor_setup#disable'
```

Phase 58 route must follow the same pattern:

```ruby
get  'users/email_registration', to: 'users/email_registrations#new',    as: :users_email_registration
post 'users/email_registration', to: 'users/email_registrations#create'
```

**Critical:** Routes must be inside the `unless ARGV.first =~ /^dad:setup(:.+)?/` block — this block guards all user model-dependent routes for the Docker build setup task. [VERIFIED: `config/routes.rb` lines 3–15]

Path helper `users_email_registration_path` is used for both GET and POST (same path, different verb) — matching the `two_factor_setup` pattern.

---

## Authentication Guard

**Confidence: HIGH** [VERIFIED: `app/controllers/application_controller.rb`]

`ApplicationController` has `before_action :authenticate_user!` globally. No extra wiring needed in `Users::EmailRegistrationsController` — unauthenticated requests are automatically redirected to sign-in before any controller action runs.

Test for unauthenticated access: simply `GET users_email_registration_path` without `sign_in` and assert redirect.

---

## Dummy-Email Guard (`before_action :require_dummy_email`)

**Confidence: HIGH** [VERIFIED: `app/models/user.rb:43-47`]

`has_valid_email?` exists on User:

```ruby
def has_valid_email?
  return false if email.blank?
  return false if email =~ /^dummy_.+@example.com$/
  true
end
```

Uses `^`/`$` anchors (not `\A`/`\z`). For plain email strings (no embedded newlines), this is functionally identical. No issue.

The guard pattern from context doc:

```ruby
before_action :require_dummy_email

private

def require_dummy_email
  redirect_to preferences_path if current_user.has_valid_email?
end
```

`preferences_path` resolves to `GET /preferences` (the `preferences` resource index route). [VERIFIED: `bin/rails routes`]

---

## Controller Implementation Patterns

**Confidence: HIGH** [VERIFIED: `app/controllers/users/two_factor_setup_controller.rb`, `app/controllers/preferences_controller.rb`]

**`current_user` vs `User.find`:** `TwoFactorSetupController` uses `current_user` directly. `PreferencesController` uses `User.find(current_user.id)`. For Phase 58, direct `current_user` is correct — same pattern as two_factor_setup.

**`save` vs `save!`:** `PreferencesController` uses `save!` (inside a transaction) because validation failure there would be a programming error. Phase 58 `create` uses plain `save` with branch on return value — the correct approach for user-data-entry flows. [ASSUMED: standard Rails practice confirmed by context decisions]

**`flash[:notice]` vs inline `redirect_to ... notice:`:** `TwoFactorSetupController` uses the inline form: `redirect_to users_two_factor_setup_path, notice: t('two_factor.enabled')`. This is equivalent to setting `flash[:notice]` before redirect. Either works; inline is more idiomatic.

**`rescue ActiveRecord::RecordNotUnique`:** Inline in `create` only (not `rescue_from` at class level). `@user.errors.add(:email, :taken)` adds the Devise standard "has already been taken" message. [ASSUMED: `:taken` is the standard ActiveModel error key for this message]

---

## Strong Params

**Confidence: HIGH** [VERIFIED: 058-CONTEXT.md decisions]

Use `:email_registration` wrapper (not `:user`) to avoid collision with Devise's own param sanitizer which expects `params[:user]`. `PreferencesController` uses `params.require(:user)` — using the same key in `EmailRegistrationsController` would be ambiguous.

```ruby
def email_registration_params
  params.require(:email_registration).permit(:email)
end
```

The form stub must use `name="email_registration[email]"` or `form_with(scope: :email_registration)`.

---

## Test Conventions

**Confidence: HIGH** [VERIFIED: `test/test_helper.rb`, `test/controllers/two_factor_setup_controller_test.rb`, `test/support/users.rb`]

- All integration tests: `class Foo < ActionDispatch::IntegrationTest`
- `Devise::Test::IntegrationHelpers` is included in `ActionDispatch::IntegrationTest` — `sign_in` available
- `user` helper = `User.first` (fixture `1`, `user@example.com`, real email) — do NOT use `user` for dummy-email tests; use `users(:twitter_user)` [VERIFIED: `test/support/users.rb`]
- Japanese method names used throughout (e.g., `test_ダミーメールユーザーがメールアドレスを登録できる`)
- `assert_redirected_to` for redirect assertions
- `assert_response :success` for rendered views
- `assert_select` for DOM assertions
- No `setup` block required (tests are self-contained)

---

## Fixtures Needed

**Confidence: HIGH** [VERIFIED: Phase 57 plan + current users.yml]

Phase 58 tests require the `twitter_user` fixture (dummy email). This fixture is Phase 57 scope but was never created. It must exist before Phase 58 tests run.

The three existing users (1, 2, 3) all have real emails (`user@example.com`, `user2@example.com`, `user3@example.com`) — any of them can serve as the "real-email user" for CTRL-03 guard tests.

For collision test (success criterion #2): POST an email matching fixture `1` (`user@example.com`) from `twitter_user`'s session — this triggers Devise uniqueness validation (not `RecordNotUnique`). The `RecordNotUnique` rescue covers a race condition, tested separately via mock or a forced duplicate insert.

---

## Recommendations for Planner

1. **Wave 0: Execute Phase 57** — Implement the three Phase 57 tasks (user.rb validator, users.yml twitter_user, user_test.rb) before any Phase 58 work. Without `twitter_user`, Phase 58 tests cannot load.

2. **Resolve test file placement** — Recommend flat convention: `test/controllers/email_registrations_controller_test.rb` / `EmailRegistrationsControllerTest` to match `TwoFactorSetupControllerTest` and `TwoFactorAuthenticationControllerTest`. If `users/` subdirectory is chosen, document it as a new pattern.

3. **Add stub view to Phase 58 scope** — `app/views/users/email_registrations/new.html.erb` with a minimal form stub (enough for re-render tests to pass). Full form goes in Phase 59.

4. **Use inline `redirect_to ... notice:` pattern** — matches TwoFactorSetupController idiom.

5. **Use `rescue ActiveRecord::RecordNotUnique` inline in `create`** — narrowest scope. `@user.errors.add(:email, :taken)` surfaces the correct message.

6. **Route inside the `unless ARGV.first` guard** — required for Docker build.

---

## Files to Create / Modify

| File | Action | Notes |
|------|--------|-------|
| `app/models/user.rb` | Modify | Wave 0 (Phase 57) — add validator |
| `test/fixtures/users.yml` | Modify | Wave 0 (Phase 57) — add twitter_user |
| `test/models/user_test.rb` | Create | Wave 0 (Phase 57) |
| `config/routes.rb` | Modify | Add 2 routes inside `unless` block |
| `app/controllers/users/email_registrations_controller.rb` | Create | New controller |
| `app/views/users/email_registrations/new.html.erb` | Create | Stub form (new directory) |
| `test/controllers/email_registrations_controller_test.rb` | Create | Flat convention (see discrepancy note) |
