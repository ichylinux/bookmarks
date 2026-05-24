---
phase: 114-oauth-identity-data-layer
verified: 2026-05-24T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 114: OAuth Identity Data Layer Verification Report

**Phase Goal:** Every successful OAuth sign-in is durably recorded in a dedicated `oauth_identities` table, all three providers are wired, and existing X-linked accounts are backfilled — giving the app a single authoritative source for linked provider state.
**Verified:** 2026-05-24
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `oauth_identities` table exists with unique index on `(user_id, provider)` and FK to `users` | VERIFIED | `db/schema.rb` line 57-66: `create_table "oauth_identities"` with `t.bigint "user_id", null: false`, `t.string "provider", null: false`, `t.string "uid", null: false`, `t.index ["user_id", "provider"], name: "index_oauth_identities_on_user_id_and_provider", unique: true`; FK via `t.references :user, foreign_key: true` in migration |
| 2 | `OauthIdentity` model validates presence of `provider` and `uid`; validates uniqueness of `provider` scoped to `user_id` | VERIFIED | `app/models/oauth_identity.rb` lines 4-6: `validates :provider, presence: true`, `validates :uid, presence: true`, `validates :provider, uniqueness: { scope: :user_id }` |
| 3 | `User.from_omniauth` calls `OauthIdentity.upsert_for!` in all three provider branches (only when user is persisted) | VERIFIED | `app/models/user.rb` line 72 (twitter2 existing-user path, guarded by `user.persisted?`), line 86 (twitter2 new-user path, no guard needed — `create!` always persists), line 92 (facebook, guarded by `user.persisted?`), line 97 (google_oauth2 else branch, guarded by `user.persisted?`) |
| 4 | Backfill migration is idempotent | VERIFIED | `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb` uses `find_or_create_by!` with inline model classes; unique index on `(user_id, provider)` prevents duplicate rows. Both migrations show `up` in `db:migrate:status`. Note: implementation uses `find_or_create_by!` instead of plan-specified `insert_all` with `unique_by:` — functionally equivalent for idempotency; SUMMARY documents this deviation. |
| 5 | Minitest covers model validations, upsert for each provider, backfill idempotency — all passing | VERIFIED | `test/models/oauth_identity_test.rb` has 10 test methods; `bin/rails test test/models/oauth_identity_test.rb` exits 0: "10 runs, 26 assertions, 0 failures, 0 errors, 0 skips" |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `db/migrate/20260524000001_create_oauth_identities.rb` | Schema migration creating `oauth_identities` table | VERIFIED | Exists; creates table with `user_id`, `provider`, `uid`, timestamps; adds unique index on `(user_id, provider)` |
| `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb` | Idempotent backfill of X-linked users | VERIFIED | Exists; uses inline model classes + `find_or_create_by!`; `up` in migrate:status |
| `app/models/oauth_identity.rb` | `OauthIdentity` model with validations and `upsert_for!` | VERIFIED | Exists; `belongs_to :user`, presence validations, uniqueness validation, `upsert_for!` class method using `find_or_initialize_by` + `save!` with `RecordNotUnique` rescue-retry |
| `app/models/user.rb` (modified) | All three provider branches call `OauthIdentity.upsert_for!` | VERIFIED | Lines 72, 86, 92, 97 each call `OauthIdentity.upsert_for!`; also adds `has_many :oauth_identities, dependent: :destroy` |
| `test/models/oauth_identity_test.rb` | 9+ Minitest cases covering validations, upsert, provider branches, idempotency | VERIFIED | 10 test methods; all passing |
| `db/schema.rb` (modified) | Contains `create_table "oauth_identities"` with correct columns and index | VERIFIED | Lines 57-66 contain all required columns and indexes |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `User.from_omniauth` `:twitter2` existing-user branch | `OauthIdentity.upsert_for!` | Direct call line 72, guarded by `user.persisted?` | WIRED | Confirmed in `app/models/user.rb` |
| `User.from_omniauth` `:twitter2` new-user branch | `OauthIdentity.upsert_for!` | Direct call line 86 (no guard — `create!` never returns unpersisted) | WIRED | Confirmed in `app/models/user.rb` |
| `User.from_omniauth` `:facebook` branch | `OauthIdentity.upsert_for!` | Direct call line 92, guarded by `user.persisted?` | WIRED | Confirmed in `app/models/user.rb` |
| `User.from_omniauth` `else` (google_oauth2) branch | `OauthIdentity.upsert_for!` | Direct call line 97, guarded by `user.persisted?` | WIRED | Confirmed in `app/models/user.rb` |
| Backfill migration | `users` table (source) | Inline `User` model, queries `provider IS NOT NULL AND uid IS NOT NULL` | WIRED | Uses inline model classes immune to live model changes |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase creates a data recording layer (no rendering components). `OauthIdentity.upsert_for!` writes to DB; no component renders the data in this phase.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Minitest suite for OauthIdentity | `bin/rails test test/models/oauth_identity_test.rb` | 10 runs, 26 assertions, 0 failures, 0 errors, 0 skips | PASS |
| Full Minitest suite | `bin/rails test` | 587 runs, 2554 assertions, 0 failures, 0 errors, 0 skips | PASS |
| ESLint | `yarn run lint` | Exit 0, no errors | PASS |
| Migrations up | `bin/rails db:migrate:status` (grep oauth/backfill) | Both 20260524000001 and 20260524000002 show `up` | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| IDNT-01 | 114-01-PLAN.md | `oauth_identities(user_id, provider, uid)` table stores one row per linked OAuth provider per user | SATISFIED | `db/schema.rb` has `create_table "oauth_identities"` with `user_id`, `provider`, `uid`; unique index on `(user_id, provider)` enforces one-row-per-provider-per-user |
| IDNT-02 | 114-01-PLAN.md | `from_omniauth` creates or updates an `OauthIdentity` row on each successful sign-in (all 3 providers: google_oauth2, twitter2, facebook) | SATISFIED | `app/models/user.rb` lines 72, 86, 92, 97 call `OauthIdentity.upsert_for!` in all three provider branches; tests verify create (new user) and update (existing user) paths for each provider |
| IDNT-03 | 114-01-PLAN.md | Existing X-linked accounts backfilled from `users.provider` / `users.uid` via migration | SATISFIED | `db/migrate/20260524000002_backfill_oauth_identities_from_users.rb` queries `users WHERE provider IS NOT NULL AND uid IS NOT NULL` (X-linked users); migration shows `up` |

All three requirements assigned to Phase 114 in REQUIREMENTS.md traceability table are satisfied.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

Scanned all 6 modified/created files. No TBD, FIXME, XXX, placeholder, or stub patterns found. No hardcoded empty returns. The `rescue ActiveRecord::RecordNotUnique; retry` in `OauthIdentity.upsert_for!` is correct defensive code, not a stub.

---

### Implementation Deviations (Non-blocking)

Three deviations from plan were noted in SUMMARY.md. All were evaluated:

**1. `upsert_for!` uses `find_or_initialize_by` + `save!` instead of `find_or_create_by!` + `update!`**
Assessment: Functionally equivalent. Both create if absent, update if present. Added `rescue ActiveRecord::RecordNotUnique; retry` for race safety — strictly more robust than the plan.

**2. Backfill uses `find_or_create_by!` per-row instead of `insert_all` with `unique_by:`**
Assessment: Both are idempotent. PLAN must-have is "idempotent backfill" — that property is achieved. The `insert_all` mechanism was specified in the parenthetical, not as the only acceptable path. CONTEXT D-11 did specify `insert_all` but this is an implementation decision within the planner's discretion. The inline model class pattern used is safer (immune to live model changes).

**3. `has_many :oauth_identities, dependent: :destroy` added to User**
Assessment: CONTEXT D-14 deferred this to Phase 116/118. SUMMARY notes it was added because `purge!` already referenced `OauthIdentity.where(user_id:).delete_all`. The association is additive and correct. No negative impact.

None of these deviations block the phase goal. All are documented by the executor.

---

### Human Verification Required

None — this is a data layer phase with no UI changes. All behavior is verifiable programmatically via model tests and migration status.

---

## Gaps Summary

No gaps. All five must-haves are verified, all three requirement IDs (IDNT-01, IDNT-02, IDNT-03) are satisfied, the Minitest suite passes (10 tests, 587 total), lint is clean, and all migrations are `up`. The phase goal is achieved.

---

_Verified: 2026-05-24_
_Verifier: Claude (gsd-verifier)_
