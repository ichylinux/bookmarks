# Pitfalls Research: Mastodon OAuth 2.0 Sign-In

**Milestone:** v1.35
**Date:** 2026-06-12

## Critical Pitfalls

### 1. Account ID collision across instances
**Risk:** Mastodon account IDs are only unique per instance.
**Prevention:** Store composite uid `instance_domain:account_id` in `oauth_identities.uid`.
**Phase:** 120 (identity wiring)

### 2. Static OmniAuth config won't work
**Risk:** `config.omniauth` runs at boot with fixed URLs; Mastodon is federated.
**Prevention:** Custom strategy overrides `client.site` from `session[:mastodon_instance]` at request time.
**Phase:** 119 (strategy)

### 3. OAuth client credentials per instance
**Risk:** Each Mastodon instance needs its own registered OAuth app.
**Prevention:** Dynamic app registration via `POST /api/v1/apps` before authorization; cache client_id/secret in session for the callback token exchange.
**Phase:** 119 (strategy)

### 4. Using OAuth1 gems
**Risk:** `omniauth-mastodon` etc. implement OAuth 1.0a only.
**Prevention:** Build custom strategy on `omniauth-oauth2`; do not add legacy gems.
**Phase:** 119 (strategy)

### 5. Instance domain validation
**Risk:** Open redirect or SSRF if arbitrary URLs accepted.
**Prevention:** Validate domain format (hostname only, no scheme/path); normalize to `https://{domain}`; reject private IP ranges.
**Phase:** 119 (instance form)

## Integration Pitfalls

### 6. Disconnect safety guard regression
**Risk:** New provider changes "last auth method" calculation.
**Prevention:** Reuse existing `OauthIdentitiesController` guard; add test with only Mastodon linked.
**Phase:** 123 (tests)

### 7. Email-less Mastodon accounts
**Risk:** Mastodon may not return email; user creation needs dummy email pattern.
**Prevention:** Follow Twitter pattern: `dummy_{uuid}@example.com` for new users without email.
**Phase:** 120 (from_omniauth)

### 8. Session instance lost between authorize and callback
**Risk:** Callback can't resolve which instance to exchange token against.
**Prevention:** Persist instance in session before redirect; strategy reads same key on callback.
**Phase:** 119 (instance form + strategy)

## Warning Signs During Implementation

- `OmniAuth::Strategies::OAuth2::CallbackError` — check redirect_uri matches registered app
- `RecordNotUnique` on `(provider, uid)` — composite uid format inconsistent
- Strategy connects to wrong host — session key not read in `callback_phase`
