# Domain Pitfalls: v1.29 Admin X API Usage Report

**Domain:** Adding API usage tracking + admin dashboard to an existing Rails 7/8 app
**Researched:** 2026-05-20
**Scope:** Pitfalls specific to this codebase (XClient, MySQL, WebMock, Minitest+Cucumber, no background jobs)

---

## Critical Pitfalls

These mistakes cause rewrites, silent security holes, or complete test suite breakdown.

---

### Pitfall 1: Tracking Hook Placed Inside XClient — Breaks All Existing Tests

**What goes wrong:**
If the tracking write (`XApiCall.create!(...)`) is placed directly inside `XClient#fetch_following` or `#fetch_recent_tweets`, every existing Minitest that exercises XClient via Faraday `:test` stubs will begin writing to the `x_api_calls` table. Tests that do not reset that table between runs will see stale rows and produce non-deterministic counts. Tests that mock at the WebMock layer (controller integration tests, Cucumber `@x_gadget` hook) will also trigger tracking writes — meaning a green test run today will have `x_api_calls` rows that contaminate the next test that asserts on counts.

**Why it happens:**
XClient is tested in three distinct ways in this codebase: (a) `XClientTest` via Faraday `:test` adapter with a forced `connection:` argument, (b) controller integration tests via `WebMock.stub_request`, and (c) Cucumber via `WebMock.stub_request` in the `@x_gadget` Before hook. None of these stubs prevent an `XApiCall.create!` inside XClient from writing — WebMock only blocks outbound HTTP, not ActiveRecord writes.

**Consequences:**
- Minitest tests that assert on `XApiCall.count` break as soon as execution order changes.
- Cucumber `@x_gadget` scenarios accumulate tracking rows from each scenario run; the global `Before` hook in `features/support/hooks.rb` resets `XAccount.delete_all` and `VisitedLink.delete_all` but does NOT reset `x_api_calls` — this must be added explicitly or scenarios will see phantom call counts.
- Tracking writes in production introduce a DB write for every X API call, adding latency to what is currently a read-only Faraday call path.

**Prevention:**
Place the tracking hook at the **call site** (the controller or service object that calls XClient), not inside XClient itself. XClient remains a pure HTTP adapter. This mirrors the existing pattern where `Portal#get_gadgets` drives XClient but XClient has no side effects beyond returning its result hash.

Alternatively, use an `after_action` callback on `XAccountsController` and a dedicated service call in `WelcomeController` — but keep XClient ignorant of tracking.

**Detection:**
If `XClientTest` starts failing on `XApiCall`-related errors, or if Cucumber `@x_gadget` scenarios fail with unexpected row counts, tracking was placed inside XClient.

---

### Pitfall 2: Admin Gate Implemented Only in the View — Not at the Controller Level

**What goes wrong:**
The app currently has `users.admin boolean NOT NULL DEFAULT false` and a tested `admin?` predicate on User, but no admin controller, no `require_admin` before_action, and no routing namespace. The first admin feature risks having the view correctly hide admin links while the underlying route and action remain accessible to any authenticated non-admin user.

**Why it happens:**
It is tempting to add `<% if current_user.admin? %>` guards in the nav and rely on obscurity. But `ApplicationController` only enforces `authenticate_user!` — there is no second gate. Any signed-in user who knows or discovers `/admin/x_api_usage` can access the data.

**Consequences:**
- Any authenticated user can see all users' X API usage data — a privacy violation in a multi-user app.
- Future admin features inherit the same gap by following the "established" pattern.

**Prevention:**
Create a `require_admin` before_action concern (or an `Admin::BaseController < ApplicationController` that includes it). The gate must call `head :forbidden` or redirect away if `!current_user.admin?`. This gate belongs at the controller level, not the view level. The view-level guard is additive (prevents the link showing) but cannot be the only guard.

Test it explicitly: an integration test with a non-admin signed-in user must assert that `GET /admin/x_api_usage` returns 403 (or redirects), not 200. The existing fixture user id:2 (`admin: false`) is available for this negative case; user id:1 (`admin: true`) serves the positive case.

**Detection:**
No `require_admin` before_action exists anywhere in the controller inheritance chain for the admin route.

---

### Pitfall 3: Tracking Records Leak Between Cucumber Scenarios — Missing Before Hook Cleanup

**What goes wrong:**
Minitest uses `fixtures :all` with transactional rollback (Rails default). Rows created during a Minitest method are rolled back after that method — this is safe automatically.

Cucumber does NOT use transactional rollback — it runs through a real Puma server via Capybara. The global `Before` hook in `features/support/hooks.rb` explicitly resets `MastodonAccount.delete_all`, `XAccount.delete_all`, and `VisitedLink.delete_all`. A new `x_api_calls` table will NOT be in that list unless explicitly added. If `@x_gadget` scenarios trigger tracking writes, each subsequent scenario sees rows from all prior scenarios.

**Why it happens:**
New tables require explicit additions to the Cucumber `Before` hook cleanup list. The omission is not caught until two `@x_gadget` scenarios run back-to-back and the second one sees unexpected existing rows. The failure is non-obvious because it is scenario-order-dependent — the test suite passes in isolation but fails together.

**Prevention:**
Add `XApiCall.delete_all` (or whatever the model is named) to the global `Before` hook in `features/support/hooks.rb` alongside the existing cleanup lines. Do this in the same phase that introduces the table — not as a follow-up.

**Detection:**
Run the Cucumber suite twice in sequence without resetting the DB. If the second run sees different row counts than the first, the `Before` hook is missing the cleanup.

---

### Pitfall 4: Tracking Write Inside an Existing Transaction — Silent Data Loss on Rollback

**What goes wrong:**
`XAccountsController#update` wraps its logic in `@x_account.transaction do` (confirmed in the codebase at line 47). If the tracking `XApiCall.create!` is placed inside an existing transaction block — or if the controller action wraps both the X API call and the tracking insert in a single transaction — a failed update to `x_accounts` will silently roll back the tracking record too. The API call happened (the X API was hit and consumed), but no tracking row survives.

For the welcome-page gadget path (`WelcomeController#index` → `Portal#get_gadgets` → XClient), there is no explicit transaction, so this pitfall does not apply there. But the `XAccountsController` path has an active transaction.

**Why it happens:**
Developers naturally wrap "do X then record X" in a single transaction for atomicity — but that is the wrong mental model for usage tracking. The API call is external and irrevocable; the tracking record should survive even if the local business logic rolls back.

**Prevention:**
Write tracking records **outside** any existing transaction, or use `after_commit` hooks if using callbacks. The simplest pattern: write the tracking row **after** the transaction block returns, using the result hash from XClient. This way even failed X API calls (`:rate_limited`, `:unauthorized`) are tracked — which is desirable for a rate-limit report.

**Detection:**
Write a test where the containing transaction is forced to roll back (e.g., raise inside the transaction block after XClient call). Assert that `XApiCall.count` increased by 1 regardless. If the count is 0, the tracking is inside the transaction.

---

## Moderate Pitfalls

---

### Pitfall 5: Unbounded Growth of `x_api_calls` — No Pruning Strategy

**What goes wrong:**
Every X API call (both `fetch_following` and `fetch_recent_tweets`) creates a tracking row. The welcome-page gadget fetches tweets for every selected X account on every page load. With multiple users, multiple selected accounts per user, and frequent page loads, the `x_api_calls` table can grow to millions of rows within weeks. MySQL with no index on `(user_id, called_at)` will make the admin report query a full-table scan. With no pruning, the table becomes a performance liability indefinitely.

**Why it happens:**
Schema design focuses on "record everything" without considering volume or access patterns. The codebase has no background jobs (no Sidekiq/Redis), so there is no obvious place to run automated pruning.

**Prevention:**
- Add a composite index on `(user_id, called_at)` at migration creation time — the admin report will filter and group by these columns.
- Plan the retention model from the start. Two options:
  - **Row-level tracking** with a defined retention window (e.g., keep 90 days): implement a purge Rake task runnable via cron or `rails runner`.
  - **Aggregate counters**: a `x_api_daily_counts` table (user_id, date, endpoint, call_count) via SQL `INSERT ... ON DUPLICATE KEY UPDATE`. Much smaller, naturally bounded, loses per-call granularity.
- For the MVP admin report, aggregating in SQL (`GROUP BY user_id, DATE(called_at)`) is sufficient and avoids storing fine-grained rows at all. Decide the schema model before writing the migration.

**Detection:**
`SHOW TABLE STATUS LIKE 'x_api_calls'` after two weeks of normal use. If rows exceed expected (users × accounts × daily loads × 14 days), pruning is needed.

---

### Pitfall 6: N+1 on the Admin Report Page

**What goes wrong:**
The admin report shows usage by user. If the view iterates over `XApiCall.all` and calls `record.user.email` for each row, each distinct user triggers an additional `SELECT * FROM users WHERE id = ?` query. With 10 users and 1000 tracking rows, that is up to 10 extra queries on top of the main table scan.

**Why it happens:**
In every existing controller, the query is scoped to `current_user` — there is no cross-user loading anywhere in the codebase. The admin report is the first cross-user query, and the instinct to call `.user.email` from the view is inherited from the single-user pattern.

**Prevention:**
Query at the aggregate level rather than loading individual rows into the view:

```ruby
XApiCall.joins(:user)
        .group('users.id', 'users.email')
        .select('users.email, COUNT(*) AS call_count, MAX(x_api_calls.called_at) AS last_called_at')
```

This returns a flat result set without N+1. If individual rows are needed, use `includes(:user)`.

**Detection:**
Enable query logging in development and load the admin report page. If the SQL log shows repeated `SELECT * FROM users WHERE id = ?` queries (one per unique user in the result set), N+1 is present.

---

### Pitfall 7: Admin UI Elements Bleeding Into the Guest Path

**What goes wrong:**
If admin navigation links are added to the shared application layout with a `if current_user.admin?` guard, and `current_user` is nil (guest path — `WelcomeController#index` uses `skip_before_action :authenticate_user!, only: :index`), calling `current_user.admin?` will raise `NoMethodError: undefined method 'admin?' for nil`.

**Why it happens:**
The guest landing path is a known nil-`current_user` surface. The existing layout is carefully guarded: `current_user.preference` is only called inside blocks guarded by `user_signed_in?`. An admin link added carelessly without the same guard breaks the guest path.

**Prevention:**
Guard all admin UI with `user_signed_in? && current_user.admin?` (both conditions required, in that order). Prefer isolating admin navigation in a dedicated admin layout rather than polluting the main application layout.

Regression contract: the existing v1.22 test that loads `GET /` as a guest must remain green. Any `NoMethodError` on `nil.admin?` will cause that test to fail with a 500 rather than the expected 200 — this is a clear signal.

**Detection:**
Load the root page as a guest (no session). Any 500 response mentioning `NoMethodError` or `admin?` indicates the guard is missing.

---

### Pitfall 8: WebMock Scope Does Not Prevent Tracking Writes in Tests

**What goes wrong:**
When writing integration tests for the admin report controller (e.g., `GET /admin/x_api_usage`), test setup inserts `x_api_calls` rows to assert on. If that setup calls through XClient (instead of inserting rows directly via `XApiCall.create!`), WebMock will raise `WebMock::NetConnectNotAllowedError` unless the Twitter API endpoints are stubbed. This is not a tracking-in-XClient problem — it is a test setup discipline issue.

More subtly: if an integration test loads the full portal (sign in, then `GET /`), the `@x_gadget` fixture setup path can trigger XClient calls. Without the existing `WebMock.stub_request(:get, /api\.twitter\.com/)` stubs in the test, the failure message will be a WebMock connection error rather than an assertion failure — harder to diagnose.

**Prevention:**
- Insert `XApiCall` rows directly in test setup, never by calling through XClient.
- If an integration test loads the portal, copy the `WebMock.stub_request` pattern from `x_client_test.rb` into the test.
- Keep `XApiCall.delete_all` in the Cucumber `Before` hook (see Pitfall 3).

**Detection:**
Any `WebMock::NetConnectNotAllowedError` mentioning `api.twitter.com` in a test file other than `x_client_test.rb` indicates missing stubs.

---

### Pitfall 9: Admin Controller Accidentally Inheriting a `skip_before_action` Pattern

**What goes wrong:**
`PagesController` uses `skip_before_action :authenticate_user!` with no `only:` — intentionally fully public. If an admin controller is created by copying `PagesController` as a template, or if a developer adds `skip_before_action :authenticate_user!` thinking it is needed for some other reason, the authentication gate disappears.

**Why it happens:**
Copy-paste from a "public" controller into an "admin" controller is a common mistake. The admin controller structure (`Admin::BaseController`) is new to the codebase and there is no existing template to follow.

**Prevention:**
`Admin::BaseController` inherits from `ApplicationController` and adds ONLY `require_admin` — it never adds `skip_before_action`. Write the two negative integration tests (unauthenticated → redirect to sign-in; authenticated non-admin → 403) before writing any admin views. These tests are the specification that prevents the bypass.

**Detection:**
`curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/admin/x_api_usage` without a session. Anything other than 302 (redirect to sign-in) means authentication is not enforced.

---

## Minor Pitfalls

---

### Pitfall 10: Counting `refresh_oauth2_token!` Calls as X API Usage

**What goes wrong:**
`XClient#refresh_if_expired!` makes a POST to `https://api.x.com/2/oauth2/token`. This is a token refresh call, not a user-data read. If tracking is placed at the Faraday connection level or in a way that intercepts all outbound calls, token refreshes inflate the usage count with unrelated calls.

**Prevention:**
Track only at the `fetch_following` and `fetch_recent_tweets` call sites. The result hash from those methods identifies the endpoint and outcome. Do not intercept at the Faraday middleware level.

---

### Pitfall 11: Date/Timezone Mismatch in Report Grouping

**What goes wrong:**
The admin report groups calls by date. MySQL's `DATE()` function uses the server timezone. Rails stores datetimes in UTC by default. If `config.time_zone` is set to `'Tokyo'` (JST, UTC+9), a call at 23:30 JST is stored as 14:30 UTC. `GROUP BY DATE(called_at)` in MySQL will assign that call to the UTC date (one day earlier in JST). The report date will be wrong by up to one day for evening calls.

**Prevention:**
Use `GROUP BY DATE(CONVERT_TZ(called_at, 'UTC', 'Asia/Tokyo'))` in SQL, or aggregate in Ruby after fetching rows using `called_at.in_time_zone.to_date`. Verify `config.time_zone` and MySQL server timezone before shipping the report.

---

### Pitfall 12: Admin Report Displaying Dummy Emails Without Twitter Identity

**What goes wrong:**
Users who signed in via Twitter OAuth and never registered a real email have `dummy_UUID@example.com` addresses. The admin report showing only `users.email` will display unreadable dummy addresses for those users, making the report unusable for identifying which user consumed which quota.

**Prevention:**
Show both `users.email` and the associated Twitter handle (available from `x_accounts.username` or `users.uid`) on the report. This gives the admin a complete identity picture for all user types.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Schema: tracking table migration | Unbounded growth; missing index | Add `(user_id, called_at)` index at migration time; decide row vs. aggregate model before writing migration |
| XClient instrumentation hook | Breaking existing XClient tests; tracking inside transaction | Hook at controller call site; write outside any transaction block |
| `Admin::BaseController` + gate | Auth bypass; `skip_before_action` inheritance | Two negative integration tests (unauthed + non-admin) before wiring any admin views |
| Cucumber hook updates | `x_api_calls` rows leaking between `@x_gadget` scenarios | Add `XApiCall.delete_all` to global `Before` hook in the same phase that introduces the table |
| Admin report view | N+1 on user association; admin link on guest path | Use aggregate SQL with `joins(:user)`; guard all `current_user.admin?` inside `user_signed_in?` |
| Date filtering in report | Timezone mismatch in `GROUP BY DATE(called_at)` | Use timezone-aware grouping from day one; verify `config.time_zone` |
| Test setup for admin controller tests | WebMock errors from incidental XClient calls | Insert tracking rows directly via `XApiCall.create!`; stub Twitter endpoints if portal is loaded |

---

## Sources

- Direct code inspection: `app/services/x_client.rb` — hook placement analysis; `refresh_oauth2_token!` separation; three-path Faraday connection strategy
- Direct code inspection: `test/support/webmock.rb` — WebMock isolation scope (blocks HTTP, not ActiveRecord)
- Direct code inspection: `features/support/hooks.rb` — confirmed cleanup list: `MastodonAccount.delete_all`, `XAccount.delete_all`, `VisitedLink.delete_all`; confirmed `x_api_calls` is absent
- Direct code inspection: `app/controllers/application_controller.rb` — `authenticate_user!` inheritance chain; no admin gate exists
- Direct code inspection: `app/controllers/pages_controller.rb` — `skip_before_action :authenticate_user!` without `only:` (public pattern to not copy)
- Direct code inspection: `app/controllers/x_accounts_controller.rb` — transaction wrapping at line 47 (Pitfall 4 basis)
- Direct code inspection: `db/schema.rb` — `users.admin boolean NOT NULL DEFAULT false` confirmed; no admin controllers confirmed absent
- Direct code inspection: `test/fixtures/users.yml` — id:1 `admin: true`, id:2 `admin: false`; ready for positive/negative gate tests
- Direct code inspection: `test/services/x_client_test.rb` — three distinct test strategies documented (Faraday `:test`, WebMock, mixed)
- Confidence: HIGH — all pitfalls grounded in actual codebase structure, not general Rails patterns alone
