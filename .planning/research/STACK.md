# Stack Research: Mastodon OAuth 2.0 Sign-In

**Milestone:** v1.35 — Sign in with Mastodon using OAuth2
**Date:** 2026-06-12

## Existing Stack (unchanged)

- Rails 8.1, Ruby 3.4, Devise + `omniauthable`
- `omniauth`, `omniauth-rails_csrf_protection` already in Gemfile
- `omniauth-oauth2` 1.9.0 already present transitively via `omniauth-google-oauth2` / `omniauth-facebook`

## Additions Required

| Gem / Component | Version | Purpose |
|-----------------|---------|---------|
| `omniauth-oauth2` | ~> 1.9 (explicit in Gemfile) | Base class for custom `OmniAuth::Strategies::Mastodon` |
| `lib/omniauth/strategies/mastodon.rb` | app code | Custom strategy — not an external gem |

## Not Used

| Option | Reason |
|--------|--------|
| `omniauth-mastodon` and similar gems | OAuth 1.0 only; do not support Mastodon OAuth 2.0 |

## Mastodon OAuth 2.0 Endpoints (per instance)

Base URL: `https://{instance_domain}`

| Step | Endpoint |
|------|----------|
| App registration | `POST /api/v1/apps` |
| Authorization | `GET /oauth/authorize` |
| Token exchange | `POST /oauth/token` |
| Verify credentials | `GET /api/v1/accounts/verify_credentials` |

## Configuration

- Add `omniauth_mastodon_client_id` / `omniauth_mastodon_client_secret` to `config/app_config.yml` **only if** using pre-registered apps on known instances
- **Recommended for arbitrary instances:** dynamic app registration via `/api/v1/apps` at request time (no static credentials per instance in env)
- Redirect URI: `{host}/users/auth/mastodon/callback` (standard Devise OmniAuth path)

## Integration Points

- `config/initializers/devise.rb` — register `:mastodon` provider
- `app/models/user.rb` — `omniauth_providers` + `from_omniauth` `:mastodon` branch
- `app/controllers/users/omniauth_callbacks_controller.rb` — `#mastodon` action
- `oauth_identities` table — provider `'mastodon'`, uid `'instance:account_id'`
