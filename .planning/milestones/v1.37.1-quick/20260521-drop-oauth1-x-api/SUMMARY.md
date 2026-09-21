---
task: drop-oauth1-x-api
date: 2026-05-21
status: complete
commit: 3113e32
---

# Drop OAuth1 support from X API

Removed all OAuth 1.0a code, configuration, gem dependencies, database columns, and test artifacts. XClient now exclusively uses OAuth 2.0 Bearer tokens.

## What was removed

- `faraday-oauth1` and `omniauth-twitter` gems (Gemfile + Gemfile.lock)
- `oauth_faraday` method and `require 'faraday/oauth1'` from `x_client.rb`
- Fallback branch in `connection_for` — now always calls `bearer_faraday`
- `encrypts :token, :token_secret` from `user.rb`
- `omniauth_twitter_client_id` / `omniauth_twitter_client_secret` from `app_config.yml`
- `token` / `token_secret` columns (migration `20260521091442`)
- `test_oauth1_header_present_on_real_faraday_stack` and `test_token_encrypted_at_rest` tests
- OAuth1 references in Cucumber `hooks.rb` (`@x_gadget` / `@account_deletion` hooks)
- `token` / `token_secret` fixture fields in `users.yml`

## Behavioral change

Users without `oauth2_token` now receive `{ success: false, error: :unauthorized }` from the API (previously fell back to OAuth1). `TwitterLinkRequirement` gate now requires `uid + oauth2_token` (previously accepted `uid + token OR oauth2_token`).

## Test results

- `yarn run lint` ✓
- `bin/rails test` 515/515 ✓
- `bundle exec rake dad:test` 30/30 ✓
