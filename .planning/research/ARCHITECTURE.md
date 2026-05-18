# Architecture Research — v1.26 Visited Link Tracking

**Project:** Bookmarks v1.26
**Researched:** 2026-05-18
**Confidence:** HIGH (all findings traced directly through existing source files; no new frameworks or external services required)

---

## Summary

v1.26 adds cross-device visited-link tracking. A user clicks a content URL in
any gadget on any device; the click is recorded server-side; on the next page
load (any device) the visited link renders with a CSS "visited" class.

The change requires one new table, one new controller, one new JS file, and
targeted modifications to three show-action views (the AJAX-injected HTML
responses). The portal gadget scaffolding, AJAX lifecycle, and portalLazy
coordinator are **unchanged**. No new gems, no new JS frameworks, no SPA
routing.

---

## Current Gadget Rendering Architecture (baseline)

Understanding the two-step render pipeline is prerequisite to understanding
where visited-URL data must flow.

### Step 1 — Skeleton render (server, page load)

`WelcomeController#index` assigns `@portal = current_user.portals.first`.
`_dashboard.html.erb` → `_portal_column_section.html.erb` loops over
`@portal.portal_columns` and renders one partial per gadget:

```
welcome#index
  └── _dashboard.html.erb
        └── _portal_column_section.html.erb
              ├── _feed.html.erb (skeleton + inline <script>)
              ├── _mastodon_account.html.erb (skeleton + inline <script>)
              └── _x_account.html.erb (skeleton + inline <script>)
```

Each gadget skeleton partial emits a `<div id="<gadget_id>" class="gadget">` with
a loading placeholder and an inline `<script>` that registers the AJAX load
with `window.portalLazy`.

### Step 2 — Content injection (AJAX, after page load)

`portalLazy.register(columnIndex, fn)` fires `fn()` — either immediately
(desktop, or mobile initial column) or deferred (mobile, non-initial column).
`fn()` calls `$.get(show_url)` which hits the gadget's show controller action:

| Gadget | AJAX target | Controller#action |
|--------|-------------|------------------|
| Feed | `GET /feeds/:id` (XHR) | `FeedsController#show` |
| Mastodon | `GET /mastodon_accounts/:id` (XHR) | `MastodonAccountsController#show` |
| X account | `GET /x_accounts/:id` (XHR) | `XAccountsController#show` |

Each show action renders its view **without layout** when `request.xhr?`.
The response HTML replaces the skeleton's inner content:

```js
$('#<gadget_id>').html(html);
```

The link `<a>` tags for content items are rendered in the show views:
- `feeds/show.html.erb` — `link_to e.title, e.url`
- `mastodon_accounts/show.html.erb` — `link_to item[:text], item[:url]`
- `x_accounts/show.html.erb` — `link_to item[:text], item[:url]`

**This is where visited-class must be applied.** The content links are only
rendered in step 2, not in step 1.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser (click event on gadget link)                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  visited_links.js                                        │   │
│  │  delegated click on .gadget a[href]                      │   │
│  │    → $.post('/visited_links', { url: href })             │   │
│  │    → add .link--visited to clicked <a>                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │ POST /visited_links
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Rails (VisitedLinksController#create)                          │
│    authenticate_user!                                           │
│    upsert(user_id, url) → ignore duplicate                      │
│    head :no_content (204)                                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │ writes
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  visited_links table                                            │
│    user_id  :integer  NOT NULL                                  │
│    url      :string   NOT NULL                                  │
│    UNIQUE INDEX (user_id, url)                                  │
└─────────────────────────────────────────────────────────────────┘
                      │ read at gadget show render time
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Show controllers (Feed / MastodonAccounts / XAccounts)        │
│    @visited_urls = VisitedLink.urls_for(current_user)          │
│    passes @visited_urls into view                               │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Show views (feeds/show, mastodon_accounts/show,               │
│              x_accounts/show)                                   │
│    link_to e.title, e.url,                                     │
│      class: visited_link_class(@visited_urls, e.url)           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | Status |
|-----------|----------------|--------|
| `visited_links` table | Persistent deduped store of (user_id, url) pairs | NEW |
| `VisitedLink` model | ActiveRecord model; `urls_for(user)` scope; `upsert` | NEW |
| `VisitedLinksController` | `POST /visited_links` — authenticate, upsert, 204 | NEW |
| `visited_links.js` | Delegated click handler on `.gadget a[href]`; `$.post` to record; immediate class toggle | NEW |
| `ApplicationHelper#visited_link_class` | Returns `"link--visited"` if url in visited set, `""` otherwise | NEW |
| `feeds/show.html.erb` | Pass `class:` to `link_to` using `visited_link_class` | MODIFY |
| `mastodon_accounts/show.html.erb` | Same | MODIFY |
| `x_accounts/show.html.erb` | Same | MODIFY |
| `FeedsController#show` | Assign `@visited_urls` | MODIFY |
| `MastodonAccountsController#show` | Assign `@visited_urls` | MODIFY |
| `XAccountsController#show` | Assign `@visited_urls` | MODIFY |
| `common.css.scss` | `.link--visited` style rule | MODIFY |

---

## Data Flow

### Click → record → immediate visual feedback

```
User clicks link in gadget
  ↓
visited_links.js delegated handler fires ($(document).on('click', '.gadget a[href]', fn))
  ↓
href = $(this).attr('href')
  ↓
$.post('/visited_links', { url: href })   ← fire-and-forget (no success callback needed)
  ↓
$(this).addClass('link--visited')         ← optimistic immediate update
  ↓
Link opens (default browser navigation; target="_blank" if preference set)
```

### POST → server upsert → 204

```
POST /visited_links  { url: "https://example.com/article" }
  ↓
VisitedLinksController#create
  authenticate_user!  (before_action from ApplicationController)
  url = params.require(:visited_link).permit(:url)[:url].to_s.strip
  return head :bad_request if url.blank? or url.length > 2048
  VisitedLink.upsert({ user_id: current_user.id, url: url },
                     unique_by: [:user_id, :url])
  head :no_content   # 204 — JS does not need a response body
```

### Gadget AJAX load → visited-class on content links

```
portalLazy drains column → $.get('/feeds/42', format: 'html')
  ↓
FeedsController#show
  @feed = Feed.find(42)
  @visited_urls = VisitedLink.urls_for(current_user)
    → Set of url strings for this user
  render layout: !request.xhr?
  ↓
feeds/show.html.erb
  @feed.entries.each do |e|
    link_to e.title, e.url,
            class: visited_link_class(@visited_urls, e.url),
            **link_opts
  ↓
HTML returned: <a href="https://…" class="link--visited">Article title</a>
  ↓
$.get callback: $('#feed_42').html(html)
  ↓
Link renders with grey/dimmed "visited" style
```

### Cross-device sync

```
Device A: user clicks link → POST /visited_links → row stored in DB
Device B: user loads welcome page → gadget AJAX → FeedsController#show
  → @visited_urls includes the url from Device A's click
  → link renders with .link--visited
```

---

## New File: `app/assets/javascripts/visited_links.js`

This is a **new file** following the IIFE + `window.visitedLinks` pattern
used by other files in this pipeline (`portal_lazy.js`, `feeds.js`).

```js
// app/assets/javascripts/visited_links.js
window.visitedLinks = window.visitedLinks || {};
const visitedLinks = window.visitedLinks;

(function () {
  'use strict';

  // Path written by a data attribute on <body> or hard-coded as a constant.
  // Use a data attribute to avoid hard-coding the Rails route in JS.
  // <body data-visited-links-path="<%= visited_links_path %>"> in layout.

  function getPostPath() {
    return document.body.getAttribute('data-visited-links-path') || '/visited_links';
  }

  $(document).on('click', '.gadget a[href]', function () {
    const $a = $(this);
    const href = $a.attr('href');
    if (!href || href.charAt(0) === '#') return;   // skip fragment-only links

    $a.addClass('link--visited');

    // Retrieve CSRF token from <meta name="csrf-token"> (Rails standard)
    const token = $('meta[name="csrf-token"]').attr('content');

    $.post({
      url: getPostPath(),
      data: { visited_link: { url: href } },
      headers: { 'X-CSRF-Token': token },
    }).fail(function (xhr) {
      // Non-critical: server failure does not affect navigation.
      // Silently ignore; link remains visually marked on this device.
      if (window.console && xhr.status !== 0) {
        console.warn('visited_links: record failed', xhr.status);
      }
    });
  });
}());
```

**Design decisions:**

1. **Delegated handler on `$(document)`** — gadget content is injected via
   AJAX after DOM ready. A static handler on `.gadget a` would miss
   dynamically injected links. Delegation on `document` catches all gadget
   links regardless of injection order.

2. **Fire-and-forget with optimistic local toggle** — the user should never
   wait for the network round-trip before the link opens. `$.post` is
   dispatched and the class is added immediately. If the POST fails the link
   still navigates normally; the visited state is just not recorded.

3. **CSRF token from `<meta>` tag** — Rails UJS / Turbo already writes
   `<meta name="csrf-token">` in the layout. Reading it in JS is the
   established pattern in this codebase (Rails convention, works with
   `protect_from_forgery`).

4. **`data-visited-links-path` on `<body>`** — avoids hard-coding
   `/visited_links` in JS, matches the Rails route helper convention, and
   keeps the JS testable without a server.

5. **Fragment-only link guard** — `href.charAt(0) === '#'` skips in-page
   anchor links which should not be recorded.

6. **No new JS global API surface** — `window.visitedLinks` is allocated but
   no methods are exposed yet. If future phases need programmatic access
   (e.g., bulk-mark), the object is already namespaced.

---

## New File: `app/models/visited_link.rb`

```ruby
class VisitedLink < ApplicationRecord
  URL_MAX_LENGTH = 2048

  belongs_to :user

  validates :url, presence: true, length: { maximum: URL_MAX_LENGTH }

  # Returns a Set of url strings visited by the given user.
  # A Set gives O(1) membership test in views.
  def self.urls_for(user)
    where(user_id: user.id).pluck(:url).to_set
  end
end
```

**Why `Set` not `Array`:** Each show view iterates `display_count` links
(default 5, max ~20) and calls `visited_link_class(set, url)` per link.
`Set#include?` is O(1); `Array#include?` is O(n). For a user with hundreds of
visited URLs, the difference is meaningful. `pluck(:url).to_set` materializes
once per gadget show request.

**Why no `has_many` on User:** The `VisitedLink` model is accessed through
`VisitedLink.urls_for(user)` directly. Adding `has_many :visited_links` to
`User` is optional and not needed for v1.26 functionality.

---

## New File: `app/controllers/visited_links_controller.rb`

```ruby
class VisitedLinksController < ApplicationController
  def create
    url = visited_link_params[:url].to_s.strip
    return head :bad_request if url.blank? || url.length > VisitedLink::URL_MAX_LENGTH

    VisitedLink.upsert(
      { user_id: current_user.id, url: url },
      unique_by: [:user_id, :url]
    )

    head :no_content
  end

  private

  def visited_link_params
    params.require(:visited_link).permit(:url)
  end
end
```

**Why `upsert` not `find_or_create_by`:** `upsert` is a single SQL
`INSERT ... ON DUPLICATE KEY UPDATE` (MySQL). `find_or_create_by` issues a
SELECT then conditionally an INSERT — two round-trips and a TOCTOU race.
`upsert` with `unique_by:` is both faster and race-safe. The `unique_by`
constraint matches the `UNIQUE INDEX (user_id, url)` on the table.

**Why `head :no_content` (204):** The JS caller uses fire-and-forget. No
response body is consumed. 204 is the correct semantic for a write that
produces no response entity.

**Authentication:** `authenticate_user!` is inherited from `ApplicationController`
as a `before_action`. No explicit guard needed.

---

## New Migration

```ruby
# db/migrate/20260518XXXXXX_create_visited_links.rb
class CreateVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :visited_links do |t|
      t.integer :user_id, null: false
      t.string  :url,     null: false, limit: 2048

      t.timestamps
    end

    add_index :visited_links, [:user_id, :url], unique: true
    add_index :visited_links, :user_id
  end
end
```

**No `belongs_to` foreign key constraint:** consistent with `feeds`, `notes`,
and other user-scoped tables in this codebase which use `user_id :integer NOT NULL`
without an explicit FK constraint (no `add_foreign_key`).

---

## New Route

```ruby
# config/routes.rb addition
resources :visited_links, only: [:create]
```

This yields `POST /visited_links` → `VisitedLinksController#create` and the
named helper `visited_links_path`.

---

## New Helper: `ApplicationHelper#visited_link_class`

```ruby
# app/helpers/application_helper.rb
def visited_link_class(visited_urls, url)
  visited_urls&.include?(url) ? 'link--visited' : ''
end
```

Lives in `ApplicationHelper` because it is used across three controllers'
views (feeds, mastodon_accounts, x_accounts). No new helper file needed.

---

## Modified: Show Views

All three show views use an identical pattern. The only structural change is
adding `class: visited_link_class(@visited_urls, url)` to content `link_to`
calls.

**`feeds/show.html.erb` — before:**
```erb
<li><%= link_to e.title, e.url, link_opts %></li>
```

**after:**
```erb
<li><%= link_to e.title, e.url, **link_opts, class: visited_link_class(@visited_urls, e.url) %></li>
```

The feed title link (`link_to @feed.title, @feed.url`) is a meta-link to the
feed source site. Record-keeping this is debatable — it is not a content item
URL. **Recommendation: do not apply visited-class to gadget title links.** Only
content item links (the `ol li` links) should carry the visited class.

The same pattern applies to `mastodon_accounts/show.html.erb` (for
`item[:url]`) and `x_accounts/show.html.erb` (for `item[:url]`).

**No change to the gadget skeleton partials** (`_feed.html.erb`,
`_mastodon_account.html.erb`, `_x_account.html.erb`). The skeleton only
emits a loading placeholder and the `portalLazy.register` script. Visited
state belongs in step 2 (the AJAX-injected HTML from the show actions), not
in step 1 (the skeleton).

---

## Modified: Show Controllers — `@visited_urls` Assignment

```ruby
# FeedsController#show (existing)
def show
  if @feed.feed?
    @visited_urls = VisitedLink.urls_for(current_user)   # NEW
    render layout: !request.xhr?
  else
    render plain: @feed.status, status: @feed.status
  end
end
```

Same pattern for `MastodonAccountsController#show` and
`XAccountsController#show`: assign `@visited_urls` before the `render` call.

**Why an instance variable, not a helper method that queries inline:**
Instance variables in Rails are the standard channel from controller to view.
A helper that queries the DB would hide the DB call from the controller, making
it harder to test and to reason about N+1 patterns. Assigning once in the
controller and passing through `@visited_urls` is the established pattern in
this codebase (see `@mastodon_items`, `@x_items`, `@x_error`).

**Why not a `before_action`:** Only the show actions that render gadget content
need this query. `index`, `create`, `update`, `destroy` do not render content
links. A targeted assignment in `show` is cleaner than a broad `before_action`
with an `only:` guard on three separate controllers.

---

## Modified: Layout — `data-visited-links-path`

```erb
<!-- app/views/layouts/application.html.erb -->
<!-- add data attribute to <body> tag, inside user_signed_in? guard or unconditionally -->
<body data-visited-links-path="<%= user_signed_in? ? visited_links_path : '' %>">
```

The JS reads this attribute. If blank (unauthenticated), the handler still
fires but `$.post` sends to `''` which Rails will reject — however
`authenticate_user!` will intercept first and return 401/redirect. The `$.post`
failure is silently ignored. An alternative is to only initialize the click
handler when the user is signed in, but that requires more complex JS. The
simplest approach: always write the path if signed in, empty string if not.

Alternatively, the path could be hard-coded as `/visited_links` in JS without
the data attribute. Given that this is a personal app with a stable URL
structure, hard-coding is acceptable. The data-attribute approach is documented
here as the preferred pattern for maintainability.

---

## Modified: CSS — `.link--visited`

```scss
// app/assets/stylesheets/common.css.scss
// Visited link style — applies across all gadgets and themes
a.link--visited {
  color: var(--link-visited-color, #808080);
  opacity: 0.7;
}
```

The style belongs in `common.css.scss` (not a theme file) because:
1. All three themes render gadget content through the same show views.
2. The `body.no-icons` pattern (v1.23) established `common.css.scss` as the
   place for cross-theme functional state classes.
3. CSS custom property fallback (`var(--link-visited-color, #808080)`) allows
   theme files to override the color without duplicating the structural rule.

**Do not use the native browser `:visited` pseudo-class** for this feature.
`:visited` is intentionally sandboxed by browsers (color-only, no computed
style access, no JS detection) to prevent privacy fingerprinting. Our server-
side tracking is independent and cross-device; the class-based approach is the
correct tool here.

---

## What Changes vs What Stays the Same Per Gadget File

### Feed gadget

| File | Change | Reason |
|------|--------|--------|
| `app/views/welcome/_feed.html.erb` | None | Step-1 skeleton; no content links |
| `app/controllers/feeds_controller.rb` | Add `@visited_urls = VisitedLink.urls_for(current_user)` in `show` | Supply data to view |
| `app/views/feeds/show.html.erb` | Add `class: visited_link_class(@visited_urls, e.url)` to each entry `link_to` | Render visited class |
| `app/services/` (Feed parsing) | None | Data flow unchanged |

### Mastodon gadget

| File | Change | Reason |
|------|--------|--------|
| `app/views/welcome/_mastodon_account.html.erb` | None | Step-1 skeleton |
| `app/controllers/mastodon_accounts_controller.rb` | Add `@visited_urls` in `show` | Supply data to view |
| `app/views/mastodon_accounts/show.html.erb` | Add `class: visited_link_class(@visited_urls, item[:url])` | Render visited class |

### X account gadget

| File | Change | Reason |
|------|--------|--------|
| `app/views/welcome/_x_account.html.erb` | None | Step-1 skeleton |
| `app/controllers/x_accounts_controller.rb` | Add `@visited_urls` in `show` | Supply data to view |
| `app/views/x_accounts/show.html.erb` | Add `class: visited_link_class(@visited_urls, item[:url])` | Render visited class |

### JS coordinator (unchanged)

| File | Change |
|------|--------|
| `app/assets/javascripts/portal_lazy.js` | None — load lifecycle unchanged |
| `app/assets/javascripts/portal_mobile_tabs.js` | None |
| `app/assets/javascripts/application.js` | None — `require_tree .` picks up new `visited_links.js` automatically |

---

## Build Order

Dependencies flow: data layer → server endpoint → CSS → JS → view wiring.
Each phase is independently verifiable at the green-bar gate.

### Phase 1 — Data Layer

**Scope:** migration + model + route + controller.

1. Migration: `create_table :visited_links` with `user_id`, `url`, UNIQUE index.
2. `VisitedLink` model: `belongs_to :user`, `validates :url`, `urls_for(user)` scope.
3. Route: `resources :visited_links, only: [:create]`.
4. `VisitedLinksController#create`: authenticate (inherited), upsert, 204.
5. Minitest: `visited_link_test.rb` (model validations, `urls_for`), `visited_links_controller_test.rb` (create success, duplicate idempotent, blank url rejected, unauthenticated redirected).

**Why first:** Everything downstream depends on the table existing and the
POST endpoint accepting data. The JS and view layers can be tested in
isolation once the server side is correct.

**Verification gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`
(no E2E behavior change yet — no links emit the class, no JS fires).

### Phase 2 — CSS + Helper

**Scope:** `.link--visited` rule + `ApplicationHelper#visited_link_class`.

1. `common.css.scss`: add `a.link--visited { color: ...; opacity: ...; }`.
2. `ApplicationHelper#visited_link_class(visited_urls, url)`.
3. Minitest: helper unit test (returns `'link--visited'` for known URL,
   `''` for unknown, `''` for nil set).

**Why second:** The class must exist in CSS before views emit it. Having the
helper tested in isolation before it is wired into show views catches bugs
early.

**Verification gate:** tri-suite green (still no visible change in gadgets).

### Phase 3 — Show View Wiring

**Scope:** Assign `@visited_urls` in the three show controllers; add
`class: visited_link_class(...)` to content link_to calls in three show views.

1. `FeedsController#show`: assign `@visited_urls`.
2. `feeds/show.html.erb`: add `class:` to entry links.
3. `MastodonAccountsController#show`: assign `@visited_urls`.
4. `mastodon_accounts/show.html.erb`: add `class:` to item links.
5. `XAccountsController#show`: assign `@visited_urls`.
6. `x_accounts/show.html.erb`: add `class:` to item links.
7. Minitest: extend each controller test to assert `.link--visited` class
   present for a pre-seeded visited URL; assert class absent for unvisited URL.

**Why third:** Controller + view changes are tightly coupled; do them together
per gadget. The helper from Phase 2 is already tested, so view-level tests only
need to assert the integration (class is in the rendered HTML).

**Verification gate:** tri-suite green. Manual: load welcome page, confirm no
visited class on any links (no visits recorded yet). Seed a `VisitedLink` row
in test fixture and verify class appears.

### Phase 4 — JS Click Handler

**Scope:** `visited_links.js` + body data attribute in layout.

1. `app/assets/javascripts/visited_links.js`: IIFE, delegated click on
   `.gadget a[href]`, `$.post` fire-and-forget, optimistic `addClass`.
2. `app/views/layouts/application.html.erb`: add
   `data-visited-links-path="<%= visited_links_path %>"` to `<body>` (inside
   `user_signed_in?` guard, or unconditionally with empty-string fallback).
3. Minitest: JS contract test (file contains delegated handler pattern,
   contains `data-visited-links-path` reference, contains `link--visited`,
   contains CSRF token read).
4. Cucumber: extend an existing gadget scenario (e.g., `05.Mastodon.feature`)
   to click a link and assert the POST was intercepted (or assert the class is
   applied). This requires a WebMock stub for the POST to `/visited_links` in
   the `@mastodon_gadget` hook.

**Why fourth:** JS depends on the POST endpoint (Phase 1), the CSS class
(Phase 2), and the show views emitting pre-visited classes (Phase 3). Building
JS last means end-to-end manual verification is possible in a single session:
click a link, reload, see the visited class on next gadget load.

**Verification gate:** tri-suite green. Manual smoke:
- Open welcome page, open network tab.
- Click a feed link → POST `/visited_links` fires, 204 response.
- Link gets `.link--visited` class immediately (optimistic).
- Hard-reload page → gadget AJAX re-injects content → link has `.link--visited`
  class from server-side set.
- Sign in on a second device → same URL has `.link--visited`.

---

## Integration Points

### `application.js` — Sprockets `require_tree .`

`visited_links.js` is picked up automatically by `require_tree .` in
`application.js`. No manifest change needed. Alphabetical sort places
`visited_links.js` after `todos.js` and `welcome.css.scss` — no load-order
dependency exists.

### `protect_from_forgery` and CSRF

`ApplicationController` uses `protect_from_forgery with: :exception`.
The `$.post` in `visited_links.js` must include the CSRF token. Two options:

1. **Read from `<meta name="csrf-token">`** — standard Rails UJS approach,
   works with `rails-ujs` already included in `application.js`.
2. **jQuery `ajaxSetup`** — set a global header for all `$.ajax` calls.

Option 1 is recommended: it is explicit and does not affect other AJAX calls
(feed loading, welcome save-state). The `$.post` call includes
`headers: { 'X-CSRF-Token': token }`.

### `open_links_in_new_tab` preference

The show views already compute `link_opts` from `current_user.preference.open_links_in_new_tab?`
and spread it into `link_to`. The `class:` addition must be merged, not
overwrite, the existing `link_opts`:

```erb
<%= link_to e.title, e.url, **link_opts, class: visited_link_class(@visited_urls, e.url) %>
```

The double-splat merge in Ruby passes both `target:` and `class:` to `link_to`.
This is safe: `link_opts` does not include a `class:` key today.

### `portalLazy` AJAX lifecycle

The click handler fires on `.gadget a[href]` links, which only exist after
step 2 (AJAX injection). This is safe because the delegated handler is
registered on `$(document)` at parse time, which captures events from
dynamically injected children. No change to `portal_lazy.js` or
`portal_mobile_tabs.js` is required.

### WebMock in Cucumber

Cucumber uses `WebMock.stub_request` for `@mastodon_gadget` and `@x_gadget`
hooks. The `POST /visited_links` call goes to the local Rails test server
(localhost), which `WebMock` allows by default (`allow_localhost: true` in
`test/support/webmock.rb`). No new stub is required for the controller to
receive the POST.

However, any Cucumber scenario that actually clicks a content link and expects
the POST to be received will need the `visited_links` route to exist and
`VisitedLinksController` to be loaded (both are true after Phase 1). No
WebMock changes required.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Rendering visited set in the skeleton partial

**What people do:** Pass `@visited_urls` into `WelcomeController#index`, assign
from there, pass into `_feed.html.erb`, etc.

**Why wrong:** The skeleton partials do not render content links. Adding
`@visited_urls` to `WelcomeController#index` adds a DB query on every page load,
even when gadget content is not rendered (the skeleton is rendered, not the
content). The query belongs in the show actions that actually render links.

**Do this instead:** Assign `@visited_urls` only in `FeedsController#show`,
`MastodonAccountsController#show`, `XAccountsController#show`. These are the
actions that render the content links and they only fire per-gadget on AJAX.

### Anti-Pattern 2: `find_or_create_by` with race condition

**What people do:** `VisitedLink.find_or_create_by(user_id: ..., url: ...)`

**Why wrong:** SELECT + conditional INSERT is a TOCTOU race. Two concurrent
clicks on the same link (or two devices) can create duplicate rows if the
UNIQUE index is not respected. Rails `find_or_create_by` handles this with a
rescue-and-retry but the code is more complex and slower.

**Do this instead:** `VisitedLink.upsert({ user_id:, url: }, unique_by: [:user_id, :url])`.
Single SQL statement, atomic, duplicate-safe.

### Anti-Pattern 3: Synchronous wait for POST before navigation

**What people do:** `e.preventDefault(); $.post(...).done(() => { location.href = href; })`

**Why wrong:** The user waits for a network round-trip before the link opens.
On a slow connection this is a significant UX regression.

**Do this instead:** Fire `$.post` and `addClass` without `preventDefault()`.
The link navigates immediately; the POST completes in the background.

### Anti-Pattern 4: Storing full visited set in a JS global

**What people do:** Fetch all visited URLs from the server and cache in JS;
mark links on the client side without re-rendering.

**Why wrong:** Breaks cross-device sync (JS cache is per-tab), requires a
new JSON endpoint, adds client-side state complexity, and contradicts the
project's server-rendered-first principle.

**Do this instead:** Server embeds visited class at render time (step 2).
Client-side optimistic toggle (immediate `addClass` on click) is only for the
current-click link before the next reload. Full sync happens server-side.

### Anti-Pattern 5: `$.post` inside the delegated handler without CSRF token

**What people do:** `$.post('/visited_links', { url: href })` without a header.

**Why wrong:** Rails `protect_from_forgery with: :exception` will raise
`ActionController::InvalidAuthenticityToken` and return 422.

**Do this instead:** Read `$('meta[name="csrf-token"]').attr('content')` and
pass as `headers: { 'X-CSRF-Token': token }` in the `$.post` options hash.

---

## Sources

- Direct inspection: all files listed in the "What Changes vs What Stays the Same" tables above
- Direct inspection: `app/assets/javascripts/portal_lazy.js`
- Direct inspection: `app/views/welcome/_dashboard.html.erb`, `_portal_column_section.html.erb`
- Direct inspection: `config/routes.rb`, `app/controllers/application_controller.rb`
- Direct inspection: `db/schema.rb` (table patterns for `feeds`, `notes`, `mastodon_accounts`)
- Direct inspection: `app/models/preference.rb`, `app/models/crud/by_user.rb`
- Direct inspection: `test/support/webmock.rb` (allow_localhost pattern)
- Project policy: `.planning/PROJECT.md`, `CLAUDE.md`
- Prior art: v1.24 `ARCHITECTURE.md` (portalLazy coordinator design, Sprockets load-order, column_index passing pattern)

---
*Architecture research for: Visited Link Tracking (v1.26)*
*Researched: 2026-05-18*
