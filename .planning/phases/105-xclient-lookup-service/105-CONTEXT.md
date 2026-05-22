# Phase 105: XClient Lookup Service - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning
**Mode:** Auto-generated (all decisions pre-locked in REQUIREMENTS.md + STATE.md)

<domain>
## Phase Boundary

Add `XClient#lookup_user_by_username(username:)` — a new public method on the existing `XClient` service that resolves a public X handle to a single user record, returning a structured result hash or a typed error symbol. Fully covered by isolated Minitest cases using the Faraday `:test` adapter.

This phase adds no UI, no routes, no migrations — pure service layer and tests only.

</domain>

<decisions>
## Implementation Decisions

### API Call
- Strip leading `@` from the `username` argument before building the URL path
- Call `GET /2/users/by/username/{handle}` via the existing Bearer auth `connection_for(user)` helper
- Pass `user:` as the first argument so the existing `connection_for` / `refresh_if_expired!` chain handles token refresh automatically
- Use `user.fields` query param: `id,name,username,profile_image_url,protected` (matches `normalize_following_row` fields)

### Return Shape
- Success: `{ success: true, item: { id:, username:, name:, profile_image_url:, protected: } }` — single `item` key (not `items`)
- The canonical `username` stored in `:item` comes from the API response, NOT from the raw input (per STATE.md decision)
- Reuse existing `normalize_following_row` to build the item hash (same field set as following sync)

### Error Mapping
- HTTP 404 → `:not_found`
- HTTP 400 → `:not_found` (bad handle format treated same as not found)
- HTTP 403 → `:suspended`
- HTTP 429 → `:rate_limited`
- All other non-200 → `:api_error`
- `Faraday::TimeoutError` / `Faraday::ConnectionFailed` → `:api_error` (matches REQUIREMENTS.md "network error" bucket)

### Test Approach
- Faraday `:test` adapter stubs injected via `XClient.new(connection: conn)` — same pattern as existing `fetch_following` tests
- 7 test cases: 200 success, 404 not_found, 400 not_found, 403 suspended, 429 rate_limited, Faraday::TimeoutError, Faraday::ConnectionFailed

### Claude's Discretion
- Name of private parse helper (e.g., `parse_lookup_response`) — Claude's choice, consistent with `parse_following_response` naming
- Exact stub URL regex pattern — should match `/2/users/by/username/` prefix

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `XClient#connection_for(user)` — builds Bearer Faraday connection; handles OAuth2 token refresh via `refresh_if_expired!`
- `XClient#normalize_following_row(row)` — maps API hash to `{ id:, username:, name:, profile_image_url:, protected: }` — reuse directly
- `XClient#parse_following_response(res)` — pattern to follow for new `parse_lookup_response` private method
- `XClient#parse_json_safe(raw)` — JSON parse with nil-on-error fallback
- `XClient.new(connection: conn)` — constructor injection for Faraday test stubs (used in all existing service tests)

### Established Patterns
- Return shape: `{ success: true|false, ... }` — consistent across all XClient methods
- Error rescue at method boundary: `rescue Faraday::TimeoutError, Faraday::ConnectionFailed` and `rescue Faraday::Error` wrapping the entire method body
- Tests: `stubs = Faraday::Adapter::Test::Stubs.new; conn = Faraday.new { |f| f.adapter :test, stubs }`
- Fixture: `users(:twitter_user)` for the test user

### Integration Points
- `app/services/x_client.rb` — add `lookup_user_by_username` as a new public method
- `test/services/x_client_test.rb` — add 7 new test cases in `XClientTest`

</code_context>

<specifics>
## Specific Ideas

- REQUIREMENTS.md XSVC-01: "strips leading `@`", "calls `GET /2/users/by/username/:username`", "reuses existing Bearer auth connection and `normalize_following_row`"
- REQUIREMENTS.md XSVC-02: "stores API-returned `username` (not user input)"
- STATE.md: "HTTP 403 from X API for suspended accounts maps to `:suspended` error symbol"
- ROADMAP Phase 105 success criterion 4: "7 response codes (200, 404, 400, 403, 429, timeout, network error)"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
