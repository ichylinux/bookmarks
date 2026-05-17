# Codebase Structure

**Analysis Date:** 2026-05-18

## Directory Layout

```
bookmarks/                         # Rails 8.1 app root
├── app/
│   ├── assets/
│   │   ├── javascripts/           # Sprockets JS bundle
│   │   └── stylesheets/
│   │       └── themes/            # Theme SCSS files (modern, simple, classic)
│   ├── channels/                  # ActionCable (stub only)
│   ├── controllers/
│   │   ├── concerns/              # Shared controller concerns
│   │   └── users/                 # Devise-extension controllers
│   ├── helpers/                   # View helpers per resource
│   ├── jobs/                      # ApplicationJob (stub only — no background jobs)
│   ├── mailers/                   # ActionMailer (currently unused)
│   ├── models/
│   │   ├── concerns/              # Model concerns (Gadget)
│   │   └── crud/                  # Crud::ByUser module
│   ├── services/                  # External API client objects
│   └── views/
│       ├── bookmarks/
│       ├── calendars/
│       ├── common/                # Shared partials (menu, drawer nav)
│       ├── devise/                # Devise form overrides
│       ├── feeds/
│       ├── icons/                 # SVG icon partials
│       ├── layouts/               # application.html.erb, mailer layouts
│       ├── mastodon_accounts/
│       ├── notes/
│       ├── preferences/
│       ├── todos/
│       ├── users/                 # 2FA, email registration, two_factor_setup views
│       ├── welcome/               # Root page: landing + dashboard partials
│       └── x_accounts/
├── bin/                           # Rails binstubs (rails, rake, etc.)
├── config/
│   ├── environments/              # development.rb, test.rb, production.rb
│   ├── initializers/              # app_config.rb (loads config/app_config.yml)
│   ├── locales/                   # i18n YAML files (ja.yml, en.yml)
│   ├── app_config.yml             # App-specific config (OmniAuth keys, etc.)
│   ├── application.rb             # Encryption keys, i18n, timezone
│   ├── database.yml
│   └── routes.rb
├── db/
│   ├── migrate/                   # AR migrations
│   ├── schema.rb                  # Authoritative schema (version 2026_05_18_120000)
│   └── seeds.rb
├── features/                      # Cucumber E2E suite
│   ├── *.feature                  # Japanese-language feature files
│   ├── step_definitions/          # Step implementations per domain
│   └── support/
│       ├── env.rb                 # Capybara + Selenium config
│       ├── hooks.rb               # Before/After hooks (state reset per scenario)
│       ├── login.rb               # Login helper for Cucumber
│       └── window_resize.rb
├── lib/
│   ├── assets/                    # Vendored non-gem assets
│   ├── capistrano/                # Capistrano deploy tasks
│   └── tasks/                     # Rake tasks
├── public/                        # Static assets, error pages
├── script/                        # Utility scripts
├── test/
│   ├── controllers/               # Integration tests (ActionDispatch::IntegrationTest)
│   ├── fixtures/                  # YAML fixtures (users, bookmarks, todos, etc.)
│   ├── helpers/                   # Helper tests
│   ├── i18n/                      # i18n correctness tests
│   ├── integration/               # (currently empty / placeholder)
│   ├── models/                    # Unit tests for AR models
│   ├── services/                  # Unit tests for service objects
│   ├── support/                   # Shared test helper methods (class_eval'd into TestCase)
│   ├── system/                    # System test placeholder
│   └── test_helper.rb
├── vendor/                        # Vendored gems/assets
├── Gemfile
├── Rakefile
├── babel.config.js
├── eslint.config.mjs
├── package.json                   # JS dependencies (ESLint, Babel)
└── yarn.lock
```

## Directory Purposes

**`app/controllers/`:**
- Purpose: HTTP request handling; all inherit from `ApplicationController`
- Contains: One controller file per resource, plus `concerns/` and `users/` subdirs
- Key files: `application_controller.rb`, `welcome_controller.rb`

**`app/controllers/concerns/`:**
- Purpose: Reusable controller behavior included via `include`
- Key files: `localization.rb` (locale `around_action`), `twitter_link_requirement.rb` (X auth guard)

**`app/controllers/users/`:**
- Purpose: Devise overrides and extensions for authentication flows
- Key files: `sessions_controller.rb` (2FA intercept), `two_factor_authentication_controller.rb`, `two_factor_setup_controller.rb`, `omniauth_callbacks_controller.rb`, `email_registrations_controller.rb`

**`app/models/`:**
- Purpose: ActiveRecord models and plain Ruby domain objects
- Contains: One file per model; gadget plain-Ruby classes at top level
- Key files: `user.rb`, `portal.rb`, `preference.rb`, `bookmark.rb`, `feed.rb`

**`app/models/concerns/`:**
- Purpose: Shareable model modules
- Key files: `gadget.rb` (Gadget interface for portal widgets)

**`app/models/crud/`:**
- Purpose: Authorization mixin
- Key files: `by_user.rb` (`readable_by?`, `updatable_by?`, `deletable_by?`)

**`app/services/`:**
- Purpose: External HTTP API clients; plain Ruby objects returning result hashes
- Key files: `mastodon_client.rb`, `x_client.rb`

**`app/views/welcome/`:**
- Purpose: Root page views — both landing (unauthenticated) and portal dashboard (authenticated)
- Key files: `index.html.erb`, `_dashboard.html.erb`, `_landing.html.erb`, `_portal_column_section.html.erb`, per-gadget partials

**`app/views/common/`:**
- Purpose: Partials reused across multiple views (navigation menu, drawer nav links)

**`app/views/icons/`:**
- Purpose: SVG icon partials rendered via `render 'icons/foo'`

**`app/views/layouts/`:**
- Purpose: Page-level HTML shell
- Key files: `application.html.erb` (sets body theme/font-size classes, flash messages, drawer nav)

**`app/assets/stylesheets/themes/`:**
- Purpose: Theme-specific CSS — body-class-gated styles
- Key files: `modern.css.scss`, `simple.css.scss`, `classic.css.scss`, `_drawer_shared.scss`, `_notes_shared.scss`

**`app/assets/javascripts/`:**
- Purpose: Sprockets JS bundle; all files under this directory are included via `require_tree .`
- Key files: `application.js` (manifest), `portal_lazy.js` (lazy column loader), `portal_mobile_tabs.js`, `portal_column_width_sliders.js`, `note_gadget.js`, `flash_messages.js`

**`config/`:**
- Purpose: Rails configuration
- Key files: `routes.rb`, `application.rb`, `app_config.yml` (loaded by `initializers/app_config.rb` into `Rails.application.config.app_config`)

**`config/locales/`:**
- Purpose: i18n translation files
- Language files: `ja.yml` (default), `en.yml`

**`db/`:**
- Purpose: Database schema and migrations
- Key files: `schema.rb` (canonical truth for DB structure), `migrate/` (sequential AR migrations)

**`features/`:**
- Purpose: Cucumber E2E test suite; run via `bundle exec rake dad:test`
- Feature files: Named `01.ブックマーク.feature` through `07.設定.feature` (Japanese names)
- Key files: `support/hooks.rb` (Before hook resets preference state per scenario)

**`test/`:**
- Purpose: Minitest suite (`bin/rails test`)
- Contains: `models/` (unit), `controllers/` (integration via `ActionDispatch::IntegrationTest`), `services/` (unit for MastodonClient, XClient)
- `support/` files are loaded into `ActiveSupport::TestCase` via `class_eval`

## Key File Locations

**Entry Points:**
- `config/routes.rb`: All route definitions
- `app/controllers/welcome_controller.rb`: Root `/` handler
- `app/controllers/application_controller.rb`: Auth and cross-cutting before_actions

**Configuration:**
- `config/application.rb`: Encryption keys, locale, timezone
- `config/app_config.yml`: OmniAuth provider credentials (references ENV vars)
- `config/initializers/app_config.rb`: Single line loading `app_config.yml` into `Rails.application.config.app_config`

**Core Logic:**
- `app/models/portal.rb`: Gadget assembly, column layout
- `app/models/preference.rb`: All user preference constants and column-width validation
- `app/models/user.rb`: Devise configuration, OmniAuth provisioning, 2FA helpers
- `app/models/concerns/gadget.rb`: Gadget interface definition
- `app/models/crud/by_user.rb`: Authorization mixin

**External API Clients:**
- `app/services/mastodon_client.rb`
- `app/services/x_client.rb`

**Testing:**
- `test/test_helper.rb`: Fixture loading, support file class_eval, Devise integration helpers
- `test/support/*.rb`: Shared helper methods injected into all test cases
- `features/support/hooks.rb`: Cucumber Before hooks for DB state reset

**Assets:**
- `app/assets/javascripts/application.js`: JS manifest (entry point for Sprockets)
- `app/assets/stylesheets/application.css`: CSS manifest
- `app/assets/stylesheets/themes/`: Per-theme SCSS overrides

## Naming Conventions

**Files:**
- Models: `snake_case.rb` matching class name (e.g., `mastodon_account.rb` → `MastodonAccount`)
- Controllers: `snake_case_controller.rb` (e.g., `x_accounts_controller.rb`)
- Views: `resource/action.html.erb`; partials prefixed with `_`
- JS files: `snake_case.js` per feature (e.g., `portal_lazy.js`, `note_gadget.js`)
- SCSS files: `snake_case.css.scss` per resource; themes in `themes/`

**Directories:**
- Views subdirs match controller/resource name (e.g., `app/views/mastodon_accounts/`)
- Namespace controllers go in subdir matching namespace (e.g., `app/controllers/users/`)

**Classes:**
- Models: PascalCase (e.g., `PortalLayout`, `XAccount`)
- Controllers: PascalCase + `Controller` suffix
- Concerns: PascalCase module name (e.g., `Crud::ByUser`, `Gadget`)

**Tests:**
- Minitest: Japanese method names for test descriptions (e.g., `test_一覧`, `test_更新`)
- Cucumber features: Japanese filenames and scenario descriptions

## Where to Add New Code

**New resource (CRUD feature):**
- Controller: `app/controllers/<resource>s_controller.rb`
- Model: `app/models/<resource>.rb` — include `Crud::ByUser` if user-owned, use `destroy_logically!` for deletes
- Views: `app/views/<resource>s/` directory
- Routes: Add `resources :<resource>s` block in `config/routes.rb`
- Minitest: `test/models/<resource>_test.rb`, `test/controllers/<resource>s_controller_test.rb`
- Cucumber: Add a new `.feature` file under `features/` and step definitions under `features/step_definitions/`

**New gadget type:**
- Plain Ruby class: `app/models/<name>_gadget.rb` — include `Gadget` concern or manually implement `gadget_id`, `entries`, `title`
- Register in `Portal#get_gadgets` (`app/models/portal.rb`)
- Add partial: `app/views/welcome/_<name>_gadget.html.erb`
- Add feature flag in `Preference` if the gadget is optional

**New controller concern:**
- File: `app/controllers/concerns/<concern_name>.rb`
- Include in target controller via `include <ConcernName>`

**New model concern:**
- File: `app/models/concerns/<concern_name>.rb`

**New external API client:**
- File: `app/services/<service_name>_client.rb` (plain Ruby class)
- Return `{ success: Boolean, ... }` hash from public methods
- Add test: `test/services/<service_name>_client_test.rb`

**Shared test helpers:**
- File: `test/support/<topic>.rb`
- Automatically loaded into `ActiveSupport::TestCase` via `class_eval` in `test/test_helper.rb`

**New SCSS theme:**
- File: `app/assets/stylesheets/themes/<theme_name>.css.scss`
- Apply via body class; see `WelcomeHelper#favorite_theme` (`app/helpers/welcome_helper.rb`)

**i18n strings:**
- Add to `config/locales/ja.yml` (primary) and `config/locales/en.yml` (secondary)

## Special Directories

**`.planning/`:**
- Purpose: GSD planning documents (milestones, phases, codebase maps, research)
- Generated: No (hand-maintained and AI-generated planning artifacts)
- Committed: Yes

**`.claude/`:**
- Purpose: Claude agent skill definitions and worktree state
- Generated: Partially
- Committed: Yes

**`tmp/`:**
- Purpose: Rails temp files, caches, PIDs
- Generated: Yes
- Committed: No

**`log/`:**
- Purpose: Rails log files
- Generated: Yes
- Committed: No

**`public/assets/`:**
- Purpose: Sprockets-compiled assets (created by `rails assets:precompile`)
- Generated: Yes
- Committed: No — always run `rails assets:clobber` after precompile to clean up

---

*Structure analysis: 2026-05-18*
