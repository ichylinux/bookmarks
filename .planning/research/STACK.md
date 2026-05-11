# Stack Research — Mastodon API Integration

**Project:** Bookmarks v1.16
**Researched:** 2026-05-12
**Confidence:** HIGH (all findings verified against Gemfile.lock and live source code)

---

## Summary

The Mastodon API integration requires **zero new gems**. Faraday 1.10.5 is already locked and actively used in `BookmarksController#fetch_title` for outbound HTTP with redirect following. Nokogiri 1.19.3 is already locked and used in the same controller for HTML parsing. Rails ships `JSON.parse` / `ActiveSupport::JSON` as standard. The only addition needed is a new service class (`MastodonClient`) that wires these existing capabilities together for JSON REST calls. Feedjira is irrelevant to this feature.

---

## HTTP Client

**Verdict: Use Faraday directly. No new gem needed.**

`Daddy::HttpClient` is a thin Faraday wrapper designed for XML/HTML body-returning endpoints. Its `get` method returns `response.body` (a string) and has no mechanism to inspect status codes, set `Accept: application/json`, or handle JSON-specific error paths — all of which are needed for the Mastodon REST API.

Faraday 1.10.5 is already locked in `Gemfile.lock` and is used directly in `BookmarksController#fetch_title` (line 66) with timeout configuration and redirect following. That precedent confirms Faraday is the project's chosen HTTP abstraction for outbound calls.

For Mastodon:
- Two sequential GETs are needed: `GET /api/v1/accounts/lookup?acct=<username>` then `GET /api/v1/accounts/<id>/statuses?limit=N`
- Both return JSON; setting `Accept: application/json` explicitly is defensive but good practice
- A short timeout (5s) prevents welcome-page hangs
- No authentication, no cookies, no redirects expected

The correct pattern, consistent with existing usage in `BookmarksController`:

```ruby
conn = Faraday.new(url: "https://#{instance_host}") do |f|
  f.options.timeout      = 5
  f.options.open_timeout = 5
  f.headers['Accept']   = 'application/json'
end
response = conn.get('/api/v1/accounts/lookup', acct: username)
```

**Do not use `Daddy::HttpClient`** for this feature — it hides status codes behind a body-string return value, making HTTP error handling awkward for a JSON API. It suits XML feed fetching (where the caller only needs the body) but not REST calls where non-200 responses must be distinguished from success.

**Do not add HTTParty** — it appears in `Gemfile.lock` (0.24.2) as a transitive dependency but is not used anywhere in app code and would be redundant alongside Faraday.

---

## JSON Parsing

**Verdict: Use `JSON.parse` (Ruby stdlib). No gem needed.**

Rails includes ActiveSupport, which provides `ActiveSupport::JSON.decode` as a thin wrapper around Ruby's stdlib `JSON.parse`. Both are available without any gem addition. The Mastodon API returns well-formed JSON; no schema validation or streaming is needed.

Use `JSON.parse(response.body, symbolize_names: false)` and access keys as strings (`data['id']`, `status['content']`). This is idiomatic Rails and matches what `ActiveSupport::JSON.decode` does internally.

`MultiJson` (the adapter-switching layer) is pulled in transitively via Rails but is overkill — it exists for adapter portability across different JSON backends, which this feature does not need.

---

## HTML Stripping

**Verdict: Use Rails `strip_tags`. Nokogiri already locked — no new gem needed.**

Mastodon statuses return the `content` field as an HTML string, for example:

```html
<p>Hello <a href="...">world</a> <span class="h-card">@user</span></p>
```

A one-line toot preview requires stripping all tags to plain text.

Two options, both already available:

| Approach | Available | Notes |
|----------|-----------|-------|
| `ActionView::Helpers::SanitizeHelper#strip_tags` | Rails built-in | Idiomatic; handles nil, empty string; usable in views directly |
| `Nokogiri::HTML.parse(html).text` | Nokogiri 1.19.3 locked | Lower-level; used in `BookmarksController` for title extraction |

**Recommendation: `strip_tags` via Rails helper.** It is the idiomatic approach for view-adjacent text cleaning, handles nil/empty cleanly, and is available in controllers and views without extra includes. In a service class outside ActionView context, call `ActionController::Base.helpers.strip_tags(html)` or include `ActionView::Helpers::SanitizeHelper`.

Nokogiri 1.19.3 (`force_ruby_platform: true`) is already locked — no gem change either way.

---

## Feedjira

**Verdict: Irrelevant. Do not extend or involve Feedjira.**

Feedjira parses RSS/Atom XML. The Mastodon REST API returns JSON. These are entirely different formats and concerns. The existing `Feed` model and its `Daddy::HttpClient` + Feedjira pipeline should not be touched. The new `MastodonAccount` feature is a parallel, independent data source type.

---

## What NOT to Add

| Library | Reason to exclude |
|---------|------------------|
| `httparty` | In lockfile as transitive dep but unused in app; redundant alongside Faraday |
| `mastodon-api` gem | Designed for authenticated OAuth clients managing accounts; overkill for unauthenticated public read-only status fetching |
| `faraday_middleware` JSON auto-parse | Already in Gemfile but adds implicit magic; explicit `JSON.parse` is clearer and easier to stub in tests |
| Any new JS library | Welcome page gadget follows the existing RSS feed collapsible-panel pattern (server-rendered HTML); no new JS deps needed per PROJECT.md constraint |
| `sanitize` gem | Rails `strip_tags` + Nokogiri already handle the HTML-stripping requirement |

---

## Recommendation

**Use Faraday (already locked, v1.10.5) + `JSON.parse` (stdlib) + `strip_tags` (Rails) in a new `MastodonClient` service class. Add zero new gems.**

Implementation approach:

1. **`app/services/mastodon_client.rb`** — plain Ruby class, initialized with `instance_host` + `username`. Two public methods: `lookup_account` (returns account hash including `id`) and `fetch_statuses(account_id, limit:)` (returns array of status hashes). Uses Faraday directly with 5s timeout. Raises a descriptive error on non-2xx.

2. **`MastodonAccount` model** — parses profile URL on save to extract `instance_host` + `username`. Exposes a `statuses(limit: display_count)` method that delegates to `MastodonClient`.

3. **View partial** — calls `strip_tags(status['content'])` inline or via a helper to produce one-line plain-text preview. Standard ERB, no new JS.

This approach is consistent with every existing pattern in the codebase:
- Faraday usage matches `BookmarksController#fetch_title` exactly
- `strip_tags` / Nokogiri matches the same controller's title-extraction pattern
- Service-class encapsulation of external API calls keeps the model thin and the client testable in isolation
- No Gemfile changes means no Bundler lock churn and no deployment risk
