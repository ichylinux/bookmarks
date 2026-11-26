# External Integrations

**Analysis Date:** 2026-11-26

## Sign-In Providers (OmniAuth)

All providers are registered in `config/initializers/devise.rb`, routed through `Users::OmniauthCallbacksController` (`google_oauth2`, `twitter2`, `facebook`, `mastodon` actions → `handle_callback`) and resolved by `User.from_omniauth` (`app/models/user.rb`). Every successful sign-in upserts an `OauthIdentity(user_id, provider, uid)` row (`app/models/oauth_identity.rb`). OmniAuth sign-ins bypass the TOTP step.

| Provider | Gem / strategy | Scope | Credentials |
|----------|----------------|-------|-------------|
| Google | `omniauth-google-oauth2` | `email` | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |
| X (OAuth 2.0) | `omniauth-twitter2` | `tweet.read users.read follows.read users.email offline.access` | `TWITTER2_CLIENT_ID`, `TWITTER2_CLIENT_SECRET` |
| Facebook | `omniauth-facebook` | `email` | `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET` |
| Mastodon | `OmniAuth::Strategies::Mastodon` (`lib/omniauth/strategies/mastodon.rb`) | `read` | None static — placeholders in `devise.rb`; client id/secret are obtained per instance at request time |

**User matching rules (`User.from_omniauth`):**
- `twitter2`: match by `OauthIdentity(twitter2, uid)`, then by email; stores `oauth2_token`, `oauth2_refresh_token`, `oauth2_token_expires_at`, `x_user_name`; saved with `save(validate: false)`. New users without an email get `dummy_<uuid>@example.com` and can later register a real address (`Users::EmailRegistrationsController`).
- `facebook` / `google_oauth2`: match by email or create.
- `mastodon`: uid is the composite `"<instance>:<account_id>"`; match by identity, then by the user's normalized `mastodon_handle` (`MastodonHandleNormalizer`), else create.

**Mastodon OAuth flow:**
1. User enters an instance on the sign-in page → `POST /users/mastodon_instance` (`Users::MastodonInstancesController#create`, unauthenticated)
2. `MastodonInstanceNormalizer` validates the hostname → stored in `session[:mastodon_instance]`
3. `authorize_redirect.html.erb` auto-submits a POST to `/users/auth/mastodon` (CSRF-protected request phase)
4. The strategy registers an app on the instance (`POST /api/v1/apps`, Faraday), keeps client credentials in session, then runs standard OAuth2
5. The callback clears the `mastodon_*` session keys

**Connected-account management:** `DELETE /oauth_identities/:provider` (`OauthIdentitiesController`) disconnects a provider, or `provider=form` disables password login. Guarded by `User#disconnect_oauth!` / `#disconnect_form_auth!`: refuses to remove the last auth method (`LastAuthMethodError`) and uses `users.lock_version` for optimistic concurrency (`StaleObjectError`).

## Content APIs

**X API v2** — `app/services/x_client.rb`
- Base URL `https://api.twitter.com` for data calls; token refresh at `POST https://api.x.com/2/oauth2/token`
- Per-user Bearer token (`users.oauth2_token`), refreshed automatically when near expiry
- `fetch_following` (`GET /2/users/:uid/following`), `fetch_recent_tweets` (`GET /2/users/:id/tweets`, excludes retweets and replies), `lookup_user_by_username` (`GET /2/users/by/username/:handle`)
- Timeouts: 3s connect, 5s read. Result hash with error symbols `:timeout :network :unauthorized :rate_limited :not_found :suspended :api_error :parse_error`
- **Usage metering:** controllers log every call via `XApiCall.record!` (endpoint, success, error_code, rate_limit_remaining). The `x_api_calls` table feeds the admin report at `/admin/x_api_usages`.
- Gate: `TwitterLinkRequirement` concern (`User#twitter_linked?` = twitter2 identity + token present)
- Selection cap: at most 12 selected X accounts per user (`XAccount::MAX_SELECTION`, soft warning at 9)

**Mastodon REST API** (read-only, unauthenticated) — `app/services/mastodon_client.rb`
- `GET /api/v1/accounts/lookup`, `GET /api/v1/accounts/:id/statuses` against `https://<instance_host>`
- Timeouts: 3s / 5s; same result-hash convention
- Helpers: `MastodonHandleNormalizer`, `MastodonInstanceNormalizer`

**RSS / Atom feeds** — `app/models/feed.rb`
- Fetched with `Daddy::HttpClient`, parsed by `feedjira` (RSS, Atom, RSSFeedBurner parsers)
- Synchronous fetch on each gadget XHR (`feeds#show`); no caching
- Feed icon URLs read from feed metadata (`gadget_title_icon_image_url`)

**Page-title fetch** — `GET /bookmarks/fetch_title` (Faraday + `follow_redirects`) and `GET /feeds/fetch_title` (via `Feed#feed?`). Scheme / host checks only; see CONCERNS.md (SSRF).

## Data Storage

- **MySQL** (utf8mb4): 13 tables — `bookmarks, feeds, mastodon_accounts, notes, oauth_identities, portal_layouts, portals, preferences, todos, users, visited_links, x_accounts, x_api_calls`. Schema version `2026_11_24_120000`.
- **Browser `localStorage`:** `bookmarksPendingVisitedLinks` (queue of visit / like posts made while the session was expired, flushed after re-login — `visited_links.js`); `portalMobileActiveColumn` (mobile tab).
- **ActiveStorage:** local disk; routes disabled; unused.
- **Cache store:** none configured in production.

## Email

- Production: SMTP (port 587, `login` auth) via AWS SES — `AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`; sender `SMTP_FROM`; links use `https://$APP_HOST`
- Only Devise mailers (password reset etc.); no application mailers

## Observability

- Logs: STDOUT, tagged by request id, `RAILS_LOG_LEVEL` (default `info`); `/up` silenced
- `config/initializers/omniauth_logger.rb` routes OmniAuth logs to the Rails logger
- No error tracker or APM

## CI/CD

**Jenkins** (`Jenkinsfile`, Kubernetes agents, `global-build-lock`):
1. `build` — Kaniko builds `base` and `test` images, pushed to ECR
2. `unit` — `bin/bundler-audit`, `rake dad:db:create`, `rails db:reset`, `rails test` (`COVERAGE=true`, JUnit + SimpleCov HTML published)
3. `release` — pushes `HEAD:release`, tags `${MILESTONE}-${BUILD_NUMBER}` (`MILESTONE = "v1.37.1"` in the Jenkinsfile), builds the `app` image
4. On success, triggers `bookmarks-features` (`Jenkinsfile.features`): MySQL + Chrome pod, `rake dad:test` with `HEADLESS=true REMOTE=true`; publishes `features/reports`

No GitHub Actions. ESLint is **not** run in CI — run `yarn run lint` locally.

**Deploy:** Kustomize manifests (`config/kustomize/app.yml`, `db.yml`, `service.yml`), secret `bookmarks-secret`. Server provisioning recipes: Itamae (`config/itamae/`).

## Admin Tooling

- `bin/rails users:promote_admin EMAIL=… | USER_ID=…` (`lib/tasks/users.rake`) sets `users.admin = true`
- `/admin/users` — user list with per-user content counts; purge of accounts soft-deleted ≥ 90 days ago (`User::PURGE_AFTER_DAYS`, `User#purge!`)
- `/admin/x_api_usages` — X API call summary and per-day breakdown, with date-range filter

## Environment Variables (production)

| Variable | Purpose |
|----------|---------|
| `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` | Database |
| `SECRET_KEY_BASE` | Rails secret |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `…_DETERMINISTIC_KEY`, `…_KEY_DERIVATION_SALT` | AR encryption (falls back to `dev_dummy_key` if unset!) |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Google sign-in |
| `TWITTER2_CLIENT_ID`, `TWITTER2_CLIENT_SECRET` | X sign-in + API |
| `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET` | Facebook sign-in |
| `AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `SMTP_FROM` | Mail |
| `APP_HOST` | Mailer URL host |
| `RAILS_MAX_THREADS`, `PORT`, `RAILS_LOG_LEVEL` | Puma / logging |
| `BOOKMARKS_OTP_LENGTH` | Sets `app_config.otp_length`, but nothing reads it; TOTP is always ROTP's 6-digit default |

---

*Integration audit: 2026-11-26*
