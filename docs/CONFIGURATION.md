# Configuration

<!-- gsd-generated: docs-update 2026-05-25 -->

## Environment variables

### Database (required for local setup)

| Variable | Default | Purpose |
|----------|---------|---------|
| `MYSQL_HOST` | `127.0.0.1` | MySQL host (`config/database.yml`) |
| `MYSQL_PORT` | `3306` | MySQL port |
| `MYSQL_USERNAME` | `bookmarks` | MySQL user |
| `MYSQL_PASSWORD` | `bookmarks` | MySQL password |

Database names: `bookmarks_dev`, `bookmarks_test`, `bookmarks_pro` (development, test, production).

### Rails runtime

| Variable | Default | Purpose |
|----------|---------|---------|
| `RAILS_MAX_THREADS` | `5` (DB pool), `3` (Puma) | Thread pool / Puma threads |
| `PORT` | `3000` | Puma listen port |
| `RAILS_LOG_LEVEL` | `info` | Production log level |
| `CI` | — | When set, enables eager load in test |

### Active Record encryption

Required in production for encrypted OAuth token columns on `users` (`oauth2_token`, `oauth2_refresh_token` via `encrypts`):

| Variable | Notes |
|----------|-------|
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Falls back to dev dummy in `config/application.rb` if unset |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Same |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Same |

### OAuth (OmniAuth)

Loaded from `config/app_config.yml` (ERB over ENV):

| Variable | Provider |
|----------|----------|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google |
| `TWITTER2_CLIENT_ID` / `TWITTER2_CLIENT_SECRET` | X (twitter2) |
| `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET` | Facebook |

### Application

| Variable | Default | Purpose |
|----------|---------|---------|
| `APP_HOST` | `localhost` | Mailer / URL host in app config |
| `BOOKMARKS_OTP_LENGTH` | `6` | TOTP code length |
| `SMTP_FROM` | `from@example.com` | Devise mailer sender |

### AWS (production mail via SES)

Production sends mail through Amazon SES using `smtp_settings` in `config/app_config.yml`:

| Variable | Purpose |
|----------|---------|
| `AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | SES SMTP credentials |

## Key config files

| File | Role |
|------|------|
| `config/database.yml` | MySQL connection per environment |
| `config/app_config.yml` | OAuth keys, OTP length, mail host |
| `config/initializers/devise.rb` | Devise + OmniAuth provider setup |
| `config/routes.rb` | HTTP routing |
| `config/locales/ja.yml`, `en.yml` | UI strings (parity tested) |
| `eslint.config.mjs`, `.prettierrc.json` | JavaScript lint/format |

## Docker / CI

- Docker: `Dockerfile.app`, `Dockerfile.base`, `Dockerfile.test` at repo root.
- CI: `Jenkinsfile`.

Production hostnames and secrets are supplied via environment variables at deploy time (`APP_HOST`, database credentials, OAuth keys, encryption keys, and AWS/SES variables above).
