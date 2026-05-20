# Feature Research — v1.29 Admin X API Usage Report

**Project:** Bookmarks v1.29
**Domain:** Admin API usage reporting in a multi-user Rails app with external Twitter/X API calls
**Researched:** 2026-05-20
**Confidence:** HIGH (codebase read directly; X API rate-limit model confirmed via official sources; Rails audit-log patterns well-documented)

---

## Context: What Already Exists

Understanding the exact shape of XClient calls constrains every design choice here.

**XClient call sites (non-test code only):**

| Caller | Method | When Called | User Context |
|--------|--------|-------------|--------------|
| `XAccountsController#refresh` | `XClient#fetch_following` | User clicks "refresh" on `/x_accounts` | `current_user` |
| `XAccountsController#show` | `XClient#fetch_recent_tweets` | AJAX gadget load on welcome page, per selected X account | `current_user` |

**What XClient currently returns (but does NOT persist):**

- Success/failure symbol (`:unauthorized`, `:rate_limited`, `:timeout`, `:network`, `:parse_error`, `:api_error`, `:not_found`)
- Result items (following list or tweet previews)

**Nothing is logged.** No `x_api_calls` table, no counter, no timestamp beyond `users.x_accounts_last_refreshed_at` (which only captures the last `fetch_following` time, not `fetch_recent_tweets`, and gives no error state, no count).

**Admin column already exists.** `users.admin boolean NOT NULL DEFAULT false`. No admin controller or admin namespace exists yet. The admin role is defined at the DB level but has no gated routes.

**X API rate limit model (as of 2026):**

The free tier is 500 Posts / 100 Reads per month across the entire app. Basic and Pro tiers use 15-minute rolling windows. Per-user OAuth 1.0a calls count against both the per-user window AND the app-level cap. `fetch_recent_tweets` is a Read (GET /2/users/:id/tweets). `fetch_following` is a Read (GET /2/users/:id/following). Rate-limit headers are returned on every response (`x-rate-limit-remaining`, `x-rate-limit-limit`, `x-rate-limit-reset`). The `parse_following_response` and `parse_tweets_response` methods in XClient already detect HTTP 429 and return `{ success: false, error: :rate_limited }` — but this signal is lost after the controller renders.

---

## Feature Landscape

### Table Stakes — Must Have for the Milestone to Deliver Value

An admin usage report is useless if any of these are absent. An admin who opens the report and sees no data, or sees data without the dimensions needed to act on it, receives no value.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Per-user request count** | The primary question an admin asks: "who is calling the API, how often?" Without totals per user, the report cannot identify heavy or anomalous callers. | LOW | `GROUP BY user_id COUNT(*)` on a log table. Trivial query with a compound index on `(user_id, called_at)`. |
| **Last call timestamp per user** | Tells admin whether a user has been active recently. "User A made 400 calls last week, 0 this week — did something break?" A call count without recency context is much less actionable. | LOW | `MAX(called_at)` grouped by user. Same query as above, add `MAX`. |
| **Endpoint dimension (following vs tweets)** | The two XClient methods hit different X API endpoints with different rate-limit budgets. An admin needs to know which endpoint is being hammered. If `fetch_following` is called 80 times in a day, that is suspicious (it should only be called on manual refresh). If `fetch_recent_tweets` is called 2000 times, that is the welcome-page AJAX loading. Without separating them, the count is uninterpretable. | LOW | Store `endpoint` as an enum or short string (`:following`, `:tweets`) in the log table. Group by `(user_id, endpoint)`. |
| **Success vs error breakdown per user** | Rate-limit errors (`:rate_limited`) are the most important operational signal — they mean the X API cap was hit. Auth errors (`:unauthorized`) mean a user's OAuth token is stale. Without error tracking, the admin cannot distinguish "many calls, all successful" from "many calls, half failing with 429". | LOW | Store `success boolean` + `error_code varchar(32)` (nullable) in the log table. Filter and group in queries. |
| **Admin-only access gate** | The report contains usage data across all users, including indirectly identifying information (who uses the app and how often). It must be inaccessible to non-admin users. The `users.admin` boolean exists but no middleware uses it yet. | LOW | `before_action :require_admin` in a new `Admin::BaseController`. Redirect 403 or root path on failure. One filter, applied once. |
| **Basic filtering by date range** | Usage patterns are only meaningful in a time window. An admin asking "how many calls did we make this month?" cannot answer that from an all-time total. The minimum is a "this week / this month / all time" filter or a date range picker. | LOW-MEDIUM | Three radio buttons or a simple date range form. `WHERE called_at >= ? AND called_at <= ?`. No gem needed. |
| **Ja/en locale strings** | The app is bilingual end-to-end. An admin-only page that renders in English only violates the established pattern. All labels, headings, column headers, and filter UI must exist in both `ja.yml` and `en.yml`. | LOW | Same i18n pattern as every other page in the app. Not optional given the project mandate. |

### Differentiators — Useful But Not Required for MVP

These improve operator experience but the report delivers real value without them.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Per-user rate-limit header capture** | X API returns `x-rate-limit-remaining` and `x-rate-limit-reset` on every response. Capturing these per-user in the log table would let the admin see "User A has 3 requests remaining in the current 15-minute window". This is operational gold for avoiding 429s proactively. | MEDIUM | XClient must read headers from the Faraday response and pass them back alongside the result hash. Adds columns to the log table. Requires Faraday header access in the response parsing path. The existing `parse_*_response` methods return only the parsed body — they would need to return headers too. **Worth building if rate-limit headroom is operationally important; defer if free-tier 100-read/month limit makes the window concept irrelevant.** |
| **Sorting on the report table** | Admin can click column headers to sort by "total calls", "last call", "error rate". Makes finding the heaviest or most error-prone user faster when there are >5 users. | LOW-MEDIUM | Sort params in query string. `order(params[:sort] => params[:dir])` with a whitelist. Standard Rails pattern, no gem needed. |
| **Pagination** | Needed once the log table has enough rows that a full-table render is slow. | LOW | `page` / `per_page` params. `limit/offset` on the query. At personal scale (a handful of users, hundreds of calls per day), a 30-row `GROUP BY` result is not paginated — but the raw log view (if added) would need it. |
| **Raw call log view** | Admin can drill down from the per-user summary into individual call records — sorted by time, showing endpoint, success, error code, response time. Useful for debugging a specific incident. | MEDIUM | A detail page per user: `GET /admin/x_api_logs?user_id=N`. Paginated table of raw log rows. Adds one controller action and one view partial. |
| **Response time tracking** | Log `duration_ms` (wall time of the XClient HTTP call). Enables spotting slow endpoints or degraded X API performance. | LOW | Wrap the Faraday call with `Process.clock_gettime(Process::CLOCK_MONOTONIC)` before and after. Store the delta in milliseconds. Adds one integer column. |
| **CSV export** | Admin downloads the report as CSV for sharing or analysis outside the app. | LOW-MEDIUM | `respond_to :html, :csv` + `render csv:` with a template. No gem needed for simple row-by-row output. |

### Anti-Features — Explicitly Not This Milestone

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Real-time dashboard / live counters** | ActionCable/WebSocket push for live call counts adds infrastructure (Redis or async adapter) for a report that an admin checks at most once a day. The X API is not called frequently enough to make live updates meaningful. | Reload the page. A server-rendered HTML report is correct for this use case. |
| **Alerting / email notifications** | "Send an email when User A exceeds 50 calls/hour." Adds Action Mailer wiring, a background job, configuration UI. Out of scope for a personal-scale app with a handful of users and a small API budget. | Admin reads the report manually. |
| **Heavy BI / charting library (Chartkick, Highcharts, Chart.js)** | New npm/gem dependency. PROJECT.md forbids new bundler-level JS dependencies. A bar chart of calls per day looks nice but adds a CDN script tag or a Sprockets gem that needs ongoing maintenance. The report is operational, not a data product for presentations. | HTML table with clear numeric columns. Optionally a simple CSS bar representation using `width: N%` on a colored div — no library needed. |
| **Sidekiq / background job for log writes** | Writing a log row synchronously on each XClient call adds <1ms to the controller response. The table will have a simple index and single-row inserts. There is no reason to introduce a background job framework for this workload. | Synchronous `XApiLog.create!(...)` in the XClient call path or in an observer/callback pattern. |
| **Separate admin namespace gem (ActiveAdmin, Administrate)** | These gems are appropriate for large CRUD-heavy backends managing dozens of models. For one report page and one access gate, a gem adds hundreds of lines of configuration, its own asset pipeline, and version coupling risk. | A minimal `Admin::BaseController` with one subclass `Admin::XApiLogsController`. Two controllers, two view templates, one route namespace. Total: ~100 lines. |
| **User management via admin panel** | Creating/deleting/editing users from the admin report page is a separate concern. The report answers "how is X API used?" — user management answers "who can sign in?" Mixing them in this milestone adds scope and defers the report. | User management via rake tasks (already established: `dad:create_admin_user`). |
| **Per-account (x_account) granularity in logs** | Logging which specific X account's tweets were fetched (e.g., "@elonmusk's tweets were fetched 40 times") is more granular than what the admin needs. The per-user + per-endpoint breakdown is sufficient to identify load drivers. Per-X-account data adds a foreign key to the log table and complicates the GROUP BY queries. | Per-user + per-endpoint is the right granularity for v1.29. |
| **X API quota meter / progress bar against monthly cap** | Showing "you've used 73 of 100 monthly reads" would require the app to know the billing period start date and aggregate all calls. This is valuable but requires knowing the X Developer portal billing cycle, which is not exposed in the API response. Rate-limit headers only show the current 15-minute window. | Expose raw call counts by time period; let the admin do the arithmetic against their known quota. |

---

## Feature Dependencies

```
[x_api_logs table + XApiLog model]
    └──required by──> [per-user count query]
    └──required by──> [last call timestamp query]
    └──required by──> [endpoint breakdown query]
    └──required by──> [success/error breakdown]

[XClient instrumentation (log write on each call)]
    └──requires──> [x_api_logs table]
    └──hooks into──> [fetch_following + fetch_recent_tweets call sites]
    └──records──> [user_id, endpoint, success, error_code, called_at]

[Admin::BaseController + require_admin before_action]
    └──required by──> [Admin::XApiLogsController]
    └──gates on──> [current_user.admin?]

[Admin::XApiLogsController]
    └──requires──> [Admin::BaseController]
    └──queries──> [x_api_logs GROUP BY user_id, endpoint]
    └──renders──> [admin/x_api_logs/index.html.erb]

[Date range filter]
    └──adds WHERE clause to──> [report query]
    └──has no schema dependency]

[Ja/en locale strings]
    └──required by──> [admin report view]
    └──pattern: existing config/locales/ja.yml + en.yml]
```

### Dependency Notes

- **Log table is the foundation.** All reporting depends on it existing and being populated. Instrumentation (writing to the table) must be in place before any admin report can show data.
- **XClient instrumentation should be non-intrusive.** The cleanest approach: a wrapper method in XClient that logs before returning, or a separate `XApiLog.record(user:, endpoint:, result:)` class method called at each call site in the controller. Do not modify XClient's return contract — callers already depend on `{ success:, items: }` and `{ success:, error: }`.
- **`require_admin` before_action is a new cross-cutting concern.** It must check `current_user&.admin?` and redirect (not 403) to avoid leaking route existence. A 302 to root is appropriate. This goes in `Admin::BaseController`, not in `ApplicationController`, to avoid applying it globally.
- **No Devise changes needed.** `users.admin` is already a boolean column. `current_user.admin?` works without any gem changes.
- **Instrumentation call sites:** Two places in `XAccountsController` (`#refresh` calls `fetch_following`; `#show` calls `fetch_recent_tweets`). The log write should happen after the XClient call returns, using the result's `:success` and `:error` fields.

---

## Log Table Schema Recommendation

The table must be small, fast to insert into, and efficient to aggregate.

```
x_api_logs
  id             bigint   PK
  user_id        bigint   NOT NULL  FK → users.id
  endpoint       varchar(32) NOT NULL  # 'following' or 'tweets'
  success        boolean  NOT NULL
  error_code     varchar(32)  NULL    # nil on success; ':rate_limited' etc. on failure
  called_at      datetime NOT NULL
  created_at     datetime NOT NULL

INDEX (user_id, called_at)          # covers per-user time-range queries
INDEX (called_at)                    # covers global time-range queries
```

No `duration_ms` at MVP (add as differentiator). No `x_account_id` FK (per-account granularity is anti-feature for v1.29). `endpoint` as varchar(32) is simpler than a Rails enum and avoids migration risk if a third endpoint is added later. `error_code` mirrors the XClient error symbol as a string (`:rate_limited` → `"rate_limited"`).

---

## MVP Definition

### Build in v1.29

- `x_api_logs` table with `user_id`, `endpoint`, `success`, `error_code`, `called_at`
- `XApiLog` model: `belongs_to :user`, validations, `XApiLog.record!(user:, endpoint:, result:)` class method
- Instrumentation: call `XApiLog.record!` in `XAccountsController#refresh` (after fetch_following) and `#show` (after fetch_recent_tweets)
- `Admin::BaseController` with `require_admin` before_action (redirect non-admins to root)
- `Admin::XApiLogsController#index`: aggregation query — per-user totals, per-endpoint breakdown, error counts, last call time; filterable by date range
- `GET /admin/x_api_logs` route (namespaced under `admin`)
- Admin report view: HTML table with per-user row, endpoint columns, error column, last-call column; date range filter form
- Ja/en locale strings under `admin.x_api_logs.*` in both YAML files
- Minitest: `XApiLog` model tests, `Admin::XApiLogsController` access control (non-admin redirected, admin allowed), query correctness
- Cucumber: one scenario — admin signs in, visits report, sees per-user data; non-admin redirected

### Explicitly Defer

- Rate-limit header capture — only valuable for Pro/Basic tier (15-minute windows); less relevant at free-tier 100 reads/month
- Response time logging — adds complexity; call duration is not operationally critical at personal scale
- Raw per-call drill-down page — summary view is sufficient for v1.29
- Sorting by column header — summary table will have few rows (one per user); sorting is low-value
- CSV export — admin can copy the HTML table; not worth the respond_to plumbing at v1.29
- CSS/JS chart visualizations — table is sufficient; no new JS/gem dependencies

---

## X API Rate-Limit Context for the Report Design

Understanding the rate-limit model prevents the report from misleading the admin.

**Free tier (likely tier for this app):** 100 Reads per month across all users. `fetch_following` and `fetch_recent_tweets` are both Reads. 100 total reads is not a lot — a single user with 5 selected X accounts loading the welcome page 20 times in a month will consume 100 reads. The report must make this visible.

**Rate-limit errors already detected:** XClient returns `{ success: false, error: :rate_limited }` on HTTP 429. Logging this error code lets the admin see how often the app is hitting the cap.

**Per-user vs per-app:** X API v2 with OAuth 1.0a User Context has both per-user rate-limit windows (which reset every 15 minutes) and monthly read quotas that are app-wide. The admin report tracks app-wide call volume; it cannot know per-user window status without reading headers from each response.

**`called_at` precision:** Storing `datetime` (second precision) is sufficient. The admin is not doing millisecond-level rate-limit analysis. MySQL `datetime` with a `called_at` index gives sub-millisecond range queries across millions of rows — vastly more than this app will ever produce.

---

## Complexity Assessment

| Feature | Effort | Risk | Notes |
|---------|--------|------|-------|
| `x_api_logs` table + model | 1 phase | LOW | Standard migration + model pattern |
| XClient instrumentation | 1 phase | LOW | 2 call sites; no XClient return contract change |
| Admin::BaseController + gate | 0.5 phase | LOW | One before_action, one redirect |
| Report controller + view | 1 phase | LOW | GROUP BY query + HTML table |
| Date range filter | 0.5 phase | LOW | WHERE clause addition, simple form |
| Ja/en locale strings | Folded into view phase | LOW | Same pattern as every other page |
| Minitest + Cucumber | 1 phase | LOW | Access control + query tests |

**Total: 5–6 phases.** Well within the existing milestone pattern (v1.26 was 5 phases, v1.28 was 4 phases for comparable scope).

---

## Sources

- Codebase read directly: `app/services/x_client.rb`, `app/controllers/x_accounts_controller.rb`, `app/models/x_account.rb`, `app/models/portal.rb`, `db/schema.rb`
- [X API v2 Rate Limits — developer.x.com](https://developer.x.com/en/docs/x-api/v1/rate-limits)
- [X API Pricing 2026 — postproxy.dev](https://postproxy.dev/blog/x-api-pricing-2026/) — free tier 100 reads/month confirmed
- [Audit Logging in Ruby and Rails — AppSignal Blog](https://blog.appsignal.com/2023/04/12/audit-logging-in-ruby-and-rails.html) — Rails audit log patterns
- [Building a Custom Audit Trail in Rails — DEV Community](https://dev.to/nemwelboniface/building-a-custom-audit-trail-in-ruby-on-rails-without-papertrail-klk) — bespoke log table approach vs gem

---

*Feature research for: admin X API usage report in multi-user Rails personal dashboard*
*Researched: 2026-05-20*
