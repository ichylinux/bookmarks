# Technology Stack

**Analysis Date:** 2026-04-27

## Overview

Bookmarks is a Rails 8.1 application written in Ruby 3.4, backed by MySQL, and served via Puma with Passenger as the production app server. The frontend uses the classic Rails asset pipeline (Sprockets) with jQuery, SCSS, and no modern JS framework.

## Languages

**Primary:**
- Ruby 3.4.9 (`/.ruby-version`) — application code
- JavaScript (ES5/ES6 via Sprockets) — browser-side behaviour

**Secondary:**
- SCSS (`app/assets/stylesheets/`) — styles compiled via `sass-rails`
- ERB — view templates

## Runtime

**Environment:**
- Ruby 3.4.9 (pinned in `.ruby-version`)
- Node.js 22.22.2 (pinned in `.node-version`, used for asset compilation tooling)

**Web Server:**
- Puma 8.0.0 (`config/puma.rb`) — development and production
- Passenger (`config/daddy.yml` `app.type: passenger`) — declared as production app server type via `daddy` provisioning

**Package Manager:**
- Bundler — Ruby gems; `Gemfile.lock` present and committed
- Yarn — JS packages; `yarn.lock` present, but `package.json` has no runtime JS dependencies (all JS served via gem-bundled Sprockets assets)

## Frameworks

**Core:**
- Rails 8.1.3 (`config/application.rb` — `config.load_defaults 8.1`)
- ActiveRecord 8.1.3 — ORM

**Authentication:**
- Devise 5.0.3 — user authentication and registration
- devise-two-factor 6.4.0 — TOTP-based 2FA
- OmniAuth 2.1.4 — OAuth integration framework

**Frontend:**
- Sprockets (via `sass-rails 6.0.0`) — Rails asset pipeline
- jQuery 4.6.1 (via `jquery-rails`) — DOM/AJAX
- jQuery UI 8.0.0 (via `jquery-ui-rails`)
- Uglifier 4.2.1 — JavaScript minification in production

**Testing:**
- Minitest 5.x — unit tests
- Cucumber / cucumber-rails — acceptance / integration tests (`features/`)
- Capybara 3.40.0 + Selenium WebDriver — browser-based feature tests
- SimpleCov — code coverage

**Build/Dev:**
- Bootsnap 1.23.0 — boot-time optimisation
- Babel (`babel.config.js`) — present but JS dependencies are minimal
- Itamae + `daddy` — server provisioning (recipes in `config/itamae/`)

## Key Dependencies

**Critical:**
- `acts_as_tree 2.9.1` — hierarchical bookmark/folder structure via adjacency list
- `devise 5.0.3` — full authentication lifecycle (`app/models/user.rb`)
- `devise-two-factor 6.4.0` + `rqrcode 2.2.0` — TOTP 2FA with QR code provisioning
- `feedjira 4.0.2` — RSS/Atom feed parsing (`app/models/feed.rb`)
- `nokogiri 1.19.2` — HTML/XML parsing (feed content, link metadata)
- `holiday_jp 0.8.1` — Japanese public holiday data used in `Calendar` model (`app/models/calendar.rb`)

**HTTP Clients:**
- `httparty 0.24.2` — outbound HTTP requests
- `faraday 1.10.5` + `faraday_middleware` — alternative HTTP client (present in Gemfile, check usage)

**Infrastructure:**
- `puma 8.0.0` — web server
- `mysql2 >= 0.4.4, < 0.6.0` — MySQL adapter (declared in `:itamae` group, used for production DB)
- `daddy 0.12.0` — internal provisioning/infra gem

**I18n:**
- `rails-i18n 8.1.0` — Rails locale data
- `devise-i18n 1.16.0` — Devise locale data
- `i18n-js 4.2.4` — expose I18n translations to JavaScript

## Database

**Type:** MySQL (mysql2 adapter)
**ORM:** ActiveRecord 8.1.3
**Configuration:** `config/database.yml`
- Development DB: `bookmarks_dev`
- Test DB: `bookmarks_test`
- Production DB: `bookmarks_pro`
- Connection via env vars: `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`
- Encoding: `utf8mb4`

## Frontend Approach

Rails Sprockets asset pipeline — **no Webpack/Vite/esbuild**.

- JavaScript: `app/assets/javascripts/application.js` (manifest-based concatenation)
  - Includes: `rails-ujs`, `activestorage`, `jquery`, `jquery-ui`, and per-feature JS files
- Styles: `app/assets/stylesheets/application.css` + per-feature `.css.scss` files
- No React, Vue, Stimulus, or Turbo detected

## Background Jobs

- ActiveJob 8.1.3 is included (via `rails/all`)
- Only `app/jobs/application_job.rb` (base class) exists — no custom job classes detected
- No queue adapter explicitly configured; defaults to inline execution in development/test
- Production comment in `config/environments/production.rb` mentions `:resque` as a candidate but it is commented out

## Caching

- Development: `:memory_store` (`config/environments/development.rb`)
- Test: `:null_store`
- Production: not explicitly set (commented-out `mem_cache_store`) — defaults to Rails in-process memory cache

## Action Cable

- Development/Test: `async` adapter (`config/cable.yml`)
- Production: Redis adapter at `redis://localhost:6379/1`

## Active Storage

- Configured for local disk service in production (`config/environments/production.rb`)
- `config/storage.yml` has commented-out templates for S3, GCS, and Azure — none are active

## Containerisation

- `Dockerfile.app`, `Dockerfile.base`, `Dockerfile.test` present at repo root
- `.dockerignore` present
- CI via `Jenkinsfile`

---

*Stack analysis: 2026-04-27*
