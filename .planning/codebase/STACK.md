# Technology Stack

**Analysis Date:** 2026-05-23

## Languages

**Primary:**
- Ruby 3.4.9 — all server-side code (`Gemfile`, `.ruby-version`)
- JavaScript (ES2015+) — browser-side behavior (`app/assets/javascripts/`)

**Secondary:**
- SCSS/CSS — styling via `sass-rails` (`app/assets/stylesheets/`)
- ERB — HTML templating (`app/views/`)
- YAML — configuration files (`config/`)

## Runtime

**Environment:**
- Ruby 3.4.9 (MRI/CRuby)
- Node.js — required for ESLint/Prettier tooling only (no frontend bundler)

**Package Manager:**
- Bundler — Ruby gems (`Gemfile.lock` present)
- Yarn — JS devDependencies only (`package.json`)

## Frameworks

**Core:**
- Rails 8.1.3 (`rails ~> 8.1.0`) — full-stack MVC framework
  - ActiveRecord with MySQL2 adapter
  - ActionMailer with SMTP delivery (production)
  - ActionCable (async adapter dev/test; Redis adapter production)
  - ActiveStorage (local disk service in all environments)
  - ActiveRecord Encryption (`otp_secret`, `oauth2_token`, `oauth2_refresh_token` on User)

**Authentication:**
- Devise 5.0.4 — core auth (two_factor_authenticatable, registerable, recoverable, rememberable, trackable, validatable, omniauthable)
- devise-two-factor ~> 6.0 — TOTP two-factor auth
- omniauth 2.1.4 — OmniAuth base
- omniauth-google-oauth2 — Google OAuth2 provider
- omniauth-twitter2 — X OAuth 2.0 provider
- omniauth-rails_csrf_protection — CSRF protection for OmniAuth POST routes

**Testing:**
- Minitest 5.27.0 — unit and integration tests (`bin/rails test`)
- Cucumber 9.2.1 + cucumber-rails — E2E feature tests (`bundle exec rake dad:test`)
- Capybara 3.40.0 — browser automation DSL
- Selenium WebDriver — headless Chrome driver for Capybara

**Build/Dev:**
- ESLint 9.x + `@babel/eslint-parser` — JavaScript linting (`yarn run lint`)
- Prettier 3.x + `eslint-config-prettier` — JavaScript formatting (`yarn run format`)
- Sprockets (via `sass-rails`) — asset pipeline (no Webpack/Vite)
- Uglifier 4.2.1 — JavaScript minification in production

## Key Dependencies

**Critical:**
- `mysql2 >= 0.4.4, < 0.6` — MySQL database adapter
- `puma 8.0.1` — application server (multi-threaded, default 3 threads via `RAILS_MAX_THREADS`)
- `devise 5.0.4` — authentication backbone
- `nokogiri 1.19.3` — HTML/XML parsing (used by feedjira, i18n-js, rails-erd)
- `faraday 1.10.5` — HTTP client for external API calls (`app/services/mastodon_client.rb`, `app/services/x_client.rb`, OAuth2 token refresh)
- `faraday_middleware` — `:follow_redirects` for bookmark title fetch
- `feedjira 4.0.2` — RSS/Atom feed parsing (`app/models/feed.rb`)

**Infrastructure:**
- `bootsnap 1.24.4` — boot time optimization
- `daddy 0.12.0` — custom deployment/setup gem (provides `dad:setup`, `dad:test` rake tasks)
- `acts_as_tree 2.9.1` — hierarchical bookmark model in `app/models/bookmark.rb`
- `holiday_jp 0.8.1` — Japanese public holiday lookups in `app/models/calendar_gadget.rb`
- `rqrcode ~> 2.0` (2.2.0) — QR code generation for TOTP setup in `app/controllers/users/two_factor_setup_controller.rb`
- `i18n-js 4.2.4` — exports Rails i18n translations to JavaScript
- `rails-i18n ~> 8.0` — Rails built-in i18n translations for Japanese
- `devise-i18n` — Devise i18n translations
- `jquery-rails` + `jquery-ui-rails` — jQuery and jQuery UI via asset pipeline

**Development/Test Only:**
- `dotenv-rails 3.2.0` — `.env` file loading in dev/test
- `byebug` — Ruby debugger
- `webmock 3.26.2` — HTTP request stubbing for tests
- `database_cleaner 2.1.0` — DB cleanup between Cucumber scenarios
- `simplecov 0.22.0` — test coverage reporting
- `minitest-reporters` — enhanced Minitest output
- `ci_reporter` — CI-compatible test reporting
- `rails-erd 1.7.2` — entity-relationship diagram generation

## Configuration

**Environment:**
- `config/app_config.yml` — app-level config with ENV interpolation (OmniAuth keys, SMTP settings, OTP length)
- `config/database.yml` — MySQL connection (ENV: `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`)
- ActiveRecord Encryption keys via ENV: `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` (fallback to hardcoded `'dev_dummy_key'` in non-production)
- `.env` file present at repo root (loaded by `dotenv-rails` in dev/test — never read contents)

**Build:**
- `config/initializers/assets.rb` — Sprockets asset precompile list
- `config/initializers/content_security_policy.rb` — CSP headers
- `.prettierrc.json` — Prettier: `semi: true`, `singleQuote: true`, `trailingComma: "es5"`
- `eslint.config.mjs` — ESLint flat config with Babel parser

## Platform Requirements

**Development:**
- Ruby 3.4.9
- MySQL (utf8mb4 encoding, `utf8mb4_general_ci` collation)
- Node.js (for ESLint/Prettier)
- Yarn

**Production:**
- Docker-based deployment (AlmaLinux 9.7 base image: `hybitz-almalinux:9.7`)
- Kubernetes via Kustomize (`config/kustomize/`)
- MySQL database `bookmarks_pro`
- Redis at `redis://localhost:6379/1` (for ActionCable)
- SMTP via AWS SES (`AWS_ADDRESS`, `AWS_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- SSL enforced (`config.force_ssl = true`)
- Puma on port 3000 (`PORT` env var)

---

*Stack analysis: 2026-05-23*
