# Architecture Research: Mastodon OAuth 2.0 Sign-In

**Milestone:** v1.35
**Date:** 2026-06-12

## Data Flow

```
Sign-in page
  → user enters instance domain (e.g. mastodon.social)
  → POST stores instance in session
  → redirect to /users/auth/mastodon
  → strategy reads session instance
  → (optional) POST /api/v1/apps on instance for dynamic client_id/secret
  → redirect to https://{instance}/oauth/authorize
  → callback /users/auth/mastodon/callback
  → strategy exchanges code at https://{instance}/oauth/token
  → GET /api/v1/accounts/verify_credentials
  → OmniAuth auth hash → User.from_omniauth
  → OauthIdentity.upsert_for!(provider: 'mastodon', uid: '{instance}:{id}')
  → Devise sign_in
```

## New Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `OmniAuth::Strategies::Mastodon` | `lib/omniauth/strategies/mastodon.rb` | Dynamic site URL, OAuth2 flow, raw_info from verify_credentials |
| Instance form | `app/views/devise/shared/_mastodon_instance_form.html.erb` | Domain input + submit before OAuth |
| Instance session key | `session[:mastodon_instance]` | Pass instance between form and strategy |
| `from_omniauth :mastodon` | `app/models/user.rb` | Find by composite uid; create with dummy email if new |

## Modified Components

| Component | Change |
|-----------|--------|
| `User` devise config | Add `:mastodon` to `omniauth_providers` |
| `devise.rb` | `config.omniauth :mastodon, ...` with strategy class |
| `_oauth_buttons.html.erb` | Mastodon button (with instance form) |
| `_connected_accounts.html.erb` | 5th row for Mastodon |
| `OauthIdentitiesController` | No change — `mastodon` is just another provider string |

## Identity Model

```
oauth_identities:
  provider: 'mastodon'
  uid:      'mastodon.social:12345'   # instance_domain + ':' + account_id
```

Global unique index on `(provider, uid)` already exists — composite uid prevents cross-instance collisions.

## Build Order

1. Strategy + gem wiring (foundation)
2. Instance selection UI + session plumbing
3. `from_omniauth` + callback controller
4. Auth buttons + Connected Accounts view
5. Tests + tri-suite gate

## Testing Strategy

- Strategy: unit test with WebMock stubbing instance endpoints
- `from_omniauth`: Minitest with OmniAuth auth hash fixture (no HTTP)
- Controller: integration test with OmniAuth test mode
- Cucumber: `@connected_accounts` extension — Mastodon row presence (no live OAuth)
