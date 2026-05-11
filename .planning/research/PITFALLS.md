# Pitfalls Research — Mastodon API Integration

**Domain:** Live third-party API fetching in a server-rendered Rails app (Mastodon public REST API)
**Researched:** 2026-05-12
**Overall confidence:** HIGH (live API verified, existing codebase confirmed)

---

## Slow Page Load / API Timeouts

**Risk level:** CRITICAL

**What goes wrong:**
The existing `Feed` model calls `Daddy::HttpClient` with no timeout set. `Daddy::HttpClient` is a thin Faraday wrapper and Faraday's default timeout is no timeout — it will block the Puma thread indefinitely if the remote server hangs. The `MastodonAccount` model will follow the same pattern if copied from `Feed`. A single unresponsive Mastodon instance can hold a Puma worker for 30+ seconds, cascading to starvation when multiple gadgets are on the welcome page.

**Why it happens:**
The `Feed` pattern works passably for RSS feeds because the UI loads them via AJAX after page render (the welcome page renders a skeleton, then JavaScript fetches). Mastodon toots are also planned as live fetches — but if they are fetched during server-side render of the welcome page, all fetches are synchronous and serial.

**Evidence from codebase:**
`bookmarks_controller.rb` already has a working Faraday timeout pattern:
```ruby
f.options.timeout      = 5
f.options.open_timeout = 5
```
This pattern exists but is NOT used in `Daddy::HttpClient` or `Feed`. `MastodonAccount` must not use `Daddy::HttpClient` for live API calls; it should use direct Faraday with explicit timeouts.

**Two-request cost:**
The lookup-then-statuses flow makes TWO sequential HTTP calls per followed account: `GET /api/v1/accounts/lookup?acct=username` to resolve the numeric ID, then `GET /api/v1/accounts/:id/statuses`. With 5 followed accounts on the welcome page and a 5-second timeout each, worst-case blocking is 50 seconds (5 accounts × 2 calls × 5s timeout). This is the strongest argument for not fetching on the welcome page in the same request.

**Prevention:**
- Set `timeout: 5, open_timeout: 3` on Faraday explicitly in `MastodonClient` — do not use `Daddy::HttpClient` for Mastodon API calls.
- Rescue `Faraday::TimeoutError` and `Faraday::ConnectionFailed` at the model level, return empty results with a logged warning, matching the `Feed#feed` rescue pattern.
- Store the resolved numeric account ID in the `mastodon_accounts` table after first successful lookup; subsequent welcome page fetches only need the statuses call, halving the cost.
- Consider loading toots via AJAX after page render (matching the RSS feed gadget pattern) — this removes Mastodon latency from the critical page-load path entirely.

**Which phase:** Address in the `MastodonClient` service object phase (before welcome page integration). Do not defer timeout configuration to "polish."

---

## XSS from Toot HTML Content

**Risk level:** CRITICAL

**What goes wrong:**
Mastodon `status.content` is always raw HTML, not plain text. The actual API response contains markup like:
```
<p>So ready for day 2 at <span class="h-card" translate="no"><a href="..." class="u-url mention">@<span>blueridgeruby</span></a></span>!</p>
```
Rendering `status.content` with `raw()` or `html_safe` in an ERB template without sanitization is a stored XSS vector. Mastodon instances themselves are trusted, but the content they serve may include user-crafted payloads boosted from malicious accounts.

**Confirmed content structure (live API):**
- `<p>` blocks for paragraphs
- `<span class="h-card">` with nested `<a>` for @mentions
- `<a class="mention hashtag">` for #hashtags
- `<a>` for URLs (auto-linked)
- No `<script>` or `<style>` from well-behaved instances, but no guarantee

**For one-line previews, the right approach is strip_tags, not sanitize:**
A one-line preview showing the text content of a toot only needs plain text. Use Rails `strip_tags(content)` (ActionView helper, backed by Loofah) which removes all HTML and returns the inner text. This is simpler and safer than an allowlist sanitizer for this use case.

**Prevention:**
- In the view helper or model method that produces the one-line preview, call `ActionView::Base.full_sanitizer.sanitize(content)` or `strip_tags(content)` — never `raw()` or `html_safe` on toot content.
- If the show page ever renders full toot HTML (for a detail view), use `sanitize(content, tags: %w[p a span br], attributes: %w[href class])` with an explicit allowlist.
- Never pass `content.html_safe` directly to ERB. ERB auto-escapes non-`html_safe` strings; `html_safe` bypasses that.
- `nokogiri` is already in the Gemfile — it is the backing parser for Loofah/rails-html-sanitizer, so no new gem dependency is needed.

**Detection:** Add a test fixture toot whose `content` contains `<script>alert(1)</script>` and assert the rendered output does not contain `<script`.

**Which phase:** Address in the view/partial phase when toot content is first rendered. Do not leave `TODO: sanitize` comments; do it on first render.

---

## Rate Limiting

**Risk level:** MODERATE

**Confirmed rate limits (live API headers from ruby.social, 2026-05-12):**
```
x-ratelimit-limit: 300
x-ratelimit-remaining: 295
x-ratelimit-reset: 2026-05-11T15:15:00.953749Z
```
300 requests per 5-minute window per IP, unauthenticated. This is per-instance, not global. An app with 10 users each following 3 accounts on one instance would generate 6 API calls per page load (2 per account), meaning 60 calls per concurrent page load event — well within the limit for a single-tenant personal app.

**What goes wrong:**
- If multiple users follow accounts on the same instance and all load the welcome page simultaneously, the 300/5min limit can be hit. For a personal app with a few users this is unlikely but possible.
- If the 429 response is not handled, the Faraday client raises an error (or returns a non-200 body) and the rescue block needs to surface a meaningful degraded state.
- The `x-ratelimit-reset` header tells when the window resets — but since there is no caching layer, the app cannot pause and retry without blocking the request.

**Prevention:**
- Rescue HTTP 429 responses explicitly and return an empty toot list with a `:rate_limited` status, parallel to `Feed#status` returning `:internal_server_error`.
- Store the resolved numeric account ID in the DB (avoiding the lookup call on every page load) — this halves API call count from 2 to 1 per followed account.
- Log 429s at WARN level so patterns are visible.
- For a personal single-user app, rate limiting is not a practical problem — but the graceful degradation path (empty gadget, no error explosion) is still required for robustness.

**Which phase:** Rescue 429 in the `MastodonClient` service object. Store numeric ID in the DB migration phase.

---

## Profile URL Parsing Edge Cases

**Risk level:** HIGH

**Known URL format variations:**
```
https://ruby.social/@FastRuby          # canonical Mastodon profile URL
https://ruby.social/@FastRuby/         # trailing slash (broken in some Mastodon versions)
https://ruby.social/web/@FastRuby      # /web/ prefix — redirects 302 to canonical (confirmed)
https://ruby.social/users/FastRuby     # internal URI format (not intended for input)
https://mastodon.social/@user@other    # cross-instance acct handle in URL (rare)
@FastRuby@ruby.social                  # handle notation — NOT a URL, but users may paste this
FastRuby@ruby.social                   # handle without leading @ — also pasted by users
```

**Parsing the instance + username from the canonical URL:**
```
URI.parse("https://ruby.social/@FastRuby")
# host: "ruby.social", path: "/@FastRuby"
# username: path.delete_prefix("/@")  → "FastRuby"
```

**Edge cases to handle:**

1. **Trailing slash:** `/@FastRuby/` — strip trailing slash before extracting username. Mastodon itself has known issues with trailing slashes in verification (GitHub issue #20459, #9195).

2. **`/web/` prefix:** `https://ruby.social/web/@FastRuby` — redirects 302 to canonical. Either follow the redirect on save (Faraday `:follow_redirects` is available), or normalize by stripping `/web` from path on model validation.

3. **`/users/` URI format:** `https://ruby.social/users/FastRuby` — this is the ActivityPub actor URI, not the profile URL. Users may paste it. Normalize by substituting `users/` → `@` in the path or reject with a validation message.

4. **Handle notation pasted:** `@FastRuby@ruby.social` or `FastRuby@ruby.social` — not a URL. The model validation should detect the absence of `https://` and either reject with a clear error or auto-construct the URL.

5. **Non-Mastodon instances claiming Mastodon API compatibility:** Pleroma/Akkoma instances serve the same `/@username` URL format and the same `/api/v1/accounts/lookup` endpoint. Parsing is identical. Misskey does NOT support the Mastodon API — a Misskey instance URL will return 404 from the lookup endpoint. The error path handles this gracefully if implemented.

6. **Account does not exist on that instance:** The lookup endpoint returns `{"error": "Record not found"}` with HTTP 404. This must be caught during CRUD validation (on create/edit) to give the user an actionable error rather than a runtime failure on the welcome page.

**Recommended validation approach:**
- On model `before_save` or `validate`: parse the URL with `URI.parse`, require `https` scheme and `/@` prefix in path. Strip trailing slash. Normalize `/web/@username` paths. Reject handle notation with explicit error.
- On create (controller or service): make a live lookup call to confirm the account exists; store the returned numeric ID and canonical username. If lookup fails (404, network error), surface a validation error.

**Which phase:** URL parsing and normalization in the model validation phase. Live lookup confirmation in the CRUD controller phase. Separate from the welcome page rendering phase.

---

## Test Isolation

**Risk level:** HIGH

**Current state of the project:**
No HTTP stubbing library is present — no WebMock, no VCR, no Mocha. The existing `Feed` tests avoid making live HTTP calls by using the `with_feed_new` pattern: they monkey-patch `Feed.new` to return a fake object, bypassing `retrieve_feed` entirely. This works because `Feed#feed` is only called at render time (via AJAX), not during controller actions under test.

For `MastodonAccount`, the same approach can work but requires careful design:

**Option 1 — Service object injection (recommended):**
Extract a `MastodonClient` service object. Inject it into `MastodonAccount` or pass it as a parameter. In tests, inject a fake client that returns fixture JSON. No monkey-patching required.

```ruby
# Production
MastodonAccount.new(profile_url:, client: MastodonClient.new)

# Test
MastodonAccount.new(profile_url:, client: FakeMastodonClient.new(fixture_response))
```

**Option 2 — Faraday test adapter (no new gems):**
Faraday ships with a built-in `Faraday::Adapter::Test` that stubs HTTP requests without a network call. Since `Daddy::HttpClient` wraps Faraday, tests can swap the adapter:
```ruby
stubs = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.get('/api/v1/accounts/lookup') { [200, {}, account_json] }
end
```
This works for Minitest without adding any gems.

**Option 3 — WebMock (requires adding gem):**
`webmock` in `group :test` intercepts all Net::HTTP/Faraday calls globally with `stub_request`. Simpler test code but adds a dependency. Given the project's conservative gem philosophy, Option 1 or 2 is preferable.

**Cucumber / E2E isolation:**
Cucumber scenarios run against a live Rails server. Mastodon API calls made during welcome page render will attempt real network calls during E2E tests. This is the same problem as RSS feeds in Cucumber — the E2E tests for feeds appear to test UI structure (the gadget container exists), not live content. The Mastodon Cucumber scenarios should follow the same pattern: assert the gadget container is present and that the account title renders, not that specific toots appear.

**Test fixture data:**
Create `test/fixtures/mastodon_accounts.yml` following the pattern of `test/fixtures/feeds.yml`. The fixture can store a pre-resolved numeric ID to avoid the lookup call in tests that only test the statuses fetch path.

**Which phase:** Design the `MastodonClient` with dependency injection in mind from the first phase. Do not write tests that make live Mastodon calls — add a CI note to this effect.

---

## I18n Considerations

**Risk level:** LOW (confirmed non-issue for content, but UI chrome needs attention)

**Toot content language:**
Toot `content` is always in the author's language. This is by design and matches the existing pattern for RSS feed content, calendar event titles, and bookmark URLs — all of these are "user/external content" that the app explicitly does not translate (documented in PROJECT.md: "user content (bookmark/folder names, note bodies, Todo titles, feed/calendar external data) remains untranslated by design"). Mastodon toot content falls into the same category.

**What does need I18n:**
- UI chrome labels: "Mastodon" panel header, "No accounts" empty state, "Loading..." placeholder, error messages ("Could not fetch toots"), CRUD form labels, validation error messages.
- All of these must have `ja.yml` and `en.yml` keys with parity (enforced by the existing locale key parity tests).

**One subtle issue — `lang` attribute on toot content:**
Mastodon statuses include a `language` field (BCP 47 code, e.g. `"en"`, `"ja"`). If toot content is rendered in HTML (even stripped to plain text), the surrounding `<div>` or `<span>` should ideally carry `lang="en"` so the browser applies correct hyphenation and screen reader behavior. This is a minor accessibility concern, not a security or functionality concern. It can be addressed in the view layer as a one-line addition.

**Locale parity gate:**
The existing test that enforces `ja.yml`/`en.yml` key parity will catch any missing Mastodon-specific keys added to one file but not the other. This is a benefit of the existing test architecture — no special action required beyond following the existing pattern.

**Which phase:** Add locale keys in the same phase as each UI surface that uses them. Do not add all keys upfront and leave them unused.

---

## API Version Compatibility

**Risk level:** MODERATE

**Mastodon API version landscape:**

The two endpoints used (`GET /api/v1/accounts/lookup` and `GET /api/v1/accounts/:id/statuses`) have the following version history:
- `/api/v1/accounts/lookup`: Added in Mastodon 3.4.0 (released 2021-11). Instances running 3.3.x or older will return 404 on this endpoint.
- `/api/v1/accounts/:id/statuses`: Available since Mastodon 2.7.0, unauthenticated use allowed since 2.7.0. Extremely stable.

**Instance software compatibility:**
- **Mastodon 3.4.0+:** Both endpoints work. Lookup requires no auth for public accounts (confirmed live, despite documentation showing OAuth as "required" — the docs appear to refer to looking up private accounts or server-side use).
- **Pleroma/Akkoma:** Compatible with Mastodon 2.7.2 API. The `/api/v1/accounts/lookup` endpoint may not be present (added in Mastodon 3.4.0 and not listed in Pleroma's compatibility notes). An alternative approach: use `/api/v2/search?q=username&type=accounts` which is more broadly compatible, or fall back to WebFinger resolution.
- **Misskey/Calckey:** Does NOT implement the Mastodon REST API. A Misskey instance URL will fail immediately at lookup. The 404 error path handles this.

**Practical recommendation:**
For the scope of this milestone (following public Mastodon accounts by profile URL), targeting Mastodon 3.4.0+ is sufficient — the vast majority of active instances run current versions. Document the minimum version requirement. If a lookup fails with 404, show the user a clear error at CRUD time ("Account not found. Check the URL or ensure the instance is reachable.") rather than a generic server error.

**`/api/v1/instance` version check:**
It is technically possible to call `/api/v1/instance` to check the Mastodon version before using version-gated endpoints. This adds a third API call per account and is not worth the complexity for this milestone — rely on the 404 error path instead.

**Response field stability:**
The fields used (`id`, `username`, `content`, `url`, `created_at`, `visibility`) are present in all Mastodon versions since 2.x. Fields like `language`, `spoiler_text`, and `media_attachments` are also stable. Avoid relying on fields marked as "nullable" without nil guards.

**Which phase:** Document the Mastodon 3.4.0+ requirement in the CRUD form help text. Handle 404 from lookup gracefully in `MastodonClient`. No version-check API call needed.

---

## Phase-Specific Warnings Summary

| Phase Topic | Pitfall | Mitigation |
|-------------|---------|------------|
| MastodonClient service object | No timeout → thread starvation | Use Faraday directly with 5s/3s timeout; rescue TimeoutError |
| DB migration | Missing numeric ID column | Store `mastodon_account_id` (string, Mastodon IDs are 64-bit, use string not integer) |
| Profile URL model validation | Users paste handle notation or /web/ URLs | Normalize on validation; validate URL format; live lookup on create |
| Toot content rendering | XSS via raw HTML content | Always strip_tags before display; never html_safe toot content |
| Welcome page gadget | Synchronous API call on page render | Load via AJAX after render (matching RSS pattern) or strictly enforce timeout |
| Test suite | Live API calls in Minitest/Cucumber | Use Faraday test adapter or service object injection; never hit live instances in CI |
| Locale keys | Key added to ja.yml without en.yml | Follow existing pattern; parity test will catch it |
| CRUD error handling | Lookup 404 shows unhandled exception | Catch at controller level; display actionable validation error |

---

## Sources

- Mastodon accounts API: https://docs.joinmastodon.org/methods/accounts/
- Mastodon rate limits: https://docs.joinmastodon.org/api/rate-limits/
- Mastodon client guide (public data): https://docs.joinmastodon.org/client/public/
- Pleroma API differences: https://docs-develop.pleroma.social/backend/development/API/differences_in_mastoapi_responses/
- Akkoma API differences: https://docs.akkoma.dev/stable/development/API/differences_in_mastoapi_responses/
- Mastodon trailing slash issue: https://github.com/mastodon/mastodon/issues/20459
- Faraday test adapter: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Test
- rails-html-sanitizer: https://github.com/rails/rails-html-sanitizer
- Live API verification: ruby.social /api/v1/accounts/lookup (2026-05-12)
