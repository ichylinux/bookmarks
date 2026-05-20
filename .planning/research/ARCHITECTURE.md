# Architecture Patterns: v1.29 Admin X API Usage Report

**Domain:** Admin instrumentation layer on top of existing XClient service
**Researched:** 2026-05-20
**Confidence:** HIGH — based on direct codebase inspection

---

## Existing Architecture (what we build on)

### XClient call sites (two, both synchronous)

| Call site | Method | Where |
|-----------|--------|-------|
| `XAccountsController#refresh` | `XClient.new.fetch_following(user:)` | controller action |
| `XAccountsController#show` | `XClient.new.fetch_recent_tweets(user:, x_user_id:, limit:)` | controller action, also via `Portal#get_gadgets` |

Both call sites instantiate `XClient.new` directly. No service layer sits between controller and client. No background jobs. No callbacks on `XClient`.

### Existing data tables relevant to this milestone

- `users.admin boolean NOT NULL DEFAULT false` — already exists; the access gate predicate is free
- `x_accounts` — per-user cache table; has `user_id`, `username`, `x_user_id`, timestamps
- No existing usage tracking table — must be created

---

## Component Map: New vs Modified

| Component | Status | Description |
|-----------|--------|-------------|
| `x_api_calls` table | **NEW** | Permanent usage log, one row per XClient call |
| `XApiCall` model | **NEW** | ActiveRecord model for the table |
| `XClient` (instrumentation) | **MODIFIED** | Wrap `fetch_following` and `fetch_recent_tweets` to record after each call |
| `Admin::XApiUsagesController` | **NEW** | Admin-only controller, namespaced |
| `app/views/admin/x_api_usages/` | **NEW** | Report view, filter form |
| `admin/` namespace in routes | **NEW** | `namespace :admin` block |
| `app/controllers/admin/base_controller.rb` | **NEW** | Shared admin `before_action` for `admin?` gate |
| Layout drawer nav (admin link) | **MODIFIED** | Conditional `current_user.admin?` drawer link |
| Locale files `ja.yml` / `en.yml` | **MODIFIED** | `admin.*` key section |

---

## Tracking Hook: Where to Put It

### Decision: Instrument inside XClient, not in a concern, not in the controller

**Rationale:**

There are only two call sites and both are in `XAccountsController`. Instrumenting in the controller via a `before_action`/`after_action` concern would require passing call metadata (which method, which user, success/failure) through instance variables — awkward coupling.

A concern on the controller is also the wrong layer: if a future background job or second controller ever calls `XClient`, tracking would be silently missed. Putting tracking inside `XClient` is the only place that is guaranteed to fire regardless of call site.

A Rails `ActiveSupport::Notifications` hook (instrument/subscribe) is the textbook approach for cross-cutting concerns in Rails services. However, given this codebase's size and the fact that tracking is the primary goal (not an incidental side effect), a direct approach inside `XClient` is simpler and more debuggable.

**Recommended pattern: wrap the two public methods with a private `record_call` helper**

```ruby
def fetch_following(user:, max_results: 100)
  result = fetch_following_internal(user:, max_results:)
  record_call(user: user, endpoint: 'fetch_following', success: result[:success], error_code: result[:error]&.to_s)
  result
end

private

def record_call(user:, endpoint:, success:, error_code: nil)
  XApiCall.create!(
    user_id: user.id,
    endpoint: endpoint,
    success: success,
    error_code: error_code,
    called_at: Time.current
  )
rescue StandardError
  nil  # never let a tracking failure break the API call result
end
```

The implementation renames the existing method body to `fetch_following_internal` (private) and the public `fetch_following` becomes a thin tracking wrapper. Same pattern for `fetch_recent_tweets`.

**What NOT to do:**

- Do not use `ActiveSupport::Notifications` — subscription setup in an initializer adds hidden indirection with no benefit at this scale
- Do not add a callback on `XAccount` model — `XAccount` has no knowledge of when API calls happen
- Do not use a controller `around_action` — call metadata (endpoint, user, success) is not available cleanly from the controller level without coupling

---

## DB Schema: One Row per Call

### Decision: One row per call, NOT daily rollup, NOT counter columns

**Rationale:**

The report goal is "per-user breakdowns, request counts, last call, filtering by user or date range." Daily rollup cannot answer "show me all calls this user made yesterday." Counter columns (increment a `x_accounts.call_count`) cannot answer date-range queries at all.

One row per call gives full flexibility: the admin can see exact timestamps, error symbols, and per-user totals with a simple `GROUP BY user_id`. MySQL can handle tens of thousands of rows per year for a personal app with one admin; no partitioning needed.

Rollup is only worth adding if raw row volume becomes a problem, which is not a near-term concern. Defer.

### `x_api_calls` table schema

```sql
CREATE TABLE x_api_calls (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT       NOT NULL,
  endpoint    VARCHAR(64) NOT NULL,             -- 'fetch_following' | 'fetch_recent_tweets'
  success     BOOLEAN   NOT NULL DEFAULT false,
  error_code  VARCHAR(32),                      -- NULL on success; error symbol string on failure
  called_at   DATETIME(6) NOT NULL,
  INDEX idx_x_api_calls_user_called (user_id, called_at),
  INDEX idx_x_api_calls_called (called_at)
);
```

**Column notes:**

- `endpoint` (VARCHAR not enum) — easier to extend if a third endpoint is added; values are controlled by `XClient` code, not user input
- `error_code` — nullable; stores the 7-symbol error contract values (`:timeout`, `:network`, `:rate_limited`, etc.) as strings for display in the report
- `called_at` — use `Time.current` explicitly (not relying on `created_at`) so the semantics are unambiguous in queries
- No `deleted` soft-delete — audit records must not be removed; hard-delete only via a future admin purge action
- No foreign key constraint at DB level (consistent with this codebase — no FK constraints exist in `schema.rb`)

**No counter cache on `x_accounts` or `users`.** The report queries `x_api_calls` directly with `GROUP BY`.

---

## Admin Routes: Namespaced Under `/admin`

### Decision: `namespace :admin` in `routes.rb`

```ruby
namespace :admin do
  resources :x_api_usages, only: [:index]
end
```

URL: `GET /admin/x_api_usages`

**Rationale:**

- Namespacing is the Rails convention for admin surfaces; it makes the access gate easy to test (path prefix is the tell)
- A flat `AdminController` at `/admin_x_api_usages` is unconventional and harder to extend
- The single route (`index` only) means no nested resource complexity now; future admin pages drop into the same namespace

**`Admin::BaseController`:**

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: t('errors.unauthorized') unless current_user&.admin?
  end
end
```

`Admin::XApiUsagesController` inherits from `Admin::BaseController`. This inherits `authenticate_user!` from `ApplicationController`, so Devise authentication fires first, then the admin check. No need to call `authenticate_user!` again.

---

## Admin Layout / Nav Integration

### Decision: Conditional drawer link; no separate admin layout

**Rationale:**

The app has one layout (`application.html.erb`) used by all authenticated controllers. Creating a separate `admin.html.erb` layout for one admin page is over-engineering. The existing drawer nav already has a secondary section (privacy, terms, sign-out). Adding an admin link behind `current_user.admin?` is the minimal, consistent approach — identical to the existing `current_user.uid.present?` conditional guard on the X accounts link.

**Drawer nav change in `app/views/layouts/application.html.erb`:**

Inside the `drawer_ui?` block, after the secondary section (privacy/terms/sign-out), add:

```erb
<% if current_user.admin? %>
  <div class="drawer-nav-divider" role="separator"></div>
  <div class="drawer-nav-section drawer-nav-section--admin">
    <%= render 'common/drawer_nav_link',
          label: t('nav.admin_x_api_usages'),
          url: admin_x_api_usages_path,
          icon: :admin %>
  </div>
<% end %>
```

**Admin report view:** Standard ERB at `app/views/admin/x_api_usages/index.html.erb`. No new SCSS file required at first — the existing `common.css.scss` table styles cover basic report tables. Add `admin.css.scss` only if admin-specific styles accumulate beyond one or two rules.

---

## Data Flow

```
Controller action
  └─ XClient.new.fetch_following(user:) OR fetch_recent_tweets(user:, ...)
       ├─ [public wrapper — NEW]
       │     ├─ delegates to private implementation method
       │     ├─ record_call(user:, endpoint:, success:, error_code:)
       │     │     └─ XApiCall.create!(...)   rescue nil
       │     └─ returns result hash unchanged
       └─ result returned to controller (unchanged)

Admin browser request
  └─ GET /admin/x_api_usages
       └─ Admin::XApiUsagesController#index
            ├─ authenticate_user! (Devise, from ApplicationController)
            ├─ require_admin! (from Admin::BaseController)
            └─ XApiCall.joins(:user)
                        .group(:user_id)
                        .select('user_id, users.email, COUNT(*) AS call_count,
                                 SUM(success = 0) AS error_count,
                                 MAX(called_at) AS last_called_at')
                        .order('call_count DESC')
                        [optional: .where(called_at: date_range)]
```

---

## Phase Build Order

Dependencies flow data-layer-first:

1. **Data layer** — `x_api_calls` migration + `XApiCall` model + model unit tests
   Must be first: `XClient` instrumentation and the admin controller both depend on this model existing.

2. **XClient instrumentation** — add `record_call` private method; refactor both public methods to be thin tracking wrappers over private implementation methods
   Must be second: all subsequent tests assume tracking is live.

3. **Admin base controller + route namespace** — `Admin::BaseController`, `routes.rb` `namespace :admin` block
   Can overlap with phase 2; must precede the admin controller.

4. **Admin report controller + view** — `Admin::XApiUsagesController#index`, ERB table, filter form (user / date range)
   Depends on phases 1, 2, 3.

5. **Drawer nav + locale strings** — admin conditional link in layout, `nav.admin_x_api_usages` and `admin.*` keys in ja/en YAMLs
   Depends on phase 3 (route helper must exist). Can be done alongside phase 4.

6. **Test coverage closure** — Minitest for model, controller admin gate and non-admin rejection, XClient `record_call` path; Cucumber admin login and report scenario; tri-suite gate
   Integrated throughout; closed in a final verification phase.

---

## Interfaces That Change

| Interface | Change | Notes |
|-----------|--------|-------|
| `XClient#fetch_following` | Side effect added: writes `XApiCall` row | Return value identical — callers unaffected |
| `XClient#fetch_recent_tweets` | Side effect added: writes `XApiCall` row | Return value identical — callers unaffected |
| `app/views/layouts/application.html.erb` | Admin drawer section added under `current_user.admin?` guard | Simple-theme `_menu` partial likely unchanged |
| `config/routes.rb` | `namespace :admin` block added | No existing routes change |
| `config/locales/ja.yml`, `en.yml` | `nav.admin_x_api_usages`, `admin.*` keys added | No existing keys change |

---

## What NOT to Build (Scope Boundaries)

- **Rate-limit consumption tracking** — X API v2 does not return rate-limit headers consistently across endpoints; parsing `x-rate-limit-remaining` adds complexity disproportionate to an MVP report. Defer.
- **Real-time dashboard** — WebSocket / ActionCable out of scope; plain HTML page is the target.
- **Per-call log drilldown** — the index showing per-user totals is the target; row-level drilldown is a future enhancement.
- **Separate admin layout file** — unnecessary; single application layout with conditional drawer section is sufficient.
- **Counter cache columns on `users` or `x_accounts`** — not needed; `COUNT(*)` on a small table is trivial and keeps the data model simple.
- **Pagination** — a personal app with one admin and a handful of users does not need it at this stage; a simple `LIMIT 100` is sufficient.

---

## Sources

- Direct inspection: `app/services/x_client.rb`
- Direct inspection: `app/controllers/x_accounts_controller.rb`
- Direct inspection: `app/controllers/application_controller.rb`
- Direct inspection: `app/views/layouts/application.html.erb`
- Direct inspection: `config/routes.rb`
- Direct inspection: `db/schema.rb` (confirmed `users.admin` exists; no usage tracking table exists)
- Direct inspection: `app/models/x_account.rb`, `app/models/user.rb`
