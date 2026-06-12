# Phase 119: Custom OmniAuth Mastodon Strategy - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped in autonomous mode)

<domain>
## Phase Boundary

Build a working custom OAuth 2.0 OmniAuth strategy that dynamically targets the user's Mastodon instance, registers an OAuth app via `POST /api/v1/apps`, and returns a valid OmniAuth auth hash with `uid` and `info` from `/api/v1/accounts/verify_credentials`. Wire the gem, autoload the strategy, and register `:mastodon` in Devise. This phase does NOT include instance selection UI, `from_omniauth` wiring, or auth page buttons — those are later phases.

</domain>

<decisions>
## Implementation Decisions

### Strategy Architecture
- Use explicit `omniauth-oauth2` gem (~> 1.9) as base class — no third-party Mastodon OmniAuth gems (OAuth 1.0 only)
- Strategy file at `lib/omniauth/strategies/mastodon.rb`, autoloaded via `config.autoload_lib`
- Read `session[:mastodon_instance]` to set `client.site` to `https://{instance}` (no trailing slash)
- Composite uid format deferred to Phase 121 — this phase populates raw Mastodon account id in auth hash; composite uid assembly happens in `from_omniauth`

### Dynamic Client Registration
- Call `POST /api/v1/apps` on the selected instance before authorization redirect to obtain `client_id` and `client_secret`
- Cache registered credentials in session for the OAuth round-trip (instance-specific)
- App registration payload: `client_name`, `redirect_uris`, `scopes` (read scope sufficient for verify_credentials)

### Devise Wiring
- Add `:mastodon` to `User.omniauth_providers` array
- Register strategy in `devise.rb` with `OmniAuth::Strategies::Mastodon` class
- Placeholder client_id/secret in devise config (overridden at runtime by dynamic registration)

### Testing
- Minitest with WebMock stubs for app registration, authorize URL construction, token exchange, and verify_credentials
- No live Mastodon API calls in tests
- Follow existing OAuth test patterns from `omniauth_callbacks_controller_test.rb`

### Claude's Discretion
- Exact session key names for cached client credentials
- Error handling for failed app registration or verify_credentials
- Scope string for Mastodon OAuth app registration

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `omniauth`, `omniauth-rails_csrf_protection` already in Gemfile
- Existing providers: `:google_oauth2`, `:twitter2`, `:facebook` in `devise.rb` and `User.omniauth_providers`
- `OauthIdentity` model with `upsert_for!` (used in Phase 121, not this phase)
- WebMock in test group for HTTP stubbing

### Established Patterns
- Devise OmniAuth config in `config/initializers/devise.rb` lines 255-267
- `User.from_omniauth` case statement per provider in `app/models/user.rb`
- `Users::OmniauthCallbacksController` handles provider callbacks
- Research docs in `.planning/research/` (ARCHITECTURE.md, STACK.md, PITFALLS.md)

### Integration Points
- Strategy must integrate with Warden/Devise OmniAuth middleware
- `session[:mastodon_instance]` will be set by Phase 120 instance form — strategy must read it
- Callback route: `/users/auth/mastodon/callback` (Devise default)

</code_context>

<specifics>
## Specific Ideas

- Reference: `.planning/research/ARCHITECTURE.md` data flow diagram
- Pitfall: Mastodon account IDs are per-instance — composite uid `{instance}:{id}` is Phase 121 scope
- Pitfall: `config.omniauth` runs at boot with fixed URLs — strategy must override `client.site` dynamically from session

</specifics>

<deferred>
## Deferred Ideas

- Instance selection UI form (Phase 120)
- `from_omniauth :mastodon` handler (Phase 121)
- Auth buttons and Connected Accounts UI (Phase 122)
- Cucumber E2E coverage (Phase 123)

</deferred>
