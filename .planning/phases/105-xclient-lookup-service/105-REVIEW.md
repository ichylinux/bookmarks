---
phase: 105-xclient-lookup-service
reviewed: 2026-05-22T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - app/services/x_client.rb
  - test/services/x_client_test.rb
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 105: Code Review Report

**Reviewed:** 2026-05-22
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed `XClient#lookup_user_by_username` (new method) and supporting changes in `app/services/x_client.rb`, plus the accompanying test suite. The core logic is sound and follows the existing patterns in the file. Four issues stand out: one critical security defect (username interpolated into a URL path without format validation), one test that asserts nothing meaningful about the code under test, and two inconsistencies between `lookup_user_by_username` and the existing methods that will confuse callers.

---

## Critical Issues

### CR-01: Username interpolated into URL path without format validation

**File:** `app/services/x_client.rb:85`
**Issue:** `handle` is interpolated directly into the URL path with no validation that it conforms to the X username format (`[A-Za-z0-9_]{1,15}`). A caller passing a crafted value such as `"validname?injected=param"`, `"name/../../../other"`, or `"name/extra/segments"` would alter the URL sent to the X API. The only sanitisation applied is stripping a leading `@` character and a blank check — neither prevents path traversal characters or query-string injection.

While there are no current callers of `lookup_user_by_username` in the application code (the method is unused as of this phase), this is the exact kind of boundary that future controllers will pass user-supplied input through. Shipping without validation establishes an unsafe pattern.

**Fix:** Add a format guard before the HTTP call:

```ruby
def lookup_user_by_username(user:, username:)
  handle = username.to_s.sub(/\A@/, '').presence
  return { success: false, error: :not_found } if handle.blank?
  # X usernames: 1–15 alphanumeric or underscore characters only
  return { success: false, error: :not_found } unless handle.match?(/\A\w{1,15}\z/)

  res = following_connection(user).get("/2/users/by/username/#{handle}") do |req|
    req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
  end
  parse_lookup_response(res)
  # ... rescue block unchanged
end
```

---

## Warnings

### WR-01: `test_bearer_header_used_when_oauth2_token_present` tests its own setup, not XClient

**File:** `test/services/x_client_test.rb:74-95`
**Issue:** The test builds its own `Faraday` connection, manually sets `Authorization: Bearer my-bearer-token` on that connection, then calls `conn.get('/2/ping')` directly — bypassing `XClient` entirely. The assertion inside the stub fires and passes, but it is asserting on a header that the test itself injected. The test proves nothing about whether `XClient` uses Bearer auth; it would pass even if `bearer_faraday` were completely rewritten to use a different auth scheme.

The adjacent test `test_fetch_following_uses_bearer_when_oauth2_token_present` (lines 97–121) correctly exercises `XClient` and is the actual meaningful coverage. The redundant test should either be removed or rewritten to route through `XClient`.

**Fix:** Replace with a version that goes through `XClient`:

```ruby
def test_bearer_header_sent_by_xclient
  stubs = Faraday::Adapter::Test::Stubs.new
  stubs.get(%r{/2/users/\w+/following}) do |env|
    assert_match(/\ABearer my-bearer-token\z/, env[:request_headers]['Authorization'].to_s)
    [200, { 'Content-Type' => 'application/json' }, { data: [], meta: {} }.to_json]
  end
  u = users(:twitter_user)
  u.update_columns(oauth2_token: 'my-bearer-token', oauth2_token_expires_at: 1.hour.from_now)
  conn = Faraday.new { |f| f.headers['Authorization'] = "Bearer #{u.oauth2_token}"; f.adapter :test, stubs }
  XClient.new(connection: conn).fetch_following(user: u)
ensure
  users(:twitter_user).update_columns(oauth2_token: nil, oauth2_token_expires_at: nil)
end
```

### WR-02: `parse_lookup_response` silently maps HTTP 401 to `:api_error` instead of `:unauthorized`

**File:** `app/services/x_client.rb:195-214`
**Issue:** `parse_following_response` and `parse_tweets_response` both explicitly handle `401` and return `{ success: false, error: :unauthorized }`. `parse_lookup_response` has no `when 401` branch, so an expired or revoked token causes `lookup_user_by_username` to return `:api_error` instead of `:unauthorized`. Any caller that inspects the error symbol to decide whether to re-authenticate will silently fail to trigger a re-auth flow for `lookup_user_by_username`.

**Fix:** Add a `when 401` branch consistent with the sibling parsers:

```ruby
def parse_lookup_response(res)
  case res.status
  when 200
    # ... existing
  when 400, 404
    { success: false, error: :not_found }
  when 401
    { success: false, error: :unauthorized }
  when 403
    { success: false, error: :suspended }
  when 429
    { success: false, error: :rate_limited }
  else
    { success: false, error: :api_error }
  end
end
```

### WR-03: `lookup_user_by_username` rescue maps network errors to `:api_error`, inconsistent with other public methods

**File:** `app/services/x_client.rb:90-93`
**Issue:** `fetch_following` and `fetch_recent_tweets` distinguish `:timeout` (for `Faraday::TimeoutError` / `Faraday::ConnectionFailed`) from `:network` (for generic `Faraday::Error`). `lookup_user_by_username` collapses both into `:api_error`, and the method's own doc comment does not list `:timeout` or `:network` as possible error values. This means callers have no way to surface "the request timed out — retry?" versus "the API returned an unexpected status". Callers that use a common error-message lookup (e.g., `t("errors.x_client.#{result[:error]}")`) may also produce the wrong message when a network timeout occurs.

**Fix:** Mirror the rescue structure of `fetch_following`:

```ruby
rescue Faraday::TimeoutError, Faraday::ConnectionFailed
  { success: false, error: :timeout }
rescue Faraday::Error
  { success: false, error: :network }
```

Update the method comment to list `:timeout` and `:network` as possible error symbols, or accept that `:api_error` is intentionally a catch-all and document that explicitly.

---

## Info

### IN-01: `per_page` calculation contains a redundant `Array#max` call

**File:** `app/services/x_client.rb:17`
**Issue:** `[max_results.to_i, 5].max.clamp(5, 100)` — the `[x, 5].max` is fully subsumed by `.clamp(5, 100)`. `Integer#clamp` already enforces the lower bound of 5, making the array form unnecessary.

**Fix:**
```ruby
per_page = max_results.to_i.clamp(5, 100)
```

### IN-02: No test coverage for entity expansion in `expand_tco_entities`

**File:** `test/services/x_client_test.rb:31-41`
**Issue:** `test_fetch_tweets_expands_tco_and_truncates` passes a 200-char plain string with no `entities` field. It verifies that `truncate` works, but the method under test is called `expands_tco`. There is no test that passes a tweet with a `urls` entity block and verifies that the `t.co` short URL is replaced with `display_url` in the output. The expansion logic (sorting by descending start index, slicing `out[start...nxt]`) has non-trivial correctness requirements and is entirely untested.

**Fix:** Add a targeted unit test:

```ruby
def test_expand_tco_replaces_url_in_text
  tweet = {
    'id' => '1',
    'text' => 'Check this out https://t.co/abc123 cool',
    'entities' => { 'urls' => [{ 'start' => 17, 'end' => 34, 'display_url' => 'example.com/page' }] }
  }
  # stub connection as usual ...
  # assert result[:items].first[:text].include?('example.com/page')
  # assert_not result[:items].first[:text].include?('t.co')
end
```

---

_Reviewed: 2026-05-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
