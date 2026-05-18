# Stack Research — v1.26 Visited Link Tracking

**Project:** Bookmarks v1.26
**Researched:** 2026-05-18
**Confidence:** HIGH (all patterns verified against existing codebase and Rails 8.1 API docs;
no new dependencies required; deduplication strategy verified against MySQL behavior)

---

## Summary

v1.26 needs server-side tracking of visited URLs. The entire feature is implementable with
**zero new gems** and **zero new npm packages** using Rails 8.1's built-in `upsert` API
and jQuery patterns already in the project.

The key insight from reading the codebase: every gadget content link is rendered server-side
in `show.html.erb` partials injected via AJAX. The visited state can be injected at render
time as a CSS class — no client-side DOM querying of the full visited set is needed. The
click-intercept fires a lightweight `$.post` using the CSRF token already wired by
`jquery_ujs.js`.

---

## New Components Required

### 1. Database — `visited_urls` table

A single new table stores `(user_id, url)` pairs with a unique composite index:

```sql
CREATE TABLE visited_urls (
  id         bigint       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id    int          NOT NULL,
  url        varchar(2083) NOT NULL,
  created_at datetime     NOT NULL,
  INDEX      index_visited_urls_on_user_id (user_id),
  UNIQUE     index_visited_urls_on_user_id_and_url (user_id, url(768))
)
```

**URL column length:** 2083 chars (IE historic max; practical URLs are much shorter). MySQL
requires a prefix length for unique indexes on columns exceeding 767 bytes in `utf8mb4`.
Use `url(768)` as the prefix in the unique index. This is sufficient to differentiate all
real-world URLs; collisions on very long URLs are not a security concern here.

**No `updated_at`:** This is an append-only store. Visited state never changes once
recorded — the row either exists or it does not. `created_at` captures when first visited
(informational). `updated_at` is omitted to keep the table minimal.

**No soft-delete:** Unlike `notes` or `bookmarks`, visited records are never logically
deleted in this milestone. Hard-presence is the semantic ("did visit" = row exists).

**Migration version:** `20260518_create_visited_urls.rb`

### 2. Model — `VisitedUrl`

```ruby
class VisitedUrl < ApplicationRecord
  include Crud::ByUser
  belongs_to :user
  validates :url, presence: true, length: { maximum: 2083 }

  # Idempotently record a visit. Safe to call on every click.
  def self.record!(user_id:, url:)
    VisitedUrl.upsert(
      { user_id: user_id, url: url, created_at: Time.current },
      unique_by: :index_visited_urls_on_user_id_and_url,
      update_only: []   # do not overwrite created_at on duplicate
    )
  end

  # Returns a Set of visited URLs for a user — used in view helpers.
  def self.url_set_for(user_id)
    where(user_id: user_id).pluck(:url).to_set
  end
end
```

**Why `upsert` not `find_or_create_by`:** `find_or_create_by` is a two-query operation
(SELECT then INSERT) with a race condition window between the two — two simultaneous clicks
on the same link from different devices can both find nothing and both attempt INSERT,
causing a `RecordNotUnique` error unless rescued. `upsert` issues a single
`INSERT ... ON DUPLICATE KEY UPDATE` to MySQL which is atomic and idempotent with no
race condition. This is the correct Rails 8.1 idiom for "insert if not exists" on MySQL.

**Why not `insert_all` with `skip_duplicates: true`:** `insert_all` is a bulk operation.
For a single-record insert-if-not-exists it is equivalent to `upsert` with
`on_duplicate: Arel.sql('url = url')` (a no-op update). Using `upsert` with `update_only: []`
is cleaner and expresses the intent precisely. Both generate `INSERT ... ON DUPLICATE KEY UPDATE`
on MySQL; `upsert` reads more naturally for a single record.

**`update_only: []`:** Rails 8.1's `upsert` accepts `update_only:` to restrict which columns
are updated on conflict. Passing `[]` means "update nothing" on duplicate — the existing
row is left unchanged (in particular, `created_at` is not reset). This is correct: the
first-visit timestamp should not be overwritten by subsequent visits.

**`unique_by:` must name the index, not columns, on MySQL:** MySQL does not support
`ON CONFLICT (col1, col2)` syntax (that is PostgreSQL syntax). On MySQL, Rails maps
`unique_by:` to the index name and generates `ON DUPLICATE KEY UPDATE`. Naming the index
explicitly (`unique_by: :index_visited_urls_on_user_id_and_url`) avoids any ambiguity.
Confirmed by Rails source: MySQL adapter uses index name to generate the clause.

### 3. Controller — `VisitedUrlsController`

```ruby
class VisitedUrlsController < ApplicationController
  def create
    url = params[:url].to_s.strip
    head :unprocessable_entity and return if url.blank?

    VisitedUrl.record!(user_id: current_user.id, url: url)
    head :ok
  end
end
```

**Route:** `POST /visited_urls` → `visited_urls#create`

```ruby
resources :visited_urls, only: [:create]
```

**Why `head :ok` not JSON:** The jQuery click-intercept does not use the response body.
`head :ok` (HTTP 204 or 200 with no body) is the lightest-weight response. No view
needed.

**CSRF:** `ApplicationController` uses `protect_from_forgery with: :exception`.
`jquery_ujs.js` (bundled by `jquery-rails 4.6.1`) automatically injects the
`X-CSRF-Token` header on all non-cross-domain `$.ajax` / `$.post` calls via
`$.ajaxPrefilter`. Verified by reading `jquery_ujs.js` line 397. No manual header
plumbing is needed in the JavaScript.

**Auth:** `ApplicationController` has `before_action :authenticate_user!`. The new
controller inherits it. Unauthenticated POST returns Devise redirect (302), which the
jQuery `.fail` handler ignores — acceptable behavior.

### 4. JavaScript — Click-Intercept (`visited_links.js`)

A new Sprockets file handles the click-intercept across all three gadget types:

```javascript
$(function () {
  'use strict';

  // Delegate on document so it works after AJAX injection of gadget HTML.
  $(document).on('click.visitedLinks', '.gadget ol a[href]', function () {
    const url = $(this).attr('href');
    if (!url || url.charAt(0) === '#') return;

    $.post('/visited_urls', { url: url })
      .fail(function (xhr) {
        // Fire-and-forget: failures are silent. Visited tracking is
        // non-critical; do not surface errors to the user.
        if (window.console && xhr.status !== 0) {
          console.warn('[visited_links] record failed', xhr.status);
        }
      });
    // Do NOT call e.preventDefault() — the link must still navigate.
  });
});
```

**Why event delegation on `document`:** All three gadgets (feeds, Mastodon, X) load their
content via `$.get` AJAX after page load. The gadget HTML is injected into `.gadget` divs.
A delegated handler on `document` captures clicks on AJAX-injected links without needing
re-binding after each gadget loads. This is the correct jQuery pattern for dynamically
inserted content.

**Why `.gadget ol a[href]`:** Targets only content links inside gadget ordered lists.
Does not intercept navigation links, form submits, or toolbar actions. The selector
matches exactly the link pattern used in all three show templates (feeds, mastodon, x).

**Fire-and-forget:** The click proceeds immediately; the POST happens asynchronously in
the background. No UX delay. Failures are logged to console only.

**No duplicate-send guard needed in JS:** `VisitedUrl.record!` uses `upsert` which is
idempotent. Multiple clicks on the same URL are safe. No client-side deduplication is
needed.

### 5. CSS Class Injection at Render Time

Visited state is injected server-side at gadget render time, not client-side after load:

**In each gadget show partial**, pass a `visited_urls` set as a local:

```erb
<%# feeds/show.html.erb %>
<% visited = local_assigns[:visited_urls] || Set.new %>
<ol>
  <% @feed.entries.each do |e| %>
    <li class="<%= 'link-visited' if visited.include?(e.url) %>">
      <%= link_to e.title, e.url, link_opts %>
    </li>
  <% end %>
</ol>
```

**How the set is passed:** The `show` action for each gadget controller fetches the
visited set and passes it as a local to the template. Example for FeedsController:

```ruby
def show
  # ... existing @feed setup ...
  @visited_urls = VisitedUrl.url_set_for(current_user.id)
  render layout: !request.xhr?
end
```

**Why server-side injection, not client-side class toggling:**
- The visited set can be large. Sending it to the client as JSON and then
  querying each link's href adds JS complexity with no benefit.
- Server-side rendering is the existing pattern for all state in this app.
- The CSS class is already the correct semantic unit (`link-visited`).
- No JS event needed after AJAX load — the class is in the injected HTML.

**CSS rule:** In `common.css.scss` (theme-agnostic, per v1.15 architecture):

```scss
.gadget ol li.link-visited a {
  color: var(--visited-link-color, #9b59b6);
  opacity: 0.75;
}
```

Using a CSS custom property allows theme overrides without duplication. A fallback
value ensures it works without theme-level definition.

**Why not `a:visited`:** Browser `a:visited` is scope-limited to the current device's
history and cannot be queried or set server-side. It also has privacy-restricted
styling (only color-related properties work). The `link-visited` server-side class
provides cross-device persistence, which is the core requirement.

---

## Recommended Stack (No New Dependencies)

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Rails 8.1.3 | Already locked | `VisitedUrl` model, `VisitedUrlsController`, `upsert` API | `ActiveRecord::Base.upsert` with `unique_by:` + `update_only: []` is the idiomatic Rails 8.1 atomic insert-if-not-exists. No gem needed. |
| MySQL 8 | Already in use | `UNIQUE KEY (user_id, url(768))` prefix index | `INSERT ... ON DUPLICATE KEY UPDATE` (MySQL's native upsert syntax) is what `upsert` generates. No extra config required. |
| jQuery 4.6.1 | Already locked (`jquery-rails 4.6.1`) | Event delegation click-intercept, `$.post` | Delegated handler on `document` correctly captures clicks on AJAX-injected gadget links. |
| jquery_ujs.js | Already bundled by `jquery-rails` | CSRF token injection | `$.ajaxPrefilter` at line 397 automatically adds `X-CSRF-Token` to all non-cross-domain `$.ajax`/`$.post` calls. No manual plumbing needed. |
| Sprockets | Already in use | New `visited_links.js` file | Drop a new file in `app/assets/javascripts/`; `require_tree .` in `application.js` picks it up automatically. No manifest change. |

### Supporting Libraries

None required.

| Evaluated | Verdict | Reason |
|-----------|---------|--------|
| `activerecord-import` gem | Reject | Bulk-insert gem for batch operations. This is a single-row upsert per click. Rails 8.1's built-in `upsert` is sufficient and requires no additional gem. |
| `redis` / `redis-rails` for visited state cache | Reject | Out of scope and overcomplicated. Redis is already configured for ActionCable in production, but using it as a visited-URL store adds a new data type, TTL management, and a cache-invalidation concern. MySQL is the correct store for durable cross-device state. |
| Browser `localStorage` for client-side visited cache | Reject | Does not provide cross-device sync, which is the stated requirement. |
| Browser `history.pushState` / `sessionStorage` | Reject | Same: device-local only. |
| Server-Sent Events / WebSocket push of visited state | Reject | Massively overengineered for a personal app. AJAX gadget content is re-fetched on each page load; the visited set is already current at that point. |

---

## Integration Map: Existing Code Touch Points

| File | Change Required | Nature |
|------|----------------|--------|
| `db/migrate/YYYYMMDD_create_visited_urls.rb` | New migration: table + unique index | New file |
| `app/models/visited_url.rb` | New model with `record!` and `url_set_for` | New file |
| `config/routes.rb` | `resources :visited_urls, only: [:create]` | 1-line addition |
| `app/controllers/visited_urls_controller.rb` | New controller, `create` action only | New file |
| `app/assets/javascripts/visited_links.js` | New file: delegated click-intercept + `$.post` | New file |
| `app/views/feeds/show.html.erb` | Accept `visited_urls` local; add `.link-visited` class | Modify |
| `app/views/mastodon_accounts/show.html.erb` | Same | Modify |
| `app/views/x_accounts/show.html.erb` | Same | Modify |
| `app/controllers/feeds_controller.rb` | Fetch `@visited_urls` set in `show` | Modify |
| `app/controllers/mastodon_accounts_controller.rb` | Fetch `@visited_urls` set in `show` | Modify |
| `app/controllers/x_accounts_controller.rb` | Fetch `@visited_urls` set in `show` | Modify |
| `app/assets/stylesheets/common.css.scss` | Add `.gadget ol li.link-visited a` rule | Modify |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `find_or_create_by` for deduplication | Two-query pattern with race condition window. Concurrent clicks from two devices on the same URL can both pass the SELECT check and both attempt INSERT, causing `RecordNotUnique`. | `upsert` with `unique_by:` — single atomic `INSERT ... ON DUPLICATE KEY UPDATE` |
| `first_or_create` / `where(...).first_or_initialize` | Same two-query race. Also used in `XAccount.refresh_cache_from_items!` — acceptable there because refresh is sequential and user-initiated, but wrong for concurrent click events. | `upsert` |
| `insert_all` with `skip_duplicates: true` | Bulk operation API; semantically correct but designed for arrays. Single-record `upsert` expresses the intent more clearly. Both generate the same SQL on MySQL. | `upsert` |
| Client-side visited set management (send full URL list to browser, query in JS) | Adds JS complexity, increases payload, requires a new JSON endpoint. Server-side class injection at gadget render time is simpler and consistent with the app's SSR-first pattern. | Server-side `link-visited` class in `show` template |
| `a:visited` CSS pseudo-class | Device-local browser history only; cannot be set or queried server-side; privacy-restricted styling (only color properties). | `.link-visited` class on `<li>` set at server render time |
| A new JS framework or npm dependency | Out-of-scope per PROJECT.md constraints; would break the Sprockets-only asset pipeline. | jQuery `.on` delegation already in `application.js` |
| Exposing `user_id` in the POST body | Security violation — `user_id` must never come from client params. Merge `current_user.id` server-side in the controller, same as `notes_controller.rb` and all other controllers. | `params[:url]` only; controller merges `user_id: current_user.id` |

---

## Deduplication Decision Matrix

| Approach | Race-safe? | Queries | Gem needed? | Recommended? |
|----------|-----------|---------|-------------|--------------|
| `upsert(unique_by:, update_only: [])` | YES (atomic INSERT) | 1 | No | **YES** |
| `find_or_create_by` | NO (TOCTOU race) | 2 | No | No |
| `where(...).first_or_initialize + save` | NO (TOCTOU race) | 2 | No | No |
| `insert_all(skip_duplicates: true)` | YES (atomic INSERT) | 1 | No | Acceptable; prefer `upsert` for single-record clarity |
| `insert_all!` | NO (raises on dup) | 1 | No | No |
| Rescue `RecordNotUnique` around `create!` | YES but ugly | 1+rescue | No | No — antipattern when SQL-level solution exists |

---

## URL Column Considerations

**Maximum length:** Rails string column defaults to `varchar(255)`. This is too short for
real-world URLs. Use `string, limit: 2083` (IE historic maximum; covers all practical URLs).

**MySQL unique index prefix:** In `utf8mb4`, a `varchar(2083)` column requires a prefix for
the unique index because `2083 × 4 bytes > 767-byte InnoDB index key limit` for older
MySQL. Use `url(768)` as the prefix length. This means URLs that differ only after position
768 chars will collide in the index — acceptable for this use case (URLs that long are
pathological). Newer MySQL with `innodb_large_prefix` enabled (default in MySQL 8) supports
up to 3072-byte keys, but using a prefix is the safe conservative approach.

**Migration syntax for prefix index in Rails:**

```ruby
add_index :visited_urls, [:user_id, :url], unique: true,
          name: 'index_visited_urls_on_user_id_and_url',
          length: { url: 768 }
```

Rails 8.1 `add_index` supports `length:` as a hash for per-column prefix lengths. Confirmed
in Rails migration guides. This generates the correct MySQL DDL.

---

## Performance Considerations

**Scale:** Personal app, single user. The visited_urls table will have at most thousands of
rows. No performance concern with a simple `WHERE user_id = ?` scan + Set construction.

**Query in show actions:** `VisitedUrl.url_set_for(current_user.id)` fetches all visited
URLs for the current user via `pluck(:url)`. At personal-app scale (hundreds to low
thousands of visited URLs) this is a single indexed query returning a small result set.
No caching or pagination required for v1.26.

**Index coverage:** The `index_visited_urls_on_user_id` index (non-unique, on `user_id`
alone) covers the `url_set_for` query efficiently. The unique composite index covers the
`upsert` conflict check.

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| `upsert` API with `unique_by:` + `update_only: []` | HIGH | Rails 8.1.3 ships `upsert` / `upsert_all` with these options. Verified via web search + Rails API docs + Saeloun blog on the `unique_by` + `on_duplicate` interaction. MySQL uses `INSERT ... ON DUPLICATE KEY UPDATE`, not `ON CONFLICT`. |
| `insert_all` MySQL behavior | HIGH | Verified via DEV Community article: MySQL adapter always emits `ON DUPLICATE KEY UPDATE col = col` even for `insert_all` (skip-duplicates path). |
| CSRF auto-injection via `jquery_ujs.js` | HIGH | Read `jquery_ujs.js` line 397 directly: `$.ajaxPrefilter` injects `X-CSRF-Token` header on all non-cross-domain requests. `jquery-rails 4.6.1` is locked in `Gemfile.lock`. |
| Delegated jQuery click handler for AJAX-injected links | HIGH | Standard jQuery pattern; verified against all three gadget partials — all inject via `$.get` into `.gadget` containers. `$(document).on('click', '.gadget ol a')` correctly captures clicks on dynamically injected content. |
| MySQL `varchar` prefix index with `length:` migration option | HIGH | Rails migration guide documents `length:` hash option for `add_index`. MySQL 8 `utf8mb4` has 3072-byte key limit by default but prefix is conservative best practice. |
| Server-side CSS class injection pattern | HIGH | All three show templates (`feeds/show`, `mastodon_accounts/show`, `x_accounts/show`) already accept locals from their controllers. Adding `visited_urls` local follows identical pattern. |
| Zero new gems required | HIGH | All Rails 8.1 APIs used (`upsert`, migration helpers, controller patterns) are built-in. All jQuery patterns used are in `jquery-rails 4.6.1` already locked. |

---

## Sources

- In-repo source read directly (all HIGH confidence):
  - `app/assets/javascripts/application.js` — `require rails-ujs`, `require jquery`, `require_tree .`
  - `app/views/welcome/_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb` — AJAX injection pattern confirmed
  - `app/views/feeds/show.html.erb`, `mastodon_accounts/show.html.erb`, `x_accounts/show.html.erb` — link rendering pattern confirmed; `link_opts` local pattern confirmed
  - `app/models/x_account.rb` — `first_or_initialize` pattern (race-susceptible; correct for sequential refresh, wrong for concurrent clicks)
  - `app/controllers/feeds_controller.rb`, `mastodon_accounts_controller.rb` — `render layout: !request.xhr?` pattern confirmed
  - `app/controllers/application_controller.rb` — `authenticate_user!` before_action confirmed
  - `app/controllers/notes_controller.rb` — `user_id: current_user.id` server-merge pattern confirmed
  - `config/routes.rb` — `resources :notes, only: [...]` pattern for minimal route
  - `db/schema.rb` — table structures for `notes`, `x_accounts` (index patterns)
  - `Gemfile.lock` — `jquery-rails 4.6.1`, `rails 8.1.3` confirmed
  - `.gem/ruby/.../jquery-rails-4.6.1/vendor/assets/javascripts/jquery_ujs.js` line 397 — `$.ajaxPrefilter` CSRF injection confirmed
- [Rails API — upsert/upsert_all behavior](https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html)
- [Saeloun: Upsert unique_by fix](https://blog.saeloun.com/2024/01/29/upsert-unique-by-fix/) — `unique_by` + `on_duplicate` interaction; MEDIUM confidence (single source, pre-8.1, but consistent with Rails source)
- [DEV: MySQL insert_all ON DUPLICATE KEY UPDATE](https://dev.to/junki555/why-is-on-duplicate-key-update-included-in-the-sql-issued-by-insertall-in-activerecord-when-using-mysql-il9) — MySQL adapter always uses `ON DUPLICATE KEY UPDATE` for `insert_all`; HIGH confidence (explains Rails adapter source behavior)
- [Rails Discussions: jquery-rails CSRF header](https://discuss.rubyonrails.org/t/x-csrf-token-http-header-added-by-jquery-rails/68564) — jquery-rails injects `X-CSRF-Token` automatically; HIGH confidence (corroborated by direct source read)

---

*Stack research for: v1.26 Visited Link Tracking*
*Researched: 2026-05-18*
