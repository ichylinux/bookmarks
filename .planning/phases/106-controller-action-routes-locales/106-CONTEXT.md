# Phase 106: Controller Action, Routes & Locales - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `POST /x_accounts/lookup_and_add` as a collection action on `XAccountsController`, wired to a new `lookup_and_add` action that calls `XClient#lookup_user_by_username`, calls `XAccount.upsert_manual!` on success, instruments via `record_x_api_call`, and redirects with a localized flash for all 7 outcomes (1 success + 6 error states). Add all required locale keys in ja.yml and en.yml. Add controller integration tests for all 7 flash states.

</domain>

<decisions>
## Implementation Decisions

### Route & Auth Design
- Route as collection action under `resources :x_accounts` — `post :lookup_and_add` in the collection block, consistent with existing `post :refresh`
- Auth gate: class-level `before_action :require_twitter_linked` already covers all actions including the new one — no additional gate needed
- Already-active duplicate: call `XAccount.upsert_manual!` (idempotent from Phase 104); check result or catch no-op to detect re-add and surface as notice

### Flash Messages & Error Mapping
- Success key: `x_accounts.lookup_and_add.success` under existing `x_accounts:` tree
- Error key strategy: reuse `errors.x_client.*` keys for API errors (`:not_found`, `:rate_limited`, `:suspended`, `:timeout`, `:network`); add new locale keys only for `:blank_input` and `:already_active`
- `:already_active` tone: `flash[:notice]` (informational) — "already being followed", not an error
- Blank input: guard in controller before calling `XClient` (no wasted API call); return early with `flash[:alert]`

### Claude's Discretion
- Exact Japanese phrasing for new locale keys
- Whether to add `lookup_and_add` as a subsection under `x_accounts.lookup_and_add.*` or inline in `x_accounts.*`
- Controller test fixture setup (reuse existing `users(:twitter_user)` pattern)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `XAccountsController` at `app/controllers/x_accounts_controller.rb` — include `TwitterLinkRequirement`, `before_action :require_twitter_linked` class-level (covers all actions)
- `record_x_api_call(endpoint:, result:)` private method at line 82 — reuse exactly as in `refresh` and `show`
- `XClient#lookup_user_by_username(user:, username:)` — implemented in Phase 105, returns `{ success: true, item: {...} }` or `{ success: false, error: :symbol }`
- `XAccount.upsert_manual!` — implemented in Phase 104, idempotent create/restore
- `t("errors.x_client.#{result[:error]}")` pattern already used in `refresh` action (line 17)

### Established Patterns
- Collection action route: `resources :x_accounts do; collection do; post :refresh; end; end` — mirror with `post :lookup_and_add`
- Flash + redirect pattern: `flash[:alert] = t(...); redirect_to x_accounts_path and return`
- Success: `flash[:notice] = t('x_accounts.X.success'); redirect_to x_accounts_path`
- Locale structure: `x_accounts:` → `lookup_and_add:` → `success:`, `already_active:`, `blank_input:`; error API keys live under `errors.x_client.*`

### Integration Points
- Routes: `config/routes.rb` line 45 — add `post :lookup_and_add` inside existing collection block
- Locales: `config/locales/ja.yml` and `en.yml` — add under `x_accounts:` section (around line 419)
- Controller test: `test/controllers/x_accounts_controller_test.rb` (277 lines) — add 7 new test methods

</code_context>

<specifics>
## Specific Ideas

- Error symbols from `lookup_user_by_username` after Phase 105 fixes: `:not_found`, `:suspended`, `:rate_limited`, `:timeout`, `:network`, `:api_error` — all have keys under `errors.x_client.*`
- New symbols needing new locale keys: `:blank_input` (controller guard before API call), `:already_active` (XAccount already exists and is active)
- The `upsert_manual!` method from Phase 104 is idempotent — need to check if account was already active before the call to distinguish "added" from "already active"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
