# Research Summary: v1.35 Mastodon OAuth 2.0 Sign-In

**Date:** 2026-06-12

## Stack Additions

- Explicit `omniauth-oauth2` gem + custom `OmniAuth::Strategies::Mastodon` in `lib/`
- No third-party Mastodon OmniAuth gem (OAuth 1.0 only)
- Dynamic app registration per instance via `POST /api/v1/apps` recommended

## Feature Table Stakes

- Instance domain input before OAuth
- Composite uid (`instance:account_id`) in `oauth_identities`
- Sign-in button + Connected Accounts row + ja/en labels
- Reuse v1.34 disconnect safety guard

## Architecture Highlights

- Session-stored instance domain drives dynamic strategy endpoints
- `User.from_omniauth` new `:mastodon` branch with dummy-email fallback
- 5-phase build order: strategy → instance UI → identity → views → tests

## Watch Out For

1. Account ID collision — composite uid mandatory
2. Static OmniAuth config — must override `client.site` per request
3. Per-instance OAuth app — dynamic registration or pre-registered credentials
4. Domain validation — prevent open redirect / SSRF
5. Email-less accounts — dummy email pattern like Twitter

## Reference

- `tmp/Mastodon_OAuth_with_Rails_Devise.pdf` — Rails + Devise + OmniAuth approach
- v1.34 `oauth_identities` + Connected Accounts patterns
