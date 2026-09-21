<!-- generated-by: gsd-doc-writer -->
# Development

## Local setup

After completing the steps in [Getting Started](GETTING-STARTED.md), the following additional steps prepare a development environment:

```bash
# Environment variables are loaded from a gitignored .env via dotenv-rails
# (Gemfile group :development, :test). There is no .env.example — create .env
# yourself if it is missing. See CONFIGURATION.md for the full variable list.

# Install all dependencies
bundle install
yarn install

# Prepare both development and test databases
bin/rails db:reset
bin/rails db:test:prepare
```

Start the development server:

```bash
bin/rails s           # Puma on port 3000 (override with PORT env var)
bin/dev               # Alias for bin/rails server
bin/rails console     # Interactive Rails console
```

After a schema change:

```bash
bin/rails db:migrate
bin/rails db:test:prepare
```

## Build commands

### Ruby / Rails

| Command | Description |
|---------|-------------|
| `bin/rails s` | Start Puma development server (default port 3000) |
| `bin/dev` | Alias for `bin/rails server` |
| `bin/rails console` | Open Rails console |
| `bin/rails routes` | Print all routes |
| `bin/rails db:migrate` | Run pending migrations |
| `bin/rails db:test:prepare` | Sync test schema after migrations |
| `bin/rails db:reset` | Drop, create, schema-load, and seed the development DB |
| `bundle exec rake dad:setup:test` | Bootstrap test environment via the `daddy` gem |
| `bundle exec rake dad:db:create` | Create the database via the `daddy` gem |
| `bin/rails users:promote_admin` | Promote an active user to admin (`EMAIL=` or `USER_ID=`) |
| `bin/rails assets:precompile` | Compile Sprockets assets |
| `bin/rails assets:clobber` | Remove compiled assets (run after `assets:precompile` in development) |

### JavaScript

| Command | Description |
|---------|-------------|
| `yarn run lint` | ESLint — lint `app/assets/javascripts/**/*.js` |
| `yarn run lint:fix` | ESLint — auto-fix lint violations |
| `yarn run format` | Prettier — format `app/assets/javascripts/**/*.js` |

### Testing

| Command | Description |
|---------|-------------|
| `bin/rails test` | Run Minitest unit + integration suite |
| `bin/rails test test/models/user_test.rb` | Run a single Minitest file |
| `bundle exec rake dad:test` | Run Cucumber E2E suite (spawns Rails server + headless Chrome automatically) |
| `bundle exec rake dad:test features/02.タスク.feature` | Run a single Cucumber feature (`dad:test` forwards paths, including `:line`) |

See [Testing](TESTING.md) for full details.

## Code style

### Ruby

- Two-space indentation (Rails default); no RuboCop config enforced (`.rubocop.yml` is absent).
- `frozen_string_literal: true` is not applied consistently. It appears in `app/controllers/admin/users_controller.rb` and some test files; most `app/` source files omit it.
- Test method names use Japanese for domain actions: `def test_一覧`, `def test_登録`, `def test_削除`. Technical or regression tests may use English names.
- Inline business-rule comments inside models and controllers are written in Japanese; architectural/technical comments may be English.

### JavaScript

Linter: **ESLint 9.x** — config file `eslint.config.mjs` (parser `@babel/eslint-parser` with `babel.config.js`).  
Formatter: **Prettier 3.x** — config file `.prettierrc.json`.

Prettier settings:

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5"
}
```

Rules:
- Prefer `const` and `let`. `eslint.config.mjs` extends `eslint:recommended` and does not enable `no-var`; a few existing files still use `var`.
- No ES module `import` — the Sprockets asset pipeline uses `//= require` directives in `application.js`.
- Reusable modules use the IIFE pattern (`window.moduleName`); page-specific event binding uses jQuery document-ready (`$(function() { ... })`).
- Allowed globals (from `eslint.config.mjs`): `$`, `jQuery`, `ActionCable`, `App`, `MOBILE_MQ`.

Run linting and formatting before every commit:

```bash
yarn run lint
yarn run format
```

### SCSS

- These non-theme files must contain **no** `.modern`, `.classic`, or `.simple` selectors — enforced by `test/assets/css_architecture_contract_test.rb`: `bookmarks`, `calendars`, `common`, `devise`, `feeds`, `landing`, `preferences`, `todos`, `welcome`.
- Theme-specific overrides go in `app/assets/stylesheets/themes/<theme>.css.scss` (`modern`, `classic`, `simple`). Shared theme partials live alongside them (`_drawer_shared.scss`, `_notes_shared.scss`).
- Mobile rules (`@media (max-width: 767px)`) for shared components (`.preferences-table`, `.bookmarks-table`) belong in `common.css.scss`, not in theme files — enforced by `test/assets/mobile_responsive_contract_test.rb`.
- Do not gate styles on hover/pointer media features (`hover`, `pointer`, `any-hover`, `any-pointer`). Gate on viewport width instead — enforced as WINCHR-01 in `test/assets/css_architecture_contract_test.rb`.

### i18n

- All user-facing strings belong in **both** `config/locales/ja.yml` (primary; `config.i18n.default_locale = :ja`) and `config/locales/en.yml`; the two files must remain in parity.
- Parity is enforced by `test/i18n/locales_parity_test.rb` — this test must pass after any locale changes.

## Directory structure

| Path | Purpose |
|------|---------|
| `app/controllers/` | HTTP layer, Devise extensions (`users/`), admin namespace |
| `app/models/` | ActiveRecord models, gadget objects, concerns (`Crud::ByUser`) |
| `app/services/` | Faraday clients (`MastodonClient`, `XClient`) and Mastodon input normalizers |
| `app/helpers/` | View helpers (`ApplicationHelper`, calendar/welcome helpers) |
| `app/views/` | ERB templates and partials |
| `app/assets/javascripts/` | jQuery modules (linted by ESLint, formatted by Prettier) |
| `app/assets/stylesheets/` | SCSS; theme overrides in `themes/` subdirectory |
| `config/locales/` | `ja.yml` and `en.yml` — must be kept in parity |
| `lib/omniauth/` | Custom Mastodon OmniAuth strategy |
| `lib/tasks/` | Custom Rake tasks (`users.rake`, `charset.rake`) |
| `features/` | Cucumber feature files and step definitions (written in Japanese) |
| `test/` | Minitest files; helpers in `test/support/`; asset contracts in `test/assets/` |

## Branch conventions

No formal branch naming convention is documented. Contributions branch from `master` (the default long-lived branch; a `release` branch also exists on the remote). Descriptive branch names such as `feat/my-feature` or `fix/issue-description` are encouraged.

## PR process

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full checklist. There is no GitHub pull-request template. Summary:

- Branch from `master` and make focused changes with tests where behavior changes.
- Run the full gate before opening a PR:
  ```bash
  yarn run lint && bin/rails test && bundle exec rake dad:test
  ```
- Do not use `bundle exec cucumber` directly — always use `bundle exec rake dad:test`.
- All three suites must exit 0 before a PR is considered ready. Jenkinsfile runs Minitest and triggers the downstream features job; Cucumber runs in Jenkinsfile.features; it does not run `yarn run lint`, so lint must be checked locally.
- Describe what changed and why in the PR body.

## Key project constraints

- **No `dependent: :destroy` or `dependent: :delete_all`** on ActiveRecord associations — enforced by `test/models/active_record_dependent_contract_test.rb`.
- **Cucumber preference changes** must use the `/preferences` UI in step definitions, not direct ActiveRecord writes — prevents cross-connection state leakage between scenarios.
- **No hover/pointer media-feature gates** in stylesheets — enforced by WINCHR-01 in `test/assets/css_architecture_contract_test.rb`.
- Assets compiled with `rails assets:precompile` must be cleaned up afterward with `rails assets:clobber`; do not leave precompiled assets in the working tree.

## Related docs

- [Getting Started](GETTING-STARTED.md) — prerequisites and first-run setup
- [Testing](TESTING.md) — full test suite reference
- [Configuration](CONFIGURATION.md) — environment variables and config files
- [Architecture](ARCHITECTURE.md) — system design and component overview
