# Features Research — Email Registration for X/Twitter Users

**Domain:** OAuth-only user email self-registration in a Rails/Devise app
**Researched:** 2026-05-13
**Overall confidence:** HIGH (codebase read directly; patterns verified against Devise modules already present)

---

## Summary

X/Twitter users currently receive a `dummy_<uuid>@example.com` address on first sign-in (`User.from_omniauth`). Registering a real email unlocks Google OAuth sign-in (via the existing `from_omniauth` email lookup path), improves `display_name`, and makes the account recoverable in future. The entire flow fits inside the existing `PreferencesController` and preferences view — no new top-level route is needed. Email confirmation via Devise `:confirmable` is explicitly out of scope: the schema has no confirmation columns, the module is not activated, and the app's threat model and single-owner character do not justify it.

---

## Table Stakes

Must be present for the feature to be correct and usable. Missing any one makes the flow broken or unsafe.

| Feature | Why Required | Complexity | Dependencies on Existing Code |
|---------|-------------|------------|-------------------------------|
| Email input field on preferences page, visible only when `!has_valid_email?` | Entry point for the entire flow | Low | `has_valid_email?` already exists; preferences view already gates the `name` row with this method — identical pattern |
| Format validation (valid email format) | Prevents obviously bad input reaching the DB | Low | Devise `:validatable` already validates email format on `User`; no new code needed at the model level |
| Uniqueness validation (reject already-registered emails) | Prevents account collision | Low | Devise `:validatable` already enforces `validates_uniqueness_of :email`; no new code needed |
| Reject dummy-pattern input (`dummy_*@example.com`) | Prevents user from re-entering a dummy address and appearing to succeed | Low | Invert `has_valid_email?` regex into a custom `validates :email` callback or `validates_format_of` exclusion |
| Server-side guard: ignore email param when current email is already real | Defense in depth; prevents the hidden field from being submitted to override a real email | Low | One `if !current_user.has_valid_email?` gate in the controller update action before assigning the email param |
| Permit `:email` in `user_params` — guarded as above | Without it, strong params will strip the value | Low | `PreferencesController#user_params` currently permits `:name` and `preference_attributes`; add `:email` with guard |
| Persist the real email to `users.email` on save | Core data mutation | Low | `@user.save!` inside the existing transaction already persists changes; only strong-params and guard need updating |
| Flash message on success (ja + en) | User feedback; matches existing preferences save flow | Low | `preferences.saved` locale key already exists; reuse it — or add a more specific key for clarity |
| Hide the email field once a real email is set | Prevents repeated mutation; avoids UX confusion | Low | Same `has_valid_email?` gate — the view condition handles it automatically after the redirect |

---

## Differentiators

Nice-to-have additions that improve experience but are not required for correctness.

| Feature | Value Proposition | Complexity | Notes |
|---------|------------------|------------|-------|
| Helper text below the email field explaining why email is requested | Reduces confusion ("this lets you sign in with Google") | Low | One locale key per language; a `<small>` or `<span class="hint">` element |
| Validation error rendered inline near the email row, not just in a global flash | Faster feedback for a single-field failure | Low | Devise model errors attach to `:email`; standard `@user.errors[:email]` rendering in the view |
| Separate "email registered" flash vs generic "settings saved" | Confirms to user specifically what changed | Low | Separate locale key; one-line controller change |
| Display current `display_name` or `name` as identity context near the field | Reassures user they are editing the right account | Low | `current_user.display_name` already available |

---

## Anti-Features

Explicitly do not build these.

| Anti-Feature | Why Avoid | What to Do Instead |
|-------------|-----------|-------------------|
| Devise `:confirmable` email confirmation | `users` table has no `confirmation_token`, `confirmed_at`, or `unconfirmed_email` columns. Adding these requires a migration and activating a Devise module with its own mailer, token-expiry logic, and access gates. `reconfirmable: true` is set in `devise.rb` but is dormant because `:confirmable` is not in the `User` model declaration. For a personal, authenticated-session app this complexity is entirely unwarranted. | Direct `users.email` update with format + uniqueness + dummy-rejection validation is sufficient |
| Separate `/users/email` route and controller | Fragments the settings surface the user already knows; introduces a new controller for trivially few lines of logic | Keep the field inside `PreferencesController` / preferences view — consistent with how 2FA setup is surfaced there |
| Allowing email edits after a real email is already set | Changing an established email is a higher-risk operation (potential account recovery implications) and is out of scope for v1.17 | Hide the field via `has_valid_email?` once set; a future milestone can introduce "change email" with stronger verification |
| Password re-entry before saving email | Over-engineering for a personal app where the user is already authenticated via an active session | Standard authenticated session is sufficient |
| Notification email to the old dummy address | The dummy address `dummy_uuid@example.com` is not a real mailbox; sending to it generates bounces and no user value | No email notification needed |
| Exposing `:email` in `user_params` without the dummy-email guard | Would allow any authenticated user with a real email to overwrite it via a crafted POST, or allow future code paths to clobber the email unexpectedly | Gate the param assignment server-side behind `!current_user.has_valid_email?` |

---

## User Journey

Step-by-step from the X/Twitter user's perspective (happy path):

1. User signs in via X/Twitter as usual (existing flow unchanged).
2. User navigates to `/preferences`.
3. A new row "メールアドレスを登録 / Register email" appears in the preferences table. The existing `name` row is hidden for dummy-email users (current behaviour) — this new row appears in its place or just above it.
4. User types a real email address into the text field.
5. User clicks "保存 / Save" (the existing submit button — no new button needed).
6. Server validates: format, uniqueness, not a dummy-pattern address, current user still has dummy email (guard).
   - Failure path: preferences page re-renders with an error message near the email field (or in flash). User corrects input and resubmits.
   - Success path: `users.email` updated; redirect to `/preferences` with flash "設定を保存しました".
7. User returns to preferences page. Email registration row is gone (`has_valid_email?` now returns true). The `name` field row reappears (existing behaviour for real-email users).
8. Downstream: user can now sign in with Google OAuth — `from_omniauth` for Google does `User.where(email: data["email"]).first` and finds their existing account.

Edge cases to handle:

- **Email already registered to another account:** show standard Devise uniqueness error; do not disclose that another account exists — Devise's default wording ("has already been taken") is correct.
- **Empty submission (field left blank):** do not treat a blank value as "clear email"; skip the email param entirely in the controller when blank. The existing email (dummy) remains untouched, and the rest of preferences saves normally.
- **User with real email somehow reaches the update action (direct POST):** server-side guard ignores the email param; preferences save proceeds without modifying the email column.
- **Duplicate submission / double-click:** Rails CSRF token + redirect-after-POST pattern makes this safe by default.

---

## Email Confirmation Decision

**Decision: Skip email confirmation. Direct update to `users.email` is correct for v1.17.**

**Justification:**

1. **Schema does not support `:confirmable`.** No `confirmation_token`, `confirmed_at`, or `unconfirmed_email` columns exist in `db/schema.rb`. Adding `:confirmable` requires a migration and activating the Devise module — non-trivial scope expansion.

2. **App is a personal, single-owner authenticated-session tool.** The user is already signed in when registering the email. There is no anonymous registration path where confirmation prevents spam. The primary threat is a typo, which is self-correctable (Google sign-in simply won't work, and the user returns to preferences to fix it — once a "change email" flow exists, or once the dummy-email detection is extended to catch obviously wrong addresses).

3. **No mailer infrastructure beyond the bare `ApplicationMailer` exists.** Production SMTP is configured, but there are no transactional mailer templates (ja/en), no test coverage patterns for mail delivery, and no user expectation of receiving email from the app. Building that pipeline exceeds the feature's scope.

4. **Google OAuth is the natural implicit verification.** If the user registers `foo@gmail.com` and can subsequently sign in with Google OAuth on that account, the email is functionally verified. A mistyped address simply prevents Google sign-in without harming the existing Twitter sign-in path.

5. **Consistency with existing direct-mutation patterns.** 2FA setup (`users/two_factor_setup`) performs a direct `update!` from the preferences surface without secondary confirmation. The app's established convention is in-session direct mutations for single-user settings.

**If confirmation is needed in future** (e.g., the app adds account recovery via email), introduce Devise `:confirmable` at that point with the appropriate migration and mailer templates. Do not pre-build infrastructure for a use case that does not yet exist.
