# Architecture

## Overview

This is a Rails 8.1 MVC application following standard Rails conventions. It implements a personal portal/dashboard for bookmarks, todos, RSS feeds, and calendars, organized around a "gadget" abstraction that renders user-owned widgets on a drag-and-drop portal homepage. Authentication is handled by Devise with optional TOTP two-factor authentication and OmniAuth (Google, Twitter) social login.

## Application Architecture Pattern

**Overall:** Rails MVC with a lightweight gadget abstraction layer in models.

The application does not use service objects, form objects, or interactors. Business logic is placed directly in models. The portal system introduces a non-standard "gadget" pattern: plain Ruby objects (`BookmarkGadget`, `TodoGadget`) and AR models (`Calendar`, `Feed`) all expose a uniform `gadget_id` / `entries` interface consumed by `Portal#portal_columns` to compose the dashboard view.

**Key characteristics:**
- Standard RESTful controllers — thin, no service layer
- Fat-ish models: `Portal`, `Feed`, `Calendar` contain display logic alongside persistence
- Gadget protocol: any object responding to `gadget_id` and `entries` can appear in the portal
- Logical deletes: all user-owned resources use a `deleted` boolean column; `destroy_logically!` is the standard delete path
- Authorization is inline via `Crud::ByUser` — no dedicated authorization library (CanCanCan / Pundit are absent)

## Key Domain Models and Relationships

```
User
├── has_one  :preference           (app/models/preference.rb)
├── has_many :portals              (app/models/portal.rb)
├── [implicit] has_many :bookmarks (app/models/bookmark.rb)
├── [implicit] has_many :todos     (app/models/todo.rb)
├── [implicit] has_many :feeds     (app/models/feed.rb)
└── [implicit] has_many :calendars (app/models/calendar.rb)

Portal
└── uses PortalLayout rows to order gadgets into 3 columns
    PortalLayout: user_id, gadget_id (string), column_no, display_order

Bookmark (acts_as_tree)
├── belongs_to :user
└── self-referential parent_id (folders at root, files under folders)

Gadget protocol objects (not AR):
  BookmarkGadget  (app/models/bookmark_gadget.rb) — wraps Bookmark query
  TodoGadget      (app/models/todo_gadget.rb)     — wraps Todo collection
  Calendar        (app/models/calendar.rb)         — AR model + gadget interface
  Feed            (app/models/feed.rb)             — AR model + gadget interface
```

The `tweets` table exists in the schema but has no corresponding model or controller — it appears to be legacy/unused.

## Request / Response Flow

### Standard resource request (e.g., bookmarks)

1. Browser sends HTTP request.
2. `config/routes.rb` — `resources :bookmarks` routes to `BookmarksController`.
3. `ApplicationController#before_action :authenticate_user!` — Devise enforces login; redirects to sign-in if unauthenticated.
4. `BookmarksController#before_action :preload_bookmark` (for member actions) — loads record and checks `readable_by?(current_user)` via `Crud::ByUser`; returns 404 on failure.
5. Action executes — reads/writes AR model directly; no service layer.
6. Renders ERB view or redirects.

### Portal homepage (root)

1. `WelcomeController#index` loads `current_user.portals.first` → `@portal`.
2. View (`app/views/welcome/index.html.erb`) iterates `@portal.portal_columns`.
3. `Portal#portal_columns` calls `Portal#get_gadgets` which instantiates all gadget objects for the user, keyed by `gadget_id`.
4. Layout ordering from `PortalLayout` rows is applied; gadgets distributed across three columns.
5. View renders each gadget via `render g.class.name.underscore, gadget: g` — partials in `app/views/welcome/` (`_bookmark_gadget.html.erb`, `_todo_gadget.html.erb`, `_feed.html.erb`, `_calendar.html.erb`).
6. jQuery UI Sortable sends AJAX `POST /welcome/save_state` when layout is changed; `WelcomeController#save_state` calls `Portal#update_layout`.

### Feed gadget partial load

`FeedsController#show` detects XHR (`request.xhr?`) and renders without a layout, allowing the gadget to be loaded inline.

## Authentication / Authorization Approach

**Authentication — Devise** (`app/models/user.rb`, `app/controllers/users/`)

- Modules enabled: `two_factor_authenticatable`, `registerable`, `recoverable`, `rememberable`, `trackable`, `validatable`, `omniauthable`
- `ApplicationController` enforces `before_action :authenticate_user!` globally — every action requires login by default
- Two-factor (TOTP) flow is custom: `Users::SessionsController#create` checks `two_factor_enabled?`; if true, stores `otp_user_id` in session and redirects to `Users::TwoFactorAuthenticationController#show` instead of completing sign-in (`app/controllers/users/sessions_controller.rb`, `app/controllers/users/two_factor_authentication_controller.rb`)
- 2FA setup managed by `Users::TwoFactorSetupController` (`app/controllers/users/two_factor_setup_controller.rb`)
- OmniAuth: `Users::OmniauthCallbacksController` handles Google and Twitter callbacks; `User.from_omniauth` creates or looks up the user (`app/controllers/users/omniauth_callbacks_controller.rb`)

**Authorization — inline / Crud::ByUser** (`app/models/crud/by_user.rb`)

- No Pundit/CanCanCan
- `Crud::ByUser` concern provides `readable_by?`, `updatable_by?`, `deletable_by?` — all check `user_id == current_user.id`
- Controllers call `readable_by?(current_user)` in `preload_*` before_actions and return 404 on failure
- Admin check: `User#admin?` compares email to `User.first.email` — fragile, no separate role column

## Data Flow Patterns

**User-scoped queries:** All resource queries include `user_id: current_user.id` directly in controller WHERE clauses. No global scope enforces this — it is a manual convention.

**Logical deletes:** Records are never hard-deleted. All user-facing models have a `deleted` boolean (default false). `destroy_logically!` sets `deleted: true`. Queries use `.not_deleted` scope (provided by the `daddy` gem).

**Feed fetching:** `Feed#retrieve_feed` makes a synchronous HTTP request using `Daddy::HttpClient` (wrapping Faraday) at render time — there is no background job or caching for feed content. This is a potential performance concern.

**Portal layout persistence:** Layout state is stored as `PortalLayout` rows (one per gadget slot). On drag-and-drop, the entire layout is serialized by JavaScript and POSTed to `WelcomeController#save_state`, which rewrites all `PortalLayout` rows for the user in a transaction.

**Preferences:** `User has_one :preference`; if none exists, `User#preference` falls back to `Preference.default_preference(user)` (an unsaved object) rather than raising. `PreferencesController` manages preferences through nested attributes on `User`.

## Architectural Constraints

- **Threading:** Single-process Puma; no background job queue configured (ActiveJob exists but no adapter beyond the default inline/test adapters is configured)
- **Global state:** None notable
- **Circular imports:** None detected
- **Feed HTTP calls at render time:** Synchronous external HTTP in the request cycle; no caching layer
- **Admin detection:** `User#admin?` uses `User.first` — breaks if users are ever reordered or the first user is deleted

---

*Architecture analysis: 2026-04-27*
