---
phase: 114-oauth-identity-data-layer
fixed_at: 2026-05-24T00:00:00Z
review_path: .planning/phases/114-oauth-identity-data-layer/114-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 5
skipped: 1
status: partial
---

# Phase 114: Code Review Fix Report

**Fixed at:** 2026-05-24T00:00:00Z
**Source review:** .planning/phases/114-oauth-identity-data-layer/114-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01, CR-02, WR-01, WR-02, WR-03, WR-04)
- Fixed: 5
- Skipped: 1

## Fixed Issues

### CR-01 + WR-04: Inline AR classes in backfill migration + raise IrreversibleMigration

**Files modified:** `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb`
**Commit:** 4ee4df0
**Applied fix:** Replaced direct `User` and `OauthIdentity` model references with inline `ActiveRecord::Base` subclasses scoped to the migration (with explicit `self.table_name`). Also replaced the silent no-op `def down; end` with `raise ActiveRecord::IrreversibleMigration` per WR-04.

### CR-02: Add unique index on (provider, uid) in oauth_identities

**Files modified:** `db/migrate/20260524000005_add_provider_uid_index_to_oauth_identities.rb`, `db/schema.rb`
**Commit:** 0ffb089
**Applied fix:** Created new migration `20260524000005_add_provider_uid_index_to_oauth_identities.rb` (version 000005 — 000003 and 000004 were already taken) adding `add_index :oauth_identities, [:provider, :uid], unique: true, name: 'index_oauth_identities_on_provider_and_uid'`. Ran `bin/rails db:migrate` successfully.

### WR-01: Rescue RecordNotUnique with retry in upsert_for!

**Files modified:** `app/models/oauth_identity.rb`
**Commit:** fa85d3c
**Applied fix:** Added `rescue ActiveRecord::RecordNotUnique; retry` around the `save!` call in `upsert_for!`. Concurrent OAuth callbacks that both pass `find_or_initialize_by` before either saves will now retry atomically instead of propagating a 500 to the user.

### WR-03: Add dependent: :destroy to has_many :oauth_identities

**Files modified:** `app/models/user.rb`
**Commit:** 639c25b
**Applied fix:** Changed `has_many :oauth_identities` to `has_many :oauth_identities, dependent: :destroy` so that ActiveRecord callbacks on `OauthIdentity` fire on `user.destroy` (future-proofing for callbacks that may be added later).

## Skipped Issues

### WR-02: User.create → User.create! in facebook/google paths

**File:** `app/models/user.rb:91-98`
**Reason:** Code context (controller design) differs from review assumption. The fix was applied (create → create!), committed, and then reverted after the full test suite revealed two regressions:
- `UserTest#test_facebook_from_omniauth_does_not_match_deleted_user` — raises `RecordInvalid` instead of returning a new user
- `Users::OmniauthCallbacksControllerTest#test_facebook_callback_redirects_to_registration_when_create_fails` — returns 422 instead of redirect

The controller (`handle_callback`) intentionally checks `user.persisted?` to redirect to `new_user_registration_url` when creation fails (e.g. email already taken by a soft-deleted account). Using `create!` breaks this graceful-failure contract. The existing `create` + `persisted?` guard is the intentional design. The REVIEW.md suggestion assumes a different controller design.

**Original issue:** `User.create` (not `create!`) silently returns a non-persisted user on failure, which `sign_in_and_redirect` could mishandle. The controller's `persisted?` check does guard against this; `sign_in_and_redirect` is only called when `persisted?` is true.

---

_Fixed: 2026-05-24T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
