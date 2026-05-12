---
phase: 58
name: Controller, Route, and Guards
date: 2026-05-13
mode: autonomous (self-discuss)
---

# Phase 58 Discussion Log: Controller, Route, and Guards

*Self-discuss mode — no human present. Claude reasoned through gray areas independently.*

## Areas Discussed

### 1. Route structure and path helper naming

**Question:** Should the controller live under `users/` namespace (like two_factor_setup) or at the top level? Explicit routes or resourceful routing?

**Options considered:**
- `users/` namespace with explicit routes (matching two_factor_setup convention)
- Top-level `email_registrations` resource (matching mastodon_accounts convention)

**Selected:** `users/` namespace with explicit routes.

**Reasoning:** Email is a user credential (like OTP setup). The `two_factor_setup` controller sets the precedent for auth-credential management under `users/`. Explicit routes keep the path helper naming flat and predictable (`users_email_registration_path`). Resourceful routing would generate unused helpers and add indirect naming.

---

### 2. Save mechanism and validation feedback

**Question:** `save!` with rescue vs. `save` with return-value check?

**Options considered:**
- `save!` inside transaction (project default elsewhere) — raises on validation failure, 500 unless rescued
- `save` with `if/else` — returns false on failure, allows re-render with user-facing errors

**Selected:** `save` with `if/else` + inline `rescue ActiveRecord::RecordNotUnique`.

**Reasoning:** Email registration is a user-data-entry flow where validation failure is expected. `save!` is appropriate when failure indicates a programming error (mastodon_accounts, preferences). The inline rescue keeps the `RecordNotUnique` handling scoped to `create` only.

---

### 3. Strong params wrapper

**Question:** Use `:user` (Devise default) or a dedicated `:email_registration` wrapper?

**Options considered:**
- `:user` namespace — consistent with Devise forms elsewhere
- `:email_registration` namespace — dedicated, no collision risk with Devise params

**Selected:** `:email_registration` namespace.

**Reasoning:** Using `:user` risks conflating this controller's narrow email-update purpose with Devise's broader user registration forms. A dedicated namespace makes the form and controller intent unambiguous and prevents accidental permitting of other user attributes.

---

### 4. Guard implementation

**Question:** `rescue_from` at class level vs. inline rescue in `create`?

**Options considered:**
- `rescue_from ActiveRecord::RecordNotUnique` at class level — handles all actions
- Inline `rescue ActiveRecord::RecordNotUnique` in `create` only

**Selected:** Inline rescue in `create`.

**Reasoning:** Only `create` can trigger a DB unique constraint violation. `rescue_from` would create an implicit global handler for an error that only one action can produce — unnecessarily broad scope.

---

### 5. Redirect after success

**Question:** Where to redirect after successful email registration?

**Options considered:**
- `preferences_path` — user lands on account settings page
- `root_path` — home dashboard

**Selected:** `preferences_path`.

**Reasoning:** Consistent with PreferencesController. The user has just updated an account setting; landing on the preferences page lets them verify the change in context.

---

## Deferred Ideas

None — all Phase 58 scope was addressed. Phase 59 (View, Preferences Entry, Locale, Tests) handles the form view, locale strings, and full Minitest coverage.

## Claude's Discretion

- Named path helper follows `users_two_factor_setup` exactly: single named helper for both GET and POST on the same path segment.
- `status: :unprocessable_entity` included on failed re-renders for Rails 7 correctness (even without Turbo).
- Test file placed under `test/controllers/users/` to mirror the controller namespace.
