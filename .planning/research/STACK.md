# Stack Research — v1.31 X Account Manual Add (Non-Following)

**Project:** Bookmarks v1.31
**Researched:** 2026-05-22
**Confidence:** HIGH (endpoint URL and auth type verified against official X API v2 docs;
rate limits verified against independent source; all conclusions grounded in direct reads
of existing `app/services/x_client.rb` and `db/schema.rb`)

---

## Summary

The v1.31 feature requires one new X API v2 call: user lookup by username/handle.

**Verdict: zero new gems. One new method on `XClient`. One new `origin` column on
`x_accounts`. The existing OAuth2 Bearer Token auth flow already covers this endpoint.**

The existing `XClient` already authenticates with a user-context OAuth2 Bearer token
(`user.oauth2_token` in `bearer_faraday`) and already parses the same X API response
structures. The new method follows the identical pattern as `fetch_following` and
`fetch_recent_tweets`.

---

## X API v2 Endpoint: User Lookup by Username

### Endpoint

```
GET https://api.x.com/2/users/by/username/{username}
```

**Source:** [X docs — Get User by Username](https://docs.x.com/x-api/users/get-user-by-username)
(verified via WebFetch on 2026-05-22; also confirmed in quickstart guide curl example)

### Path Parameter

| Parameter  | Type   | Required | Constraint |
|------------|--------|----------|------------|
| `username` | string | YES      | Pattern `^[A-Za-z0-9_]{1,15}$` — no leading `@` |

Strip the `@` prefix before calling. The API rejects handles that include it.

### Key Optional Query Parameter

```
user.fields=id,name,username,profile_image_url,protected
```

These five fields are exactly what `fetch_following` already requests and what
`x_accounts` stores. No new fields needed; the existing normalization logic
(`normalize_following_row`) is directly reusable.

Other available fields not needed for this feature: `description`, `created_at`,
`public_metrics`, `verified`, `location`, etc.

### Authentication

**App-only OAuth2 Bearer Token (`Bearer <token>`) is sufficient.**

The official quickstart guide demonstrates this endpoint with:
```bash
curl "https://api.x.com/2/users/by/username/XDevelopers?user.fields=..." \
  -H "Authorization: Bearer $BEARER_TOKEN"
```

The documentation lists `BearerToken` and `OAuth2UserToken` as both supported.
Crucially, the existing `XClient` already uses the user's `oauth2_token` (OAuth2
User Context token, not an app-only static bearer token). This is the correct credential
and requires no change to authentication infrastructure.

**The user's `oauth2_token` stored on `users.oauth2_token` works for this endpoint.**
`XClient#bearer_faraday` already injects it as `Authorization: Bearer #{user.oauth2_token}`.
The new `fetch_user_by_username` method calls `connection_for(user)` identically to
`fetch_recent_tweets`.

No app-only static bearer token is needed. No new OAuth scope is needed. The existing
`users.email` + `tweet.read` + `users.read` scopes from the v1.27 OAuth2 flow already
grant read access to public user profiles.

### Rate Limits

**900 requests per 15-minute window** — consistent across Free, Basic, and Pro tiers.

Source: [9meters.com X API rate limits reference](https://9meters.com/entertainment/social-media/x-api-rate-limits-formerly-twitter)
(MEDIUM confidence — independent source, not direct from X docs portal which requires
authentication to view rate limit tables)

At this app's scale (personal app, single user triggering manual lookups), rate limiting
is not a practical concern. The `:rate_limited` error symbol is already in the `XClient`
error contract and handled in the existing UI — no new error handling path needed.

### Response Body (success)

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

The `data` key is a single object (not an array), unlike the `fetch_following` response
where `data` is an array. The field names are identical.

### Error Responses

| HTTP Status | Meaning | Maps to XClient symbol |
|-------------|---------|------------------------|
| 404 | Username not found / account deactivated | `:not_found` |
| 401 | Token expired or revoked | `:unauthorized` |
| 429 | Rate limit exceeded | `:rate_limited` |
| other 4xx/5xx | API error | `:api_error` |

All four symbols already exist in the XClient error contract and have locale strings
under `errors.x_client.*` in `config/locales/ja.yml` and `en.yml`.

---

## New Code Required

### 1. `XClient#fetch_user_by_username(user:, username:)` — New method

Add to `app/services/x_client.rb`. Pattern is identical to `fetch_recent_tweets`:

```ruby
# Returns { success: true, item: { id:, username:, name:, profile_image_url:, protected: } }
# or      { success: false, error: :not_found | :unauthorized | :rate_limited | :api_error }
def fetch_user_by_username(user:, username:)
  handle = username.to_s.sub(/\A@/, '').presence
  return { success: false, error: :not_found } if handle.blank?

  res = connection_for(user).get("/2/users/by/username/#{handle}") do |req|
    req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
  end

  parse_user_lookup_response(res)
rescue Faraday::TimeoutError, Faraday::ConnectionFailed
  { success: false, error: :timeout }
rescue Faraday::Error
  { success: false, error: :network }
rescue JSON::ParserError
  { success: false, error: :parse_error }
end
```

The private `parse_user_lookup_response` parses `body['data']` as a single Hash (not
Array) and calls `normalize_following_row` — the existing normalization method is fully
compatible with the single-user response structure.

`connection_for(user)` already handles token refresh via `refresh_if_expired!`. No
changes needed there.

### 2. `x_accounts.origin` column — New migration

The PROJECT.md spec requires "a flag to distinguish manually-added vs follow-synced
origin". The simplest correct design:

```ruby
# Migration
add_column :x_accounts, :origin, :string, null: false, default: 'following'
```

| Value | Meaning |
|-------|---------|
| `'following'` | Added via the existing refresh-from-following flow |
| `'manual'`    | Added via the new handle-lookup form |

A string column with an inclusion validation on the model (`%w[following manual]`) is
preferable to a boolean (`manually_added`) because it is self-documenting and extensible
(e.g., a future `'import'` origin can be added without a schema change). Default is
`'following'` so all existing rows get the correct value without a data migration.

**The `origin` column is stored but does not affect the selection, display, or tweet
fetch logic.** Both origins go through the same `selected` flag gate, the same
`display_count` cap, and the same `Portal#get_gadgets` path. No conditional branching
needed anywhere except the controller action that creates the manually-added row.

### 3. `XAccountsController` — New `add_by_handle` action

New `POST /x_accounts/add_by_handle` route + action. Controller flow:

1. Strip `@` from params, reject blank/invalid pattern
2. Call `XClient.new.fetch_user_by_username(user: current_user, username: handle)`
3. On `:not_found` — flash error, redirect back
4. On success — upsert into `x_accounts` with `origin: 'manual'` using existing
   `XAccount.upsert_from_api_row` or equivalent; handle duplicate (already in table)
   gracefully (flash info, do not error)
5. Record in `x_api_calls` via existing `record_x_api_call` controller helper

This action is minimal: it shares all infrastructure with the existing `refresh` action
(token gate, error symbols, API call recording, upsert logic).

---

## Recommended Stack (No New Gems)

### Core Technologies

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| Rails 8.1 | Already locked | New migration, controller action, routes | Built-in ActiveRecord migration + string column; no gem needed |
| `faraday` | Already locked | HTTP client for `GET /2/users/by/username/:username` | `XClient` already uses Faraday; new method is 20 lines following the existing pattern |
| OAuth2 Bearer Token | User's `oauth2_token` | Auth for new endpoint | Confirmed supported by official docs quickstart; user token already in use for `fetch_following` and `fetch_recent_tweets`; no new OAuth scopes required |
| WebMock + Faraday `:test` | Already locked | Test stubs for new method | Consistent with v1.19 migration to WebMock; `stub_request(:get, /users\/by\/username/)` pattern |

### Libraries Evaluated and Rejected

| Library | Verdict | Reason |
|---------|---------|--------|
| `twitter` gem (v7+) | Reject | Heavy Ruby gem wrapping the X API. Already rejected in v1.18; `XClient` Faraday service gives full control, is already working, and avoids gem dependency on X's SDK which changes with API pricing changes. |
| `x_ruby` (official SDK) | Reject | Official Ruby SDK from X platform. Adds a gem dependency that tracks X API SDK versioning. `XClient` with Faraday is already proven, type-compatible with the existing test infrastructure (Faraday `:test` adapter), and the new endpoint is one 20-line method. |
| App-only static Bearer Token (separate from user token) | Reject | Would require storing a second credential type. The user's OAuth2 token (already in `users.oauth2_token`) is supported by this endpoint per official docs. No second credential type needed. |
| Boolean `manually_added` column | Reject | String `origin` column with inclusion validation is self-documenting and extensible. The boolean approach requires a second migration if a third origin is ever added. |

---

## Integration Map: Existing Code Touch Points

| File | Change Required | Nature |
|------|----------------|--------|
| `app/services/x_client.rb` | Add `fetch_user_by_username` public method + `parse_user_lookup_response` private method | Modify — ~25 lines |
| `db/migrate/YYYYMMDD_add_origin_to_x_accounts.rb` | `add_column :x_accounts, :origin, :string, null: false, default: 'following'` | New file |
| `app/models/x_account.rb` | Add `validates :origin, inclusion: { in: %w[following manual] }` | Modify — 1 line |
| `app/controllers/x_accounts_controller.rb` | Add `add_by_handle` action; add route | Modify |
| `config/routes.rb` | `post 'x_accounts/add_by_handle', to: 'x_accounts#add_by_handle'` | Modify |
| `app/views/x_accounts/index.html.erb` | Add handle input form | Modify |
| `config/locales/ja.yml` | New flash/error keys for handle lookup | Modify |
| `config/locales/en.yml` | Matching keys for parity | Modify |
| `test/services/x_client_test.rb` | Tests for `fetch_user_by_username` using Faraday `:test` adapter | Modify |
| `test/controllers/x_accounts_controller_test.rb` | Tests for `add_by_handle` action using WebMock stubs | Modify |

**No changes required to:**
- `app/services/x_client.rb` authentication infrastructure — `connection_for(user)`,
  `bearer_faraday`, `refresh_if_expired!` are unchanged
- `XAccount` upsert logic — the existing diff-upsert patterns from `refresh` are reusable
  with an `origin: 'manual'` override
- `XApiCall.record!` instrumentation — the existing `record_x_api_call` controller helper
  works without modification

---

## WebMock Stub Pattern for Tests

```ruby
# In service tests (Faraday :test adapter — matches existing pattern in x_client_test.rb):
stubs = Faraday::Adapter::Test::Stubs.new
stubs.get('/2/users/by/username/foobar') do
  [200, { 'Content-Type' => 'application/json' },
   '{"data":{"id":"123","username":"foobar","name":"Foo Bar","profile_image_url":null,"protected":false}}']
end

# In controller tests (WebMock — matches existing pattern):
stub_request(:get, %r{api\.x\.com/2/users/by/username/})
  .to_return(status: 200, body: '{"data":{"id":"123","username":"foobar",...}}',
             headers: { 'Content-Type' => 'application/json' })
```

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Endpoint URL `GET /2/users/by/username/{username}` | HIGH | Verified via official docs WebFetch (docs.x.com) + quickstart curl example |
| App-only / user Bearer Token both work | HIGH | Official quickstart demonstrates Bearer token; docs list BearerToken + OAuth2UserToken as supported auth methods |
| `user.oauth2_token` sufficient, no new OAuth scopes | HIGH | Same token already used for `fetch_following` (requires `users.read`) and tweets (requires `tweet.read`); user profile read is a subset of `users.read` |
| Response shape `data` as single Hash (not array) | HIGH | Official docs show single `data` object for `/by/username/{username}` vs array for `/by` bulk endpoint |
| Rate limit 900/15-min | MEDIUM | Reported by independent source (9meters.com); not directly verifiable from X docs portal without paid account; conservative number even if wrong for this app's scale |
| `origin` string column design | HIGH | Derived from codebase analysis; direct read of schema and PROJECT.md spec; no external verification needed |
| Zero new gems required | HIGH | New method follows existing Faraday + `XClient` pattern exactly; confirmed 20-line addition |

---

## What NOT to Add

| Avoid | Why |
|-------|-----|
| New gem for X API (twitter, x_ruby) | `XClient` Faraday service is already proven; new endpoint is one method |
| App-level static Bearer Token credential | User's OAuth2 token works; adding a second credential type complicates auth layer without benefit |
| Boolean `manually_added` column | String `origin` with inclusion validation is more readable and extensible |
| New Faraday middleware or auth adapter | Bearer injection is already in `bearer_faraday`; reuse unchanged |
| Separate service class (e.g. `XUserLookupClient`) | Unnecessary split; `XClient` encapsulates all X API v2 calls; adding one method stays consistent |
| Protected-account check on add path | Protected accounts are public profile data (the `protected` field is returned); the existing `protected_acknowledged` UI flow on `x_accounts` already handles this — reuse it |

---

*Stack research for: v1.31 X Account Manual Add (Non-Following)*
*Researched: 2026-05-22*
