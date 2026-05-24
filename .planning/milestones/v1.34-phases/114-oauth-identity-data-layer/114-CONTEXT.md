# Phase 114: OAuth Identity Data Layer - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a dedicated `oauth_identities` table to durably record each OAuth sign-in: one row per linked provider per user. Wire all three providers (google_oauth2, twitter2, facebook) in `User.from_omniauth` to upsert a row on every successful sign-in. Backfill existing twitter2-linked users from `users.provider`/`users.uid`. Minitest covers model validations, per-provider upsert paths, and backfill idempotency.

No UI changes in this phase. No disconnect logic. No form-auth column.

</domain>

<decisions>
## Implementation Decisions

### Schema
- **D-01:** Migration creates `oauth_identities(id bigint PK, user_id bigint NOT NULL FK→users, provider varchar NOT NULL, uid varchar NOT NULL, created_at, updated_at)` — Rails standard timestamps
- **D-02:** Unique index on `(user_id, provider)` — one row per provider per user; enforced at DB and model layers
- **D-03:** Provider stored as the OmniAuth provider string verbatim: `'google_oauth2'`, `'twitter2'`, `'facebook'`

### Upsert Strategy
- **D-04:** Use `OauthIdentity.find_or_create_by!(user_id: user.id, provider:)` then `update!(uid:)` — readable Rails idiom; unique index acts as guard
- **D-05:** Extract to class method `OauthIdentity.upsert_for!(user:, provider:, uid:)` — single call site per branch in `from_omniauth`

### from_omniauth Integration
- **D-06:** In each branch of `User.from_omniauth` (twitter2, facebook, google/else), call `OauthIdentity.upsert_for!(user:, provider: access_token['provider'], uid: access_token.uid.to_s)` immediately before the `return user` / `user` value — works for both new-user create and existing-user find paths
- **D-07:** UID sourced from `access_token.uid.to_s` for all providers — OmniAuth always provides uid regardless of provider
- **D-08:** If user creation fails (e.g. facebook `User.create` returns invalid user), skip identity upsert — don't add `upsert_for!` unless user is persisted (`user.persisted?`)

### Backfill Migration
- **D-09:** Separate data migration file (later timestamp) — keeps schema change auditable independently from data change
- **D-10:** Backfill scope: `users WHERE provider IS NOT NULL AND uid IS NOT NULL` — covers all existing twitter2-linked users; google/facebook did not historically save provider/uid to users table so coverage is narrow but correct
- **D-11:** Backfill uses `insert_all` with `unique_by: [:user_id, :provider]` to be idempotent — safe to re-run
- **D-12:** Backfill sets `created_at`/`updated_at` to `users.created_at` so identity rows have plausible timestamps

### Model
- **D-13:** `OauthIdentity` validates presence of `provider` and `uid`; validates uniqueness of `provider` scoped to `user_id` (mirrors DB index)
- **D-14:** `belongs_to :user` only — no inverse has_many on User in this phase (added when needed)

### Claude's Discretion
- Migration naming convention: follow existing timestamp pattern (`YYYYMMDD######_description`)
- No `dependent: :destroy` on User in this phase — cascade deletion for oauth_identities will be wired in Phase 116 or 118 when purge/disconnect is implemented (or added to existing `purge!` method)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — IDNT-01, IDNT-02, IDNT-03 are the v1 requirements for this phase
- `.planning/ROADMAP.md` Phase 114 section — success criteria (5 items)

### Existing OAuth code
- `app/models/user.rb` — `from_omniauth` method; understand all three provider branches before adding upsert calls
- `db/schema.rb` — `users` table has `provider` (string) and `uid` (string, unique index); `oauth_identities` does NOT exist yet

### Migration patterns
- `db/migrate/20260522000001_add_manually_added_to_x_accounts.rb` — recent additive migration example
- `db/migrate/20260519100427_add_oauth2_columns_to_users.rb` — recent users-table migration example

### Testing patterns
- `test/models/` — model test location
- `test/support/webmock.rb` — WebMock config (not needed for this phase — no HTTP calls)
- Prior Minitest fixtures at `test/fixtures/users.yml` — understand fixture structure for model test setup

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crud::ByUser` concern (on XAccount, Note, etc.) — NOT applicable here; OauthIdentity scoped by user but no soft-delete needed
- `User.active` scope — already excludes deleted users; `from_omniauth` uses it to prevent deleted-user re-auth

### Established Patterns
- All three OmniAuth provider branches in `from_omniauth` return `user` at the end — upsert_for! call goes immediately before the implicit return
- Facebook and google (else) branches use `User.create` (not `create!`) — check `user.persisted?` before upserting identity
- Twitter2 branch uses `User.create!` — always persisted if no exception

### Integration Points
- `app/models/user.rb` `from_omniauth` — three `when` branches each need `OauthIdentity.upsert_for!` call
- New `app/models/oauth_identity.rb` model
- New migration files (schema + data backfill)
- New `test/models/oauth_identity_test.rb`

</code_context>

<specifics>
## Specific Ideas

- Twitter2 is the only provider that currently saves `provider` + `uid` to the `users` table — google and facebook historically did not. Backfill targets twitter2-linked rows only in practice.
- The `users.uid` column has a unique index — this means only ONE user per uid. The `oauth_identities.uid` column has no unique constraint across users (different users could theoretically share a uid if they used different providers, but the `(user_id, provider)` unique index prevents duplicates per user/provider pair).

</specifics>

<deferred>
## Deferred Ideas

- `has_many :oauth_identities` on User — deferred to Phase 116 when controller needs it
- `dependent: :destroy` for oauth_identities cascade — wire in Phase 118 test phase or when purge! is extended
- None from discussion — scope stayed within phase boundary

</deferred>

---

*Phase: 114-OAuth Identity Data Layer*
*Context gathered: 2026-05-24*
