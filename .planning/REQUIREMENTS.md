# Requirements: Bookmarks

**Defined:** 2026-05-22
**Milestone:** v1.31 — X Account Manual Add (Non-Following)
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.31 Requirements

### Schema & Model (XMAN)

- [ ] **XMAN-01**: `x_accounts` table gains `manually_added boolean NOT NULL DEFAULT false`; existing rows default to `false` via migration
- [ ] **XMAN-02**: `refresh_cache_from_items!` soft-delete sweep skips rows where `manually_added: true`; covered by Minitest
- [ ] **XMAN-03**: `XAccount` provides an `upsert_manual!` method that creates or restores a manually-added account (`manually_added: true`, `deleted: false`)

### X API Service (XSVC)

- [ ] **XSVC-01**: `XClient#lookup_user_by_username(username:)` calls `GET /2/users/by/username/:username`, strips leading `@`, reuses existing Bearer token and `normalize_following_row`
- [ ] **XSVC-02**: Response parser handles all error codes: 404/400 → `:not_found`, 403 → `:suspended`, 429 → `:rate_limited`, other → `:api_error`; stores API-returned `username` (not user input)

### Controller & Routes (XCTL)

- [ ] **XCTL-01**: `POST /x_accounts/lookup_and_add` action looks up handle, upserts via `upsert_manual!`, instruments via `record_x_api_call`, responds with redirect + flash
- [ ] **XCTL-02**: All 7 error states surface as localized flash alerts (ja/en): not found, already active, rate limited, suspended, blank input, network error, and successful add

### View & Locales (XVIEW)

- [ ] **XVIEW-01**: Inline `form_with` on `/x_accounts` index: text input for handle (`@username`), submit button, no new JS
- [ ] **XVIEW-02**: Each account card on `/x_accounts` shows a visual indicator (badge or label) when `manually_added: true`; bilingual ja/en label
- [ ] **XVIEW-03**: Bilingual locale strings (ja/en) for all new flash messages and UI labels; i18n parity test passes

### Tests & Gate (XTEST)

- [ ] **XTEST-01**: Minitest: model tests for `manually_added` flag behavior and refresh guard; service tests with WebMock stubs for new endpoint; controller integration tests for all error paths
- [ ] **XTEST-02**: Cucumber E2E: happy path (add by handle → account appears → survives Refresh); not-found scenario; WebMock stub for `/2/users/by/username/`; tri-suite gate green

## Future Requirements

### v2+

- **XMAN-FUT-01**: Total cap on manually-added accounts (no cap in v1.31)
- **XMAN-FUT-02**: Bulk add by handle list
- **XMAN-FUT-03**: Dedicated remove action for manually-added accounts distinct from follow-synced

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-suggest / search-as-you-type | No new JS complexity constraint |
| Showing `manually_added` source differently on the dashboard gadget | Display is uniform; flag is data-layer only |
| Per-manually-added-account display_count distinct from follow-synced | Same preference model applies to all |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| XMAN-01 | — | Pending |
| XMAN-02 | — | Pending |
| XMAN-03 | — | Pending |
| XSVC-01 | — | Pending |
| XSVC-02 | — | Pending |
| XCTL-01 | — | Pending |
| XCTL-02 | — | Pending |
| XVIEW-01 | — | Pending |
| XVIEW-02 | — | Pending |
| XVIEW-03 | — | Pending |
| XTEST-01 | — | Pending |
| XTEST-02 | — | Pending |

**Coverage:**
- v1.31 requirements: 12 total
- Mapped to phases: 0 (roadmap pending)
- Unmapped: 12 ⚠️

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-22 after initial definition*
