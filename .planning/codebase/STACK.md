# Technology Stack

**Analysis Date:** 2026-11-26

## Languages

**Primary:**
- Ruby 3.4.10 — all server-side code (`.ruby-version`; `Gemfile` declares `ruby '~> 3.4.0'`)
- JavaScript (ES2015+, no modules) — browser behavior in `app/assets/javascripts/` (17 files, ~1.5k lines)

**Secondary:**
- SCSS — `app/assets/stylesheets/` (per-screen files + `themes/`)
- ERB — `app/views/`
- YAML — config, fixtures, locales

## Runtime

- Ruby 3.4.10 (MRI)
- Node.js 22.23.1 (`.node-version`) — ESLint only; also the ExecJS runtime for `uglifier` during `assets:precompile`
- Bundler (`Gemfile.lock`; `source 'https://rubygems.org', cooldown: 7` — new gem releases are held back 7 days)
- Yarn — JS devDependencies only (`package.json`)

## Frameworks

**Core:**
- Rails 8.1.4.1 (`rails ~> 8.1.0`, loaded via `require "rails/all"`)
  - ActiveRecord + `mysql2` 0.5.7
  - ActionMailer (SMTP / AWS SES in production; Devise mails only)
  - ActionCable — stub only (`app/channels/application_cable/`, no channels)
  - ActiveStorage — loaded, but routes disabled (`config.active_storage.draw_routes = false`); no attachments in use
  - ActiveRecord Encryption — `encrypts :oauth2_token, :oauth2_refresh_token`; `otp_secret` via devise-two-factor
- Sprockets via `sass-rails` 6.0 — asset pipeline (no importmap / esbuild / webpack)
- jQuery + jQuery UI (`jquery-rails` 4.6.1, `jquery-ui-rails` 8.0.1) + `rails-ujs`

**Authentication:**
- Devise 5.0.4 — `two_factor_authenticatable, registerable, recoverable, rememberable, trackable, validatable, omniauthable`
- devise-two-factor ~> 6.0 (TOTP), `rqrcode` 2.2.0 (QR codes)
- OmniAuth 2.3.1 + `omniauth-oauth2` ~> 1.9 (1.10.0)
- Providers: `omniauth-google-oauth2` 1.2.3, `omniauth-twitter2` 1.2.0 (X OAuth 2.0), `omniauth-facebook` 11.0.0, and a **custom Mastodon strategy** in `lib/omniauth/strategies/mastodon.rb` (dynamic instance + per-instance app registration)
- `omniauth-rails_csrf_protection` 2.0.1 — OmniAuth request phase is POST-only

**Testing:**
- Minitest 5.27.0 (`minitest ~> 5.0`) + `minitest-reporters`
- Cucumber 10.2.0 + `cucumber-rails`, run through `daddy`'s `rake dad:test`
- Capybara 3.40.0 + Selenium WebDriver 4.52.0 (headless Chrome)
- WebMock 3.34.0, `database_cleaner` 2.1.0, `simplecov`, `ci_reporter`, `closer` 0.18.4 (cucumber HTML report)

**Lint / Dev:**
- ESLint 9 flat config (`eslint.config.mjs`) + `@babel/eslint-parser` + `@eslint/js` recommended — `yarn run lint`
- Prettier was **removed** (no `.prettierrc.json` / `.prettierignore`, no `format` script)
- No RuboCop config
- `bundler-audit` 0.9.3 (`bin/bundler-audit`, config `config/bundler-audit.yml`) — run in Jenkins `unit` stage
- `rails-erd` + `ruby-graphviz` (ER diagram PDFs regenerated after migrate via `daddy`)
- `web-console`, `byebug`, `dotenv-rails`

## Key Dependencies

| Gem | Version | Used for |
|-----|---------|----------|
| `daddy` | 0.12.7 | In-house toolkit: `dad:setup:*`, `dad:test`, `dad:db:create`, soft-delete (`not_deleted`, `destroy_logically!`), `Daddy::HttpClient` (feed fetch), test helpers (`daddy/test_help`, `daddy/cucumber/rails`). Pulls in `itamae`, `docker-api`. |
| `faraday` | 1.10.6 | HTTP client for `XClient`, `MastodonClient`, Mastodon OmniAuth app registration, bookmark title fetch |
| `faraday_middleware` | (v1-era) | `:follow_redirects` in `BookmarksController#fetch_title` |
| `feedjira` | 4.0.3 | RSS / Atom parsing in `Feed` |
| `kaminari` | 1.3.3 | Pagination (`default_per_page = 25`) — reading history, admin users |
| `acts_as_tree` | 2.9.1 | Bookmark folder hierarchy |
| `holiday_jp` | 0.8.1 | Calendar gadget holidays |
| `i18n-js` | 4.2.4 | Translations exported to JS |
| `rails-i18n` ~> 8.0, `devise-i18n` | — | ja/en framework strings |
| `nokogiri` | 1.19.7 (`force_ruby_platform: true`) | HTML/XML parsing |
| `puma` | 8.1.2 | App server |
| `bootsnap` | 1.26.1 | Boot cache |
| `uglifier` | 4.2.1 | JS minification at precompile |

**Gemfile oddity:** `mysql2` sits in `group :itamae`, and `Dockerfile.base` sets `bundle config without 'itamae development test'`. How the production image obtains `mysql2` is not visible in this repo (presumably through `daddy`'s setup tasks or the base image) — verify before touching Gemfile groups.

## Configuration

- `config/app_config.yml` → `Rails.application.config.app_config` (`config/initializers/app_config.rb`): OTP length, OAuth client ids/secrets (Google, X, Facebook), production `default_url_options` and SMTP settings
- `config/database.yml` — `MYSQL_HOST` / `MYSQL_PORT` / `MYSQL_USERNAME` / `MYSQL_PASSWORD`; DBs `bookmarks_dev` / `bookmarks_test` / `bookmarks_pro`
- `config/application.rb` — AR encryption keys from ENV with `'dev_dummy_key'` fallback; requires `lib/omniauth/strategies/mastodon`
- `config/initializers/devise.rb` — OmniAuth provider registration and scopes
- `config/initializers/kaminari_config.rb`, `omniauth_logger.rb`, `content_security_policy.rb` (all commented out), `permissions_policy.rb`
- `config/ci.rb` — unused Rails 8 scaffold (references `bin/importmap audit`, which does not exist here)
- `.env` loaded by `dotenv-rails` in dev/test (do not read)

## Platform

**Development:** Ruby 3.4.10, Node 22, Yarn, MySQL (utf8mb4 / `utf8mb4_general_ci`), Chrome for Cucumber.

**Production:**
- Container images built with Kaniko in Jenkins: `Dockerfile.base` (FROM `hybitz-almalinux:9.9-20261116-66`, bundle install, `dad:setup:base`) → `Dockerfile.app` (`dad:setup:app`, `assets:precompile`) / `Dockerfile.test` (`dad:setup:test`)
- Kubernetes via Kustomize (`config/kustomize/`): 1 replica, 100m CPU / 256Mi, readiness probe and `preStop` hook for graceful rolling updates
- Puma on port 3000; `force_ssl` + `assume_ssl`
- ActionCable configured for Redis (`redis://localhost:6379/1`) but the `redis` gem is not in the bundle and no channels exist
- SMTP via AWS SES

---

*Stack analysis: 2026-11-26*
