<!-- generated-by: gsd-doc-writer -->
# Configuration

There is no `.env.example`. In development and test, [`dotenv-rails`](https://github.com/bkeepers/dotenv) (Gemfile group `:development, :test`) loads a gitignored `.env` at boot. Production does not load `.env`; set variables in the process environment (for example Kubernetes `envFrom` in `config/kustomize/`).

## Environment variables

### Database

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MYSQL_HOST` | Optional | `127.0.0.1` | MySQL server hostname |
| `MYSQL_PORT` | Optional | `3306` | MySQL server port |
| `MYSQL_USERNAME` | Optional | `bookmarks` | MySQL username |
| `MYSQL_PASSWORD` | Optional | `bookmarks` | MySQL password |
| `RAILS_MAX_THREADS` | Optional | `3` (Puma) / `5` (DB pool) | Puma thread count and database connection pool size |

Database names are fixed per environment: `bookmarks_dev` (development), `bookmarks_test` (test), `bookmarks_pro` (production).

When `RAILS_MAX_THREADS` is unset, Puma uses 3 threads while the MySQL pool size is 5. When it is set, both read the same value.

### Rails secret

This app has no `config/credentials.yml.enc`. Rails 8.1 therefore takes `secret_key_base` from `SECRET_KEY_BASE`, then credentials (absent here), then a generated local secret in development and test only.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | **Required (production)** | generated local secret in development/test; none in production | Cookie/session signing key. Production boot raises `ArgumentError` if missing. `Dockerfile.app` passes `SECRET_KEY_BASE=dummy` only for image build (`dad:setup:app` and `assets:precompile`). |

### ActiveRecord encryption

Three keys are required in production. In development and test they fall back to the placeholder value `'dev_dummy_key'` defined in `config/application.rb`. The same `ENV.fetch` default applies in production too — boot will succeed with the dummy values, but encrypted columns cannot be decrypted.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | **Required (production)** | `dev_dummy_key` | Primary encryption key for ActiveRecord Encryption |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | **Required (production)** | `dev_dummy_key` | Deterministic encryption key |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | **Required (production)** | `dev_dummy_key` | Key derivation salt |

These keys protect the `oauth2_token` and `oauth2_refresh_token` columns on the `users` table. Do not use the `dev_dummy_key` fallback in production.

### OAuth providers (OmniAuth)

Loaded via `config/app_config.yml` using ERB. All are optional for local development (OmniAuth routes remain mounted but sign-in with those providers will fail without credentials).

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GOOGLE_CLIENT_ID` | Optional | — | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | Optional | — | Google OAuth2 client secret |
| `TWITTER2_CLIENT_ID` | Optional | — | X (Twitter) OAuth2 client ID |
| `TWITTER2_CLIENT_SECRET` | Optional | — | X (Twitter) OAuth2 client secret |
| `FACEBOOK_APP_ID` | Optional | — | Facebook app ID |
| `FACEBOOK_APP_SECRET` | Optional | — | Facebook app secret |

Mastodon provider is configured with placeholder client credentials in `config/initializers/devise.rb` and is dynamically registered per instance (`lib/omniauth/strategies/mastodon.rb` posts to `/api/v1/apps` and stores the issued client id/secret in the session).

### Application

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `APP_HOST` | Optional | `localhost` | Host used in mailer URL generation (production `app_config.yml`) |
| `BOOKMARKS_OTP_LENGTH` | Optional | `6` | Defined in `config/app_config.yml` as `otp_length`, but not read anywhere in application code — `app/models/user.rb` calls `ROTP::TOTP.new` without a `digits:` option, so this variable has no effect on TOTP code length (ROTP's built-in 6-digit default applies regardless) |
| `SMTP_FROM` | Optional | `from@example.com` | Mailer sender address used by Devise and production ActionMailer |
| `RAILS_ENV` | Optional | `development` (Rails default); Docker image sets `production` | Rails environment. `Dockerfile.app` builds with `RAILS_ENV=production`. |

### Email / AWS SES (production only)

Production sends transactional mail through SMTP (Amazon SES). These variables have no defaults and are required when `RAILS_ENV=production`.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AWS_ADDRESS` | **Required (production)** | — | SMTP server address <!-- VERIFY: exact host depends on AWS region --> |
| `AWS_DOMAIN` | **Required (production)** | — | SMTP HELO domain |
| `AWS_ACCESS_KEY_ID` | **Required (production)** | — | SES SMTP username (IAM access key ID) |
| `AWS_SECRET_ACCESS_KEY` | **Required (production)** | — | SES SMTP password (IAM secret key) |

### Web server (Puma)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | Optional | `3000` | TCP port Puma listens on |
| `RAILS_LOG_LEVEL` | Optional | `info` | Log verbosity in production (`debug`, `info`, `warn`, `error`) |
| `SOLID_QUEUE_IN_PUMA` | Optional | — | Present in the Rails-generated `config/puma.rb` (`plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`). The `solid_queue` gem is not in the Gemfile, so setting this variable will fail at boot. |
| `PIDFILE` | Optional | — | Path for Puma PID file |

`WEB_CONCURRENCY` is mentioned only in a comment in `config/puma.rb`; this app does not configure Puma workers, so the variable has no effect.

### CI and test tooling

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CI` | Optional | — | When present, enables eager loading in the test environment (`config/environments/test.rb`). When set to `jenkins`, the Itamae test role skips the Selenium cookbook (`config/itamae/roles/test.rb`). The test Docker image (`Dockerfile.test`) bakes in `CI=jenkins` at build time. |
| `COVERAGE` | Optional | — | When set, `daddy/test_help` starts SimpleCov (used by `Jenkinsfile` as `COVERAGE=true`). |
| `DRY_RUN` | Optional | — | When set (or set `DR`), the `closer` gem passes `--dry-run` to Cucumber — resolves step definitions without launching a browser. Used locally as `DRY_RUN=1 bundle exec rake dad:test features/…`. |
| `DR` | Optional | — | Alias for `DRY_RUN` (handled by the `closer` gem). |
| `FORMAT` | Optional | — | When set to `junit`, `daddy/test_help` enables the Minitest JUnit reporter (`Jenkinsfile` sets `FORMAT=junit`). |
| `HEADLESS` | Optional | `true` when running `rake dad:test` | Headless Chrome for Cucumber (`daddy/lib/tasks/test.rake` sets it if empty; `Jenkinsfile.features` sets `HEADLESS=true`). |
| `REMOTE` | Optional | — | When set, the `closer` gem drives a remote Selenium browser (`Jenkinsfile.features` sets `REMOTE=true`). |

### Rake tasks

Used only by `bin/rails users:promote_admin` (`lib/tasks/users.rake`). Pass exactly one of them.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `EMAIL` | Optional | — | Email of the active user to promote to admin |
| `USER_ID` | Optional | — | Numeric id of the active user to promote to admin |

## Config file format

### `config/app_config.yml`

Central YAML config loaded as `Rails.application.config.app_config` by `config/initializers/app_config.rb`. Uses ERB to read environment variables at boot time.

```yaml
default: &default
  otp_length: 6                    # overridden by BOOKMARKS_OTP_LENGTH
  omniauth_google_oauth2_client_id:         # GOOGLE_CLIENT_ID
  omniauth_google_oauth2_client_secret:     # GOOGLE_CLIENT_SECRET
  omniauth_twitter2_client_id:              # TWITTER2_CLIENT_ID
  omniauth_twitter2_client_secret:          # TWITTER2_CLIENT_SECRET
  omniauth_facebook_app_id:                 # FACEBOOK_APP_ID
  omniauth_facebook_app_secret:             # FACEBOOK_APP_SECRET

production:
  <<: *default
  default_url_options:
    protocol: https
    host:                          # APP_HOST
  smtp_settings:
    address:                       # AWS_ADDRESS
    port: 587
    domain:                        # AWS_DOMAIN
    authentication: login
    user_name:                     # AWS_ACCESS_KEY_ID
    password:                      # AWS_SECRET_ACCESS_KEY
```

Access values in application code via `Rails.application.config.app_config.omniauth_google_oauth2_client_id`, etc. (e.g. `config/initializers/devise.rb`, `app/services/x_client.rb`). Note: `otp_length` is defined here but is never read elsewhere in the codebase — it has no effect on application behavior.

### `config/database.yml`

MySQL connection using the `mysql2` adapter, `utf8mb4` encoding, and `utf8mb4_general_ci` collation. The connection pool size is controlled by `RAILS_MAX_THREADS` (default `5`).

### `config/cable.yml`

Action Cable adapter by environment:

| Environment | Adapter | Notes |
|-------------|---------|-------|
| development | `async` | In-process, no external dependency |
| test | `async` | In-process, no external dependency |
| production | `redis` | URL `redis://localhost:6379/1` (hardcoded in `config/cable.yml`; no `REDIS_URL` env var), prefix `bookmarks_pro` <!-- VERIFY: Redis host and port may differ per deployment --> |

### `config/storage.yml`

Active Storage disk services. Development and production use `:local` (`storage/`); test uses `:test` (`tmp/storage`). Commented S3/GCS/Azure stanzas are unused.

### `config/daddy.yml`

Bootstrap config for the `daddy` gem (Itamae setup roles): application name `bookmarks`, default env `development`, web `server_name` `localhost`, `app.type` `passenger`. The running app server is Puma (`config/puma.rb`); the `passenger` value is used by daddy's setup recipes, not by Puma.

### `config/kustomize/`

Kubernetes manifests. `kustomization.yml` generates ConfigMap `bookmarks-config` with:

| Literal | Value | Notes |
|---------|-------|-------|
| `PORT` | `3000` | Read by Puma |
| `RAILS_LOG_TO_STDOUT` | `true` | Not read by this app's Rails 8.1 `production.rb` (logging is already hardcoded to STDOUT) |
| `RAILS_SERVE_STATIC_FILES` | `true` | Not read by this app's `production.rb`; Rails 8.1 defaults `public_file_server.enabled` to `true` |

Deployments also reference Secret `bookmarks-secret` via `secretRef`. <!-- VERIFY: secret keys and values live outside the repo -->

## Required vs optional settings

Settings that cause application boot or runtime failure if absent in production:

| Setting | Variable | Failure mode |
|---------|----------|--------------|
| Secret key base | `SECRET_KEY_BASE` | `ArgumentError` at boot (`Missing secret_key_base`) — this app has no encrypted credentials file as a fallback |
| Encryption primary key | `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Decryption errors on `oauth2_token`, `oauth2_refresh_token` columns (boot still succeeds because of the `dev_dummy_key` default) |
| Encryption deterministic key | `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Decryption errors on encrypted columns |
| Encryption derivation salt | `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Decryption errors on encrypted columns |
| MySQL password | `MYSQL_PASSWORD` | `Mysql2::Error` if production credentials differ from dev defaults |
| SES SMTP credentials | `AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | Mail delivery failures in production |

## Defaults

| Variable | Default value | Defined in |
|----------|--------------|-----------|
| `MYSQL_HOST` | `127.0.0.1` | `config/database.yml` |
| `MYSQL_PORT` | `3306` | `config/database.yml` |
| `MYSQL_USERNAME` | `bookmarks` | `config/database.yml` |
| `MYSQL_PASSWORD` | `bookmarks` | `config/database.yml` |
| `RAILS_MAX_THREADS` | `3` (Puma threads) / `5` (DB pool) | `config/puma.rb`, `config/database.yml` |
| `PORT` | `3000` | `config/puma.rb` |
| `RAILS_LOG_LEVEL` | `info` | `config/environments/production.rb` |
| `BOOKMARKS_OTP_LENGTH` | `6` | `config/app_config.yml` |
| `APP_HOST` | `localhost` | `config/app_config.yml` |
| `SMTP_FROM` | `from@example.com` | `config/initializers/devise.rb`, `config/environments/production.rb` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | `dev_dummy_key` | `config/application.rb` |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | `dev_dummy_key` | `config/application.rb` |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | `dev_dummy_key` | `config/application.rb` |
| `SECRET_KEY_BASE` | generated local secret (`tmp/local_secret.txt`) in development/test | Rails 8.1 (`Rails.env.local?`); no default in production |

Application-wide defaults (not env vars) in `config/application.rb`: time zone `Tokyo`, I18n default locale `:ja` with available locales `ja` and `en` (mirrors `Preference::SUPPORTED_LOCALES`). Session cookie key is `_bookmarks_session` (`config/initializers/session_store.rb`).

## Per-environment overrides

Environment-specific files live in `config/environments/`.

### Development (`config/environments/development.rb`)

- Code reloading enabled; changes take effect without a server restart.
- Caching disabled by default; run `bin/rails dev:cache` to toggle. Cache store is `:memory_store`.
- `config.active_record.encryption.support_unencrypted_data = true` — allows reading rows inserted without encryption (fixtures, legacy data).
- Mailer delivery errors suppressed; default URL host is `localhost:3000`.
- Active Storage uses the `:local` disk service.
- `dotenv-rails` loads `.env`.

### Test (`config/environments/test.rb`)

- `config.active_record.encryption.support_unencrypted_data = true` — required because test fixtures insert plain-text `otp_secret` values directly via SQL, bypassing ActiveRecord callbacks.
- Eager loading is off by default; set `CI=1` to enable (matches CI pipeline behaviour).
- ActionMailer uses `:test` delivery method — no real email is sent; deliveries accumulate in `ActionMailer::Base.deliveries`. Mailer default URL host is `example.com`.
- Cache store is `:null_store`. Active Storage uses the `:test` disk service.
- `dotenv-rails` loads `.env`.

### Production (`config/environments/production.rb`)

- SSL enforced via `config.force_ssl = true` and `config.assume_ssl = true`. HTTP-to-HTTPS redirect skips `/up`; that path is also silenced in logs (`silence_healthcheck_path`).
- Logs go to STDOUT with request-id tags. Log level controlled by `RAILS_LOG_LEVEL` (default `info`).
- I18n fallbacks enabled — missing translations fall back to the default locale (`ja`).
- SMTP delivery via Amazon SES using `smtp_settings` from `config/app_config.yml`.
- Action Cable uses Redis (see `config/cable.yml`).
- Active Storage uses the `:local` disk service (S3 is commented out in `config/storage.yml`).
- `SECRET_KEY_BASE` must be set; there is no credentials file.

### Docker images

- `Dockerfile.test` — sets `CI=jenkins` and `RAILS_ENV=test` at image build time; used by Jenkins unit and features stages.
- `Dockerfile.app` — sets `RAILS_ENV=production` (build arg `rails_env`, default `production`); `SECRET_KEY_BASE=dummy` only during `dad:setup:app` and `assets:precompile`.
- `Dockerfile.base` — production gem bundle (`bundle config without 'itamae development test'`); `SECRET_KEY_BASE=dummy` only during `dad:setup:base`.

### Kubernetes (`config/kustomize/`)

- App Deployment (`config/kustomize/app.yml`) and db-migrate Job (`config/kustomize/db.yml`) both load ConfigMap `bookmarks-config` and Secret `bookmarks-secret`.
- Service (`config/kustomize/service.yml`) exposes port 3000; ALB health check annotation points at `/up`.
