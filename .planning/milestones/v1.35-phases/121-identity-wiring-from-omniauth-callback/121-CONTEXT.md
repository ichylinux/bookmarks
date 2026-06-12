# Phase 121: Identity Wiring — from_omniauth & Callback - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Mode:** Auto-generated from ROADMAP phase 121 and REQUIREMENTS (IDNT-01, IDNT-02, IDNT-03, CTRL-01)

<domain>
## Phase Boundary

Wire Mastodon OAuth success into user identity: `User.from_omniauth` `:mastodon` branch assembles composite uid `instance_domain:account_id`, finds or creates users, and persists via `OauthIdentity.upsert_for!`. Add `Users::OmniauthCallbacksController#mastodon` delegating to shared `handle_callback`. Minitest coverage for create, re-auth, composite format, and upsert idempotency.

Does NOT include auth button styling (Phase 122), Connected Accounts UI (Phase 122), or disconnect guard (Phase 123). `:mastodon` is already registered in Devise/`omniauth_providers` from Phase 119 — verify only, do not duplicate.

</domain>

<decisions>
## Implementation Decisions

### Composite UID Assembly
- Strategy (Phase 119) exposes raw Mastodon account id in `access_token.uid`
- `from_omniauth` builds composite `"{instance}:#{account_id}"` for `oauth_identities.uid`
- Instance domain passed via `access_token.info['instance']` — strategy adds `session[:mastodon_instance]` to info hash at callback time (minimal strategy touch)

### User Lookup & Create
- Find existing user via `OauthIdentity` global unique `(provider, uid)` on `mastodon` + composite uid
- Scope to `User.active` (exclude soft-deleted)
- New users: dummy email `dummy_{uuid}@example.com` (Mastodon verify_credentials does not return email)
- Re-auth: same composite uid → same user; `upsert_for!` updates existing row (idempotent)

### Callback Controller
- `def mastodon; handle_callback('Mastodon'); end` — same pattern as google_oauth2/twitter2/facebook
- No changes to `handle_callback` signature

### Testing
- Unit tests on `User.from_omniauth` with OmniAuth auth hash fixtures (no HTTP)
- Integration test on `/users/auth/mastodon/callback` with OmniAuth test mode
- Follow patterns in `oauth_identity_test.rb` and `omniauth_callbacks_controller_test.rb`

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `User.from_omniauth` case statement — twitter2/facebook/google patterns in `app/models/user.rb`
- `OauthIdentity.upsert_for!` — race-safe upsert from Phase 114
- `Users::OmniauthCallbacksController#handle_callback` — signs in via `User.from_omniauth`
- `lib/omniauth/strategies/mastodon.rb` — raw uid from `raw_info['id']`, session instance keys

### Established Patterns
- Twitter2: find by uid, dummy email on create, `upsert_for!` on every path
- Facebook/Google: find by email; Mastodon finds by composite oauth identity uid instead
- Callback tests use `OmniAuth.config.test_mode` and `mock_auth`

### Integration Points
- Global unique index `index_oauth_identities_on_provider_and_uid` requires composite uid format
- `session[:mastodon_instance]` set by Phase 120 before OAuth redirect

</code_context>

<requirements>
## Requirements Mapped

| ID | Description |
|----|-------------|
| IDNT-01 | `oauth_identities.uid` for `mastodon` stores `instance_domain:account_id` |
| IDNT-02 | `from_omniauth :mastodon` finds by composite uid or creates with dummy email |
| IDNT-03 | Re-auth updates existing `OauthIdentity` via `upsert_for!` |
| CTRL-01 | `OmniauthCallbacksController#mastodon` uses `handle_callback` |

</requirements>

<deferred>
## Deferred Ideas

- Mastodon auth button / Connected Accounts row (Phase 122)
- `DELETE /oauth_identities/mastodon` disconnect guard test (Phase 123)
- Cucumber connected-accounts Mastodon row (Phase 123)

</deferred>
