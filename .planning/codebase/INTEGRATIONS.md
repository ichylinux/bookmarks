# External Integrations

**Analysis Date:** 2026-05-18

## APIs & External Services

**Google OAuth2:**
- Purpose: Social sign-in ("Sign in with Google")
- SDK/Client: `omniauth-google-oauth2` gem
- Scope: `['email']` (email only)
- Auth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` env vars (configured in `config/app_config.yml`)
- API key also stored: `GOOGLE_API_KEY` (present in app_config but not actively wired to a feature in current code)
- Flow: OmniAuth callback → `User.from_omniauth` in `app/models/user.rb`

**X (Twitter) API v2:**
- Purpose: OAuth 1.0a sign-in; fetch user's following list; fetch recent tweets for X gadget
- SDK/Client: `omniauth-twitter` (sign-in), `faraday` + `faraday-oauth1` (API calls)
- Auth: `TWITTER_CLIENT_ID`, `TWITTER_CLIENT_SECRET` env vars; per-user `token` + `token_secret` stored on `x_account` records
- Implementation: `app/services/x_client.rb`
  - `fetch_following` — `GET /2/users/:id/following` (OAuth 1.0a User Context)
  - `fetch_recent_tweets` — `GET /2/users/:id/tweets` (excludes retweets and replies)
- Rate limiting: returns `{ success: false, error: :rate_limited }` on HTTP 429

**Mastodon REST API:**
- Purpose: Fetch recent status previews for Mastodon gadget (read-only, no OAuth)
- SDK/Client: `faraday` (plain HTTP, no auth)
- Endpoints used: `GET /api/v1/accounts/lookup`, `GET /api/v1/accounts/:id/statuses`
- Implementation: `app/services/mastodon_client.rb`
- Instance host: user-configurable per `MastodonAccount` record
- Timeouts: 3s connect, 5s read

**RSS/Atom Feeds:**
- Purpose: Parse external RSS/Atom feeds for the Feed gadget
- SDK/Client: `feedjira 4.0.2`
- Implementation: `app/models/feed.rb`
- Supported parsers: `Feedjira::Parser::RSS`, `Feedjira::Parser::Atom`, `Feedjira::Parser::RSSFeedBurner`

## Data Storage

**Databases:**
- Type: MySQL (utf8mb4 charset, `utf8mb4_general_ci` collation)
- Databases: `bookmarks_dev` / `bookmarks_test` / `bookmarks_pro`
- Connection env vars: `MYSQL_HOST` (default: `127.0.0.1`), `MYSQL_PORT` (default: 3306), `MYSQL_USERNAME` (default: `bookmarks`), `MYSQL_PASSWORD` (default: `bookmarks`)
- Client: `mysql2` gem via ActiveRecord
- Pool: `RAILS_MAX_THREADS` (default: 5)

**File Storage:**
- Service: ActiveStorage local disk in all environments
- Development/test path: `storage/` and `tmp/storage/`
- Production: local disk (`config.active_storage.service = :local`)
- AWS S3, GCS, Azure Storage configs are commented out in `config/storage.yml` — not active

**Caching:**
- Development: `:memory_store`
- Production: default in-process (no external cache store configured; `mem_cache_store` commented out)

**Message Bus:**
- ActionCable
- Development/test adapter: `:async` (in-process)
- Production adapter: Redis at `redis://localhost:6379/1`, channel prefix `bookmarks_pro`

## Authentication & Identity

**Primary Auth:**
- Devise 5.0.4 with `database_authenticatable` (bcrypt, 11 stretches in production)
- Password length: 8–128 characters
- Email confirmation required (`confirmable`), reconfirmation on email change
- Password reset token valid for 6 hours
- Remember-me supported; all tokens invalidated on sign-out

**Two-Factor Auth (TOTP):**
- `devise-two-factor ~> 6.0` with ROTP
- `otp_secret` encrypted via ActiveRecord Encryption on `users` table
- OTP length: 6 digits (configurable via `BOOKMARKS_OTP_LENGTH` env var)
- QR code generation: `rqrcode 2.2.0`
- Two-step sign-in flow: password → OTP page (`app/controllers/users/two_factor_authentication_controller.rb`)
- Setup/disable: `app/controllers/users/two_factor_setup_controller.rb`
- OmniAuth sign-in bypasses OTP

**Social Sign-In:**
- Google OAuth2: `omniauth-google-oauth2`
- Twitter/X OAuth 1.0a: `omniauth-twitter`
- CSRF protection: `omniauth-rails_csrf_protection`
- User lookup/creation: `User.from_omniauth(access_token)` in `app/models/user.rb`

**ActiveRecord Encryption:**
- Used for: `otp_secret` on `User`
- Keys (ENV with dev fallback in `config/application.rb`):
  - `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
  - `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
  - `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
- `support_unencrypted_data: true` enabled in test environment (`config/environments/test.rb`) to allow fixture plain-text reads

## Email

**Delivery:**
- Development: `raise_delivery_errors = false` (no actual sending)
- Production: SMTP via AWS SES
  - `config.action_mailer.delivery_method = :smtp`
  - Settings from `config/app_config.yml` → env vars: `AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  - From address: `SMTP_FROM` env var (also used in Devise mailer sender)
- Default URL options (production): `https://` + `APP_HOST` env var

**Mailers:**
- Devise mailer (password reset, email confirmation, etc.)
- No custom application mailers detected

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logging:**
- Development: Rails default logger with verbose query logs and query log tags enabled
- Production: `ActiveSupport::TaggedLogging` to STDOUT, tagged with request ID, log level controlled by `RAILS_LOG_LEVEL` env var (default: `info`)
- Health check path `/up` silenced from logs in production

**APM/Metrics:**
- None detected

## CI/CD & Deployment

**Hosting:**
- Docker-based on Kubernetes (Kustomize manifests in `config/kustomize/`)
- Base image: `hybitz-almalinux:9.7`
- App image built from `Dockerfile.app` (extends `Dockerfile.base`)
- Test image: `Dockerfile.test`

**Deployment process:**
- `daddy` gem provides `dad:setup` rake task for app initialization
- `Dockerfile.app` runs `rake dad:setup:app` then `assets:precompile` at build time
- Kubernetes config: 1 replica, port 3000, ConfigMap + Secret via `bookmarks-secret`

**CI Pipeline:**
- No hosted CI detected (no `.github/workflows/`, `.circleci/`, etc.)
- `config/ci.rb` present (Rails CI config file)
- `ci_reporter` gem available for CI-compatible test output

**Infrastructure as Code:**
- Itamae cookbooks in `config/itamae/` (server provisioning — roles: `app`, `db`, `base`, `test`)

## Webhooks & Callbacks

**Incoming:**
- OmniAuth callbacks for Google and Twitter (mounted via Devise routes)

**Outgoing:**
- None detected

## Environment Configuration Summary

**Required env vars for production:**

| Variable | Purpose |
|----------|---------|
| `MYSQL_HOST` | Database host |
| `MYSQL_USERNAME` | Database username |
| `MYSQL_PASSWORD` | Database password |
| `GOOGLE_CLIENT_ID` | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret |
| `TWITTER_CLIENT_ID` | Twitter OAuth client ID |
| `TWITTER_CLIENT_SECRET` | Twitter OAuth client secret |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | AR encryption primary key |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | AR encryption deterministic key |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | AR encryption salt |
| `AWS_ADDRESS` | SES SMTP address |
| `AWS_DOMAIN` | SES SMTP domain |
| `AWS_ACCESS_KEY_ID` | SES SMTP username |
| `AWS_SECRET_ACCESS_KEY` | SES SMTP password |
| `SMTP_FROM` | Email from address |
| `APP_HOST` | Production hostname for mailer URLs |
| `SECRET_KEY_BASE` | Rails secret key base |
| `RAILS_MAX_THREADS` | Puma thread count (default: 3) |
| `PORT` | Puma listen port (default: 3000) |
| `BOOKMARKS_OTP_LENGTH` | TOTP code length (default: 6) |

---

*Integration audit: 2026-05-18*
