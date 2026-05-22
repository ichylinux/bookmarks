# Phase 105: XClient Lookup Service - Research

**Researched:** 2026-05-22
**Domain:** X API v2 user-lookup endpoint + Ruby Faraday service layer + Minitest isolation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Strip leading `@` from the `username` argument before building the URL path
- Call `GET /2/users/by/username/{handle}` via the existing Bearer auth `connection_for(user)` helper
- Pass `user:` as the first argument so the existing `connection_for` / `refresh_if_expired!` chain handles token refresh automatically
- Use `user.fields` query param: `id,name,username,profile_image_url,protected` (matches `normalize_following_row` fields)
- Success: `{ success: true, item: { id:, username:, name:, profile_image_url:, protected: } }` — single `item` key (not `items`)
- The canonical `username` stored in `:item` comes from the API response, NOT from the raw input (per STATE.md decision)
- Reuse existing `normalize_following_row` to build the item hash (same field set as following sync)
- HTTP 404 → `:not_found`
- HTTP 400 → `:not_found` (bad handle format treated same as not found)
- HTTP 403 → `:suspended`
- HTTP 429 → `:rate_limited`
- All other non-200 → `:api_error`
- `Faraday::TimeoutError` / `Faraday::ConnectionFailed` → `:api_error` (matches REQUIREMENTS.md "network error" bucket)
- Faraday `:test` adapter stubs injected via `XClient.new(connection: conn)` — same pattern as existing `fetch_following` tests
- 7 test cases: 200 success, 404 not_found, 400 not_found, 403 suspended, 429 rate_limited, Faraday::TimeoutError, Faraday::ConnectionFailed

### Claude's Discretion

- Name of private parse helper (e.g., `parse_lookup_response`) — Claude's choice, consistent with `parse_following_response` naming
- Exact stub URL regex pattern — should match `/2/users/by/username/` prefix

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| XSVC-01 | `XClient#lookup_user_by_username(username:)` calls `GET /2/users/by/username/:username`, strips leading `@`, reuses existing Bearer token and `normalize_following_row` | Endpoint URL confirmed via official docs; `normalize_following_row` confirmed field-compatible with single-user response shape; connection injection pattern identified |
| XSVC-02 | Response parser handles all error codes: 404/400 → `:not_found`, 403 → `:suspended`, 429 → `:rate_limited`, other → `:api_error`; stores API-returned `username` (not user input) | Error response shapes confirmed; `parse_following_response` is the structural pattern to extend; 403-for-suspended is a distinct new case not in existing parsers |
</phase_requirements>

---

## Summary

Phase 105 is a pure service-layer addition: one new public method (`lookup_user_by_username`) and one new private parser (`parse_lookup_response`) on the existing `XClient` class, covered by 7 Minitest cases. No migrations, no routes, no views.

The X API v2 endpoint `GET /2/users/by/username/{username}` returns a single `data` object (not an array), which `normalize_following_row` can consume directly after extracting `body['data']`. The five fields requested via `user.fields` are identical to what `fetch_following` already uses, so normalization is a zero-change reuse.

**The critical implementation detail** is connection routing: the new method must call `following_connection(user)` (not `connection_for(user)` directly) to support the Faraday `:test` adapter injection via `XClient.new(connection: conn)`. `connection_for` builds a fresh Faraday instance and does not check `@forced_connection`; only `following_connection` does. The CONTEXT.md references `connection_for` as the auth chain but the test injection pattern requires going through `following_connection`. See the Connection Injection section below.

**Primary recommendation:** Add `lookup_user_by_username` calling `following_connection(user)`, with a `parse_lookup_response` private method that extends `parse_following_response`'s case statement to add `when 403 → :suspended` and `when 400 → :not_found`. Seven test cases cover the full error symbol contract using the Faraday `:test` stub injection pattern already established in `x_client_test.rb`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| X API HTTP call | Service (`XClient`) | — | `XClient` owns all X API v2 calls; no bypassing to controller |
| Bearer token auth + refresh | Service (`XClient`) private infrastructure | — | `connection_for` / `refresh_if_expired!` already in `XClient` |
| `@` strip + handle normalization | Service (`XClient#lookup_user_by_username`) | — | CONTEXT.md locks this in the service method, not caller |
| Response parsing + error mapping | Service (`XClient` private) | — | Follows `parse_following_response` / `parse_tweets_response` pattern |
| Field normalization to hash | Service (`normalize_following_row`) | — | Reuse unchanged private method |
| Test isolation | Minitest with Faraday `:test` adapter | — | No WebMock needed for this method's tests |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `faraday` | Already in Gemfile | HTTP client for X API v2 | `XClient` already uses it; `:test` adapter enables connection injection |
| Minitest (Rails default) | Rails 8.1.3 | Unit tests for service | Project standard; already used in `x_client_test.rb` |
| `Faraday::Adapter::Test::Stubs` | Ships with faraday | Stub HTTP in isolated tests | Established pattern in `x_client_test.rb` |

[VERIFIED: direct codebase inspection of Gemfile and x_client_test.rb]

No new gems required. [VERIFIED: codebase inspection]

### Installation

```bash
# No new gems — all dependencies already present
```

---

## Package Legitimacy Audit

No new packages are installed in this phase. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Test:
  XClient.new(connection: stub_conn)
       │
       ▼
  lookup_user_by_username(user:, username:)
       ├─ strip '@' from username
       ├─ following_connection(user)  ←── returns @forced_connection (stub) if set
       │       └─ connection_for(user) [only in production path]
       │              ├─ refresh_if_expired!(user)
       │              └─ bearer_faraday('https://api.twitter.com', user)
       ├─ GET /2/users/by/username/{handle}?user.fields=id,name,username,profile_image_url,protected
       └─ parse_lookup_response(res)
              ├─ 200 → parse_json_safe → body['data'] → normalize_following_row → { success: true, item: }
              ├─ 404 → { success: false, error: :not_found }
              ├─ 400 → { success: false, error: :not_found }
              ├─ 403 → { success: false, error: :suspended }
              ├─ 429 → { success: false, error: :rate_limited }
              └─ other → { success: false, error: :api_error }

Rescue chain (wraps entire method body):
  Faraday::TimeoutError, Faraday::ConnectionFailed → { success: false, error: :api_error }
  Faraday::Error → { success: false, error: :api_error }
```

### Recommended Project Structure

No new files. Changes to:

```
app/services/
└── x_client.rb      # add lookup_user_by_username (public) + parse_lookup_response (private)

test/services/
└── x_client_test.rb # add 7 new test cases in XClientTest
```

### Pattern 1: New Public Method (follows `fetch_recent_tweets` skeleton)

```ruby
# Returns { success: true, item: { id:, username:, name:, profile_image_url:, protected: } }
#      or { success: false, error: :not_found | :suspended | :rate_limited | :api_error }
def lookup_user_by_username(user:, username:)
  handle = username.to_s.sub(/\A@/, '').presence
  return { success: false, error: :not_found } if handle.blank?

  res = following_connection(user).get("/2/users/by/username/#{handle}") do |req|
    req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
  end

  parse_lookup_response(res)
rescue Faraday::TimeoutError, Faraday::ConnectionFailed
  { success: false, error: :api_error }
rescue Faraday::Error
  { success: false, error: :api_error }
end
```

[VERIFIED: codebase inspection of x_client.rb — rescue chain structure matches existing methods; `following_connection` confirmed to check `@forced_connection`]

**Why `following_connection` not `connection_for`:** `connection_for` builds a new Faraday instance that does NOT check `@forced_connection`. Only `following_connection` returns the injected stub. The test pattern `XClient.new(connection: conn)` requires `@forced_connection` to be consulted. CONTEXT.md refers to `connection_for` as the auth infrastructure owner (correct — `following_connection` delegates to it), but the direct call site in the new method must be `following_connection` for test injection to work. [ASSUMED — the CONTEXT.md's phrasing is slightly ambiguous; this interpretation is the only one consistent with both the test injection requirement and the existing code structure]

### Pattern 2: New Private Parser (extends `parse_following_response`)

```ruby
def parse_lookup_response(res)
  case res.status
  when 200
    body = parse_json_safe(res.body)
    return { success: false, error: :parse_error } unless body.is_a?(Hash)

    row = body['data']
    return { success: false, error: :not_found } unless row.is_a?(Hash)

    { success: true, item: normalize_following_row(row) }
  when 400, 404
    { success: false, error: :not_found }
  when 403
    { success: false, error: :suspended }
  when 429
    { success: false, error: :rate_limited }
  else
    { success: false, error: :api_error }
  end
end
```

[VERIFIED: codebase inspection — `parse_following_response` is the structural template; `normalize_following_row` confirmed field-compatible with single-object `data` response]

Key difference from `parse_following_response`:
- `body['data']` is a Hash (single object), not an Array — extract directly, do not iterate
- New `when 403` branch for suspended accounts
- New `when 400` branch (X API returns 400 for some invalid/deactivated handles)
- Return key is `item:` (singular), not `items:`

### Pattern 3: Test Case Structure (Faraday :test adapter injection)

```ruby
def test_lookup_user_returns_item_on_200
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) do
    [200, { 'Content-Type' => 'application/json' },
     { data: { id: '123', username: 'foobar', name: 'Foo Bar',
               profile_image_url: nil, protected: false } }.to_json]
  end
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: '@foobar')
  assert r[:success]
  assert_equal 'foobar', r[:item][:username]
  assert_equal '123', r[:item][:id]
end

def test_lookup_user_strips_at_prefix
  # stub matches the path WITHOUT '@'
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/foobar}) do
    [200, { 'Content-Type' => 'application/json' },
     { data: { id: '1', username: 'foobar', name: 'Foo', profile_image_url: nil, protected: false } }.to_json]
  end
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: '@foobar')
  assert r[:success], "Expected success but got #{r.inspect}"
end
```

[VERIFIED: codebase inspection — `x_client_test.rb` uses this exact `Faraday::Adapter::Test::Stubs.new` + `Faraday.new { |f| f.adapter :test, stubs }` + `XClient.new(connection: conn)` pattern]

### Pattern 4: Error Symbol Test Cases

```ruby
def test_lookup_user_404_returns_not_found
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { [404, {}, ''] }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'gone')
  assert_not r[:success]
  assert_equal :not_found, r[:error]
end

def test_lookup_user_400_returns_not_found
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { [400, {}, ''] }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'bad_handle')
  assert_not r[:success]
  assert_equal :not_found, r[:error]
end

def test_lookup_user_403_returns_suspended
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { [403, {}, ''] }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'suspended_user')
  assert_not r[:success]
  assert_equal :suspended, r[:error]
end

def test_lookup_user_429_returns_rate_limited
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { [429, {}, ''] }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'anyone')
  assert_not r[:success]
  assert_equal :rate_limited, r[:error]
end
```

[VERIFIED: codebase inspection — matches error-case test structure in `test_fetch_following_non_200_returns_api_error`]

### Pattern 5: Network Error Test Cases (Faraday exception injection)

```ruby
def test_lookup_user_timeout_returns_api_error
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { raise Faraday::TimeoutError }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'anyone')
  assert_not r[:success]
  assert_equal :api_error, r[:error]
end

def test_lookup_user_connection_failed_returns_api_error
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/by/username/}) { raise Faraday::ConnectionFailed, 'refused' }
  conn = Faraday.new { |f| f.adapter :test, stubs }
  r = XClient.new(connection: conn).lookup_user_by_username(user: users(:twitter_user), username: 'anyone')
  assert_not r[:success]
  assert_equal :api_error, r[:error]
end
```

[ASSUMED — Faraday `:test` adapter supports raising exceptions from stub blocks; this matches the Faraday test adapter documented behavior but was not individually run against this Faraday version]

### Anti-Patterns to Avoid

- **Calling `connection_for(user)` directly in the new method:** `connection_for` does not check `@forced_connection`, so `XClient.new(connection: conn)` injection silently has no effect. Tests would fall through to real HTTP calls (blocked by WebMock) or require WebMock stubs instead of Faraday stubs.
- **Using `items:` as the return key:** All other methods return `items:` (plural) for collections. This method returns a single record; the key MUST be `item:` (singular) per CONTEXT.md.
- **Iterating `body['data']`:** The `/by/username/{username}` endpoint returns `data` as a single Hash object, not an Array. Do not `Array(body['data']).each` — extract `body['data']` directly and pass it to `normalize_following_row`.
- **Storing user-input username instead of API-returned username:** Pass `normalize_following_row(body['data'])` which reads `row['username']` from the API response. Never assign `params[:username]` or the local `handle` variable to the returned item.
- **Raising `Faraday::TimeoutError` vs `Faraday::Error`:** The existing rescue chain catches `TimeoutError, ConnectionFailed` first (more specific), then `Faraday::Error` (catch-all). Maintain this order; reversing it would shadow the specific errors.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Username field extraction from API hash | Custom field mapper | `normalize_following_row(row)` | Already maps `id`, `username`, `name`, `profile_image_url`, `protected` — exactly the five fields requested |
| Bearer token auth + token refresh | New auth logic | `following_connection(user)` → `connection_for(user)` → `refresh_if_expired!` + `bearer_faraday` | Fully implemented, tested, handles expiry window |
| JSON parse with error fallback | `begin/rescue JSON::ParserError` inline | `parse_json_safe(raw)` | Already returns `nil` on parse failure; used in all existing parsers |

**Key insight:** This phase adds ~25 lines by composing 4 existing private methods (`following_connection`, `parse_json_safe`, `normalize_following_row`, `parse_*_response` pattern). Writing any of these from scratch would be a regression in quality.

---

## Critical Research Finding: Connection Routing for Test Injection

**Question from phase brief:** "Are there any WebMock vs Faraday :test adapter considerations?"

**Answer (HIGH confidence):**

The two existing public methods use different connection paths:

| Method | Connection call | Test isolation method |
|--------|----------------|----------------------|
| `fetch_following` | `following_connection(user)` | Faraday `:test` adapter via `XClient.new(connection: conn)` |
| `fetch_recent_tweets` | `connection_for(user)` directly | WebMock `stub_request` with `XClient.new` (no injection) |

`following_connection` is the only private method that returns `@forced_connection` when the constructor injection `XClient.new(connection: conn)` is used. `connection_for` always builds a new Faraday instance regardless.

CONTEXT.md mandates the Faraday `:test` adapter injection pattern for Phase 105 tests. Therefore:

- `lookup_user_by_username` MUST call `following_connection(user)`, not `connection_for(user)` directly
- The name `following_connection` is a historical artefact; it is simply "the private method that supports test injection via `@forced_connection`"
- This approach fully satisfies both the "Bearer auth + token refresh" requirement (delegated to `connection_for` inside `following_connection`) and the test injection requirement

[VERIFIED: codebase inspection of `x_client.rb` lines 80-88 and `x_client_test.rb` lines 5-29]

---

## X API v2 Response Shape Reference

**Endpoint:** `GET /2/users/by/username/{username}?user.fields=id,name,username,profile_image_url,protected`

**Success (200):**
```json
{
  "data": {
    "id": "2244994945",
    "name": "X Developers",
    "username": "XDevelopers",
    "profile_image_url": "https://pbs.twimg.com/profile_images/...",
    "protected": false
  }
}
```
`data` is a single object, not an array. [CITED: docs.x.com/x-api/users/get-user-by-username — verified 2026-05-22 via WebFetch in prior v1.31 research]

**404 / 400:**
```json
{
  "errors": [{ "title": "Not Found Error", "type": "...", "detail": "..." }]
}
```
Both 404 and 400 should map to `:not_found`. The error body is not consumed by the parser. [CITED: prior research ARCHITECTURE.md — "X API returns 400 for unknown usernames in some API tiers"]

**403 (suspended account):**
HTTP 403 is returned when the looked-up account is suspended. The `parse_lookup_response` maps this to `:suspended`. [VERIFIED: codebase decision in STATE.md — "(v1.31) HTTP 403 from X API for suspended accounts maps to `:suspended` error symbol"]

**429:**
Standard rate limit response. Maps to `:rate_limited`. [CITED: prior research STACK.md]

---

## Common Pitfalls

### Pitfall 1: Calling `connection_for` instead of `following_connection`
**What goes wrong:** `XClient.new(connection: conn).lookup_user_by_username(...)` silently ignores the injected connection; real HTTP call is made (blocked by WebMock in tests).
**Why it happens:** `connection_for` looks like the right method (it names the auth chain), but it never checks `@forced_connection`.
**How to avoid:** Always call `following_connection(user)` in the new method. Read `x_client.rb` lines 80-88 before writing.
**Warning signs:** Test error "An HTTP request has been made that WebMock has not been told about" or similar NetConnectNotAllowed.

### Pitfall 2: Returning `items:` (plural) instead of `item:` (singular)
**What goes wrong:** Phase 106 controller reads `result[:item]`; if Phase 105 returns `result[:items]`, Phase 106 silently gets `nil` and calls `upsert_manual!(user, nil)`, raising `ArgumentError`.
**Why it happens:** Copy-paste from `fetch_following` which returns `items:`.
**How to avoid:** The return statement in the 200 branch must be `{ success: true, item: normalize_following_row(row) }` — singular `item`.
**Warning signs:** Controller `result[:item]` is nil despite a successful API call.

### Pitfall 3: Treating `body['data']` as Array
**What goes wrong:** `Array(body['data']).each` wraps a Hash in an Array — `normalize_following_row` receives `{...}` as expected, so tests pass, but the return value is wrong (an array instead of a single hash).
**Why it happens:** Copy-paste of the `fetch_following` loop which uses `Array(payload['data']).each`.
**How to avoid:** Extract `body['data']` directly: `row = body['data']`; guard `return :not_found unless row.is_a?(Hash)`.
**Warning signs:** `result[:item]` is an Array.

### Pitfall 4: Mapping 403 to `:api_error` instead of `:suspended`
**What goes wrong:** The controller in Phase 106 emits a generic "API error" flash for suspended accounts instead of a specific "this account is suspended" message.
**Why it happens:** `parse_following_response` has no `when 403` branch; copy-pasting it without adding 403 silently falls through to `else → :api_error`.
**How to avoid:** The `parse_lookup_response` case statement needs an explicit `when 403` before the `else`.
**Warning signs:** 403 test case asserts `:suspended` but gets `:api_error`.

### Pitfall 5: Error symbols `:timeout`/`:network` instead of `:api_error`
**What goes wrong:** CONTEXT.md and REQUIREMENTS.md both specify `Faraday::TimeoutError` / `Faraday::ConnectionFailed` → `:api_error`. The existing `fetch_following` method returns `:timeout` and `:network` for these. Copying the rescue chain from `fetch_following` would produce wrong symbols.
**Why it happens:** Phase 105 CONTEXT.md intentionally overrides the `fetch_following` error symbol choices for the network error bucket.
**How to avoid:** The rescue blocks must return `{ success: false, error: :api_error }` for both timeout and connection failed — NOT `:timeout` or `:network`.
**Warning signs:** Network error test case asserts `:api_error` but gets `:timeout`.

---

## Runtime State Inventory

Not applicable — Phase 105 is a pure service-layer addition (new method + new tests). No renaming, no schema changes, no stored state.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | Runtime | Yes | 3.4.9 | — |
| Rails | Runtime | Yes | 8.1.3 | — |
| faraday | XClient HTTP | Yes (Gemfile) | See Gemfile.lock | — |
| Minitest | Test suite | Yes (Rails default) | bundled with Rails | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 8.1.3 default) |
| Config file | none (uses `bin/rails test`) |
| Quick run command | `bin/rails test test/services/x_client_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| XSVC-01 | 200 success, strips `@`, returns `item:` with API username | unit | `bin/rails test test/services/x_client_test.rb` | Partial (file exists; new cases needed) |
| XSVC-01 | `@` strip actually changes URL path (handle without `@`) | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | 404 → `:not_found` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | 400 → `:not_found` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | 403 → `:suspended` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | 429 → `:rate_limited` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | TimeoutError → `:api_error` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |
| XSVC-02 | ConnectionFailed → `:api_error` | unit | `bin/rails test test/services/x_client_test.rb` | No — new case |

### Sampling Rate

- **Per task commit:** `bin/rails test test/services/x_client_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` (full tri-suite per CLAUDE.md)

### Wave 0 Gaps

None — `test/services/x_client_test.rb` already exists with the correct test infrastructure (Faraday stub pattern, `users(:twitter_user)` fixture). New test cases are appended; no new files or framework setup needed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `following_connection(user)` is the correct call site (not `connection_for`) to support `@forced_connection` injection | Connection Routing, Code Examples | Tests would require WebMock instead of Faraday `:test` stubs; test pattern would contradict CONTEXT.md |
| A2 | Faraday `:test` adapter supports raising exceptions (`Faraday::TimeoutError`) from stub blocks | Pattern 5 (network error tests) | Tests for timeout/ConnectionFailed would need a different approach |
| A3 | X API returns 403 (not 404) for suspended accounts | Pitfall 4 | The `:suspended` symbol test would need to stub a different status code |

---

## Open Questions (RESOLVED)

1. **`following_connection` naming vs. using `connection_for` directly**
   - What we know: `following_connection` was created for `fetch_following` and checks `@forced_connection`; `connection_for` builds real connections only
   - What's unclear: CONTEXT.md says "connection_for(user) helper" but the test injection pattern requires `following_connection`
   - Recommendation: Use `following_connection(user)` — this is the only interpretation consistent with both the stated test injection requirement and the live code. The CONTEXT.md description of the auth chain is accurate (following_connection delegates to connection_for), just imprecise about which private method the call site should use.

2. **Error symbols for Faraday network exceptions**
   - What we know: CONTEXT.md specifies `:api_error` for both `TimeoutError` and `ConnectionFailed`; existing `fetch_following` uses `:timeout` and `:network` for the same exceptions
   - What's unclear: Whether the divergence is intentional or a copy-paste oversight in CONTEXT.md
   - Recommendation: Follow CONTEXT.md literally (`:api_error` for both). Phase 106 controller will consume these symbols; keeping them consistent with CONTEXT.md is the safe choice.

---

## Sources

### Primary (HIGH confidence)

- Direct codebase inspection: `app/services/x_client.rb` — full implementation read
- Direct codebase inspection: `test/services/x_client_test.rb` — all 7 existing test cases read
- Direct codebase inspection: `test/fixtures/users.yml` — `twitter_user` fixture confirmed
- Direct codebase inspection: `test/support/webmock.rb` — WebMock `disable_net_connect!` confirmed
- CONTEXT.md: All locked decisions sourced from here
- STATE.md: HTTP 403 → `:suspended` decision confirmed

### Secondary (MEDIUM confidence)

- `.planning/research/STACK.md` (2026-05-22) — X API v2 endpoint URL, auth type, response shape from prior v1.31 milestone research
- `.planning/research/ARCHITECTURE.md` (2026-05-22) — `parse_lookup_response` pattern, `normalize_following_row` reuse
- `.planning/research/PITFALLS.md` (2026-05-22) — connection routing pitfall, error symbol pitfalls

### Tertiary (LOW confidence)

- X API v2 docs (docs.x.com/x-api/users/get-user-by-username) — referenced in prior research but not re-fetched in this session

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies confirmed via Gemfile and codebase inspection
- Architecture: HIGH — based on direct read of x_client.rb and existing test patterns
- Pitfalls: HIGH — connection routing pitfall confirmed by reading actual code; error symbol contract from CONTEXT.md

**Research date:** 2026-05-22
**Valid until:** 2026-06-22 (stable Ruby/Rails/Faraday stack; X API v2 endpoint is stable)
