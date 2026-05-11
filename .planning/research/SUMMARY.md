# Research Summary — v1.16 Mastodon Account Following

**Project:** Bookmarks v1.16
**Domain:** Read-only Mastodon public API gadget in a personal Rails app
**Researched:** 2026-05-12
**Confidence:** HIGH

## Executive Summary

v1.16 adds the ability to register Mastodon accounts by profile URL and display their recent public toots as collapsible gadgets on the welcome page. This is a read-only, unauthenticated integration against the Mastodon public REST API — no OAuth, no write operations. The correct architecture mirrors the existing RSS feed gadget exactly: a `MastodonAccount` model per-user record, a `MastodonClient` service class for HTTP calls, a CRUD management screen, and a welcome page gadget that loads toot content asynchronously via jQuery `$.get` after page render. The portal column layout system already supports this pattern; one loop addition to `Portal#get_gadgets` is all that is needed to wire the gadget in.

The recommended implementation requires zero new gems. Faraday 1.10.5 (already locked) handles outbound HTTP with explicit 5s/3s timeouts, `JSON.parse` (stdlib) handles API responses, and Rails `strip_tags` handles toot HTML-to-text conversion. The two-step API flow — `GET /api/v1/accounts/lookup?acct=username` to resolve a numeric account ID, then `GET /api/v1/accounts/:id/statuses` to fetch toots — is the only supported public path on Mastodon 3.4.0+.

The two critical risks are thread starvation from API timeouts and XSS from raw toot HTML. Both have clear mitigations: explicit Faraday timeouts in `MastodonClient` (never use `Daddy::HttpClient` here), AJAX loading for the gadget (not synchronous server-side fetch), and `strip_tags` on every toot content field before rendering. These must be addressed in the service object phase, not deferred to polish.

---

## Stack Additions

No new gems are needed. The entire implementation uses libraries already locked in `Gemfile.lock`.

- **Faraday 1.10.5** (already locked) — outbound HTTP to Mastodon REST API. Use directly with `timeout: 5, open_timeout: 3`. Do NOT use `Daddy::HttpClient` — it returns raw body strings with no status code access and no timeout configuration, making it unfit for a JSON REST API.
- **`JSON.parse` / Ruby stdlib** — parse Mastodon API responses. Access keys as strings. No adapter gems needed.
- **Rails `strip_tags`** — convert toot HTML content to plain text for one-line preview. In a service class: `ActionController::Base.helpers.strip_tags(html)`. Do not use `raw()` or `html_safe` on toot content.
- **`URI` (Ruby stdlib)** — parse Mastodon profile URLs to extract `instance_host` and `username`. Already available everywhere.
- **Faraday test adapter** (built-in) — stub HTTP in Minitest without adding WebMock. Use `Faraday::Adapter::Test::Stubs` or service object injection to avoid live API calls in CI.

---

## Feature Table Stakes

These features must all exist for v1.16 to be coherent.

| Feature | Notes |
|---------|-------|
| Store profile URL + parse `instance_host` / `username` in `before_save` | Prevents duplication across create and update paths |
| `display_count` per account, default 5 | Matches Feed model pattern |
| CRUD screen at `/mastodon_accounts` (index, new, edit, destroy) | Standard management UI |
| Two-step API fetch: lookup then statuses, with `exclude_replies: true` default | Core fetching logic; replies are out-of-context noise |
| Welcome page collapsible gadget per account (AJAX-loaded) | Primary product value |
| One-line toot preview: `strip_tags(content).squish.truncate(100)` with link to original toot URL | Minimum useful display |
| Error handling: API failure returns empty list, gadget shows fetch-failed message | Never crash the welcome page |
| Per-user data isolation via `Crud::ByUser` | Same pattern as Feed, Todo, Note |
| Soft delete (`deleted` boolean, not `deleted_at`) | Matches every other model in this app |
| Locale strings (ja.yml + en.yml) for all UI chrome | App contract; parity test enforces this |
| `gadget_id` method returning `"mastodon_account_#{id}"` | Required for Portal dispatch |

---

## Feature Differentiators

Nice-to-have for v1.16 if time allows; otherwise defer.

| Feature | Priority | Notes |
|---------|----------|-------|
| Store resolved numeric Mastodon account ID in DB | High — reduces API calls from 2 to 1 per gadget load | Column type must be string, not integer |
| Short-TTL Rails cache (5 min) for API responses | High — reduces instance load | Low implementation cost |
| `exclude_reblogs` preference per account | Low | Lets user control whether boosts appear |
| Show boost attribution ("boosted by @account") | Medium | Adds context for reblogged toots |
| Relative timestamps ("5 min ago") | Low | `time_ago_in_words` already available |

Explicitly out of scope for v1.16 and beyond in this milestone: OAuth, posting/replying, Mastodon social graph follow/unfollow, WebSocket streaming, rich toot rendering.

---

## Architecture Blueprint

The feature is a parallel track to the RSS feed system. Do not touch `Feed`, `FeedsController`, or the RSS pipeline.

**Major components:**

1. **`MastodonAccount` model** — persists per-user account registration; `before_save :parse_profile_url` extracts `instance_host` and `username` from raw `profile_url`; exposes `statuses`, `entries`, `visible?`, `gadget_id`; includes `Crud::ByUser`; soft-deletes via `deleted` boolean.

2. **`MastodonClient` service class** — stateless; initialized with `instance_host`; `fetch_statuses(username, limit:)` executes the two-step lookup then statuses flow using direct Faraday with explicit timeouts; raises typed errors (`NetworkError`, `AccountNotFound`, `RateLimitError`, `ApiError`); never touches ActiveRecord.

3. **`MastodonAccountsController`** — mirrors `FeedsController`; `preload_mastodon_account` before_action; `show` renders with `layout: !request.xhr?`; create/update use `save` (not `save!`) so URL validation errors re-render the form; strong params exclude `instance_host` and `username`.

4. **`app/views/welcome/_mastodon_account.html.erb`** — gadget partial mirroring `_feed.html.erb`; issues `$.get(mastodon_account_path(gadget))` on `$(document).ready`; XHR `.fail` handler writes fetch-failed message. Uses existing `.gadget` CSS class — no new CSS.

5. **`Portal#get_gadgets` addition** — `MastodonAccount.where(user_id: user.id, deleted: false).each { |a| ret[a.gadget_id] = a }` after the Feed loop. The existing `portal_column_section` dispatch resolves `"mastodon_account"` to `welcome/_mastodon_account` automatically.

**Suggested build order within phases:** migration → model → client service → CRUD controller+views → welcome gadget → locale parity + test sweep.

---

## Critical Decisions

These must be explicit in requirements to prevent implementation drift.

1. **`Daddy::HttpClient` is forbidden for Mastodon API calls.** Use `Faraday.new(url:) { |f| f.options.timeout = 5; f.options.open_timeout = 3 }` directly. `Daddy::HttpClient` has no status code access and no timeout — using it causes silent thread starvation.

2. **Store the Mastodon numeric account ID as a `string` column, never `integer`.** Some Mastodon forks use non-numeric IDs. Rails `bigint` would silently truncate or raise. String column is safe for all implementations.

3. **Always `strip_tags` before rendering toot content.** Mastodon `content` is raw HTML. The pipeline must be: `strip_tags(raw).squish.truncate(100)`. Add a fixture toot with `<script>alert(1)</script>` to enforce this in tests.

4. **URL parsing happens in `before_save`, not the controller.** Placing parse logic in the controller requires duplication across create and update.

5. **The gadget loads toots via AJAX after page render, not synchronously.** With 5+ followed accounts and a 5s timeout per two-request flow, synchronous server-side fetching blocks the page for up to 50 seconds worst case. AJAX matches the RSS feed pattern exactly.

---

## Watch Out For

Top pitfalls ranked by risk.

1. **Thread starvation from missing timeouts (CRITICAL).** No timeout on Faraday blocks a Puma thread indefinitely. Mitigation: set `timeout: 5, open_timeout: 3` in `MastodonClient`; rescue `Faraday::TimeoutError`; return `[]`. Must be addressed in the MastodonClient phase, not deferred.

2. **XSS from toot HTML content (CRITICAL).** Mastodon `content` is HTML. Rendering with `raw()` or `html_safe` is a stored XSS vector. Mitigation: `strip_tags(content)` on every render path. Add an XSS-payload fixture toot in tests.

3. **`account_id` column type must be string, not integer (HIGH).** Mastodon IDs are 64-bit snowflake IDs; some forks use non-numeric IDs. Define the migration column as `t.string :mastodon_account_id` from the start.

4. **Profile URL edge cases cause wrong-account fetches (HIGH).** Users paste `/web/@username`, trailing slashes, handle notation (`@user@instance`), and `/users/username` ActivityPub URIs. Mitigation: normalize path in `parse_profile_url` before_save; validate URL format; perform a live lookup on create to confirm the account exists.

5. **Live API calls in Minitest and Cucumber (HIGH).** No HTTP stubbing library exists. Mitigation: design `MastodonClient` for dependency injection from phase 1; use `Faraday::Adapter::Test::Stubs` in unit tests; Cucumber E2E scenarios assert only that the gadget container is present, not live toot content.

---

## Suggested Phase Structure

**Phase 1 — Data Layer (model + migration)**
**Rationale:** All downstream phases depend on the persisted model. Parse logic in `before_save` prevents duplication later.
**Delivers:** `mastodon_accounts` table, `MastodonAccount` model with `Crud::ByUser`, `before_save :parse_profile_url`, `gadget_id`, validations, model tests, `activerecord.attributes.*` locale keys.
**Decisions addressed:** string column for Mastodon account ID, `before_save` URL parsing, `deleted` boolean soft-delete.
**Research flag:** Standard Rails pattern — no phase research needed.

**Phase 2 — CRUD Controller + Views**
**Rationale:** Delivers complete management UI before touching API or welcome page; independently verifiable.
**Delivers:** `MastodonAccountsController` (index, new, create, edit, update, destroy), views, routes, controller tests with ownership checks, `mastodon_accounts.*` locale keys.
**Decisions addressed:** strong params exclude `instance_host`/`username`; use `save` not `save!` to surface URL validation errors.
**Research flag:** Standard pattern mirroring FeedsController — no phase research needed.

**Phase 3 — API Client Service**
**Rationale:** Independently testable before the gadget is wired. Proves API contract. The `show` action depends on this.
**Delivers:** `MastodonClient` with typed error classes, explicit Faraday timeouts, `MastodonAccount#statuses`/`#entries`/`#visible?`, `MastodonAccountsController#show` with XHR layout suppression, `show.html.erb`, unit tests with Faraday test adapter stubs.
**Decisions addressed:** no `Daddy::HttpClient`, explicit timeouts, `strip_tags` on render, typed error rescue to `[]`.
**Research flag:** No additional research needed — API endpoints confirmed live, Faraday patterns confirmed from codebase.

**Phase 4 — Welcome Page Gadget**
**Rationale:** Gadget integration is last; depends on `show` existing and Portal recognizing the gadget format.
**Delivers:** `welcome/_mastodon_account.html.erb`, `Portal#get_gadgets` loop addition, welcome locale keys, integration test, Cucumber E2E (register account → gadget container appears).
**Decisions addressed:** AJAX loading, not synchronous server-side fetch.
**Research flag:** No additional research needed — portal dispatch pattern confirmed by direct code inspection.

**Phase 5 — Locale Parity + Test Coverage Sweep**
**Rationale:** Tri-suite green gate before milestone close. Locale parity test catches any key added to one file but not the other.
**Delivers:** ja.yml/en.yml key parity confirmed, Minitest coverage sweep, Cucumber destroy and edit scenarios, tri-suite green.
**Research flag:** No research needed.

### Phase Ordering Rationale

- Phase 1 first: migration and model columns are stable prerequisites for all other phases.
- Phase 2 before API: CRUD UI is verifiable without live API calls; reduces blast radius if API design changes.
- Phase 3 before gadget: `show` action must exist for AJAX `$.get` to have a target.
- Phase 4 last among features: welcome page integration depends on all three prior phases being correct.
- Phase 5 as explicit close gate: locale parity and test sweep are the condition for marking the milestone complete.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies verified against Gemfile.lock; Faraday pattern confirmed from BookmarksController source; zero new gems confirmed |
| Features | HIGH | API shape verified live against ruby.social; feature list confirmed against existing Feed gadget pattern in source code |
| Architecture | HIGH | All referenced files inspected directly: portal.rb, feeds_controller.rb, _feed.html.erb, schema.rb, crud/by_user.rb |
| Pitfalls | HIGH | Rate limits confirmed via live response headers; XSS risk confirmed from live API content inspection; timeout risk confirmed from Daddy::HttpClient source |

**Overall confidence:** HIGH

### Gaps to Address

- **Pleroma/Akkoma compatibility:** `/api/v1/accounts/lookup` may not be present on Pleroma instances. The 404 error path handles this gracefully, but users following Pleroma accounts will see a fetch-failed message. Acceptable for v1.16 — document as known limitation in CRUD form help text.
- **Caching strategy:** No caching layer exists. Short-TTL Rails cache is recommended as a differentiator but not a blocker. If added, scope it to `MastodonAccount#statuses`, not the controller.

---

## Sources

### Primary (HIGH confidence)
- Mastodon accounts API official docs: https://docs.joinmastodon.org/methods/accounts/
- Mastodon rate limits official docs: https://docs.joinmastodon.org/api/rate-limits/
- Mastodon public data guide: https://docs.joinmastodon.org/client/public/
- Live API verification: ruby.social `/api/v1/accounts/lookup` response headers (2026-05-12)
- Direct codebase inspection: `app/models/feed.rb`, `app/controllers/feeds_controller.rb`, `app/views/welcome/_feed.html.erb`, `app/models/portal.rb`, `app/models/concerns/crud/by_user.rb`, `app/controllers/bookmarks_controller.rb`, `db/schema.rb`, `Gemfile.lock`

### Secondary (MEDIUM confidence)
- Pleroma API differences: https://docs-develop.pleroma.social/backend/development/API/differences_in_mastoapi_responses/
- Akkoma API differences: https://docs.akkoma.dev/stable/development/API/differences_in_mastoapi_responses/
- Mastodon trailing slash issue: https://github.com/mastodon/mastodon/issues/20459
- Unauthenticated rate limits community-confirmed: approximately 7,500 req/5min per IP (not officially documented)

### Tertiary (LOW confidence)
- Faraday test adapter usage patterns: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Test — specific stub syntax needs validation against locked version 1.10.5

---

*Research completed: 2026-05-12*
*Ready for roadmap: yes*
