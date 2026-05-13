---
phase: 57
name: Model Validation Foundation
date: 2026-05-13
mode: autonomous (self-discuss)
---

# Phase 57 Discussion Log

## Mode

Self-discuss — no human present. Claude identified gray areas, reasoned through each, and made opinionated choices.

## Areas Discussed

### 1. Validator implementation style

**Options considered:**
- A: Inline `validates` in User model (consistent with all project models)
- B: Custom validator class in `app/validators/`

**Decision:** A — inline. All existing validators (`Bookmark`, `Note`, `Preference`, `MastodonAccount`, `Portal`) use inline `validates`. A custom class adds a file for a single regex check.

---

### 2. Regex anchoring

**Options considered:**
- A: `\A`/`\z` anchors with escaped `.` — string boundary, secure
- B: `^`/`$` anchors matching `has_valid_email?` — line boundary, slightly simpler

**Decision:** A — `\A`/`\z` with `example\.com`. Rails validation best practice; prevents multi-line bypass. `has_valid_email?` left unchanged — different purpose (display/guard logic, not security validation).

---

### 3. Error message key

**Options considered:**
- A: Custom key `:dummy_email` (locale strings deferred to Phase 59)
- B: No custom key — let Devise format error "is invalid" apply

**Decision:** A — `:dummy_email`. Gives Phase 59 a clean hook to add specific ja/en user-facing wording. Falls back gracefully to format error text if key is absent.

---

### 4. Twitter dummy-email fixture

**Options considered:**
- A: Named fixture `twitter_user` with deterministic email (recommended)
- B: Build `User.new` inline in each test

**Decision:** A — named fixture `twitter_user` with `dummy_00000000-0000-0000-0000-000000000001@example.com`. Controller integration tests in Phase 58+ need a fixture that survives `fixtures :users`; inline `User.new` would not be available across test files. Deterministic email avoids random values in VCS.

---

### 5. Test file

**Options considered:**
- A: Create `test/models/user_test.rb` (new file)
- B: Add tests to `test/models/user_two_factor_test.rb`

**Decision:** A — new file. Separation of concerns: 2FA tests are distinct from validation tests. Class name `UserTest`, four tests covering dummy reject on update, format reject on update, valid accept on update, dummy accept on create.

## Deferred / Out of Scope

- Locale keys for `:dummy_email` message — Phase 59 (I18N-01)
- Fixing `has_valid_email?` regex anchoring — pre-existing code, not in Phase 57 scope; separate cleanup task if needed
- PITFALL-02 (`from_omniauth` Twitter uses `name` not `uid`) — pre-existing bug, explicitly out of v1.17 scope (per STATE.md decisions)
