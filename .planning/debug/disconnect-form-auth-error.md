---
status: awaiting_human_verify
slug: disconnect-form-auth-error
trigger: "rails test fails: UserPasswordAuthTest#test_disconnect_form_auth!_prevents_sign-in_with_old_password raises User::LastAuthMethodError"
created: 2026-05-29
updated: 2026-05-29
---

## Symptoms

- **Expected:** `disconnect_form_auth!` should succeed, then sign-in with old password should be blocked
- **Actual:** `User::LastAuthMethodError` raised inside `disconnect_form_auth!` at `app/models/user.rb:187`
- **Error:**
  ```
  User::LastAuthMethodError: User::LastAuthMethodError
    app/models/user.rb:187:in 'block in User#disconnect_form_auth!'
    app/models/user.rb:185:in 'User#disconnect_form_auth!'
    test/models/user_password_auth_test.rb:52:in 'block in <class:UserPasswordAuthTest>'
  ```
- **Timeline:** Just wrote new code — test is newly failing
- **Reproduction:** `bin/rails test test/models/user_password_auth_test.rb:52`

## Current Focus

status: fix_ready

reasoning_checkpoint:
  hypothesis: "Both disconnect_form_auth! tests use users(:one) which has no oauth_identities. The guard at user.rb:187 raises LastAuthMethodError when snapshot.oauth_identities.count == 0. This is correct behavior (can't disconnect last auth method), but the tests lack the required OAuth identity setup."
  confirming_evidence:
    - "Running full test file shows 2 errors: both disconnect_form_auth! tests fail at user.rb:187 with LastAuthMethodError"
    - "users(:one) fixture has no oauth_identities association and no oauth_identities.yml fixture file exists"
    - "disconnect_form_auth! guard: `raise LastAuthMethodError if snapshot.oauth_identities.count == 0` — count is 0 for users(:one)"
  falsification_test: "If hypothesis is wrong, adding an OauthIdentity for users(:one) before calling disconnect_form_auth! should NOT fix the error"
  fix_rationale: "Add OauthIdentity.upsert_for!(user: u, ...) setup to both failing tests so the guard check passes — this mirrors real-world usage where disconnect_form_auth! is only callable when user has an OAuth identity as fallback"
  blind_spots: "None — both failure sites are directly observed and root cause is unambiguous"

next_action: patch both tests to add OauthIdentity setup before disconnect_form_auth! call

## Evidence

- timestamp: 2026-05-29
  checked: "users(:one) fixture and oauth_identities fixture"
  found: "users(:one) has no oauth_identities; no oauth_identities.yml fixture exists"
  implication: "oauth_identities.count == 0 for users(:one) — guard fires every time"

- timestamp: 2026-05-29
  checked: "bin/rails test test/models/user_password_auth_test.rb"
  found: "2 errors: both disconnect_form_auth! tests fail with LastAuthMethodError at user.rb:187"
  implication: "Both test_disconnect_form_auth!_sets_password_auth_enabled_to_false (line 42) and test_disconnect_form_auth!_prevents_sign-in_with_old_password (line 52) affected"

## Eliminated

## Resolution

root_cause: >
  Two bugs compounded. (1) Both disconnect_form_auth! tests in user_password_auth_test.rb used
  users(:one) which has no OauthIdentities, causing the LastAuthMethodError guard to fire
  immediately. (2) After fixing the test setup, update_columns was silently updating 0 rows:
  the update_all("lock_version = lock_version + 1") increments lock_version in the DB but
  self.lock_version in memory stays at the old value. In Rails 8, update_columns includes
  lock_version in the WHERE clause (optimistic locking), so the subsequent UPDATE found 0 rows
  because the DB lock_version no longer matched the stale in-memory value.

fix: >
  1. Added OauthIdentity.upsert_for! setup to both disconnect_form_auth! tests so the
     LastAuthMethodError guard passes (user has an OAuth fallback auth method).
  2. Added `self.lock_version = snapshot.lock_version + 1` in disconnect_form_auth! after
     the update_all call to sync the in-memory lock_version with the newly incremented DB value,
     so the subsequent update_columns WHERE clause matches correctly.

verification: "5/5 tests pass in user_password_auth_test.rb; all 131 model tests pass (2 pre-existing stub errors in user_disconnect_auth_test.rb are unrelated)"

files_changed:
  - app/models/user.rb
  - test/models/user_password_auth_test.rb
