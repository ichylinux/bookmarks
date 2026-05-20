# Project Research Summary

**Project:** Bookmarks v1.29 — Admin X API Usage Report
**Domain:** Admin instrumentation layer + usage reporting on a multi-user Rails 8.1 / MySQL app
**Researched:** 2026-05-20
**Confidence:** HIGH

## Executive Summary

The v1.29 milestone adds an admin-only X API usage report to the existing Bookmarks Rails app. The scope is narrowly constrained: one new database table (`x_api_calls`), one new model, instrumentation at the XClient service boundary, a namespaced admin controller behind a `users.admin` gate, and a single server-rendered ERB report view. Every capability needed — aggregation queries, namespace routing, controller concerns, i18n, ERB views — is already provided by Rails 8.1 built-ins. Zero new gems are required.

The recommended approach is an event-log table (one row per X API call) rather than counter columns. The PROJECT.md feature spec requires date-range filtering and per-user breakdowns; these queries require timestamped rows and cannot be answered by incrementing a counter. The table carries a composite index on `(user_id, called_at)` and a separate index on `called_at`. All aggregation is done in SQL (`GROUP BY user_id COUNT(*) MAX(called_at) SUM(success = 0)`), never by pulling rows into Ruby.

The highest-priority correctness requirements are: (1) the admin gate must be enforced at the controller level, not just the view, because any authenticated user who knows the route can otherwise access cross-user data; (2) the Cucumber `Before` hook must add `XApiCall.delete_all` in the same phase the migration is introduced, or `@x_gadget` scenarios will accumulate rows and fail non-deterministically; and (3) the nav link must be guarded with `user_signed_in? && current_user.admin?` (both conditions, in order) because `current_user` is nil on the guest landing path. The admin gate returns 404 (not 403) to avoid revealing that admin routes exist.

## Key Findings

### Recommended Stack

All implementation uses the stack already present in the codebase. Rails 8.1 `ActiveRecord` handles the migration, model, validations, aggregation queries, and namespace routing. MySQL 8 provides `SUM(http_status >= 400)` boolean aggregate and efficient indexed range queries. Devise supplies `current_user` and the `users.admin` boolean (which already exists in `db/schema.rb` as `t.boolean "admin", default: false, null: false`). ERB with Sprockets serves the report view. No charting library, no pagination gem, no authorization framework.

**Core technologies:**
- Rails 8.1.3 (already locked): `XApiCall` model, `GROUP BY` aggregations, `namespace :admin` routing, controller concerns — all built-in
- MySQL 8 (already in use): composite index `(user_id, called_at)` for range queries; `SUM(boolean_expr)` for error counting
- Devise (already locked): `current_user`, `users.admin?` predicate — no changes needed
- ERB + Sprockets (already in use): server-rendered report table and date-range filter form; no new JS

**Explicitly rejected:**
- `pundit` / `cancancan`: heavyweight for one boolean check; a 5-line `before_action` concern is proportionate
- `administrate` / `activeadmin`: full admin frameworks with conflicting asset pipelines; one report page does not justify the cost
- `chartkick` + `groupdate`: gem overhead for an optional future enhancement; CDN Chart.js is available if a chart is ever needed
- `pagy` / `kaminari`: premature at personal-app user counts

### Expected Features

**Must have (table stakes for v1.29):**
- Per-user X API call count — `COUNT(*)` grouped by `user_id`; the primary question the admin needs to answer
- Last call timestamp per user — `MAX(called_at)` grouped by `user_id`; recency context makes counts actionable
- Endpoint dimension (`fetch_following` vs `fetch_recent_tweets`) — different rate-limit budgets; without this the count is uninterpretable
- Success/error breakdown per user — 429 rate-limit and 401 auth errors are the critical operational signal
- Admin-only access gate at controller level — `require_admin` before_action returning 404 (not 403) to obscure route existence
- Date-range filter — `WHERE called_at >= ?` from a `<form method="get">` date input; no JS required
- Ja/en locale strings — mandatory; app is bilingual end-to-end

**Should have (useful but not MVP-blocking):**
- Column sorting on the report table — low value when user count is small
- Raw per-call drilldown page — useful for incident debugging
- Response time tracking (`duration_ms`) — low effort if added at migration time

**Defer (v2+):**
- Rate-limit header capture (`x-rate-limit-remaining`) — most relevant for Pro/Basic tier; free tier 100-read/month makes it less critical
- CSV export
- Real-time dashboard / ActionCable
- Email alerting on threshold breaches
- Admin user management UI (already handled by Rake tasks)

### Architecture Approach

The architecture extends the existing service-oriented pattern without introducing new layers. `XClient` is the only place where X API HTTP calls are issued, making it the correct instrumentation point regardless of which controller triggers the call — covering `XAccountsController#refresh`, `XAccountsController#show`, and `Portal#get_gadgets` simultaneously. The public `fetch_following` and `fetch_recent_tweets` methods become thin tracking wrappers over private implementation methods; return contracts are unchanged so all callers are unaffected. The admin controller lives under `namespace :admin` with an `Admin::BaseController` intermediate that enforces the `require_admin` gate inherited from `ApplicationController`. No separate admin layout is needed; the existing application layout uses a conditional drawer section.

**Major components:**
1. `x_api_calls` table + `XApiCall` model — event log; `record!` class method; `usage_summary(since:)` aggregation scope returning SQL aggregates
2. `XClient` instrumentation — `record_call` private helper with `rescue StandardError => nil` so tracking failures never surface to users; `refresh_oauth2_token!` calls explicitly excluded
3. `Admin::BaseController < ApplicationController` — `before_action :require_admin` returning `head :not_found` (404) for non-admins to obscure route existence
4. `Admin::XApiUsageController` inheriting `Admin::BaseController` — `index` action with `parse_since_param`; `@users_by_id` pre-fetched via `User.where(id: user_ids).index_by(&:id)` to avoid N+1
5. Report view (`app/views/admin/x_api_usage/index.html.erb`) — date filter form + HTML table; SQL already orders by `total DESC`
6. Drawer nav conditional link — guarded by `user_signed_in? && current_user.admin?` (both conditions, in order); no separate admin layout file

### Critical Pitfalls

1. **Tracking hook inside XClient without test isolation** — `XApiCall.create!` inside XClient fires during every existing Minitest and Cucumber test that uses WebMock stubs. WebMock blocks HTTP but not ActiveRecord writes. Rows accumulate across test runs causing non-deterministic assertions. Prevention: add `XApiCall.delete_all` to Cucumber `Before` hook in the same phase as the migration; stub `allow(XApiCall).to receive(:record!)` in `XClientTest` and controller integration tests.

2. **Admin gate enforced only in the view** — A `<% if current_user.admin? %>` nav guard does not protect the route. Any authenticated non-admin who knows the URL gets a 200 with all users' data. Prevention: `require_admin` before_action in `Admin::BaseController`; write two negative integration tests (unauthenticated and authenticated-non-admin) before wiring any admin view.

3. **`x_api_calls` rows leaking between Cucumber scenarios** — The global `Before` hook in `features/support/hooks.rb` resets `MastodonAccount`, `XAccount`, and `VisitedLink` but not `x_api_calls`. Each `@x_gadget` scenario that triggers instrumentation adds rows visible to later scenarios. Prevention: add `XApiCall.delete_all` to the `Before` hook in the same phase that introduces the migration — not as a follow-up.

4. **`current_user.admin?` called when `current_user` is nil** — `WelcomeController#index` skips `authenticate_user!`; the guest path has `current_user == nil`. Calling `current_user.admin?` raises `NoMethodError` and returns 500 on the public homepage. Prevention: always guard with `user_signed_in? && current_user.admin?` in layouts and views.

5. **Tracking records inside an existing transaction** — `XAccountsController` wraps some logic in a transaction block. A business-logic rollback silently destroys the tracking record even though the X API call already happened. Prevention: write `XApiCall.record!` after the transaction block returns, using the result hash from XClient.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Layer
**Rationale:** All subsequent phases depend on this table existing. The instrumentation hook, the admin controller, and every test fixture that inserts tracking rows require the model. Migrations must be first.
**Delivers:** `db/migrate/YYYYMMDD_create_x_api_calls.rb` with composite index `(user_id, called_at)` and single index on `called_at`; `app/models/x_api_call.rb` with `record!` and `usage_summary(since:)`; Minitest model unit tests (validation, `record!` creates row, `usage_summary` returns correct aggregates and respects `since:` filter)
**Addresses:** Per-user count, last-call timestamp, endpoint dimension, success/error breakdown (all depend on schema)
**Avoids:** Pitfall 5 (unbounded growth) — composite index added at migration time before any data exists

### Phase 2: XClient Instrumentation
**Rationale:** No admin report can show data until calls are being recorded. This phase also closes the critical test-isolation risk by adding Cucumber cleanup in the same commit as the instrumentation.
**Delivers:** Modified `app/services/x_client.rb` with `record_call` private helper (wraps `XApiCall.record!` with `rescue StandardError => nil`); public methods delegate to private `_internal` variants; `refresh_oauth2_token!` untouched; `XApiCall.delete_all` added to Cucumber `Before` hook; Minitest tests asserting `record!` is called with correct args
**Avoids:** Pitfall 1 (test pollution — Cucumber cleanup added here); Pitfall 4 (transaction rollback — `record_call` called after XClient returns, outside any controller transaction); Pitfall 10 (token refresh calls excluded)

### Phase 3: Admin Access Gate
**Rationale:** The admin controller and view cannot be wired without the namespace and the gate. Writing negative integration tests here (before any admin views exist) ensures the gate is tested independently and cannot be accidentally bypassed.
**Delivers:** `app/controllers/admin/base_controller.rb` with `before_action :require_admin` returning `head :not_found`; `namespace :admin` block in `config/routes.rb`; two integration tests — unauthenticated request redirects to sign-in; authenticated non-admin gets 404
**Avoids:** Pitfall 2 (view-only gate); Pitfall 9 (accidental `skip_before_action` inheritance)

### Phase 4: Admin Report Controller and View
**Rationale:** With the table populated (Phase 1+2) and the gate in place (Phase 3), the report controller and view can be built and tested end-to-end.
**Delivers:** `app/controllers/admin/x_api_usage_controller.rb` with `index` action; `@users_by_id` pre-fetched; `parse_since_param`; `app/views/admin/x_api_usage/index.html.erb` with date filter form and HTML table sorted by `total DESC`; Minitest integration test — admin gets 200, `@rows` populated, `?since=` param filters correctly; dummy-email user display shows Twitter handle alongside email
**Avoids:** Pitfall 6 (N+1 — `index_by(&:id)` pattern); Pitfall 11 (timezone — use `in_time_zone` in Ruby display, not MySQL `DATE()` grouping); Pitfall 12 (dummy emails — show Twitter handle)

### Phase 5: Drawer Nav Link and Locale Strings
**Rationale:** Route helpers from Phase 3 must exist before this phase; the report view from Phase 4 must exist to confirm locale keys are complete. Low-risk surface closure.
**Delivers:** Conditional drawer nav link in `app/views/layouts/application.html.erb` behind `user_signed_in? && current_user.admin?`; `admin.x_api_usage.*` keys in `config/locales/ja.yml` and `config/locales/en.yml`
**Avoids:** Pitfall 7 (nil `current_user` on guest path — `user_signed_in?` guard is first and mandatory)

### Phase 6: Cucumber Scenario and Tri-Suite Gate
**Rationale:** Cucumber validates the full request path through a real Puma server. This is the milestone completion gate; all three suites must be green.
**Delivers:** New Cucumber feature file (e.g., `features/08.Admin.feature`) — admin signs in, visits `/admin/x_api_usage`, sees per-user table row; non-admin gets 404; `yarn run lint && bin/rails test && bundle exec rake dad:test` all green
**Avoids:** Pitfall 3 (scenario row leakage — verified from Phase 2); Pitfall 8 (WebMock scope — test setup inserts rows directly via `XApiCall.create!`)

### Phase Ordering Rationale

- Data layer first because every downstream component (model queries, test fixtures, Cucumber cleanup) depends on the schema; cannot write to a table that does not exist
- Instrumentation second because the admin report has no data until XClient is writing rows; also closes the test-pollution risk early so later phases build on clean test state
- Access gate third (before the report view) so the security perimeter is independently tested; prevents the anti-pattern of building the view first and bolting on auth later
- Report controller and view fourth, building on all three prior phases simultaneously
- Nav and locale fifth — cosmetic surface, depends on route helpers existing from Phase 3
- Cucumber last because it validates the full assembled system; it is the milestone completion criterion

### Research Flags

Phases with standard patterns (no additional pre-planning research needed):
- **Phase 1:** Standard Rails migration and model; `GROUP BY` aggregation is well-documented Rails/MySQL
- **Phase 3:** `namespace :admin` and `before_action` concern match existing `TwitterLinkRequirement` concern already in codebase
- **Phase 5:** Same i18n pattern used on every other page; same conditional layout guard already in use

Phases requiring careful code inspection before writing (not research, but targeted reads):
- **Phase 2:** Read `app/services/x_client.rb` in full before writing — confirm exact method boundaries for the `_internal` refactor; confirm `refresh_oauth2_token!` is not in the instrumentation path; confirm Faraday response object exposes `.status` at the right point
- **Phase 4:** Read `features/support/hooks.rb` to confirm `XApiCall.delete_all` was added in Phase 2; read `test/fixtures/users.yml` to confirm which fixture has `admin: true` for positive/negative test setup

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All components confirmed in codebase reads; `users.admin` column confirmed in `db/schema.rb`; zero new gems is a hard finding |
| Features | HIGH | XClient call sites confirmed by direct codebase inspection; X API rate-limit model confirmed via official docs; MVP scope is narrow and well-bounded |
| Architecture | HIGH | `XClient` method boundaries read directly; existing `TwitterLinkRequirement` concern confirmed as the model for `AdminRequirement`; no hidden call sites discovered |
| Pitfalls | HIGH | All pitfalls grounded in actual codebase structure: Cucumber `Before` hook cleanup list confirmed absent `x_api_calls`; `XAccountsController` transaction wrapping confirmed at line 47; `WelcomeController` `skip_before_action` confirmed |

**Overall confidence:** HIGH

### Gaps to Address

- **`http_status` vs `success` boolean column:** STACK.md recommends `http_status smallint` (raw HTTP status); ARCHITECTURE.md recommends `success boolean + error_code varchar`. Phase 1 planning must pick one. Recommendation: `success boolean + error_code varchar(32)` because it maps directly to XClient's existing `{ success:, error: }` return contract; the controller-level hook sees the parsed result, not the raw Faraday response.

- **Instrumentation placement — XClient vs controller call site:** PITFALLS recommends the controller call site to avoid test pollution; STACK and ARCHITECTURE recommend inside XClient with `rescue StandardError => nil`. Either is valid. If XClient instrumentation is chosen, Phase 2 must include adding `XApiCall.delete_all` to the Cucumber `Before` hook and stubbing `allow(XApiCall).to receive(:record!).and_return(nil)` in `XClientTest`. This gap must be resolved explicitly in Phase 2 planning, not deferred.

- **Admin resource naming:** STACK uses `x_api_usage` (non-standard); ARCHITECTURE uses `x_api_usages` (standard Rails plural resource). Use `resources :x_api_usages` to follow Rails conventions; generates `admin_x_api_usages_path` and maps to `Admin::XApiUsagesController`.

- **Dummy email display:** Users who signed in via Twitter OAuth have `dummy_UUID@example.com` addresses. The report must show the Twitter handle alongside or instead of email. Address in Phase 4 view design; the `x_accounts.username` column is available for this.

## Sources

### Primary (HIGH confidence — direct codebase reads)
- `app/services/x_client.rb` — instrumentation placement, call site enumeration, `refresh_oauth2_token!` separation
- `db/schema.rb` — `users.admin boolean NOT NULL DEFAULT false` confirmed; no existing usage tracking table
- `features/support/hooks.rb` — Cucumber `Before` hook cleanup list confirmed; `x_api_calls` absent
- `app/controllers/x_accounts_controller.rb` — transaction wrapping at line 47; XClient call sites
- `app/controllers/application_controller.rb` — `authenticate_user!` inheritance chain
- `test/fixtures/users.yml` — id:1 `admin: true`, id:2 `admin: false`
- `test/services/x_client_test.rb` — three-path test strategy; WebMock isolation scope confirmed

### Secondary (HIGH confidence — official documentation)
- [X API v2 Rate Limits](https://developer.x.com/en/docs/x-api/v1/rate-limits) — per-user vs app-level rate-limit model
- [X API Pricing 2026](https://postproxy.dev/blog/x-api-pricing-2026/) — free tier 100 reads/month confirmed

### Tertiary (MEDIUM confidence — community sources)
- [AppSignal Audit Logging in Rails](https://blog.appsignal.com/2023/04/12/audit-logging-in-ruby-and-rails.html) — event-log vs counter-column trade-offs
- [DEV Community: Custom Audit Trail in Rails](https://dev.to/nemwelboniface/building-a-custom-audit-trail-in-ruby-on-rails-without-papertrail-klk) — bespoke log table approach

---
*Research completed: 2026-05-20*
*Ready for roadmap: yes*
