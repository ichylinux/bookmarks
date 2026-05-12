# Stack Research — Email Registration for X/Twitter Users

**Project:** Bookmarks v1.17
**Researched:** 2026-05-13
**Confidence:** HIGH (findings traced directly through existing source files)

---

## Summary

Allowing X/Twitter OmniAuth users to register a real email address requires no new gems
and no schema migration. The existing Devise `:validatable` module already provides email
uniqueness and format validation, and the `users.email` column with its unique index
already exists. The implementation is a guarded controller action that writes
`current_user.email` directly, plus a model-level validator that rejects dummy-pattern
addresses. The `:confirmable` module is intentionally excluded — email ownership
confirmation via token is a separate future concern and its addition would require a
migration and a complete mailer pipeline. The goal for this milestone is only to store a
real email so that Google OAuth's `where(email:)` lookup can match the account.

---

## Required Changes

### Devise modules — no additions, no removals

Current module list on `User`:

```ruby
devise :two_factor_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
       omniauth_providers: [:google_oauth2, :twitter]
```

`:validatable` already provides:
- Email format validation via `Devise.email_regexp` (`/\A[^@\s]+@[^@\s]+\z/`)
- Email uniqueness validation (model-level; backed by `index_users_on_email` unique index)
- Password presence/length validation

No new Devise modules needed. The devise initializer requires no changes. The
`config.reconfirmable = true` setting at line 141 of `config/initializers/devise.rb`
only has effect when `:confirmable` is active — since `:confirmable` is NOT being added,
that setting is inert and must not be removed.

### Schema — no migration needed

The `users` table already has:
- `email` string NOT NULL, default `""`
- `index_users_on_email` unique index

There is no `unconfirmed_email` column and none is needed for this milestone. Adding
`:confirmable` in the future would require `unconfirmed_email`, `confirmation_token`,
`confirmed_at`, and `confirmation_sent_at` columns — but that is out of scope here.

### Model changes (User)

Add one custom validation to guard against re-submitting a dummy address:

```ruby
validate :email_must_not_be_dummy, if: -> { email_changed? }

private

def email_must_not_be_dummy
  errors.add(:email, :dummy_not_allowed) if email =~ /\Adummy_.+@example\.com\z/
end
```

Use `\A`/`\z` anchors (not `^`/`$`) per Rails security convention for multi-line strings.

The existing `has_valid_email?` method (lines 43-47) uses `^`/`$` — that is safe for
display logic but the validator must use `\A`/`\z`.

No changes are needed to `from_omniauth`. The Google branch already does:
```ruby
user = User.where(email: data["email"]).first
```
Once the Twitter user's `email` column holds a real address, the next Google OAuth
callback with the same address will find the account. The Twitter branch continues to
match by `name` — the email update does not break that lookup.

### Controller changes

Add a separate action for the email update path. Do NOT extend the existing
`PreferencesController#update` strong params to include `:email` — that would make email
writable through the same form all signed-in users POST for theme/locale/font changes.

Recommended approach: add `update_email` (or `create` variant) as a distinct action on
`PreferencesController`, or create a minimal `Users::EmailController`. Either way:

- `before_action` guard: only allow this action when `!current_user.has_valid_email?`
- Strong params: `params.require(:user).permit(:email)` — narrow, separate from
  `user_params` that governs preference saves
- On success: `current_user.update!(email: params[:user][:email])` — `:validatable`
  runs uniqueness + format checks automatically
- On failure: re-render the form with `@user.errors`

The preferences view already conditionally renders the name field based on
`@user.has_valid_email?` (line 3). The email-registration section should follow the
same conditional pattern: show the email input only when `!current_user.has_valid_email?`.

### Route changes

Add one route for the email update action, for example:

```ruby
resources :preferences, only: ['index', 'create', 'update'] do
  collection do
    patch 'update_email'
  end
end
```

Or a standalone shallow resource. The exact shape is an implementation detail; the key
constraint is that the route must be distinct from `preference_path` so the two forms
POST to separate URLs with separate strong params.

---

## New Gems

None required.

---

## What NOT to Add

| Anti-pattern | Why |
|---|---|
| `:confirmable` Devise module | Requires a migration (4 new columns), a working mailer pipeline, and changes all sign-in flows to enforce confirmation before access. Goal is account linkage only. |
| `email_validator` gem | Overkill — Devise's `email_regexp` plus uniqueness validation via `:validatable` is sufficient. |
| `devise_invitable` or any invitation gem | Unrelated to the goal. |
| Token-based email change confirmation | Future milestone. The mailer pipeline exists in production (`delivery_method :smtp`) but no confirmation UX or token columns exist yet. |
| Extending `user_params` in the existing preference `update` action | Security risk — all signed-in users (including those with real emails) can POST to that action; email must not be writable through that path. |
| Overriding `Devise::RegistrationsController` | The app does not use Devise's registration views (Twitter/Google OmniAuth is the only sign-up path). Overriding it adds complexity for no benefit. |

---

## Integration Notes

### Google OAuth matching works immediately after email update

`User.from_omniauth` for the Google branch (user.rb lines 29-30):

```ruby
user = User.where(email: data["email"]).first
user ||= User.create(email: data['email'], ...)
```

Once a Twitter user's `email` is updated to a real address, the next Google OAuth
callback with that address will find the record via `where(email:)` and sign the user
into their existing account. No change to `from_omniauth` is needed.

### `:validatable` uniqueness is model-enforced and DB-enforced

Devise's `:validatable` adds `validates_uniqueness_of :email, allow_blank: true,
if: :email_changed?`. The database backs this with a unique index. Double protection
means a clear validation error message before any DB constraint violation. No additional
uniqueness gem is needed.

### Test environment is already ready

`config/environments/test.rb` line 37: `config.action_mailer.delivery_method = :test`.
`ActionMailer::Base.deliveries` is available for inspection in Minitest if any future
iteration adds email confirmation. No test environment changes are needed for this
milestone.

### Locale strings needed

Both `ja.yml` and `en.yml` must receive keys for:
- Email field label
- Validation error for dummy-format address
- Success flash after email update
- Section heading on the preferences page

The locale key parity test (`bin/rails test`) will fail if keys are added to one file
but not the other — this is enforced by existing tests. Add to both files together.

### Confidence assessment

| Area | Level | Reason |
|---|---|---|
| No new gems needed | HIGH | `:validatable` provides all required validation; traced through User model |
| No migration needed | HIGH | `users.email` column + unique index confirmed in `db/schema.rb` lines 102, 117 |
| No `:confirmable` for this milestone | HIGH | Confirmed by reviewing what columns it would require vs. what exists |
| Google OAuth matching works immediately | HIGH | Directly traced through `from_omniauth` source (user.rb lines 23-32) |
| Dummy-email guard approach | HIGH | `has_valid_email?` pattern already exists; converting to model validator is standard Rails |
| Separate route/action for email update | HIGH | Security requirement; existing `user_params` must not gain `:email` |
