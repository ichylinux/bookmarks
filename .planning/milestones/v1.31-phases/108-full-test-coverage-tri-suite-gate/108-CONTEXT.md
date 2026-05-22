# Phase 108: Full Test Coverage & Tri-suite Gate - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add Cucumber E2E scenarios for the v1.31 manual-add feature: a happy-path scenario (enter handle → account appears → Refresh → account survives) and a not-found error scenario (enter nonexistent handle → not-found flash appears). All Minitest tests (model, service, controller) were added in prior phases and must remain green. Run the full tri-suite gate: `yarn run lint && bin/rails test && bundle exec rake dad:test` — all must exit 0.

</domain>

<decisions>
## Implementation Decisions

### Cucumber Scenario Scope
- 2 scenarios: happy-path + not-found (exactly what ROADMAP specifies; no additional scenarios)
- New file: `features/07.X手動追加.feature` — follows Japanese naming pattern alongside `06.X.feature`
- New `@x_manual_add` tag with dedicated Before/After hooks — isolated from `@x_gadget` (different stub setup)
- Happy-path Refresh assertion: click '更新' button, then assert the manually-added account card is still visible

### Hook & WebMock Setup
- `@x_manual_add` Before hook:
  - Set `provider: 'twitter2', uid: 'x_manual_uid_host', oauth2_token: 'manual_add_token'` on `user`
  - Stub `GET https://api.twitter.com/2/users/by/username/testhandle` → 200 with body `{ "data": { "id": "x_manual_uid", "username": "testhandle", "name": "Test Handle" } }`
  - Stub `GET https://api.twitter.com/2/users/by/username/ghost_user` → 404 with body `{ "errors": [{ "detail": "Could not find user with username: ghost_user" }] }`
  - Also stub tweets endpoint for testhandle (needed if Refresh triggers tweet fetch): `GET https://api.twitter.com/2/users/x_manual_uid/tweets` → 200 `{ "data": [] }`
- `@x_manual_add` After hook:
  - `WebMock.remove_request_stub` for all stubs
  - `XAccount.where(user_id: user.id).delete_all`
  - `user.update_columns(provider: nil, uid: nil, oauth2_token: nil)`
- Success response body: `{ "data": { "id": "x_manual_uid", "username": "testhandle", "name": "Test Handle" } }` — matches `parse_lookup_response` → `normalize_following_row` field expectations (`id`, `username`, `name`)

### Step Definitions
- Language: Japanese `もし /^...$/ do` — consistent with all other step files
- Fill handle input via `fill_in` matching placeholder `'@handle'` — matches the placeholder on the form input
- Verify account appears: `assert_text 'testhandle'` on the x_accounts page
- Refresh: `click_button '更新'` (the refresh button locale key is `x_accounts.index.refresh` = '更新')
- After refresh assertion: `assert_text 'testhandle'` still present (account card not deleted)
- New step definitions go in `features/step_definitions/x_accounts.rb` (existing file, append)

### Claude's Discretion
- Exact scenario step wording in Japanese
- Whether to assert the manually-added badge text ('手動追加') in addition to the username
- Exact URL pattern for tweets stub (whether testhandle tweets are needed for Refresh to not error)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `features/support/hooks.rb` — add `@x_manual_add` Before/After hooks alongside `@x_gadget`
- `features/step_definitions/x_accounts.rb` — existing step file with 1 step; append new steps
- `WebMock.stub_request` / `WebMock.remove_request_stub` — established pattern from `@x_gadget`, `@mastodon_gadget`
- `user` helper from `test/support/users.rb` — returns `User.first` (id=1); available in Cucumber World

### Established Patterns
- Hooks: `Before('@tag') do ... end` / `After('@tag') do ... end` in `features/support/hooks.rb`
- User setup: `user.update_columns(provider: 'twitter2', uid: '...', oauth2_token: '...')` pattern from `@x_gadget`
- Step definitions: `もし /^pattern$/ do |params| ... end` in `features/step_definitions/*.rb`
- Feature files: `# language: ja` header, `@tag\n機能: Name\n\n  @tag\n  シナリオ: Name\n    * step`
- Assertions: `assert_text`, `assert_selector` from Capybara::Minitest::Assertions in World

### Integration Points
- `XAccountsController#lookup_and_add` at `POST /x_accounts/lookup_and_add` — the action under test
- `XClient#lookup_user_by_username` stubs via WebMock (controller uses `XClient.new(user:)`)
- `/x_accounts` index page — where the form and account cards appear
- Refresh button triggers `POST /x_accounts/refresh` which calls `refresh_cache_from_items!` — the guard is what we're verifying survives

### parse_lookup_response confirmed
- 200 → body must have `{ "data": { "id": string, "username": string, "name": string } }`
- 404/400 → `{ success: false, error: :not_found }` — body irrelevant, status drives the mapping

</code_context>

<specifics>
## Specific Ideas

- The globally-run Before hook already calls `XAccount.delete_all` — no need to reset accounts at scenario start; After hook cleanup is still needed to undo user credential columns
- Refresh button in the x_accounts index page — check actual locale key to confirm '更新' is the button text
- Must stub tweets endpoint for `x_manual_uid` if Refresh triggers a tweet fetch; otherwise the refresh will fail on WebMock's `NetConnectNotAllowedError`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
