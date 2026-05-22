<!-- refreshed: 2026-05-23 -->
# Architecture

**Analysis Date:** 2026-05-23

## System Overview

```text
┌──────────────────────────────────────────────────────────────────┐
│                        Browser / Client                          │
│   jQuery + jQuery UI (drag/drop, AJAX), vanilla JS gadget layer  │
└───────────────┬──────────────────────────────────────────────────┘
                │ HTTP
                ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Rails 8.1 MVC App                          │
│                                                                  │
│  Controllers (app/controllers/)                                  │
│  ApplicationController — authenticate_user!, Localization        │
│  ├── WelcomeController        (root — portal dashboard)          │
│  ├── BookmarksController      (CRUD + folder tree)               │
│  ├── TodosController          (CRUD + bulk delete)               │
│  ├── NotesController          (CRUD + AJAX gadget endpoint)      │
│  ├── FeedsController          (CRUD + RSS feeds)                 │
│  ├── PreferencesController    (user settings via nested attrs)   │
│  ├── CalendarsController      (gadget AJAX only)                 │
│  ├── MastodonAccountsController (CRUD + XHR gadget preview)     │
│  ├── XAccountsController      (cache refresh + XHR preview)     │
│  └── users/ (Devise extensions)                                  │
│       ├── SessionsController          (2FA intercept)            │
│       ├── TwoFactorAuthenticationController                      │
│       ├── TwoFactorSetupController    (TOTP QR setup)            │
│       ├── OmniauthCallbacksController (Google, X / twitter2)       │
│       └── EmailRegistrationsController (dummy->real email)       │
└───────────┬──────────────────────────────────────────────────────┘
            │ ActiveRecord
            ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Models / Domain                          │
│   User, Preference, Portal, PortalLayout                         │
│   Bookmark (acts_as_tree), Todo, Note, Feed                      │
│   MastodonAccount, XAccount                                      │
│   Gadget concern: BookmarkGadget, TodoGadget, CalendarGadget     │
└───────────┬──────────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────────┐
│                External Services (via Service Objects)           │
│   MastodonClient  (app/services/mastodon_client.rb) — Faraday   │
│   XClient         (app/services/x_client.rb) — Faraday+OAuth2   │
│   Feed retrieval  (inside Feed model, daddy HttpClient)          │
└──────────────────────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────────┐
│                           MySQL Database                         │
│   (charset: utf8mb4, timezone: Tokyo/local)                      │
└──────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `ApplicationController` | Auth gate (`authenticate_user!`), 2FA session, locale, font-size notice | `app/controllers/application_controller.rb` |
| `Localization` concern | `around_action` resolving locale from preference or Accept-Language | `app/controllers/concerns/localization.rb` |
| `TwitterLinkRequirement` concern | Guard requiring `uid` + `oauth2_token` on X-related routes | `app/controllers/concerns/twitter_link_requirement.rb` |
| `WelcomeController` | Renders portal dashboard or landing page; saves drag-drop layout | `app/controllers/welcome_controller.rb` |
| `Portal` model | Assembles gadget list, maps `PortalLayout` rows to columns | `app/models/portal.rb` |
| `Preference` model | Per-user settings (theme, font size, column count/widths, feature flags) | `app/models/preference.rb` |
| `Crud::ByUser` | Shared `readable_by?` / `updatable_by?` / `deletable_by?` guards | `app/models/crud/by_user.rb` |
| `Gadget` concern | Interface contract (`gadget_id`, `entries`, `visible?`) for portal widgets | `app/models/concerns/gadget.rb` |
| `MastodonClient` | Read-only Mastodon REST API calls via Faraday | `app/services/mastodon_client.rb` |
| `XClient` | X API v2 via Faraday + OAuth 2.0 Bearer (following, tweets, username lookup, token refresh) | `app/services/x_client.rb` |

## Pattern Overview

**Overall:** Standard Rails MVC with a Gadget plug-in system layered on top.

**Key Characteristics:**
- Strict `authenticate_user!` on all controllers; `skip_before_action` only on public entry points (`WelcomeController#index`, `TwoFactorAuthenticationController`)
- Soft deletion (`deleted` boolean column + `.not_deleted` scope + `destroy_logically!`) provided by the `daddy` gem, applied to Bookmark, Todo, Feed, Note, Portal, MastodonAccount, XAccount
- Locale resolution order: saved preference → Accept-Language header → `I18n.default_locale` (`:ja`)
- Preference is lazily initialized via `User#preference` fallback to `Preference.default_preference(user)` — it may be an unsaved in-memory object when the user has no DB row yet
- Portal column layout is stored as `PortalLayout` join records (`user_id`, `column_no`, `display_order`, `gadget_id`) and recomputed each request

## Layers

**Controllers:**
- Purpose: Authenticate, authorize, delegate to models/services, redirect or render
- Location: `app/controllers/`
- Contains: Resource CRUD, Devise extensions, AJAX endpoints (`render layout: false` / `head :ok`)
- Depends on: Models, Service objects
- Used by: Router (`config/routes.rb`)

**Models:**
- Purpose: Business rules, validations, associations, soft-delete, AR scopes
- Location: `app/models/`
- Contains: ActiveRecord models, plain Ruby gadget classes, `Crud::ByUser` and `Gadget` concerns
- Depends on: Database, external gems (`acts_as_tree`, `daddy`, `rotp`)
- Used by: Controllers, Service objects

**Service Objects:**
- Purpose: Encapsulate external HTTP calls with structured result hashes
- Location: `app/services/`
- Contains: `MastodonClient`, `XClient`
- Return value pattern: `{ success: true, items: [...] }` or `{ success: false, error: :symbol }`
- Used by: `MastodonAccountsController`, `XAccountsController`

**Views:**
- Purpose: HTML rendering, ERB templates, JS inline for gadget coordination
- Location: `app/views/`
- Contains: Partials per resource, two layout files (application + mailer), `common/` shared partials
- Theme-controlled body class (`modern` / `simple` / `classic`) applied in layout

**Assets:**
- JS: Sprockets manifest `application.js` bundles jQuery, jQuery UI, and per-feature files via `require_tree .`
- CSS: Sass/SCSS per-resource files plus `themes/` directory with `modern.css.scss`, `simple.css.scss`, `classic.css.scss`

## Data Flow

### Authenticated Request — Portal Dashboard

1. GET `/` → `WelcomeController#index` — skips auth only for unauthenticated; signed-in users get `@portal = current_user.portals.first` (`app/controllers/welcome_controller.rb`)
2. `Portal#portal_columns` — queries `PortalLayout` rows, instantiates gadget objects, partitions into column arrays (`app/models/portal.rb`)
3. `app/views/welcome/index.html.erb` — branches on `favorite_theme`; renders `_dashboard` partial
4. `_dashboard` → `_portal_column_section` → per-gadget partials (e.g., `_bookmark_gadget`, `_feed`, `_mastodon_account`)
5. Gadgets requiring remote data (Feed, Mastodon, X) are loaded lazily via AJAX on mobile via `portalLazy` JS coordinator (`app/assets/javascripts/portal_lazy.js`)

### Two-Factor Authentication Sign-In Flow

1. POST `/users/sign_in` → `Users::SessionsController#create`
2. If `user.two_factor_enabled?` → stores `session[:otp_user_id]`, redirects to `users_two_factor_authentication_path`
3. POST `/users/two_factor_authentication` → `Users::TwoFactorAuthenticationController#verify` — validates TOTP, signs in, clears session key
4. OmniAuth providers bypass 2FA (`sign_in_and_redirect` directly in `Users::OmniauthCallbacksController`)

### Portal Layout Save (AJAX)

1. jQuery UI sortable `update` event fires `collect_portal_layout_params()` in dashboard inline script
2. `$.post('/welcome/save_state', params)` → `WelcomeController#save_state`
3. Calls `portal.update_layout(params[:portal])` which upserts/deletes `PortalLayout` rows in a transaction
4. Responds with `head :ok`

**State Management:**
- No Rails cache store for user data — all portal and preference state lives in DB
- Mobile active column index stored in `localStorage` (`portalMobileActiveColumn`) and pre-hydrated via inline `<script>` before page paint to avoid flash (`app/views/welcome/_dashboard.html.erb`)

## Key Abstractions

**Gadget Protocol:**
- Purpose: Any object placed in a portal column must respond to `gadget_id` (String), `entries` (Array-like), and optionally `title` and `visible?`
- Defined by: `app/models/concerns/gadget.rb` (ActiveSupport::Concern)
- Note: `Feed`, `MastodonAccount`, and `XAccount` implement the same interface without including the concern
- Examples: `app/models/bookmark_gadget.rb`, `app/models/todo_gadget.rb`, `app/models/calendar_gadget.rb`

**Crud::ByUser:**
- Purpose: Ownership authorization mixin — checks `user_id` equality
- File: `app/models/crud/by_user.rb`
- Used by: `Bookmark`, `Feed`, `Note`, `Todo`, `MastodonAccount`, `XAccount`

**Soft Delete (daddy gem):**
- Purpose: `.not_deleted` scope and `destroy_logically!` (sets `deleted = true`) — provided by `daddy` gem
- Referenced at: `app/models/note.rb`, `app/models/todo.rb`, `app/models/feed.rb`, `app/models/mastodon_account.rb`, `app/models/portal.rb`, `app/models/bookmark.rb`, `app/models/x_account.rb`
- Source in companion gem: `/home/ichy/workspace/daddy/lib/daddy/models/query_extension.rb`, `crud_extension.rb`

**Service Object Result Hash:**
- Pattern: `{ success: Boolean, items: Array }` on success; `{ success: false, error: Symbol }` on failure
- Error symbols: `:timeout`, `:network`, `:not_found`, `:api_error`, `:parse_error`, `:unauthorized`, `:rate_limited`
- Files: `app/services/mastodon_client.rb`, `app/services/x_client.rb`

## Entry Points

**Root (`/`):**
- Location: `app/controllers/welcome_controller.rb`
- Triggers: Any HTTP request; unauthenticated users see landing page
- Responsibilities: Assigns `@portal`, delegates to `_dashboard` or `_landing` partial

**Devise Routes:**
- Location: `app/controllers/users/sessions_controller.rb`, `app/controllers/users/omniauth_callbacks_controller.rb`
- Triggers: `/users/sign_in`, `/users/auth/google_oauth2`, `/users/auth/twitter`
- Responsibilities: 2FA routing, OmniAuth user provisioning

**Health Check:**
- Location: Rails built-in `rails/health#show`
- Route: GET `/up`

## Architectural Constraints

- **Threading:** Standard Puma multi-worker/multi-thread. No global mutable state shared across requests beyond `Rails.application.config.app_config` (frozen struct from `config/app_config.yml`)
- **Global state:** `Rails.application.config.app_config` (read-only at boot) provides OmniAuth keys and similar config values
- **Circular imports:** None detected
- **Soft delete everywhere:** Hard `DELETE` is not used for user-owned content. Always call `destroy_logically!` and filter with `.not_deleted`
- **Preference fallback:** `User#preference` overrides ActiveRecord's reader to return an unsaved default object when no `preferences` row exists. Controllers must call `@user.build_preference` before forms that need a persisted record (see `PreferencesController#index`)
- **dad:setup route guard:** Routes are conditionally defined — `devise_for` and custom user routes are skipped when `ARGV.first =~ /^dad:setup/`. This prevents `User` model loading during Docker image builds (`config/routes.rb`)

## Anti-Patterns

### Calling `user.preference` and assuming it is persisted

**What happens:** `User#preference` returns `Preference.default_preference(user)` (new, unsaved) when no DB row exists. Code that calls `.update!` or `.id` on the result will raise or return `nil`.
**Why it's wrong:** Silent nil `id` causes `PortalLayout` foreign key failures; `update!` on an unsaved record raises `ActiveRecord::RecordNotSaved`.
**Do this instead:** Use `@user.build_preference unless @user.preference.present?` in controllers before rendering preference forms (`app/controllers/preferences_controller.rb#index`). For read-only access the fallback is safe.

### Adding a new gadget type without implementing the Gadget protocol

**What happens:** `Portal#get_gadgets` builds a hash of gadget objects keyed by `gadget_id`. Gadgets without a `gadget_id` method will raise `NoMethodError`.
**Why it's wrong:** The portal column render loop and `PortalLayout` persistence both depend on stable string IDs.
**Do this instead:** Include `Gadget` concern (`app/models/concerns/gadget.rb`) or manually define `gadget_id`, `entries`, and `title` methods. Register the new gadget in `Portal#get_gadgets` (`app/models/portal.rb`).

### Bypassing `Crud::ByUser` authorization in controllers

**What happens:** Some controllers call `find(params[:id])` directly then check ownership manually; others use a `preload_*` before_action that checks `readable_by?`.
**Why it's wrong:** Inconsistent pattern risks exposing another user's records if a new action is added without the guard.
**Do this instead:** Always use a `preload_*` before_action that calls `readable_by?(current_user)` and responds with `head :not_found` on failure, as seen in `app/controllers/mastodon_accounts_controller.rb`.

## Error Handling

**Strategy:** Controllers rescue `ActiveRecord::RecordInvalid` for explicit transactions and redirect with flash messages. Service objects return structured result hashes — never raise to the controller layer.

**Patterns:**
- `model.transaction { model.save! }` + rescue `RecordInvalid` in controllers
- `head :not_found` for authorization failures in before_actions
- Service objects: always return `{ success:, ... }` hash; callers branch on `result[:success]`
- Flash messages use `flash[:notice]` / `flash[:alert]`; AJAX responses use `head :ok` or render partial with `layout: false`

## Cross-Cutting Concerns

**Logging:** `Rails.logger` (stdout in production via `ActiveSupport::TaggedLogging`). Feed errors logged at `error` level in `Feed#feed`. AJAX failures logged in browser console via `console.warn`.
**Validation:** ActiveRecord validations on all models. `Crud::ByUser` for ownership. `TwitterLinkRequirement` controller concern for X-specific auth.
**Authentication:** Devise with `authenticate_user!` in `ApplicationController`. Two-factor via TOTP (`devise-two-factor`). OmniAuth for Google and X (`twitter2`) — X-only users may have dummy emails and can register a real email via `Users::EmailRegistrationsController`.
**Locale:** `around_action :set_locale` in `Localization` concern resolves per-request from DB preference or HTTP header. Default locale is `:ja`.
**ActiveRecord Encryption:** `oauth2_token`, `oauth2_refresh_token`, and `otp_secret` on `User` are encrypted via `ActiveRecord::Encryption`. Keys from ENV vars with hardcoded dev/test fallbacks in `config/application.rb`.

---

*Architecture analysis: 2026-05-23*
