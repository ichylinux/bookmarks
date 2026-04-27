# External Integrations

**Analysis Date:** 2026-04-27

## Overview

The application integrates with Google and Twitter for OAuth login, AWS SES for transactional email in production, and fetches external RSS/Atom feeds as a core feature. All integration credentials are supplied via environment variables. No cloud storage service is active.

## APIs & External Services

**Google OAuth2:**
- Purpose: Social login ("Sign in with Google")
- Gem: `omniauth-google-oauth2 1.2.2`
- Callback route: handled by `users/omniauth_callbacks` controller (`config/routes.rb` line 4–7)
- Auth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` env vars (`config/app_config.yml`)
- Additional key: `GOOGLE_API_KEY` env var (present in config, exact usage TBD)

**Twitter OAuth:**
- Purpose: Social login ("Sign in with Twitter")
- Gem: `omniauth-twitter 1.4.0`
- Callback route: same `users/omniauth_callbacks` controller
- Auth: `TWITTER_CLIENT_ID`, `TWITTER_CLIENT_SECRET` env vars (`config/app_config.yml`)

**RSS / Atom Feeds (generic external):**
- Purpose: Users subscribe to external RSS/Atom feeds; app fetches and parses them
- Gem: `feedjira 4.0.2` + `nokogiri 1.19.2`
- Implementation: `app/models/feed.rb` — `Feedjira.parse(xml)`, supports `Feedjira::Parser::RSS`, `::Atom`, `::RSSFeedBurner`
- HTTP retrieval: `httparty 0.24.2` and/or `faraday 1.10.5` are available for outbound requests

## Authentication & Identity

**Auth Provider:**
- Devise 5.0.3 — local email/password authentication (`app/models/user.rb`)
- OmniAuth 2.1.4 — OAuth2 broker; CSRF protection via `omniauth-rails_csrf_protection`
  - Providers: Google OAuth2, Twitter
  - User creation/lookup: `User.from_omniauth(access_token)` in `app/models/user.rb`

**Two-Factor Authentication:**
- TOTP (time-based OTP) via `devise-two-factor 6.4.0` + `rotp` (transitive dependency)
- QR code provisioning via `rqrcode 2.2.0`
- Routes: `users/two_factor_authentication` (verify), `users/two_factor_setup` (enable/disable) (`config/routes.rb`)
- OTP secret stored encrypted on `User` record (ActiveRecord Encryption)

**ActiveRecord Encryption:**
- Used to encrypt OTP secrets at rest
- Keys supplied via env vars: `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` (`config/application.rb`)

## Email Services

**Production:**
- Provider: AWS SES (Simple Email Service) via SMTP
- Delivery method: `:smtp` (`config/environments/production.rb`)
- SMTP settings sourced from `config/app_config.yml`:
  - Address: `AWS_ADDRESS` env var
  - Port: 587
  - Auth: `login` using `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
  - Domain: `AWS_DOMAIN` env var
- Sender address: `SMTP_FROM` env var (fallback: `from@example.com`)
- Devise mailer sender: same `SMTP_FROM` env var (`config/initializers/devise.rb`)

**Development/Test:**
- No SMTP configured — emails are not delivered (Rails default: `:test` or `:letter_opener` not set; verify environment config)

## Data Storage

**Database:**
- MySQL via `mysql2` gem
- Connection: `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` env vars (`config/database.yml`)

**File / Active Storage:**
- Local disk service only (`config/environments/production.rb`: `config.active_storage.service = :local`)
- `config/storage.yml` has commented-out templates for Amazon S3, Google GCS, and Microsoft Azure — none are active

**Caching:**
- No external cache store active; production uses Rails default in-process cache
- Redis is referenced only for Action Cable (`config/cable.yml`: `redis://localhost:6379/1`)

## Action Cable

- Production WebSocket backend: Redis at `redis://localhost:6379/1` (`config/cable.yml`)
- Channel prefix: `bookmarks_pro`

## Japanese Holiday Data

- Gem: `holiday_jp 0.8.1` — bundled dataset, no external API call
- Usage: `Calendar#holiday?` and `Calendar#holiday` in `app/models/calendar.rb`

## CI/CD & Deployment

**CI:**
- Jenkins (`Jenkinsfile` at repo root)

**Provisioning:**
- Itamae (infrastructure-as-code) with `daddy` gem (`config/itamae/`)
- Roles: `base`, `db`, `app`, `test`, `default` under `config/itamae/roles/`

**Containerisation:**
- Docker: `Dockerfile.app`, `Dockerfile.base`, `Dockerfile.test`

## Webhooks & Callbacks

**Incoming:**
- OmniAuth OAuth2 callbacks: `GET /users/auth/:provider/callback` handled by `Users::OmniauthCallbacksController`

**Outgoing:**
- None detected beyond RSS feed fetching

## Required Environment Variables

| Variable | Purpose |
|----------|---------|
| `GOOGLE_CLIENT_ID` | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret |
| `GOOGLE_API_KEY` | Google API key |
| `TWITTER_CLIENT_ID` | Twitter OAuth client ID |
| `TWITTER_CLIENT_SECRET` | Twitter OAuth client secret |
| `AWS_ADDRESS` | AWS SES SMTP host |
| `AWS_DOMAIN` | AWS SES SMTP domain |
| `AWS_ACCESS_KEY_ID` | AWS SES SMTP username |
| `AWS_SECRET_ACCESS_KEY` | AWS SES SMTP password |
| `SMTP_FROM` | Sender email address |
| `APP_HOST` | Production hostname for URL generation |
| `MYSQL_HOST` | Database host |
| `MYSQL_PORT` | Database port |
| `MYSQL_USERNAME` | Database user |
| `MYSQL_PASSWORD` | Database password |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | AR encryption primary key |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | AR encryption deterministic key |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | AR encryption salt |
| `RAILS_MAX_THREADS` | Puma thread count / DB pool size |
| `BOOKMARKS_OTP_LENGTH` | OTP code length (default: 6) |

---

*Integration audit: 2026-04-27*
