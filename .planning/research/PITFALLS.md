# Pitfalls Research — v1.26 Visited Link Tracking

**Project:** Bookmarks v1.26
**Researched:** 2026-05-18
**Confidence:** HIGH (all findings derived from direct codebase inspection; patterns validated against existing jQuery AJAX, WebMock, and MySQL upsert conventions already used in this codebase)

---

## Context

v1.26 adds server-side visited URL tracking to the existing AJAX-heavy gadget dashboard. When the user clicks a content link in a feed, Mastodon, or X gadget, JS fires a POST to a new endpoint (`VisitedLinksController#create` or similar) that upserts a `(user_id, url)` row. On next gadget render, the server queries the user's visited set and adds a CSS class to matching links. The gadget content is loaded via AJAX (`$.get`) into a container that replaces the full `innerHTML` on each page load.

Key existing constraints that shape all pitfalls below:

- All gadget content is replaced wholesale via `$('#container').html(html)` — there is no incremental DOM update; every page load the AJAX fires again and renders fresh HTML from the server.
- Links in X gadgets point to `https://x.com/i/status/{tweet_id}` (server-constructed), never raw t.co URLs. t.co expansion already happens in `XClient#expand_tco_entities` before the item is stored in memory.
- Links in Mastodon gadgets point to the status URL (e.g. `https://ruby.social/@FastRuby/999`), extracted from `status['url']` by `MastodonClient#build_preview_item`. HTML content is fully stripped before display.
- Links in feed gadgets are RSS entry URLs, passed through unchanged.
- `rails-ujs` is loaded globally; jQuery `$.post` without a manually set `X-CSRF-Token` header works when the form authenticity token is embedded in POST params or when `rails-ujs` sets the AJAX header automatically.
- `protect_from_forgery with: :exception` is active in `ApplicationController`.

---

## Critical Pitfalls

### PITFALL-1: Double-firing click handler after AJAX gadget reload

**What goes wrong:**
Each gadget partial ships an inline `$(document).ready(function() { … })` that calls `$.get` and replaces the gadget container's `innerHTML`. A click handler bound with `$('#gadget-container').on('click', 'a', handler)` — delegated to the container — survives across AJAX reloads because the container element itself is never replaced, only its content. But if the handler is instead bound directly to each `<a>` element (e.g., `$('#gadget-container a').on('click', handler)`), every AJAX reload creates a fresh set of `<a>` nodes and the old bindings evaporate. Handlers bound this way fire zero times after a reload, and if you add them in both `document.ready` and after `$.get` success, you get double-fire on first load (both bindings active on the original nodes) and zero-fire after reload (old nodes replaced).

**Why it happens:**
Developers often write `$('a.gadget-link').on('click', handler)` in a ready block, then also call the same binding inside the AJAX success callback to cover the re-render case. On first load the handler runs twice for every click; on subsequent page-session navigations it may not run at all if the success callback binding is missing or the ready block runs before the AJAX completes.

The existing codebase already solved this for the note gadget via delegated handlers on a stable ancestor and a named namespace (`.noteGadgetSave`). The same pattern is required here.

**How to avoid:**
Bind the visit-recording click handler using event delegation on a stable ancestor that is never replaced by AJAX. The `document` itself is always available. Use a namespaced event and a specific selector that matches only gadget content links:

```js
$(document).on('click.visitedLinks', '.gadget ol li a[href]', function(e) {
  // POST the href
});
```

Do NOT bind to the gadget container element (`$('#x_account_5').on('click', …)`) because portal drag-drop can move gadgets between columns and the container id is stable but the entire gadget div can be re-parented. `document` delegation is safe. Call `.off('.visitedLinks')` before rebinding if the module is ever re-initialised (see PITFALL-2).

**Warning signs:**
- DevTools Network shows two POST requests to the visit endpoint for a single click during the first page session.
- After switching away from a mobile column and back (triggering a re-render), clicks on gadget links fire zero POST requests.
- `bin/rails test` passes but Cucumber shows no visit-class on re-render.

**Phase to address:** The JS phase that introduces the click handler (Phase 1 of the v1.26 roadmap).

---

### PITFALL-2: Handler accumulation on AJAX re-init paths

**What goes wrong:**
`note_gadget.js` already established the pattern of calling `initNoteGadget()` both on `document.ready` and in response to the `noteGadgetLoaded` custom event (Phase 79). If a `initVisitedLinks()` function is introduced and follows a similar pattern — called on `document.ready` and also in any future "gadget reload" event — and the function does NOT call `.off(namespace)` before rebinding, each re-init call accumulates an additional click listener. With three re-inits and one click, three POST requests fire.

The existing note gadget avoids this by calling `$gadget.off('.noteGadgetSave')` on line 59 before rebinding. The visited-link handler, if delegated to `document`, must call `$(document).off('.visitedLinks')` before rebinding, or use `.on` with a guard that prevents re-registration.

**Why it happens:**
jQuery `.on()` stacks handlers — calling it twice on the same element/event/selector registers two independent handlers. There is no auto-deduplication. This is a well-known jQuery gotcha that becomes invisible when the DOM element itself is replaced (masking the problem) but surfaces on document-level delegation where the element is never replaced.

**How to avoid:**
In the module initialization function, always call `$(document).off('.visitedLinks')` before calling `$(document).on('click.visitedLinks', …)`. This is a one-liner guard that makes the function idempotent:

```js
function initVisitedLinks() {
  $(document).off('.visitedLinks');
  $(document).on('click.visitedLinks', '.gadget ol li a[href]', function(e) {
    // …
  });
}
```

If the function is called once at parse time via IIFE (like `portal_lazy.js`) and never called again, the `.off` guard is still cheap insurance.

**Warning signs:**
- N POST requests per click where N equals the number of times the page or gadget was re-loaded in the session.
- Minitest for the POST endpoint passes but Cucumber shows 3 records in `visited_links` after one click.

**Phase to address:** Phase 1 (JS module design), before any gadget reload event wiring.

---

### PITFALL-3: URL mismatch between recorded URL and comparison URL at render time

**What goes wrong:**
The URL stored in the `visited_links` table must exactly match the URL checked at render time, or the CSS class is never applied. Multiple normalization discrepancies can cause silent mismatches:

1. **Fragment stripping:** The user clicks `https://example.com/article#section2`. The `href` attribute in the `<a>` tag includes the fragment. If the visit POST records the full URL including fragment, but the server compares against the base URL without fragment (or vice versa), no match.

2. **Trailing slash:** `https://example.com/article` vs `https://example.com/article/`. RSS feeds and Mastodon status URLs vary; some include trailing slashes, some don't.

3. **Scheme normalization:** `http://` recorded from an older feed entry vs `https://` used in the rendered link after a feed refreshes.

4. **Query string ordering:** `https://example.com/?b=2&a=1` vs `https://example.com/?a=1&b=2`. Unlikely for RSS/Mastodon/X but possible.

5. **X gadget specificity:** The URL rendered in `x_accounts/show.html.erb` is `https://x.com/i/status/{tweet_id}` (server-constructed in `XClient#build_tweet_preview`). The `href` in the rendered `<a>` tag is exactly this string. The JS click handler reads `this.href` (the fully resolved DOM URL) or `$(this).attr('href')`. On a page at `https://yourapp.com`, `this.href` (DOM property) returns the fully resolved absolute URL; `$(this).attr('href')` returns the raw attribute value. If the attribute value is already absolute (it is, for X and Mastodon), both are identical. For feed entry URLs that are relative — check whether `Feed#entries` yields absolute URLs.

**Why it happens:**
Each gadget type has a different URL origin:
- Feeds: RSS entry `<link>` value — can be relative or absolute depending on the feed.
- Mastodon: `status['url']` — always absolute (`https://instance.social/@user/id`).
- X: `https://x.com/i/status/{id}` — always absolute, server-constructed.

Developers recording `this.href` (DOM property, always absolute) then comparing with the stored attribute value (possibly relative) will get mismatches for relative feed links.

**How to avoid:**
Establish one normalization rule and apply it identically on write (JS click handler) and on read (server-side comparison):

- **Always use the DOM-resolved absolute URL:** read `this.href` (not `$(this).attr('href')`) in the click handler. This is always absolute even for relative `href` attributes.
- **Strip fragments on write and on read:** `url.split('#')[0]` in JS before POSTing; `URI.parse(url).omit(:fragment).to_s` or a simple `.gsub(/#.*$/, '')` in Ruby before inserting and before comparing.
- **Do not normalize trailing slashes** unless you find a concrete mismatch — normalization introduces its own ambiguity. Record exactly what the DOM resolves.
- **Do not normalize schemes** — record the URL as-is; if a feed switches from http to https, old visit records simply stop matching. Acceptable for a personal app.

Store the normalizer in one Ruby method (e.g. `VisitedLink.normalize_url(url)`) called on both write and read, and one JS helper (`normalizeVisitUrl(href)`) called before every POST. Tests must verify both.

**Warning signs:**
- Visit is recorded in DB but the CSS visited class never appears on re-render.
- `visited_links` table accumulates duplicate rows for the same URL with different fragment suffixes (e.g., `https://example.com/article` and `https://example.com/article#intro` as separate rows).

**Phase to address:** Phase 1 (normalization spec must be decided before the migration and before the JS handler — changing it later requires a data migration).

---

### PITFALL-4: CSRF token missing from the visit POST — `ActionController::InvalidAuthenticityToken` in production

**What goes wrong:**
`ApplicationController` uses `protect_from_forgery with: :exception`. Any POST without a valid CSRF token raises `ActionController::InvalidAuthenticityToken` and returns 422. jQuery `$.post` does NOT automatically include the Rails CSRF token unless `rails-ujs` has wired `$.ajaxSetup` — which it does, but only if `rails-ujs` is loaded and its initialization ran before the `$.post` call.

The existing `$.post` in `_dashboard.html.erb` (save_state) works because it manually includes `authenticity_token` in the params object. The todo `delete_todos` function also reads the token from a `data-authenticity_token` attribute. The only reason all other `$.post` calls work is that `rails-ujs` injects `X-CSRF-Token` as an AJAX header globally via `$.ajaxSetup`.

The risk: if the visit POST is fired very early (before `rails-ujs` has run its `$( document ).ready`), the header may not be set yet. Given Sprockets `require_tree`, `rails-ujs` is loaded first (it is listed before `require_tree` in `application.js`), so in practice `$.ajaxSetup` will be in place. But this ordering is invisible and fragile.

**Why it happens:**
Developers new to the project assume `$.post` "just works" because they see `_dashboard.html.erb` succeed. They don't notice that `save_state` succeeds because the CSRF header is injected globally by rails-ujs, not because params include the token.

**How to avoid:**
Read `rails-ujs` behaviour: it calls `$.ajaxSetup({ headers: { 'X-CSRF-Token': csrfToken } })` on DOMContentLoaded. This covers all subsequent `$.post` calls made after DOM ready. The visit POST fires inside a click handler which always fires after DOM ready. Therefore the global header injection is reliable in this specific flow.

For defensive clarity, document this in a comment in the new JS file:
```js
// CSRF token is set globally by rails-ujs on DOMContentLoaded.
// $.post calls made in click handlers (post-DOM-ready) inherit the header automatically.
// See: app/assets/javascripts/application.js (//= require rails-ujs)
```

Do NOT use `protect_from_forgery with: :null_session` on the visit endpoint — it silently ignores CSRF failures instead of raising them, making security regressions invisible.

**Warning signs:**
- 422 responses in browser Network tab when clicking gadget links.
- Rails log shows `ActionController::InvalidAuthenticityToken` for POST to visit endpoint.
- Works in development but fails in production if assets are served differently (unlikely with Sprockets but possible with CDN misconfiguration).

**Phase to address:** Phase 1 (add a comment and a controller integration test that POSTs without a CSRF token and asserts 422, to lock the expectation).

---

### PITFALL-5: MySQL upsert race condition from multiple browser tabs

**What goes wrong:**
The user has two browser tabs open on the dashboard. They click the same link in both tabs within milliseconds. Both tabs fire POST to the visit endpoint simultaneously. Both backend requests attempt to insert `(user_id, url)`. Without a unique index + upsert strategy, this produces either:

- **Two rows:** No unique constraint → duplicate rows for the same URL, polluting the visited set and wasting space.
- **Two raised exceptions:** Unique constraint exists but the Ruby code uses `find_or_create_by` → ActiveRecord race: both `find` phases return nil, both `create` phases attempt insert, second one raises `ActiveRecord::RecordNotUnique` and returns 500.

Rails 8.1 provides `Model.upsert(attrs, unique_by: :index_name)` which maps to `INSERT … ON DUPLICATE KEY UPDATE` in MySQL. This is the correct primitive — it is atomic at the DB level and handles concurrent inserts without application-level locking.

**Why it happens:**
Developers reach for `find_or_create_by` because it reads naturally. For visited links the semantics are "record that this URL was visited" — the row either exists (already visited, no-op) or doesn't (insert). `find_or_create_by` has a TOCTOU race; `upsert` does not.

**How to avoid:**
- Add a unique index on `(user_id, url)` in the migration (following the existing pattern from `x_accounts`: `t.index ["user_id", "x_user_id"], unique: true`).
- Use `VisitedLink.upsert({ user_id: user.id, url: normalized_url }, unique_by: :index_visited_links_on_user_id_and_url)` in the controller or model class method.
- The `upsert` call with `update_only: []` (no-op on conflict) or a `updated_at` touch is sufficient; visited links are facts, not updated records.
- Alternatively, rescue `ActiveRecord::RecordNotUnique` and return 200/204 — the duplicate insert means the URL is already recorded, which is the desired outcome. Both patterns are acceptable; `upsert` is cleaner.
- Controller should return `head :no_content` (204) on success, matching the `save_state` pattern. Fire-and-forget from JS — no response body needed.

**Warning signs:**
- `visited_links` table grows with duplicate `(user_id, url)` rows.
- 500 errors appearing in logs when visiting the same link rapidly from two tabs.
- `count` queries on `visited_links` return unexpected numbers.

**Phase to address:** Phase 1 (migration must include the unique index; model must use upsert; controller must return 204 or rescue on duplicate).

---

### PITFALL-6: N+1 query — checking visited set inside the gadget partial per-link

**What goes wrong:**
The gadget show views (`x_accounts/show.html.erb`, `mastodon_accounts/show.html.erb`, `feeds/show.html.erb`) iterate over `@x_items`, `@mastodon_items`, `@feed_entries` and render a link per item. If visited-class logic is implemented as:

```erb
<% visited = VisitedLink.exists?(user_id: current_user.id, url: item[:url]) %>
<li class="<%= visited ? 'visited' : '' %>">…</li>
```

This fires one SQL query per item. With 5–20 items per gadget and 3–10 gadgets loading concurrently, a single page load triggers 15–200 extra queries. At single-user scale this is tolerable in terms of absolute time but wasteful and harder to reason about.

**Why it happens:**
ERB partials tempt inline query logic because it "just works." There is no ORM N+1 warning for inline `exists?` calls in views.

**How to avoid:**
Load the full visited set for the user once per controller action, pass it as a local or instance variable, and check membership in-memory:

```ruby
# In XAccountsController#show (and equivalent for Mastodon, Feeds):
@visited_urls = VisitedLink.where(user_id: current_user.id).pluck(:url).to_set
```

In the view:
```erb
<li class="<%= @visited_urls.include?(item[:url]) ? 'link--visited' : '' %>">…</li>
```

One query per gadget render (not per link). The `visited_urls` set is per-request so cross-device sync is automatic — every gadget re-render issues a fresh query.

This also means the `visited_links` table only needs a simple index on `user_id` (not composite with `url`) for the `pluck` query, though the unique composite index on `(user_id, url)` for upsert already covers this with the leading column.

**Warning signs:**
- `bin/rails test` shows no failures but the development log shows 10+ `SELECT 1 FROM visited_links WHERE …` lines per gadget render.
- `bullet` gem (if added later) would flag this immediately.

**Phase to address:** Phase 2 (server-side rendering of visited class) — load the visited set once in the controller, never query per-item.

---

### PITFALL-7: CSS visited class conflicts with existing `a:visited` rules

**What goes wrong:**
The existing stylesheet already defines `a:visited { text-decoration: none; }` globally in `common.css.scss` (line 33) and the modern theme overrides link colors for visited links in `.modern div.gadgets div.gadget div div.title a:visited` and `.modern .actions a:visited`. Browser-native `:visited` applies a purple/default color to links that are in the browser's history, regardless of server knowledge.

If the server-side visited class (e.g., `.link--visited`) is added to an `<a>` element that the browser also considers `:visited` (the user physically navigated to that URL in this browser), the styling may be controlled by whichever rule wins the CSS specificity battle. Worse: `.link--visited` and `:visited` can diverge — the server knows the URL was visited on any device; the browser only knows about this browser's history.

The main risk is visual confusion: a link shows as `.link--visited` (server-visited, faded/grey) but also has browser `:visited` applied, potentially overriding the class style with the browser default purple. Since `common.css.scss` line 33 sets `a:visited { text-decoration: none }` (low specificity), this only affects text-decoration. But if a theme file applies `a:visited { color: … }` and the `.link--visited` rule has lower specificity, the theme color wins and `.link--visited` appears invisible.

**Why it happens:**
The project already has `a, a:visited { text-decoration: none }` as a baseline reset and per-theme `:visited` overrides for specific link contexts. Adding a new `.link--visited` class without auditing specificity competition leads to silent visual failures.

**How to avoid:**
- Use a class selector with sufficient specificity to win in all theme contexts: `.gadget ol li a.link--visited` (specificity 0,2,2) beats theme-scoped `a:visited` rules which are at most 0,1,2 in the existing files.
- Define the `.link--visited` style in `common.css.scss` (not in a theme file) so it applies across all three themes without duplication.
- Explicitly include `:visited` in the new rule to handle the browser-history overlap: `.gadget ol li a.link--visited, .gadget ol li a.link--visited:visited { color: #888; }` ensures the server-driven style wins even when the browser also considers the link visited.
- Add a contract test in `test/assets/` asserting the selector exists in `common.css.scss`, following the existing pattern in `visual_qa_consistency_contract_test.rb`.

**Warning signs:**
- `.link--visited` class is present in the DOM (verified in DevTools Elements) but the link color is unchanged visually.
- The visited style appears in simple/classic theme but not modern theme (specificity difference between theme files).
- `bin/rails test` passes but the Cucumber visited-link scenario shows the wrong color.

**Phase to address:** Phase 2 (CSS) — define the selector and add the contract test in the same commit as the first gadget view change.

---

### PITFALL-8: WebMock blocks the visit POST in Minitest integration tests

**What goes wrong:**
`test/support/webmock.rb` calls `WebMock.disable_net_connect!(allow_localhost: true)`. This allows Capybara/Puma on localhost (Cucumber) but has no effect on `ActionDispatch::IntegrationTest` requests — those go through the Rails test stack directly and are never subject to WebMock. However, if a developer adds a WebMock stub for the visit endpoint expecting it to intercept the internal POST (confusing internal Rails test dispatch with external HTTP), the stub is silently ignored and the test makes real DB writes.

The actual risk in the other direction: the visit endpoint POSTs to `current_user`-scoped URLs. If a Minitest integration test navigates to the welcome page and Capybara (or a simulated link click) triggers a real POST to the Puma dev server port rather than the in-process Rails stack, WebMock allows it (localhost is whitelisted) but the test DB may not have the right seed state.

**Why it happens:**
WebMock intercepts Faraday/Net::HTTP connections, not `ActionDispatch::IntegrationTest` rack dispatch. Developers confuse "stub the endpoint" (wrong) with "the integration test hits the endpoint via rack dispatch" (correct — no stub needed). This confusion is more likely because the codebase already uses `WebMock.stub_request` heavily for external API calls.

**How to avoid:**
- Minitest integration tests for `VisitedLinksController#create` should use `post visited_links_path, params: { url: '…' }, headers: { 'X-CSRF-Token': … }` — plain rack dispatch, no WebMock needed.
- Do NOT add a `WebMock.stub_request(:post, /visited_links/)` stub anywhere — it will be silently ignored by the in-process test stack and mislead future readers.
- In Cucumber scenarios that click gadget links and expect a visit to be recorded, the POST happens via the real Puma server (localhost, WebMock-allowed). No stub is needed; verify the DB row directly.
- The existing `STUB_RSS_BODY` stub in `webmock.rb` is for external RSS feeds (outbound HTTP from Rails). The visit POST is an inbound request to the app — a completely different flow.

**Warning signs:**
- A `WebMock::NetConnectNotAllowedError` for `localhost` when the test fires the visit POST (only happens if `allow_localhost: true` was accidentally removed or if the test runs the POST against the wrong host).
- Developer adds `WebMock.stub_request(:post, /localhost.*visited_links/)` and wonders why the DB row is not created.

**Phase to address:** Phase 1 (controller) — add the integration test alongside the controller; include a comment explaining rack dispatch vs WebMock scope.

---

### PITFALL-9: Test state isolation — visited rows leaking across Minitest tests and Cucumber scenarios

**What goes wrong:**
`visited_links` rows created in one test leak into the next if they are not cleaned up. Rails fixtures use transactional rollback by default for Minitest (each test runs inside a transaction that is rolled back at the end). This handles `visited_links` rows created via ActiveRecord in Minitest automatically — no manual cleanup needed.

For Cucumber: the `Before` hook in `features/support/hooks.rb` resets `MastodonAccount.delete_all` and `XAccount.delete_all` but does not delete `visited_links` rows (the table does not exist yet). When v1.26 adds the table, any `visited_links` rows written during a Cucumber scenario persist across scenarios. If scenario B expects "no visited links", but scenario A created one, scenario B will fail unexpectedly.

Additionally: the `Before` hook currently resets `preferences` but not `visited_links`. If a visited-link scenario sets a row and the next scenario tests "unvisited appearance", the test fails due to leaked state.

**Why it happens:**
Cucumber scenarios share a single DB transaction that is never rolled back between scenarios (as documented in `CLAUDE.md`: "Scenarios share DB state — no truncation between scenarios"). The `Before` hook manually deletes rows for tables that have cross-scenario leakage risk. When a new table is added, the hook must be updated.

**How to avoid:**
When adding the `visited_links` migration, simultaneously add `VisitedLink.delete_all` (or `VisitedLink.where(user_id: user.id).delete_all`) to the `Before` hook in `features/support/hooks.rb`. This follows the existing `MastodonAccount.delete_all` / `XAccount.delete_all` pattern exactly. This is the single most important test-isolation step for v1.26.

For Minitest: rely on the default transactional rollback — no change needed. Verify by adding one test that asserts `VisitedLink.count == 0` at the start and one that creates a row; run in order and confirm the second test's teardown rolls back.

**Warning signs:**
- Cucumber scenario "link renders as unvisited on first load" starts passing on first run but fails on re-run (state leaks from a prior scenario that created a visited row).
- `CLAUDE.md` flakiness note mentions "order-dependent failures" — visited link state leakage would produce exactly this symptom pattern.

**Phase to address:** Phase 1 (migration + `Before` hook update must be in the same commit; failing to do this will manifest as flaky Cucumber on the very first `dad:test` run).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `find_or_create_by` instead of `upsert` for visit insert | Readable, familiar | Race condition from multiple tabs → 500 on RecordNotUnique | Never — use upsert from day one |
| Per-link `VisitedLink.exists?` in view | Simple inline logic | N+1 queries (15–200 per page load) | Never — pluck the full set once per controller action |
| Binding click handler with `$('a').on('click', …)` instead of delegated `$(document).on` | Simple, direct | Handler lost after AJAX re-render | Never — delegation on stable ancestor is the correct pattern for AJAX-injected content |
| Using `$(this).attr('href')` instead of `this.href` for recording URL | Reads attr directly | Relative URLs stored as-is; mismatch with server-constructed absolute comparisons | Only safe if all gadget URLs are guaranteed absolute (they are for X and Mastodon; RSS entries can be relative) |
| Fragment stripping skipped | Simpler code | Two rows for `url` and `url#section`; visited class never appears if recorded with fragment and compared without | Never — always strip fragments at both write and read |
| Skipping `VisitedLink.delete_all` in Cucumber `Before` hook | Saves one line | Order-dependent Cucumber failures on visited-link scenarios | Never — always update the hook when a new table is added |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| jQuery click + AJAX-reloaded gadgets | Binding directly to `<a>` elements; handler lost on re-render | Delegated handler on `document` with gadget link selector; namespaced event for safe `.off` |
| `rails-ujs` CSRF injection | Assuming manual CSRF token param is required | `$.post` in click handlers inherits the header set globally by `rails-ujs`; document this assumption |
| WebMock + visit POST in Minitest | Adding `stub_request(:post, /visited_links/)` which is silently ignored | Plain `post visited_links_path, params:` rack dispatch; no stub needed or useful |
| X gadget URLs | Recording `this.href` which might include t.co | X gadget renders `https://x.com/i/status/{id}` only; t.co expansion happens server-side in `XClient`; no t.co ever reaches the `<a>` tag |
| Mastodon gadget HTML | Recording link from HTML content of status | `MastodonClient#build_preview_item` strips all HTML and only exposes `status['url']`; inline links in status body never appear in rendered `<a>` tags |
| CSS `:visited` pseudo-class | Relying on browser `:visited` for the visited style | `:visited` is browser-local; server-side class (`.link--visited`) provides cross-device sync; both can coexist if specificity is managed |
| MySQL `ON DUPLICATE KEY UPDATE` | Omitting `update_only:` on `upsert` causing unexpected column updates | Use `VisitedLink.upsert(attrs, unique_by:, update_only: [])` to make the conflict a no-op |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| N+1 per-link visited query in gadget show | 15–200 extra queries per page load depending on gadget count | Pluck the full visited set once per controller action | At any non-trivial gadget count; immediate at 5+ items per gadget |
| `visited_links` table unbounded growth | Table scan for `WHERE user_id = ?` slows as rows accumulate | Index on `user_id`; the unique composite index on `(user_id, url)` already covers leading-column scans | Personal app: years of daily use; not an immediate concern but index from day one |
| POST fired on every link click including gadget title links | Double-firing for the same URL (title link + content link click both hit the same URL) | Scope the click selector to content links only: `.gadget ol li a[href]` not `.gadget a[href]` — gadget title links are in `div.title`, not `ol li` | Harmless (upsert is idempotent) but wastes a round-trip per title click |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Trusting client-submitted URL without server-side ownership validation | Attacker POSTs arbitrary URLs to mark them as visited; pollutes visited set with injected data | Acceptable for personal app — `current_user` scoping means only the logged-in user's set is affected; no XSS vector from stored URL because it is compared server-side and a CSS class is added, not the URL rendered as markup |
| Rendering the stored URL back into HTML without escaping | XSS if a crafted URL containing `</a><script>` is stored and reflected | Never render the stored URL as raw HTML; the visited class is applied as a CSS class on a server-rendered `<a>` tag whose `href` comes from the service layer, not from `visited_links.url` |
| Skipping `authenticate_user!` on the visit endpoint | Unauthenticated POST stores rows without `user_id`; NOT NULL constraint prevents this but the error path is ugly | Visit endpoint must be under the default `authenticate_user!` before_action; do not add `skip_before_action` |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Visited state only updates on next full AJAX reload, not immediately on click | After clicking, the link still looks unvisited until the gadget reloads (next page load) | Optimistic CSS: on click success callback, add `.link--visited` class directly to the clicked element immediately. The server round-trip confirms persistence; the UI updates immediately |
| Visited class applied to gadget title links (profile links) as well as content links | Every visit to the X gadget marks the `@username` profile link as visited — not useful | Scope the CSS rule and click handler to `ol li a` (content items), not the title area `div.title a` |
| No visual distinction between "never loaded" and "visited" in error state | If the gadget fails to load, no links render, so visited state is invisible | This is fine — error state shows a localized error message, not links; visited class is irrelevant |

---

## "Looks Done But Isn't" Checklist

- [ ] **Fragment normalization on both ends:** Verify that `visited_links.url` stores the fragment-stripped URL AND that the server-side comparison uses the same normalization. A test that POSTs `https://example.com/article#section` and then checks membership of `https://example.com/article` must pass.
- [ ] **Cross-device sync:** Verify that a visited row created via a direct `VisitedLink.create!` (simulating another device) causes the gadget to render the link with the visited class on the next request — the AJAX re-render must re-query the DB, not use a cached result.
- [ ] **Cucumber `Before` hook updated:** Confirm `VisitedLink.delete_all` (or user-scoped variant) is in `features/support/hooks.rb` before any Cucumber scenario touches visited links.
- [ ] **Delegated click handler, not direct:** Grep for `$('.gadget … a').on('click'` — if found, replace with `$(document).on('click.visitedLinks', '.gadget ol li a[href]', …)`.
- [ ] **No t.co in stored URLs:** Verify that clicking an X gadget link stores `https://x.com/i/status/{id}`, not a t.co URL. The t.co expansion in `XClient#expand_tco_entities` replaces t.co in the display text but the link `href` in `show.html.erb` is `item[:url]` which is always `https://x.com/i/status/{id}` from `build_tweet_preview`. Confirm with a test on `XClient`.
- [ ] **CSS specificity verified across all three themes:** The `.link--visited` style must be visually distinct in simple, classic, and modern themes. Add a contract test asserting the selector in `common.css.scss`.
- [ ] **Upsert, not find_or_create_by:** Grep for `find_or_create_by` in the new model/controller — replace with `upsert`. Confirm the unique index exists in `schema.rb`.
- [ ] **204 response on success:** The visit POST should return `head :no_content`. The JS click handler should fire-and-forget — no UI update from the response other than the optimistic class addition.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Double-firing click handler (PITFALL-1 / PITFALL-2) | LOW | Add `.off('.visitedLinks')` before rebinding; clear any duplicate rows with `DELETE FROM visited_links WHERE …` group by `(user_id, url)` keeping one |
| URL mismatch — visits recorded but class never shown (PITFALL-3) | MEDIUM | Add Ruby normalizer, re-run normalization against existing `visited_links` rows via a migration `update` |
| N+1 query (PITFALL-6) | LOW | Move `VisitedLink.pluck` to controller action; one-line refactor |
| Cucumber state leakage (PITFALL-9) | LOW | Add `VisitedLink.delete_all` to `Before` hook; re-run `dad:test` |
| CSS visited class invisible (PITFALL-7) | LOW | Increase specificity in selector; add `:visited` variant to the rule |
| `find_or_create_by` race causing 500 (PITFALL-5) | LOW | Replace with `upsert` + `rescue ActiveRecord::RecordNotUnique`; no migration needed if unique index already exists |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| PITFALL-1: Double-firing click handler | Phase 1 — JS module design | Minitest JS contract or Cucumber: click once, assert one DB row and one POST in Network |
| PITFALL-2: Handler accumulation on re-init | Phase 1 — JS module design | `$(document).off('.visitedLinks')` present before `.on` in source; Minitest: reload gadget then click, assert one row |
| PITFALL-3: URL normalization mismatch | Phase 1 — migration + normalizer | Unit test: `VisitedLink.normalize_url('https://example.com/p#section') == 'https://example.com/p'`; integration: fragment in POST → class rendered |
| PITFALL-4: CSRF token missing | Phase 1 — controller | Integration test: POST without CSRF token asserts 422; POST with valid session asserts 204 |
| PITFALL-5: MySQL upsert race | Phase 1 — migration + model | Unique index in `schema.rb`; model test: two concurrent `upsert` calls produce exactly one row |
| PITFALL-6: N+1 queries | Phase 2 — gadget show view | Controller test: assert `VisitedLink` is queried once per render regardless of item count |
| PITFALL-7: CSS specificity conflict | Phase 2 — CSS | Contract test asserting `.gadget ol li a.link--visited` in `common.css.scss`; Cucumber: visited link is visually distinct |
| PITFALL-8: WebMock confusion in Minitest | Phase 1 — controller | Integration test uses plain rack dispatch; no `stub_request` for visit endpoint anywhere in codebase |
| PITFALL-9: Cucumber state leakage | Phase 1 — `Before` hook | `VisitedLink.delete_all` in `hooks.rb`; `dad:test` passes on second run without flake |

---

## Sources

- Codebase: `app/assets/javascripts/note_gadget.js` (delegated handler pattern, `.off(namespace)` before rebinding, re-init on custom event)
- Codebase: `app/assets/javascripts/todos.js` (manual `authenticity_token` param in `$.post`)
- Codebase: `app/assets/javascripts/application.js` (`//= require rails-ujs` — global CSRF header injection)
- Codebase: `app/views/welcome/_x_account.html.erb`, `_mastodon_account.html.erb`, `_feed.html.erb` (AJAX replace pattern: `$('#container').html(html)`)
- Codebase: `app/views/x_accounts/show.html.erb`, `mastodon_accounts/show.html.erb`, `feeds/show.html.erb` (link rendering in gadget content)
- Codebase: `app/services/x_client.rb` (`expand_tco_entities`, `build_tweet_preview` — t.co expansion server-side; item URL is always `https://x.com/i/status/{id}`)
- Codebase: `app/services/mastodon_client.rb` (`build_preview_item` — HTML stripped, `status['url']` only)
- Codebase: `app/controllers/application_controller.rb` (`protect_from_forgery with: :exception`)
- Codebase: `app/controllers/welcome_controller.rb` (`save_state` — fire-and-forget POST returning `head :ok`)
- Codebase: `app/models/x_account.rb` (`refresh_cache_from_items!` upsert pattern using `first_or_initialize`)
- Codebase: `test/support/webmock.rb` (`disable_net_connect!(allow_localhost: true)`, RSS fixture stubs)
- Codebase: `features/support/hooks.rb` (`Before` hook with `MastodonAccount.delete_all`, `XAccount.delete_all` — isolation pattern)
- Codebase: `app/assets/stylesheets/common.css.scss` (existing `a:visited` rules, specificity baseline)
- Codebase: `app/assets/stylesheets/themes/modern.css.scss` (theme-scoped `:visited` overrides)
- Codebase: `db/schema.rb` (unique index pattern on `x_accounts.user_id + x_user_id`)
- Project policy: `CLAUDE.md` (Cucumber flakiness policy, between-scenario DB state sharing, rerun policy)
- Project policy: `.planning/PROJECT.md` (v1.26 goal, existing stack constraints, no new JS deps)

---

*Pitfalls research for: visited URL tracking on AJAX-heavy Rails 8.1 + jQuery gadget dashboard (v1.26)*
*Researched: 2026-05-18*
