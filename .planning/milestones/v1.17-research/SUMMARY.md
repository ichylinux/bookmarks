# Research Summary — v1.17 Email Registration for X/Twitter Users

**Project:** Bookmarks v1.17
**Domain:** Devise + OmniAuth account email self-registration
**Researched:** 2026-05-13
**Confidence:** HIGH

## Overview

X/Twitter users in this app are created with a `dummy_<uuid>@example.com` address because the Twitter OAuth flow returns no email. Registering a real email has one primary payoff: `User.from_omniauth` for Google OAuth does an exact-match lookup on `users.email`, so once the dummy address is replaced the same user can sign in via Google with no code changes to `from_omniauth`. The entire feature fits within existing Rails/Devise infrastructure — no new gems, no schema migration, no new Devise modules.

The key architectural insight is that email update must live in a **dedicated controller** (`EmailRegistrationsController`) rather than inside the existing `PreferencesController`. Two pitfalls make this mandatory: (1) mixing email into the preferences `user_params` creates a writable-email surface for all authenticated users, and (2) the existing `save!` pattern in `PreferencesController` raises a 500 on validation failure instead of re-rendering a form with errors.

## Stack

**No new gems. No migration.**

The `users` table already has `email` (string, NOT NULL, unique index). Devise `:validatable` already provides format validation and application-level uniqueness enforcement backed by the DB unique index. The only model change is one new `validates` call to block dummy-pattern emails on update. The preferences view already uses `has_valid_email?` as a display gate — the same method drives the new UI section visibility.

Intentionally excluded from this milestone:
- Devise `:confirmable` — requires 4 new columns (`confirmation_token`, `confirmed_at`, `confirmation_sent_at`, `unconfirmed_email`), a mailer pipeline, and access-gate changes to all sign-in flows. Google OAuth provides implicit verification: if the user can subsequently sign in with Google, the address is correct.
- Any email delivery or mailer templates — no confirmation tokens, no notifications.
- Overriding `Devise::RegistrationsController` — the app has no Devise registration views; OmniAuth is the only sign-up path.

## Feature Scope

**Table stakes (required for correct, safe behavior):**
- Email input on preferences page, visible only when `!has_valid_email?`
- Server-side guard: skip email param if the current user already has a valid email
- Format validation (Devise `:validatable` handles this automatically)
- Uniqueness validation with a legible user-facing error (Devise `:validatable` + DB unique index)
- Dummy-pattern rejection on write: `validates :email, format: { without: /\Adummy_.+@example\.com\z/, message: :invalid }, on: :update`
- Flash message on success (ja + en locale keys — parity enforced by existing tests)
- Email registration field hidden after successful registration (same `has_valid_email?` gate re-evaluated after redirect)

**Nice to have (low effort, worth including):**
- Helper text below the email field explaining why email is requested ("Googleでもサインインできるようになります")
- Inline validation error display near the email field, not only in a global flash
- Distinct "email registered" flash key separate from the generic "settings saved" message

**Confirmed out of scope for v1.17:**
- Email confirmation via Devise `:confirmable`
- Account merging for users who have both a Twitter-originated and a separate Google account with the same email
- Allowing email changes after a real address is already set (separate future milestone)
- Password re-entry before saving
- Notification to the old dummy address

## Architecture Approach

The build is four components deep: a model validator, a dedicated controller, a standalone view, and a link row added to the existing preferences view.

**New components:**

1. **`app/controllers/email_registrations_controller.rb`** — singular resource controller, `new` (GET) and `create` (POST). Guards: redirect to preferences if `current_user.has_valid_email?` already. Uses `@user.save` (not `save!`) and renders the form with `@user.errors` on failure. Permits only `[:email]` — never `:password`, never preference attributes.

2. **`app/views/email_registrations/new.html.erb`** — standalone page with a single email field, inline error display via `@user.errors[:email]`, and a submit button.

3. **Route addition** (inside the `unless ARGV.first =~ /^dad:setup/` block):
   ```ruby
   resource :email_registration, only: [:new, :create]
   ```

**Modified components:**

4. **`app/models/user.rb`** — one new validator scoped to `on: :update`:
   ```ruby
   validates :email, format: { without: /\Adummy_.+@example\.com\z/, message: :invalid }, on: :update
   ```
   `on: :update` is required so it does not fire during the Twitter `from_omniauth` create path, which legitimately generates a dummy address on new record creation.

5. **`app/views/preferences/index.html.erb`** — add one link row inside `<% unless @user.has_valid_email? %>`. This is a link to `new_email_registration_path`, not an inline form. The mutation occurs on the dedicated page.

6. **`config/locales/en.yml` and `ja.yml`** — new keys under `email_registrations.*` and `preferences.index.email_registration.*`. Both files must be updated together; the locale parity test enforces this.

**Suggested build order:**
1. Model validation + unit tests (no UI risk; establishes the safety net before any form is reachable)
2. Route + controller + integration tests (headless; no view rendering required for redirect paths)
3. Views + locale keys (wire together; I18n errors surface immediately on first render)
4. Cucumber E2E + full tri-suite gate

## Watch Out For

Ranked by severity:

**CRITICAL — PITFALL-01: Account takeover via email collision with an existing Google user**
If a Twitter user registers an email address already held by a Google OAuth account, `User.from_omniauth` for Google (`User.where(email: data["email"]).first`) will match the Twitter user's record on the next Google sign-in — silently signing the Google account owner into a different user's data. Devise `:validatable` uniqueness + the DB unique index block the duplicate from being stored, but the user-facing error message must be present and clear. This guard must land before any UI is shipped.

**HIGH — PITFALL-04 + PITFALL-07: `password_required?` fires / `save!` raises 500**
Adding `:email` to the existing preferences `user_params` would cause Devise's `password_required?` to fire unexpectedly if any form field sends an empty password param, producing cryptic validation errors. The existing `save!` in `PreferencesController` propagates as a 500 on validation failure. Both problems are eliminated by a dedicated controller using `save` (not `save!`) with a narrowly-scoped `permit(:email)`.

**HIGH — PITFALL-02: Twitter `from_omniauth` uses `name` not `uid` (pre-existing bug)**
The Twitter branch in `from_omniauth` matches by `User.where(name: data["name"]).first`. Twitter display names are not unique; a name change between visits creates a second orphaned account, losing the registered email. Do NOT fix this in v1.17 (scope creep risk), but ensure the email update always writes via `current_user` — never re-resolve by name. Log as a separate task referencing the unused `uid`/`provider` columns in the schema.

**MEDIUM — PITFALL-05: Dummy-pattern writable without explicit model validator**
`has_valid_email?` is a read-path check only. Without `on: :update` model validation, a user can submit `dummy_foo@example.com` and appear to succeed (the field disappears, but `has_valid_email?` still returns false). The model validator closes this.

**LOW — PITFALL-06: TOCTOU race on uniqueness**
Devise's `SELECT` before `UPDATE` uniqueness check has a race window under concurrent requests. The DB unique index guarantees no duplicate row but raises `ActiveRecord::RecordNotUnique` (500) rather than a validation error. Rescue it in the controller and re-render with a user-facing error. Low probability for a personal app; the rescue is cheap.

**LOW — PITFALL-03: Skipping email confirmation**
The decision to skip `:confirmable` is correct for v1.17 (schema has no confirmation columns; Google OAuth provides implicit verification; app is personal/single-owner). Document the trade-off explicitly so a future developer does not add `:confirmable` without understanding the migration and mailer pipeline it requires.

## Open Questions

**Already decided — no action needed:**
- Email confirmation: skip; immediate-accept with collision guard is correct for v1.17
- Controller placement: dedicated `EmailRegistrationsController`, not inside `PreferencesController`
- Schema: no migration needed; `users.email` column and unique index already exist

**Needs a decision before writing locale keys:**
- Wording for the collision error: Devise default is "has already been taken" (safe; does not confirm another account exists). A more helpful message could say "If you have a Google account with this address, sign in via Google instead." Choose wording before adding the locale key.
- Should the `display_name` change (from Twitter handle to email after registration) be surfaced in help text or a release note? Currently silent, designed behavior — but users who care about their display name may be surprised.

**Must be logged as a separate task before v1.17 closes:**
- PITFALL-02 fix: `from_omniauth` Twitter branch should use `uid` + `provider` columns (both exist in schema, currently unused) instead of `name` for account lookup.
- EDGE-03: After a Twitter user links via email and later signs in via Google, the `provider`/`uid` columns on the record remain Twitter values. Any future `from_omniauth` refactor that switches to `uid`+`provider` lookup must handle the "email-linked, no Google uid" case.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No gems or migrations needed — verified against `db/schema.rb`, `user.rb`, and `devise.rb` directly |
| Features | HIGH | Scope boundaries traced through existing code; `:confirmable` exclusion confirmed by schema inspection |
| Architecture | HIGH | Build order and component shape derived from existing 2FA setup (`users/two_factor_setup_controller.rb`) as direct precedent |
| Pitfalls | HIGH | PITFALL-01 through PITFALL-07 traced through `user.rb` and `preferences_controller.rb`; Devise `:validatable` source reviewed |

**Overall confidence:** HIGH

### Gaps to Address

- **Fixture for Twitter-style user:** No fixture with `email: "dummy_<uuid>@example.com"` confirmed to exist. Create it in Phase 1 before writing controller integration tests.
- **Cucumber Twitter mock state:** Verify the Twitter-authenticated user fixture state is reachable in the E2E scenario without triggering a live OmniAuth callback (the email registration flow itself does not call OmniAuth, but the signed-in session setup may depend on mock state).
- **`provider`/`uid` audit:** Confirm whether the current codebase ever writes to `users.provider` or `users.uid`. If not, document explicitly so the next developer does not assume those columns are populated.

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `app/models/user.rb` — `has_valid_email?`, `from_omniauth`, Devise module list, `display_name`
- `db/schema.rb` — `users` table columns (email, provider, uid), unique indexes
- `app/controllers/preferences_controller.rb` — `user_params`, `save!` transaction pattern
- `config/initializers/devise.rb` — `case_insensitive_keys`, `reconfirmable`, `email_regexp`
- `config/environments/test.rb` — mailer delivery method, `support_unencrypted_data`
- `app/controllers/users/two_factor_setup_controller.rb` — architectural precedent for dedicated settings sub-controllers

### Secondary (MEDIUM confidence — official docs / community)
- Devise validatable source: https://github.com/heartcombo/devise/blob/main/lib/devise/models/validatable.rb
- Devise wiki — edit without password: https://github.com/heartcombo/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password
- Devise wiki — OmniAuth overview: https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview
- Rails uniqueness race condition: https://rietta.com/blog/validates-uniqueness-race-condition-in-ruby-on-rails/
- Auth0 account linking best practices: https://auth0.com/docs/manage-users/user-accounts/user-account-linking
- OAuth account linking security discussion: https://github.com/nextauthjs/next-auth/discussions/2808
- Twitter OAuth no email context: https://github.com/pocketbase/pocketbase/discussions/2497

---
*Research completed: 2026-05-13*
*Ready for roadmap: yes*
