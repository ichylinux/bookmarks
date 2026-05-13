# Pitfalls Research — Email Registration for X/Twitter Users

**Domain:** Adding email registration to an existing Devise + OmniAuth app where some users hold dummy emails
**Researched:** 2026-05-13
**Overall confidence:** HIGH (codebase directly inspected; Devise source and community patterns verified)

---

## Summary

Twitter/X OAuth users in this app were created with a `dummy_<uuid>@example.com` address because Twitter does not return a real email via OAuth. Adding a flow to let those users register a real email is a security-sensitive operation: the new email immediately becomes the key used by `from_omniauth` to match Google OAuth sign-ins. The three dominant risk categories are (1) account takeover via email collision with an existing Google-authenticated account, (2) Devise `:validatable` / `password_required?` interaction that will unexpectedly fire password validations when saving only the email, and (3) the name-based Twitter lookup in `from_omniauth` that can silently misroute users who share a display name.

---

## Critical Pitfalls

### PITFALL-01: Account Takeover via Email Collision with Existing Google User

**What goes wrong:**
A Twitter user submits an email address that already belongs to a different account created via Google OAuth. The current `from_omniauth` for Google uses `User.where(email: data["email"]).first` — once the Twitter user saves that email, their account *becomes* the match target for the Google OAuth flow. The legitimate Google account owner is now locked out or silently merged into the Twitter user's account.

**Why it happens:**
The collision check during email update would be a model-level uniqueness validation (`validates_uniqueness_of :email` from `:validatable`). That validation prevents duplicate `INSERT` and `UPDATE`, but it does not enforce that the *type* of account owning the email is compatible. The `from_omniauth` logic does not distinguish "this existing user owns a Google identity" from "this user has set an email that happens to match" — it just does `where(email:).first`.

**From the codebase (user.rb line 29):**
```ruby
user = User.where(email: data["email"]).first
user ||= User.create(email: data['email'], password: Devise.friendly_token[0,20])
```
After the Twitter user updates their email to `alice@gmail.com`, Google OAuth for `alice@gmail.com` will log Alice into the Twitter user's account — silently, with no warning.

**Severity:** CRITICAL — this is an account takeover vector.

**Prevention:**
- When a Twitter user submits a new email, check whether a user already exists with that email (`User.where(email: new_email).where.not(id: current_user.id).exists?`). This is the same check `:validatable` would do, but surface it explicitly with a user-facing message: "This email is already registered to another account."
- The database already has `UNIQUE INDEX` on `email` (schema.rb line 117), so the DB will reject a duplicate on `save!` regardless. But the user experience needs an app-level guard before the uniqueness exception bubbles up.
- No implicit account merging — the Twitter user setting an email that collides with a Google user should fail loudly, not silently reroute.

**Phase:** Email validation phase (model / controller). Must be in place before any UI is shipped.

---

### PITFALL-02: `from_omniauth` Twitter Lookup Uses `name`, Not `uid`

**What goes wrong:**
The current `from_omniauth` for Twitter (user.rb lines 25–27) does `User.where(name: data["name"]).first`. Twitter display names are not unique — two users can have the display name "John Smith". If two distinct Twitter accounts with the same display name exist, the first one registered captures all future logins for anyone with that name.

More critically for this milestone: if the Twitter user *changes* their display name on Twitter between visits, `from_omniauth` creates a new account instead of finding the existing one, leaving the user with two accounts and orphaned data.

**From the codebase (schema.rb line 118):** `index_users_on_name` is UNIQUE in the DB. This means two Twitter users with the same display name cannot both be stored — the second create attempt raises a DB exception with a confusing error.

**Severity:** HIGH — this is a pre-existing correctness bug that becomes more visible once email is attached, because the orphaned new account will have no email and users will wonder why their registered email is gone.

**Prevention:**
- This is technically out of scope for v1.17, but v1.17 must not *worsen* it. The email update flow should be gated to `current_user` (the signed-in user) and write via `current_user.update(email: ...)`, not re-resolve by name.
- The fix for `from_omniauth` (use `uid` + `provider` columns — both exist in the schema) should be logged as a separate task. The `uid` and `provider` columns exist on `users` but are not used in the Twitter branch.
- Do not attempt to fix `from_omniauth` in the same PR as the email registration feature — the scope creep risk is high.

**Phase:** Flag as pre-existing risk. Phase notes for v1.17 should document the dependency.

---

### PITFALL-03: Skipping Email Confirmation Allows Unverified Ownership Claims

**What goes wrong:**
If the email update is accepted and persisted without confirming that the submitting user controls the new email address, any user can claim any email (subject only to uniqueness). An attacker who knows `alice@gmail.com` already has a Bookmarks account via Google can register a Twitter account, log in, and try to claim `alice@gmail.com` — the uniqueness constraint blocks them, but without confirmation email there is no *verified-ownership* gate.

More practically for v1.17's single-user persona: the app does not currently use Devise `:confirmable`, and adding it mid-flight requires a DB migration (`confirmation_token`, `confirmed_at`, `confirmation_sent_at` columns) plus mailer configuration. Without `ActionMailer` + SMTP configured correctly, confirmable silently fails or raises on production.

**From the codebase:** `devise.rb` uses `config.mailer_sender = ENV['SMTP_FROM'] || 'from@example.com'`. The fallback `from@example.com` indicates mailer may not be configured for production.

**Severity:** HIGH if this is a multi-user app; MEDIUM for a personal/small-group app.

**Options:**
1. **Immediate-accept with collision guard only** — simpler, sufficient for a personal app. Accept the new email if unique, persist immediately, rely on the uniqueness constraint to block collisions. No mailer dependency.
2. **Confirmation flow** — set `unconfirmed_email`, send confirmation email, switch on click. Requires `:confirmable` + SMTP. Adds significant complexity; requires the v1.17 roadmap to include mailer setup as a prerequisite.

**Recommendation:** For v1.17, use option 1 (immediate-accept with collision guard). Document the trade-off. Confirmable can be added as a future milestone if the user base grows.

**Phase:** Decision must be explicit at the start of the milestone (before any code is written).

---

## Devise-Specific Pitfalls

### PITFALL-04: `password_required?` Fires on Email-Only Update

**What goes wrong:**
Devise `:validatable` includes:
```ruby
def password_required?
  !persisted? || !password.nil? || !password_confirmation.nil?
end
```
This returns `false` for a persisted user with no password change — which is the intended behavior. However, the `PreferencesController` currently calls `@user.save!` inside a transaction. If the email field is added to the preferences form and the form accidentally submits an empty `password` param, `password_required?` returns `true`, triggering `validates_length_of :password` and `validates_confirmation_of :password_confirmation`, which fail.

**From the codebase (`preferences_controller.rb` lines 42–51):**
```ruby
def user_params
  params.require(:user).permit([
    :name,
    preference_attributes: [...]
  ])
```
`email` is not currently permitted. If it is added naively to this whitelist without isolating it in its own form/controller, and any other form field sends an empty string for `password`, the save will fail with cryptic validation errors.

**Prevention:**
- Use a dedicated controller action and form for the email update — do not add `email` to the existing `user_params` in `PreferencesController`.
- In the dedicated controller, permit only `[:email]`. Use `@user.update(email: params[:user][:email])` and let Devise's validations run normally.
- Never permit `:password` or `:password_confirmation` in the email-update path.

**Phase:** Controller design phase.

---

### PITFALL-05: `has_valid_email?` Regex is the Only Guard; Must Also Validate on Write

**What goes wrong:**
`has_valid_email?` (user.rb lines 43–47) checks `/^dummy_.+@example.com$/` to detect dummy emails for display purposes. This is a read-path check. It does NOT prevent someone from saving a new email that matches the dummy pattern (e.g., a user manually entering `dummy_foo@example.com`). Devise's `:validatable` validates format and uniqueness but does not block dummy-pattern addresses.

**Prevention:**
- Add a model validation that rejects the dummy pattern on write:
  ```ruby
  validates :email, format: { without: /\Adummy_.+@example\.com\z/,
    message: :invalid }
  ```
- Keep `has_valid_email?` for display logic, but do not rely on it for write-path security.
- The regex anchors matter: `^` and `$` in Ruby match line start/end (not string start/end). Use `\A` and `\z` in validators to avoid multiline bypass.

**Phase:** Model validation phase.

---

### PITFALL-06: Devise `:validatable` Email Uniqueness Is Application-Level Only (but DB backs it up)

**What goes wrong:**
`validates_uniqueness_of :email` in Devise checks uniqueness with a `SELECT` before the `UPDATE`. Under concurrent requests this is a TOCTOU race: two simultaneous requests with the same new email can both pass the check and one will raise `ActiveRecord::RecordNotUnique` on the DB.

**From the codebase:** The `index_users_on_email` UNIQUE index exists (schema.rb line 117). The DB will enforce uniqueness at insert time. The risk is a 500 error rather than a duplicate row.

**Prevention:**
- Rescue `ActiveRecord::RecordNotUnique` in the email-update controller action and re-render the form with a user-facing collision message.
- This is a very low probability event for a personal app but the defensive code is cheap.

**Phase:** Controller error-handling phase.

---

### PITFALL-07: `save!` vs `save` in `PreferencesController` Transaction

**What goes wrong:**
`PreferencesController#create` and `#update` call `@user.save!` inside a transaction. This means validation failures raise `ActiveRecord::RecordInvalid` rather than returning `false`. The controller does not rescue this exception — it would propagate as a 500.

Adding email to any save path that uses `save!` without catching `RecordInvalid` means a duplicate email or format error shows a generic Rails error page instead of a form with errors.

**Prevention:**
- The dedicated email-update action should use `@user.save` (not `save!`) and render the form with `@user.errors` on failure.
- Alternatively, rescue `ActiveRecord::RecordInvalid` and render errors. Do NOT silently add `email` to the existing `save!` path in `PreferencesController` without also wrapping it in rescue.

**Phase:** Controller design phase. Must be explicit.

---

## Account Linking Edge Cases

### EDGE-01: Twitter User Sets Email That Matches Existing Google Account (Core Scenario)

**Full flow analysis:**

1. Alice has a Google OAuth account with `alice@gmail.com` (User A).
2. Bob signs in via Twitter, gets `dummy_<uuid>@example.com` (User B).
3. Bob is actually also Alice, or Bob wants to steal Alice's data.
4. Bob registers `alice@gmail.com` as their email on User B.

**With collision guard (PITFALL-01 prevention in place):**
- Step 4 fails — uniqueness check finds User A owns `alice@gmail.com`.
- Bob sees "This email is already registered to another account."
- User A is not affected.

**Without collision guard:**
- Step 4 succeeds. User B now has `alice@gmail.com`.
- Next time Alice signs in via Google, `from_omniauth` finds User B by email and signs Alice into Bob's account.
- All of Alice's bookmarks, notes, portals are gone from her perspective; she is now in Bob's account.

**Result:** Collision guard (PITFALL-01) fully prevents this scenario. The `UNIQUE INDEX` ensures only one user can hold a given email, but the app-level error message is what makes the failure legible to the user.

---

### EDGE-02: User Has Both Twitter and Google Accounts — Wants to Link Them

**Flow:**
1. User has a Twitter account (User T, dummy email).
2. Same user also signed up separately via Google OAuth (User G, `user@gmail.com`).
3. User T registers `user@gmail.com` → blocked by collision guard.
4. User is now stuck: they can't link their accounts; they have two separate accounts.

**Why this is hard:**
The app does not have an "identity linking" concept — each user record is one account. Merging two existing accounts requires migrating all associated data (bookmarks, notes, portals, portals_layouts, todos, feeds, mastodon_accounts) from one user to the other and deleting the source record. This is a non-trivial data migration.

**Recommendation for v1.17:** Do NOT attempt account merging. The v1.17 scope is for Twitter users who do not have a separate Google account. Document this explicitly as a known limitation. Surface the "email already registered" error clearly. If account merging is needed in the future, it is a separate milestone.

**Prevention:** The collision guard (PITFALL-01) already produces the right behavior (fail loudly). Add a comment in the UI for the "already registered" error case suggesting the user contact support or sign in via Google with the existing account.

---

### EDGE-03: Google `from_omniauth` After Email Registration — Provider/UID Not Stored

**What goes wrong:**
After the Twitter user registers `alice@gmail.com`, they expect to be able to sign in via Google. `from_omniauth` for Google does `User.where(email: data["email"]).first` — this will find the existing Twitter-originated user record and sign them in. This is the intended behavior.

However, the `provider` and `uid` columns on the user record will still reflect the original Twitter values (or may be blank — the current `from_omniauth` does not write `provider`/`uid` to the user record for either provider). There is no record that this user has a verified Google identity.

**Implication:**
- The Google sign-in works but leaves no audit trail of the linking.
- If `from_omniauth` is later modified to use `uid` + `provider` for lookup (the correct fix for PITFALL-02), users who only linked via email will break because no `uid` + `provider` pair is stored for Google.

**Prevention:**
- For v1.17, the current email-based Google lookup is sufficient and intentional. Document that `provider`/`uid` are not being used for account identity right now.
- If `from_omniauth` is ever refactored to use `uid` + `provider`, that refactor must also handle the "email-linked, no uid" case.

---

### EDGE-04: Email Case Sensitivity Mismatch Between Twitter User Input and Google OAuth

**What goes wrong:**
The user registers `Alice@Gmail.com` (mixed case). Google OAuth returns `alice@gmail.com` (lowercase). Devise has `config.case_insensitive_keys = [:email]` — emails are downcased on save. So the stored value is `alice@gmail.com`. When Google OAuth comes back with `alice@gmail.com`, the match works.

**Confirmed safe:** `config.case_insensitive_keys = [:email]` is set in `devise.rb` line 51. Devise downcases the email on assignment. The `UNIQUE INDEX` in MySQL uses `utf8mb4_general_ci` collation (schema.rb), which is case-insensitive. Both layers agree.

**Action:** No action needed. Document that this is safe.

---

### EDGE-05: User Submits Dummy-Pattern Email as Their "Real" Email

**What goes wrong:**
A user deliberately (or accidentally) enters `dummy_someuuid@example.com` as their registered email. `has_valid_email?` would return `false` for this address, so `display_name` would continue showing their Twitter name rather than the email — a confusing inconsistency.

**Prevention:** PITFALL-05 (reject dummy pattern on write) covers this. The model validation blocks it before save.

---

## Prevention Strategies

| Pitfall | Phase | Strategy |
|---------|-------|----------|
| PITFALL-01: Email collision → account takeover | Model + Controller | App-level uniqueness check with user-facing error; DB UNIQUE INDEX is the fallback |
| PITFALL-02: Twitter name-based lookup | Pre-existing risk | Do not fix in v1.17; use `current_user` for all email update writes; log as separate task |
| PITFALL-03: No email confirmation | Architecture decision | Decide before coding: immediate-accept (recommended) vs confirmable + SMTP |
| PITFALL-04: `password_required?` fires on email save | Controller design | Dedicated controller + form for email; never mix with preferences form |
| PITFALL-05: Dummy pattern writable | Model validation | `validates :email, format: { without: /\Adummy_.+@example\.com\z/ }` |
| PITFALL-06: TOCTOU race on uniqueness | Controller error handling | Rescue `ActiveRecord::RecordNotUnique`; render form with error |
| PITFALL-07: `save!` propagates 500 on validation error | Controller design | Use `save` not `save!` in email-update action; render form with `@user.errors` |
| EDGE-01: Google collision → account takeover | Same as PITFALL-01 | Collision guard is sufficient |
| EDGE-02: Two accounts wanting to merge | Scope | Out of scope for v1.17; document as known limitation |
| EDGE-03: provider/uid not updated after Google link | Documentation | Document; flag for future `from_omniauth` refactor |
| EDGE-04: Email case mismatch | Already safe | `case_insensitive_keys` + MySQL `utf8mb4_general_ci` handle this |
| EDGE-05: User submits dummy-pattern email | Model validation | Covered by PITFALL-05 |

---

## Phase-Specific Warnings

| Phase Topic | Highest Risk | Mitigation |
|-------------|-------------|------------|
| Model validation | Dummy-pattern email writable; regex anchor bugs | Use `\A`/`\z` not `^`/`$`; test the dummy pattern write path explicitly |
| Controller (email update action) | `save!` → 500; `password_required?` → cryptic error | Dedicated action; `save` not `save!`; never permit `:password` |
| `from_omniauth` interaction | Twitter user's new email triggers Google login for wrong account | Collision guard must land before UI ships |
| Preferences form | Inadvertently including `:email` in existing `user_params` | Do not modify `PreferencesController#user_params`; use separate controller |
| Test suite | No fixture for Twitter-style user (dummy email) | Add a fixture user with `email: "dummy_<uuid>@example.com"` and `name: "TwitterUser"` |
| Cucumber E2E | Twitter OAuth flow is mocked; email update flow may not be | Add dedicated feature file for the email registration scenario |

---

## Sources

- Devise validatable source: https://github.com/heartcombo/devise/blob/main/lib/devise/models/validatable.rb
- Devise wiki — allow users to edit without password: https://github.com/heartcombo/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password
- OmniAuth overview (Devise wiki): https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview
- OAuth account linking security (NextAuth discussion): https://github.com/nextauthjs/next-auth/discussions/2808
- OAuth account linking fails — email case: https://github.com/better-auth/better-auth/issues/7806
- Rails uniqueness race condition + DB constraint: https://rietta.com/blog/validates-uniqueness-race-condition-in-ruby-on-rails/
- Auth0 user account linking best practices: https://auth0.com/docs/manage-users/user-accounts/user-account-linking
- Twitter OAuth no email: https://github.com/pocketbase/pocketbase/discussions/2497
