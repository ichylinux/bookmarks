# Codebase Structure

**Analysis Date:** 2026-11-26

## Directory Layout

```
bookmarks/
├── app/
│   ├── assets/
│   │   ├── javascripts/          # Sprockets bundle (application.js: jquery, jquery-ui, rails-ujs, activestorage, require_tree .)
│   │   └── stylesheets/          # per-screen *.css.scss + themes/ (modern, simple, classic, _drawer_shared, _notes_shared)
│   ├── channels/application_cable/  # ActionCable stub (no channels)
│   ├── controllers/
│   │   ├── admin/                # BaseController (require_admin), users, x_api_usages
│   │   ├── concerns/             # localization.rb, twitter_link_requirement.rb
│   │   └── users/                # Devise extensions (sessions, 2FA, OmniAuth, email registration, mastodon instance, account deletion)
│   ├── helpers/
│   ├── models/
│   │   ├── concerns/gadget.rb
│   │   └── crud/by_user.rb
│   ├── services/                 # x_client, mastodon_client, mastodon_handle_normalizer, mastodon_instance_normalizer
│   └── views/
│       ├── admin/{users,x_api_usages}/
│       ├── bookmarks/ calendars/ feeds/ todos/ notes/ mastodon_accounts/ x_accounts/
│       ├── feed_article_histories/   # reading history page
│       ├── common/                   # drawer, menu, nav, gadget title w/ icon, like button, history entry
│       ├── icons/                    # SVG partials (render 'icons/like', …)
│       ├── devise/ users/            # auth screens, 2FA, email registration, account deletion, mastodon authorize redirect
│       ├── layouts/                  # application.html.erb, mailer
│       ├── pages/                    # privacy, terms
│       ├── preferences/
│       └── welcome/                  # index, _landing*, _dashboard, _portal_column_section, per-gadget partials
├── bin/                      # rails, rake, setup, bundler-audit, …
├── config/
│   ├── environments/ initializers/ locales/{ja,en}.yml
│   ├── app_config.yml        # ENV-interpolated app config
│   ├── bundler-audit.yml
│   ├── ci.rb                 # unused Rails scaffold
│   ├── daddy.yml             # daddy gem settings
│   ├── itamae/               # provisioning cookbooks + roles
│   ├── kustomize/            # k8s manifests (app, db, service)
│   └── routes.rb
├── db/
│   ├── migrate/
│   ├── schema.rb             # version 2026_11_24_120000
│   └── seeds.rb
├── docs/                     # generated project documentation
├── features/                 # Cucumber (Japanese / English), run via rake dad:test
│   ├── NN.<name>.feature     # 01–15 (two files share prefix 07)
│   ├── step_definitions/
│   └── support/              # env.rb, hooks.rb, login.rb, preferences_reset.rb, test_support.rb, window_resize.rb, gadget_settings_helpers.rb
├── lib/
│   ├── omniauth/strategies/mastodon.rb
│   └── tasks/                # users.rake (promote_admin), charset.rake
├── test/
│   ├── assets/               # source-level JS/CSS contract tests (no browser)
│   ├── controllers/          # integration tests; admin/, users/, welcome_controller/
│   ├── fixtures/             # users, bookmarks, feeds, notes, todos, portals, preferences, mastodon_accounts, oauth_identities, visited_links, files/
│   ├── helpers/ i18n/ lib/omniauth/strategies/ models/ services/
│   ├── support/              # class_eval'd into ActiveSupport::TestCase
│   └── integration/ mailers/ system/   # empty
├── .planning/                # GSD planning docs (this directory)
├── .claude/ .cursor/         # agent configuration
├── Dockerfile.{base,app,test}
├── Jenkinsfile, Jenkinsfile.features
├── eslint.config.mjs, babel.config.js, package.json, yarn.lock
└── Gemfile, Gemfile.lock, Rakefile, CLAUDE.md, CONTRIBUTING.md, SECURITY.md
```

## Key Files

**Entry points:** `config/routes.rb`, `app/controllers/welcome_controller.rb` (root), `app/controllers/application_controller.rb`.

**Domain core:**
- `app/models/portal.rb` — gadget assembly and layout
- `app/models/preference.rb` — all user settings and defaults
- `app/models/user.rb` — auth, OmniAuth provisioning, lifecycle (delete / purge / disconnect)
- `app/models/visited_link.rb` — visits, likes, reading history
- `app/models/x_api_call.rb` — X API metering

**Frontend modules** (`app/assets/javascripts/`):

| File | Role |
|------|------|
| `portal_lazy.js` | `window.portalLazy.register/loadColumn` — mobile per-column lazy gadget loading |
| `portal_mobile_tabs.js` | Mobile column tabs, active index in `localStorage` |
| `portal_gadget_sort.js` | jQuery UI sortable for gadgets (long-press on touch), posts `save_state` |
| `portal_column_width_sliders.js` | Column width sliders on preferences |
| `gadget_header_settings.js` | Feed / X / Mastodon header settings dialogs |
| `visited_links.js` | Visit beacons, like toggling, offline queue |
| `bookmark_gadget.js`, `note_gadget.js`, `todos.js` | Gadget / page interactions |
| `menu.js`, `flash_messages.js` | Drawer menu (theme-guarded), flash dismissal |
| `auth_mastodon_instance.js` | Mastodon instance form on sign-in |
| `feeds.js`, `bookmarks.js`, `calendars.js` | Form helpers (title fetch etc.) |

**Testing:** `test/test_helper.rb`, `test/support/*.rb`, `features/support/hooks.rb` (global `Before` deletes MastodonAccount / XAccount / XApiCall / VisitedLink rows; tagged hooks install WebMock stubs).

## Naming Conventions

- Models `snake_case.rb` ↔ PascalCase class; controllers `<plural>_controller.rb`; namespaced controllers in matching subdirectory
- Views `resource/action.html.erb`, partials `_name.html.erb`
- JS `snake_case.js`, one feature per file
- SCSS `snake_case.css.scss`; theme overrides only in `themes/`
- Gadget DOM / ids: `feed_<id>`, `x_account_<id>`, `mastodon_account_<id>`, `bookmark_gadget`, `todo`
- Cucumber feature files: `NN.<日本語名>.feature`
- Asset contract tests: `test/assets/<subject>_contract_test.rb`

## Where to Add New Code

**User-owned resource:**
- Model with `include Crud::ByUser`; soft-delete via `deleted` column + `destroy_logically!`
- **Add the table to `User#purge!`** and a `has_many` on `User` (no `dependent:` option — forbidden by contract test)
- Controller with a `preload_*` ownership check → `head :not_found`
- Routes, views, `test/models/…`, `test/controllers/…`, a feature file

**Gadget type:**
- Class implementing `gadget_id`, `title`, `entries` (or `include Gadget`)
- Register in `Portal#get_gadgets` (behind a `Preference` flag if optional)
- Partial `app/views/welcome/_<name>.html.erb`; if it fetches remote data, use `window.portalLazy.register` + XHR to a `show` action that calls `assign_entry_link_states`
- For history / likes, add the source to `VisitedLink::HISTORY_SOURCES` and `GADGET_ID_PATTERNS`

**Admin screen:** controller under `app/controllers/admin/` inheriting `Admin::BaseController`; route in `namespace :admin`.

**External client:** `app/services/<name>_client.rb`, optional `connection:` injection, result-hash return, `test/services/<name>_client_test.rb`.

**Preference flag:** migration with `default: false, null: false`, default in `Preference.default_preference`, permit in `PreferencesController#user_params`, form section in `preferences/`, strings in both locale files.

**i18n:** add keys to `config/locales/ja.yml` **and** `en.yml` (parity test).

**JS module:** new IIFE file in `app/assets/javascripts/` (picked up by `require_tree .`); consider a `test/assets/*_contract_test.rb`.

## Special Directories

| Path | Generated | Committed |
|------|-----------|-----------|
| `.planning/` | Hand + AI maintained | Yes |
| `docs/` | Generated documentation | Yes |
| `tmp/`, `log/` | Yes | No |
| `public/assets/` | `assets:precompile` | No — run `rails assets:clobber` after a local precompile |
| `coverage/`, `test/reports/`, `features/reports/` | CI output | No |

---

*Structure analysis: 2026-11-26*
