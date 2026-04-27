# Codebase Structure

## Overview

Standard Rails 8.1 directory layout with MySQL as the database. The application uses ERB templates and the Sprockets asset pipeline (no Webpacker/Vite — JavaScript is managed via Yarn/Babel but served through the classic pipeline). Deployment infrastructure includes Dockerfile variants, a Kubernetes kustomize config, and Capistrano tasks, which are co-located in `config/` and `lib/capistrano/`.

## Top-Level Directory Layout

```
bookmarks/
├── app/                  # Rails application code
│   ├── assets/           # Sprockets assets (images, JS, CSS)
│   ├── channels/         # ActionCable (stub only)
│   ├── controllers/      # Request handlers
│   ├── helpers/          # View helpers
│   ├── jobs/             # ActiveJob (stub only)
│   ├── mailers/          # ActionMailer (stub only)
│   ├── models/           # AR models, concerns, gadget objects
│   └── views/            # ERB templates
├── bin/                  # Binstubs (rails, rake, bundle, etc.)
├── config/               # App config, routes, initializers, deploy config
│   ├── environments/     # Per-environment overrides
│   ├── initializers/     # Boot-time configuration
│   ├── itamae/           # Server provisioning recipes (itamae)
│   ├── kustomize/        # Kubernetes kustomize overlays
│   └── locales/          # I18n YAML files (ja primary)
├── db/                   # Schema and migrations
│   └── migrate/          # Migration files
├── features/             # Cucumber integration tests
│   ├── step_definitions/
│   └── support/
├── lib/
│   ├── assets/           # Non-app assets
│   ├── capistrano/tasks/ # Custom Capistrano deploy tasks
│   └── tasks/            # Custom Rake tasks
├── public/               # Static files served directly
├── script/               # One-off scripts
├── test/                 # Minitest unit and controller tests
│   ├── controllers/
│   ├── fixtures/
│   ├── integration/
│   ├── mailers/
│   ├── models/
│   ├── support/
│   └── system/
├── vendor/assets/        # Third-party JS/CSS
├── Dockerfile.app        # Production app image
├── Dockerfile.base       # Shared base image
├── Dockerfile.test       # Test image
├── Gemfile               # Ruby dependencies
├── Jenkinsfile           # CI pipeline definition
├── package.json          # Node dependencies (Babel, jQuery)
├── babel.config.js       # Babel transpiler config
└── yarn.lock             # Node lockfile
```

## Key Directories and Their Purpose

**`app/controllers/`**
- `application_controller.rb` — base controller; sets `authenticate_user!` and Devise parameter sanitizer
- `welcome_controller.rb` — portal homepage (`/`) and layout save endpoint
- `bookmarks_controller.rb`, `feeds_controller.rb`, `todos_controller.rb`, `calendars_controller.rb`, `preferences_controller.rb` — standard CRUD for user-owned resources
- `users/` — Devise overrides: `sessions_controller.rb`, `omniauth_callbacks_controller.rb`, `two_factor_authentication_controller.rb`, `two_factor_setup_controller.rb`
- `controllers/concerns/` — empty; no shared controller concerns in use

**`app/models/`**
- `user.rb` — central domain model; Devise, OmniAuth, 2FA, portal creation
- `bookmark.rb` — tree-structured bookmarks (`acts_as_tree`); includes `Crud::ByUser`
- `portal.rb` — dashboard container; assembles gadgets into 3-column layout
- `portal_layout.rb` — stores gadget position (column, order) per user
- `preference.rb` — per-user settings (theme, todo visibility, link behavior)
- `feed.rb` — RSS/Atom feed; fetches content synchronously at render time
- `calendar.rb` — monthly calendar gadget; uses `holiday_jp` for Japanese holidays
- `todo.rb` — task with priority; includes `Crud::ByUser`
- `bookmark_gadget.rb` — plain Ruby object wrapping Bookmark queries for the portal
- `todo_gadget.rb` — plain Ruby object wrapping a Todo collection for the portal
- `crud/by_user.rb` — mixin providing `readable_by?` / `updatable_by?` / `deletable_by?`
- `concerns/gadget.rb` — `Gadget` concern defining the gadget protocol (`gadget_id`, `entries`, `visible?`)
- `application_record.rb` — base AR class

**`app/views/`**
- `layouts/application.html.erb` — main HTML shell
- `welcome/` — portal dashboard templates and gadget partials (`_bookmark_gadget.html.erb`, `_todo_gadget.html.erb`, `_feed.html.erb`, `_calendar.html.erb`)
- `bookmarks/`, `feeds/`, `todos/`, `calendars/`, `preferences/` — standard CRUD views
- `users/` — Devise views plus `two_factor_authentication/` and `two_factor_setup/`
- `common/` — shared partials

**`app/assets/`**
- `stylesheets/themes/` — per-theme CSS overrides (theme is a `Preference` attribute)
- `javascripts/` — application JS; jQuery + jQuery UI used for sortable portal layout

**`config/`**
- `routes.rb` — all routes; Devise routes, REST resources, two-factor custom routes
- `initializers/devise.rb` — Devise configuration
- `initializers/app_config.rb` — loads `app_config.yml`
- `daddy.yml` — configuration for the `daddy` gem (HTTP client base settings)
- `database.yml` — MySQL connection (charset utf8mb4); uses environment variables for credentials
- `secrets.yml` — legacy secrets file (superseded by credentials in Rails 5.2+; still present)
- `itamae/` — server provisioning recipes; not part of the Rails boot process
- `kustomize/` — Kubernetes manifests for container deployment

**`db/`**
- `schema.rb` — canonical schema; MySQL, utf8mb4, version `2026_04_20_000000`
- `migrate/` — incremental migration files

**`features/`**
- Cucumber-based integration tests using Capybara and Selenium
- Complements Minitest unit tests in `test/`

**`lib/capistrano/tasks/`**
- Custom Capistrano deploy hooks for this application

## Naming Conventions

**Files:**
- Models: `snake_case.rb` matching class name (e.g., `bookmark_gadget.rb` → `BookmarkGadget`)
- Controllers: `snake_case_controller.rb`; namespaced controllers in subdirectories (`users/sessions_controller.rb`)
- Views: `action_name.html.erb`; partials prefixed with `_`

**Directories:**
- Match controller namespace (`app/controllers/users/`, `app/views/users/`)

## Where to Add New Code

**New resource (model + CRUD):**
- Model: `app/models/<name>.rb` — include `Crud::ByUser` if user-scoped; add `deleted` boolean for logical delete support
- Controller: `app/controllers/<name>s_controller.rb`
- Views: `app/views/<name>s/` — create `index`, `new`, `edit`, `show`, `_form` partials following existing patterns
- Route: add `resources :<name>s` in `config/routes.rb`
- Test: `test/models/<name>_test.rb`, `test/controllers/<name>s_controller_test.rb`

**New portal gadget:**
- If plain Ruby (no persistence): create `app/models/<name>_gadget.rb`, include the `Gadget` concern, implement `entries`
- If AR-backed (persistent, like `Feed` or `Calendar`): implement `gadget_id` and `entries` directly on the model
- Register in `Portal#get_gadgets` (`app/models/portal.rb` lines 51-73)
- Add partial `app/views/welcome/_<name>_gadget.html.erb` (or `_<name>.html.erb` matching `g.class.name.underscore`)

**New user preference:**
- Add column to `preferences` table via migration
- Permit the attribute in `PreferencesController#user_params` (`app/controllers/preferences_controller.rb`)
- Add UI in `app/views/preferences/index.html.erb`

**Shared controller logic:**
- Place in `app/controllers/concerns/`

**Shared model logic:**
- Reusable mixins: `app/models/crud/` (authorization pattern) or `app/models/concerns/` (gadget protocol)

## Special Directories

**`config/itamae/`**
- Purpose: Itamae server provisioning recipes (infrastructure as code for setting up the host OS)
- Generated: No
- Committed: Yes — part of the repo but not loaded by Rails

**`config/kustomize/`**
- Purpose: Kubernetes kustomize overlays for container deployment
- Generated: No
- Committed: Yes

**`vendor/assets/`**
- Purpose: Third-party JS/CSS not managed via npm (e.g., legacy jQuery plugins)
- Generated: No
- Committed: Yes

**`tmp/`**
- Purpose: Rails tmp (cache, pids, sockets)
- Generated: Yes
- Committed: No

---

*Structure analysis: 2026-04-27*
