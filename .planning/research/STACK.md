# Stack Research — v1.29 Admin X API Usage Report

**Project:** Bookmarks v1.29
**Researched:** 2026-05-20
**Confidence:** HIGH (all conclusions grounded in direct codebase reads and Rails 8.1 built-ins;
no new gem lookups required — see rationale per component)

---

## Summary

The Admin X API Usage Report requires three things: (1) a way to record each X API call
per user, (2) an admin-only route/controller guarded by `users.admin`, and (3) a report
view showing per-user call counts, timestamps, and totals. All three are achievable with
**zero new gems** using Rails 8.1 built-ins, the existing MySQL/ActiveRecord stack, and
the server-rendered ERB + Sprockets pipeline.

The critical design decision is the tracking layer. Two approaches are viable:

- **Counter approach:** Increment a counter on `users` or `x_accounts` each time
  `XClient` makes a call. Simple, no new table, but loses granularity (can't filter by
  date range or endpoint).
- **Event log approach:** Insert one row per API call with `user_id`, `called_at`,
  `endpoint`, `http_status`. A new `x_api_calls` table. Slightly more work to migrate
  and query, but satisfies "filter by date range" and "per-user breakdowns" from the
  feature spec without a later schema expansion.

**Recommendation: event log table.** The PROJECT.md feature spec explicitly calls for
"filtering/sorting by user, by date range" and "request counts, last call, totals".
These are aggregation queries over timestamped rows — a counter column cannot answer
them. The table is tiny (MySQL `INT` + `DATETIME` columns; rows only accumulate on
explicit user actions), and Rails `GROUP BY` + `COUNT` + `MAX` aggregations require no
extra gems. A counter column can be derived from the table with a `COUNT(*)` query.

---

## New Components Required

### 1. Database — `x_api_calls` table

```sql
CREATE TABLE x_api_calls (
  id          bigint   NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id     int      NOT NULL,
  endpoint    varchar(255) NOT NULL,
  http_status smallint NOT NULL,
  called_at   datetime NOT NULL,
  INDEX index_x_api_calls_on_user_id (user_id),
  INDEX index_x_api_calls_on_called_at (called_at)
)
```

**Columns:**
- `user_id` (NOT NULL, indexed) — which user triggered the call
- `endpoint` (varchar 255, NOT NULL) — e.g. `"following"` or `"tweets"` to distinguish
  `fetch_following` from `fetch_recent_tweets`; keeps the report useful without storing
  full URL paths with embedded IDs
- `http_status` (smallint, NOT NULL) — raw HTTP status code returned by X API (200, 401,
  429, etc.); allows admin to see rate-limit hits and auth failures without extra boolean
  columns
- `called_at` (datetime, NOT NULL) — timestamp of the call; used for date-range filtering
  and "last call" display

**No `created_at`/`updated_at`:** This is an append-only event log. Rails timestamp
columns are omitted intentionally — `called_at` is the only timestamp that matters, and
it has a concrete semantic meaning. Adding Rails timestamps would be redundant.

**No soft-delete:** Event log rows are never logically deleted. The admin report always
shows historical data.

**Migration version:** `YYYYMMDD_create_x_api_calls.rb`

**Why not add columns to `users` or `x_accounts`:**
- A counter column on `users` (e.g. `x_api_call_count`) cannot answer "calls this week"
  or "calls by endpoint" without a full scan. It also races on concurrent requests.
- A "last called at" column on `users` answers only one of the admin's questions and
  discards all history.
- The `x_accounts` table tracks followed accounts, not API requests; conflating them
  creates a model responsibility problem.

### 2. Model — `XApiCall`

```ruby
class XApiCall < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true
  validates :http_status, presence: true, numericality: { only_integer: true }
  validates :called_at, presence: true

  # Record a single API call. Called from XClient after each HTTP round-trip.
  # Uses insert! (bang) because a failed insert is a bug, not a user error.
  def self.record!(user_id:, endpoint:, http_status:)
    create!(user_id: user_id, endpoint: endpoint.to_s,
            http_status: http_status.to_i, called_at: Time.current)
  end

  # Aggregated per-user summary for the admin report.
  # Returns ActiveRecord relation: [{ user_id:, total:, last_called_at:, error_count: }]
  def self.usage_summary(since: nil)
    scope = all
    scope = scope.where('called_at >= ?', since) if since
    scope
      .select('user_id, COUNT(*) AS total, MAX(called_at) AS last_called_at,
               SUM(http_status >= 400) AS error_count')
      .group(:user_id)
      .order('total DESC')
  end
end
```

**Why `create!` not `upsert`:** Each API call is a unique event — there is no
uniqueness constraint to resolve. `create!` is the simplest correct choice. A failure
here indicates a programming error (missing user_id, schema mismatch) that should raise.

**Why aggregate in SQL not Ruby:** `usage_summary` uses `COUNT`, `MAX`, and `SUM` in
SQL. This is a single query regardless of how many rows exist. Pulling all rows into
Ruby and aggregating in memory would be incorrect at any scale. Rails `select` with raw
aggregates + `group` is the idiomatic approach; no gem required.

**`SUM(http_status >= 400)` on MySQL:** MySQL evaluates boolean expressions as 0/1,
so `SUM(http_status >= 400)` correctly counts error responses. This is MySQL-specific
SQL, not portable to PostgreSQL. The project already uses MySQL unconditionally
(see `Gemfile` and `db/schema.rb`) so this is appropriate.

### 3. XClient instrumentation

`XClient` currently makes HTTP calls in two methods: `fetch_following` and
`fetch_recent_tweets`. Both return a `{ success:, error: }` hash or `{ success:, items: }`
hash. The HTTP response status is already parsed inside `parse_following_response` and
`parse_tweets_response`.

**Insertion point:** After each `connection_for(user).get(path)` call, before the parse
step, insert a `XApiCall.record!` call:

```ruby
# Inside fetch_following, after res = following_connection(user).get(path):
XApiCall.record!(user_id: user.id, endpoint: 'following', http_status: res.status)

# Inside fetch_recent_tweets, after res = connection_for(user).get(path):
XApiCall.record!(user_id: user.id, endpoint: 'tweets', http_status: res.status)
```

**Why inside XClient, not in the controllers:** The service is the single location that
issues X API HTTP requests. Recording here means all callers — `XAccountsController#refresh`,
`XAccountsController#show`, `Portal#get_gadgets` — are covered without touching each
controller individually. This is the correct single-responsibility boundary.

**Rescue behavior:** The `XApiCall.record!` calls must not raise into user-facing requests
if the database insert fails for any reason. Wrap in a `rescue => e` block that logs but
does not re-raise. Tracking failures must be silent to the end user.

**Token refresh calls:** The `refresh_oauth2_token!` private method also makes HTTP
calls to `api.x.com`, but these are credential maintenance calls, not data API calls.
They should NOT be instrumented — they are infra plumbing, not user-visible API usage.

### 4. Admin access gate — `Admin` concern

A new controller concern enforces that only `users.admin == true` users may access admin
routes. Pattern matches the existing `TwitterLinkRequirement` concern:

```ruby
# app/controllers/concerns/admin_requirement.rb
module AdminRequirement
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    unless current_user&.admin?
    # 404 instead of 403: do not reveal that admin routes exist to non-admins
      head :not_found
    end
  end
end
```

**Why 404 not 403:** Returning 403 (Forbidden) reveals that the route exists and that
the current user lacks the required role. Returning 404 (Not Found) is the conventional
Rails approach for "this does not exist for you" — it does not leak the existence of
admin infrastructure. This is consistent with `XAccountsController#preload_account`
which also uses `head :not_found`.

**Why a concern, not a base class:** The existing pattern in this codebase is concerns,
not controller inheritance hierarchies (compare `TwitterLinkRequirement`,
`Localization`). A concern `include AdminRequirement` is idiomatic.

**`users.admin` column:** Already exists in `db/schema.rb` as
`t.boolean "admin", default: false, null: false`. No migration needed for access control.

### 5. Admin controller and routes

```ruby
# app/controllers/admin/x_api_usage_controller.rb
module Admin
  class XApiUsageController < ApplicationController
    include AdminRequirement

    def index
      @since = parse_since_param
      summary = XApiCall.usage_summary(since: @since)
      user_ids = summary.map(&:user_id)
      @users_by_id = User.where(id: user_ids).index_by(&:id)
      @rows = summary
      @total_calls = summary.sum(&:total)
    end

    private

    def parse_since_param
      return nil if params[:since].blank?
      Date.parse(params[:since].to_s).beginning_of_day rescue nil
    end
  end
end
```

```ruby
# config/routes.rb addition:
namespace :admin do
  resources :x_api_usage, only: [:index]
end
```

**`namespace :admin`:** Rails namespace scoping maps routes to `Admin::XApiUsageController`
in `app/controllers/admin/` and generates path helpers `admin_x_api_usage_index_path`.
This is the standard Rails pattern for admin namespacing; no gem required.

**`@users_by_id`:** Pre-fetch user display names in a single `WHERE id IN (...)` query
to avoid N+1 in the view. The `index_by(&:id)` pattern is used in the existing codebase
(confirmed in `XAccount#refresh_cache_from_items!` which iterates `seen` hash the same way).

**Date filter (`since`):** Parse a `?since=YYYY-MM-DD` query parameter. The view renders
a simple `<form method="get">` date input — no JS required.

### 6. Report view — server-rendered ERB table

```erb
<%# app/views/admin/x_api_usage/index.html.erb %>
<h1><%= t('admin.x_api_usage.title') %></h1>

<form method="get" action="<%= admin_x_api_usage_index_path %>">
  <label><%= t('admin.x_api_usage.since_label') %>
    <input type="date" name="since" value="<%= params[:since] %>">
  </label>
  <button type="submit"><%= t('admin.x_api_usage.filter') %></button>
</form>

<p><%= t('admin.x_api_usage.total', count: @total_calls) %></p>

<table>
  <thead>
    <tr>
      <th><%= t('admin.x_api_usage.user') %></th>
      <th><%= t('admin.x_api_usage.total_calls') %></th>
      <th><%= t('admin.x_api_usage.error_calls') %></th>
      <th><%= t('admin.x_api_usage.last_called_at') %></th>
    </tr>
  </thead>
  <tbody>
    <% @rows.each do |row| %>
      <tr>
        <td><%= @users_by_id[row.user_id]&.display_name || "user##{row.user_id}" %></td>
        <td><%= row.total %></td>
        <td><%= row.error_count %></td>
        <td><%= l(row.last_called_at.in_time_zone, format: :short) if row.last_called_at %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

**No charting library needed.** A sortable HTML table satisfies the spec. The `total`
column is already sorted descending by the SQL query (`ORDER BY total DESC`). Adding a
link-sort toggle (sort by last_called_at, sort by error_count) is achievable with a
single `?sort=last_called_at` query parameter and an `ORDER BY` branch in the model
scope — no JS required.

**If a basic chart is desired later:** Chart.js can be loaded from CDN
(`<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js">`).
The report page renders a `<canvas id="usage-chart">` and a small inline `<script>` that
reads JSON data from a `data-` attribute populated by the controller. This requires:
- Zero new gems
- Zero new npm packages
- One `<script>` CDN tag in the report layout or the view itself
- One small inline `<script>` block (10-15 lines)

The Sprockets pipeline does not need to change; CDN delivery bypasses it entirely.

---

## Recommended Stack (No New Gems Required)

### Core Technologies

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| Rails 8.1.3 | Already locked | `XApiCall` model, aggregation queries, namespace routing, admin controller | `ActiveRecord` `GROUP BY` + `COUNT` + `MAX` aggregations; `namespace` routing; concerns — all built-in. No gem adds value here. |
| MySQL 8 | Already in use | `SUM(http_status >= 400)` aggregate; indexed `user_id` + `called_at` columns | Boolean-as-integer in MySQL `SUM()` is a standard MySQL feature. Indexes on `user_id` and `called_at` cover all expected queries. |
| Devise | Already locked | `current_user` + `current_user.admin?` in `AdminRequirement` concern | `users.admin` column already exists; `current_user` is available in all controllers via `ApplicationController`'s `authenticate_user!`. |
| ERB + Sprockets | Already in use | Report view: HTML table, date filter form | SSR-first pattern. No new JS framework. Date input is a native HTML5 `<input type="date">`. |

### Supporting Libraries Evaluated and Rejected

| Library | Verdict | Reason |
|---------|---------|--------|
| `pundit` or `cancancan` | Reject | Authorization gems for complex role/resource matrices. This app has one admin boolean and a single admin route. A 5-line `before_action` concern is the proportionate solution. Adding a gem adds 50KB+ of code, a new DSL, and maintainability surface for one `users.admin` check. |
| `administrate`, `activeadmin`, `rails_admin` | Reject | Full admin UI frameworks. Heavy dependencies (Webpack/Propshaft, their own asset pipelines), opinionated layouts that conflict with the existing theme, and significant lock-in. The report is one table — it does not justify an admin framework. |
| `chartkick` + `groupdate` | Reject | Charting gems that auto-generate JS charts. `chartkick` requires `chartkick.js` (npm or gem-delivered); `groupdate` is for time-bucket grouping. Both are reasonable for data-heavy reporting apps. For one admin table with optional future chart, CDN Chart.js is lighter and leaves zero footprint in the Gemfile. |
| `pagy` or `kaminari` | Defer | Pagination gems. At personal-app scale (one or two users), the report table will never exceed 10 rows. Pagination is premature. Add only if the user count grows. |
| `redis` / caching layer | Reject | No caching needed. The aggregation query runs on a small table. Caching adds invalidation complexity. |

---

## Integration Map: Existing Code Touch Points

| File | Change Required | Nature |
|------|----------------|--------|
| `db/migrate/YYYYMMDD_create_x_api_calls.rb` | New migration: `x_api_calls` table | New file |
| `app/models/x_api_call.rb` | New model with `record!` and `usage_summary` | New file |
| `app/services/x_client.rb` | Add `XApiCall.record!` after each `get(path)` in `fetch_following` and `fetch_recent_tweets` | Modify — 2 insertion points |
| `app/controllers/concerns/admin_requirement.rb` | New concern: `before_action :require_admin` with 404 guard | New file |
| `app/controllers/admin/x_api_usage_controller.rb` | New namespaced controller, `index` action | New file |
| `app/views/admin/x_api_usage/index.html.erb` | Report view: date filter form + sortable HTML table | New file |
| `config/routes.rb` | `namespace :admin { resources :x_api_usage, only: [:index] }` | 3-line addition |
| `config/locales/ja.yml` | New keys under `admin.x_api_usage.*` | Modify |
| `config/locales/en.yml` | Matching keys for parity | Modify |

**No changes required to:**
- `app/controllers/application_controller.rb` — `authenticate_user!` already covers all
  admin routes since `Admin::XApiUsageController < ApplicationController`
- `app/models/user.rb` — `users.admin` column already exists; `User#admin?` is generated
  by Rails automatically for a boolean column
- Any existing test support files — existing WebMock + Faraday `:test` infrastructure
  covers XClient test stubs; `XApiCall.record!` should be stubbed with
  `allow(XApiCall).to receive(:record!)` in controller tests or the model test handles it
  directly

---

## Test Strategy (No New Gems)

| Test Layer | What to Test | How |
|-----------|-------------|-----|
| `XApiCall` model | `record!` creates row; `usage_summary` returns correct aggregates; `since:` filter narrows scope | Minitest `ActiveSupport::TestCase` |
| `Admin::XApiUsageController` | Non-admin gets 404; admin gets 200; `@rows` populated; `?since=` param filters | Minitest `ActionDispatch::IntegrationTest` with Devise `sign_in` helper |
| `XClient` instrumentation | `XApiCall.record!` called with correct args after HTTP call; rescue path does not propagate DB errors | Minitest with Faraday `:test` adapter (already in use in `test/services/x_client_test.rb`) |
| Cucumber | Admin signs in, visits `/admin/x_api_usage`, sees table with user row | New `features/08.Admin.feature` or appended to existing admin scenarios if any; `@admin_report` tag |

**Fixtures:** Add `admin: true` variant of the user fixture, or set `users(:one).update_column(:admin, true)` in test setup. The existing `test/fixtures/users.yml` pattern can accommodate this with a second fixture entry.

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Counter column on `users` or `x_accounts` | Cannot answer date-range queries; races on concurrent requests; loses endpoint granularity | `x_api_calls` event log table |
| `pundit` / `cancancan` | Heavyweight for one boolean check | 5-line `AdminRequirement` concern with `before_action :require_admin` |
| `administrate` / `activeadmin` | Full admin framework with conflicting asset pipeline; overkill for one report page | Namespaced controller + ERB view |
| `chartkick` + `groupdate` | Gem overhead for optional chart | CDN Chart.js loaded in the report view only, if chart is added at all |
| Exposing `user_id` in API call recording via client params | Security violation | `XClient` receives a `user` object; `user.id` is server-side only |
| Recording calls in controllers (FeedsController, XAccountsController) | Misses calls from Portal gadget loader; splits logic across multiple files | Record in `XClient` service — the single call site for all X HTTP requests |
| `403 Forbidden` for non-admin access | Reveals that admin routes exist | `404 Not Found` — same pattern as `XAccountsController#preload_account` |

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| `x_api_calls` event log design | HIGH | Direct read of XClient service; PROJECT.md spec calls for date-range filtering which requires timestamped rows not counters |
| `XApiCall.record!` placement in XClient | HIGH | Read all callers of XClient — refresh action, show action, Portal gadget loader; XClient is the only correct instrumentation point |
| `users.admin` availability | HIGH | Confirmed in `db/schema.rb`: `t.boolean "admin", default: false, null: false`; Rails generates `admin?` predicate automatically |
| `AdminRequirement` concern pattern | HIGH | Pattern matches `TwitterLinkRequirement` concern already in codebase |
| `namespace :admin` routing | HIGH | Standard Rails routing; confirmed against routes.rb patterns already in use |
| Aggregation SQL on MySQL | HIGH | `SUM(http_status >= 400)` is standard MySQL; `GROUP BY` + `COUNT` + `MAX` are standard SQL; no gem required |
| Zero new gems needed | HIGH | All capabilities (model, aggregation, routing, concern, view) are Rails 8.1 built-ins |
| Chart.js CDN option | MEDIUM | CDN delivery bypasses Sprockets cleanly; Chart.js 4.x API is stable but not verified against current version for this specific use |

---

*Stack research for: v1.29 Admin X API Usage Report*
*Researched: 2026-05-20*
