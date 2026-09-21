---
task: drop-oauth1-x-api
date: 2026-05-21
status: in_progress
---

# Drop OAuth1 support from X API

Remove all OAuth 1.0a code, config, gem, columns, and tests — only OAuth 2.0 Bearer remains.

## Scope

**What stays:** OAuth2 path (`oauth2_token`, `bearer_faraday`, `refresh_oauth2_token!`), all `twitter2` omniauth config.

**What goes:**
- `gem 'faraday-oauth1'` from Gemfile
- `require 'faraday/oauth1'` from x_client.rb
- `oauth_faraday` method in x_client.rb
- Fallback branch in `connection_for` (users without oauth2_token → return `:unauthorized`)
- `encrypts :token, :token_secret` from user.rb
- `omniauth_twitter_client_id` / `omniauth_twitter_client_secret` from app_config.yml
- `token` / `token_secret` columns (migration)
- OAuth1 test in x_client_test.rb + update_columns using token/token_secret
- `test_token_encrypted_at_rest` test in user_test.rb
- `token` / `token_secret` fixture fields in users.yml

## Tasks

1. [ ] Remove `gem 'faraday-oauth1'` from Gemfile; run `bundle install`
2. [ ] Update `app/services/x_client.rb`: remove require, oauth_faraday, simplify connection_for
3. [ ] Update `app/models/user.rb`: remove `encrypts :token, :token_secret`
4. [ ] Update `config/app_config.yml`: remove oauth1 twitter client_id/secret lines
5. [ ] Update `test/services/x_client_test.rb`: remove OAuth1 test, clean up token/token_secret update_columns
6. [ ] Update `test/models/user_test.rb`: remove test_token_encrypted_at_rest
7. [ ] Update `test/fixtures/users.yml`: remove token/token_secret fields
8. [ ] Generate migration to drop token/token_secret columns from users
9. [ ] Run full test suite; commit
