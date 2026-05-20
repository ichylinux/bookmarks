# Requirements — v1.29 Admin X API Usage Report

## Milestone Goal

Give admins a view of X (Twitter) API usage across all users — request counts, rate-limit consumption, per-user breakdowns.

## v1.29 Requirements

### Data Layer

- [x] **DATA-01**: `x_api_calls` table exists with columns `user_id`, `endpoint`, `success`, `error_code`, `called_at`; `(user_id, called_at)` index present
- [x] **DATA-02**: `XApiCall` model with `record!` class method and aggregation scope for per-user summaries
- [x] **DATA-03**: `rate_limit_remaining` nullable integer column on `x_api_calls` captures X-Rate-Limit-Remaining header per call

### Instrumentation

- [x] **INST-01**: `XAccountsController#refresh` writes an `XApiCall` row after each `fetch_following` call (success and error paths)
- [x] **INST-02**: `XAccountsController#show` writes an `XApiCall` row after each `fetch_recent_tweets` call (success and error paths)
- [x] **INST-03**: Cucumber `Before` hook includes `XApiCall.delete_all` to prevent tracking row accumulation across scenarios

### Admin Access

- [x] **ADMIN-01**: `Admin::BaseController` with `require_admin` before_action; non-admin and unauthenticated requests receive 404; two negative integration tests required
- [x] **ADMIN-02**: Drawer nav includes link to `/admin/x_api_usages` visible only when `user_signed_in? && current_user.admin?`

### Report

- [x] **REPORT-01**: Admin can view a per-user usage table at `/admin/x_api_usages` showing: email, total calls, last called at, endpoint breakdown, error count
- [x] **REPORT-02**: Admin can filter the report by date range (from/to); no schema changes required
- [x] **REPORT-03**: Admin can sort the report by clicking column headers (total calls, last called at)

### Locale

- [x] **LOCALE-01**: All admin report UI strings have ja/en locale keys; i18n parity test passes

## Future Requirements

- Rate-limit window tracking (per-15-min remaining count per user — needs persistent window state)
- Chart/graph visualization of usage over time (Chart.js via CDN when needed)
- Pruning/retention Rake task for `x_api_calls` rows older than 90 days (ACCT-FUT-01 pattern)
- Per-endpoint drill-down detail page

## Out of Scope

- Heavy analytics gems (no Ahoy, no Blazer) — Rails built-ins sufficient
- Background job for async tracking — synchronous write at controller call site is correct
- Real-time rate-limit header enforcement — tracking only, no blocking
- Admin management UI (user promotion to admin) — `users.admin` set via Rake task only

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| DATA-01 | Phase 96 | complete |
| DATA-02 | Phase 96 | complete |
| DATA-03 | Phase 96 | complete |
| INST-01 | Phase 97 | complete |
| INST-02 | Phase 97 | complete |
| INST-03 | Phase 97 | complete |
| ADMIN-01 | Phase 98 | complete |
| ADMIN-02 | Phase 99 | complete |
| REPORT-01 | Phase 99 | complete |
| REPORT-02 | Phase 99 | complete |
| REPORT-03 | Phase 99 | complete |
| LOCALE-01 | Phase 99 | complete |
