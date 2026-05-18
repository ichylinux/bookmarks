# Feature Research — v1.26 Visited Link Tracking

**Project:** Bookmarks v1.26
**Domain:** Visited/read-state tracking in a personal single-user feed aggregator
**Researched:** 2026-05-18
**Confidence:** HIGH (codebase read directly; domain patterns confirmed by multiple sources; single-user context eliminates multi-tenancy complexity)

---

## Context: What Already Exists

Before mapping features, the precise shape of the existing system constrains every option.

**Links that need visited tracking appear in three gadget types:**

| Gadget | View partial | Link structure | URL source |
|--------|-------------|----------------|------------|
| Feed | `feeds/show.html.erb` | `link_to e.title, e.url` for each entry | RSS/Atom entry URL (external) |
| Mastodon | `mastodon_accounts/show.html.erb` | `link_to item[:text], item[:url]` for each toot | Expanded URL from toot body |
| X (Twitter) | `x_accounts/show.html.erb` | `link_to item[:text], item[:url]` for each tweet | t.co-expanded URL from tweet |

All three partials also render a header link (`link_to gadget.title, gadget.profile_url`) pointing to the source account/feed — this is structural navigation, not content.

All three partials are loaded via AJAX into the `.gadget` container div after `portalLazy` fires the column-activate sequence. The partials render pure HTML (no JS inline scripts) — all JS is in the placeholder `_feed.html.erb` / `_mastodon_account.html.erb` / `_x_account.html.erb` partials on the welcome page.

Links open in the same tab or a new tab based on `preferences.open_links_in_new_tab`. The click event fires **before** the browser navigates, making a synchronous XHR/fetch call feasible.

**No visited URL store exists yet.** The schema has no `visited_urls` or equivalent table.

---

## Feature Landscape

### Table Stakes (Users Expect These)

These are the features the milestone is incomplete without. In the context of feed readers and link-rich dashboards, users have a strong mental model from browser `:visited` history, RSS readers (Miniflux, Feedly, FreshRSS), and read-later apps (Pocket, Instapaper): once you have seen something, it looks different. Missing this = the milestone delivers nothing.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Record visit on link click** | Users expect the action that causes a "visited" state to be the click itself — the moment they choose to open the link. Recording on scroll-past or hover would be surprising. "On click" is the universal convention from browser history and every feed reader surveyed. | LOW | JS click handler on `<a>` inside `.gadget`; fires POST to a new endpoint before (or concurrently with) navigation. `event.preventDefault()` not needed — fire and forget via `fetch` or `$.ajax`. No blocking of navigation. |
| **Visited links render visually distinct** | The entire value proposition of the feature. Without this, recording visits has no user-visible effect. Visual distinction must be unambiguous but not jarring — a muted color or opacity change is the established convention (browser `:visited` uses purple; Google Search uses red-shifted blue). A CSS class on `<a>` elements is the correct implementation surface given the SSR-partial-then-AJAX-replacement pattern. | LOW | Add `visited` CSS class to `<a>` elements when rendering partials. The AJAX-replaced HTML is freshly rendered server-side, so the server can apply the class based on DB lookup. No client-side class manipulation needed at render time. |
| **Cross-device persistence** | The PROJECT.md requirement explicitly calls this out. Without server-side storage, visited state lives only in browser history (per-device, non-transferable). The whole point of server-side recording is that any device shows the same state. | MEDIUM | New `visited_urls` table: `user_id`, `url` (TEXT/string), `created_at`. Unique index on `(user_id, url)`. On render, server checks which URLs in the current gadget's items are in the visited set and adds `class="visited"` to those `<a>` tags. |
| **URL normalization / deduplication across gadgets** | The same article URL may appear in a feed entry AND as a link inside a Mastodon toot (e.g., a shared blog post). If a user clicks it in the feed gadget, the Mastodon gadget should also show it as visited. This is the correct behavior: a URL is a URL regardless of which gadget surface it appeared in. Users will notice and be confused if two gadgets show different visited states for the same URL. | LOW | Store the canonical URL string as the dedup key. The unique index on `(user_id, url)` handles this — `INSERT ... ON DUPLICATE KEY UPDATE created_at = created_at` (MySQL no-op upsert) or `upsert` in Rails. The click handler fires the URL as-is; the server stores it. No URL normalization strategy needed at MVP — the URLs from feeds and gadgets are already expanded (t.co expansion is done server-side in XClient). |

### Differentiators (Not Required, But Valuable)

These improve the feature beyond the core spec. For a personal single-user app, the bar for "worth building" is higher than for a product competing in the market — time investment must pay off in daily use.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Per-gadget visited count badge** | Shows "5 unread" or "3 visited" on the gadget header. Useful for quickly knowing which feeds have new content. FreshRSS and Feedly both do this at the feed level. | MEDIUM | Requires counting visited URLs per gadget on the server during the `show` action render. The count is the number of items in the current gadget that are in the visited set — not a total visit count. Only useful if there are enough items (5+) that scanning for visual change is slower than reading a number. With `display_count` typically 5–10 items, scanning is instant. **For v1.26 this is likely not worth the query complexity.** |
| **Visited count / last-visited timestamp on gadget management pages** | On `/feeds`, show "last visited: 3 days ago" to help users audit which feeds they actually read. | MEDIUM | Requires an additional query on management index pages. Mildly useful for pruning stale feeds. Can be added later without schema changes. |
| **Mark all as read (bulk)** | One button clears the visual distinction for all items in a gadget or all gadgets. Common in email and feed readers. | MEDIUM | For a single-user personal tool with small item counts (5–10 per gadget), the practical need is low — you already see all items and can click them manually if you want to clear them. The main use case is "I know I won't read these, clear the state." Given the app has no unread count badge driving urgency, this is low-value for v1.26. |
| **Visit expiry / auto-cleanup** | Old visited records deleted after N days (e.g., 90 days) via a periodic job. Prevents unbounded table growth. | LOW-MEDIUM | A personal single-user app generates at most ~50 link clicks/day across all gadgets. At 365 days × 50 clicks = 18,250 rows/year. This is a trivially small table. MySQL handles millions of rows on a simple `(user_id, url)` key without issues. Auto-cleanup is an anti-feature at this scale — it introduces a scheduled job (Sidekiq, Whenever) for zero perceptible benefit. **Defer indefinitely.** |
| **Unmark / mark as unvisited** | Allow user to mark a visited link as unvisited (restore the unread appearance). Some feed readers offer this. | LOW | Right-click or hover-action to remove a visit record. Adds interaction complexity for minimal gain in a personal tool where content cycles quickly. If a user wants to revisit something, they can just click it again — no UX need to un-mark it. Anti-feature at v1.26. |

### Anti-Features (Explicitly Not This Milestone)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Visit expiry / scheduled cleanup job** | Table is tiny for a single user. A scheduled job (Sidekiq, Whenever gem, cron) adds infrastructure dependency for no user-visible benefit. The `visited_urls` table will not grow large enough to matter for a personal app. | Leave table unbounded. If row count ever becomes a concern, add a manual rake task. |
| **Per-gadget unread counts / badges** | Adds query complexity to the AJAX render path (one extra DB round-trip per gadget) and is only useful if item counts are high enough that visual scanning is slow. With 5–10 items per gadget, the user sees the visual change instantly. Counts add UI noise without improving navigation. | Let the visited CSS class alone communicate state. |
| **Bulk mark-all-read** | For a personal tool with ~5–10 items per gadget, bulk clear is overkill. The feature makes sense in email (hundreds of messages) not in a focused feed dashboard. Adds a button that needs localization, confirmation UX, and tests, for a use case that rarely occurs. | Click individual visited links to implicitly maintain state. |
| **Visit analytics / history page** | A dedicated history page showing "you visited X at Y time" is a product feature for apps where history is the product (browser, analytics tools). In this app, the goal is only visual state differentiation on the dashboard. | No history page. The DB table is purely internal. |
| **Unmark visited / toggle state** | Individual visited items rarely need to be un-marked. Adds interaction surface (right-click? hover button?) that complicates the rendering and interaction model. The value is near zero in practice. | Accept that visited state is write-only from the user's perspective. |
| **URL normalization (strip query params, canonicalize)** | Normalizing URLs before storing (strip `?utm_*`, lowercase, etc.) would cause mismatches when the same URL appears with and without tracking params. Since t.co expansion already happens server-side, and RSS entry URLs are canonical by design, normalization would over-engineer for edge cases. | Store URLs exactly as served by each gadget's data source. The unique index on raw URL string is sufficient. |
| **Client-side `:visited` CSS as fallback** | CSS `:visited` is browser-local and not cross-device. It also has security restrictions that prevent reading whether a link has been visited via JS. It cannot serve as a fallback or complement — it would show different state from the server-side record. | Use only the server-side CSS class approach. Disable or ignore browser `:visited` styling in gadget CSS. |
| **Real-time push to other open tabs/devices** | ActionCable / WebSocket push of visited state to other open sessions. Sounds nice, adds significant infrastructure (Action Cable, Redis or async adapter). For a personal single-user app, the user has one active session at a time in practice. | Cross-device sync happens on next page load — the server-rendered AJAX partial reflects current DB state. No real-time push needed. |
| **New JS dependency or bundler change** | PROJECT.md explicitly forbids new npm packages and bundler migration. The click handler must use jQuery (already available) or vanilla `fetch` (available in all supported browsers). | Use existing jQuery `.on('click')` delegation or vanilla `fetch` for the POST request. |

---

## Feature Dependencies

```
[visited_urls table + VisitedUrl model]
    └──required by──> [Record visit on click (server endpoint)]
    └──required by──> [Visited CSS class on render (server lookup)]

[Record visit on click]
    └──requires──> [JS click handler on gadget <a> elements]
    └──requires──> [POST /visited_urls endpoint]

[Visited CSS class on render]
    └──requires──> [feeds/show, x_accounts/show, mastodon_accounts/show partial update]
    └──requires──> [visited_urls lookup during AJAX show action]

[JS click handler]
    └──hooks into──> [portalLazy / AJAX-loaded gadget content]
    └──must not block──> [link navigation (open_links_in_new_tab preference)]

[URL dedup across gadgets]
    └──free from──> [unique index on (user_id, url)]
    └──no extra work beyond──> [Record visit on click]
```

### Dependency Notes

- **visited_urls table is the foundation.** All other features depend on it. It must come before the JS click hook and before the render-time lookup.
- **AJAX partial render path determines lookup timing.** The `feeds#show`, `mastodon_accounts#show`, and `x_accounts#show` actions already query external APIs; adding a `VisitedUrl.where(user_id:, url: urls).pluck(:url)` call is a single additional DB read per gadget render. This is cheap and appropriate.
- **JS click handler must tolerate AJAX-loaded content.** Gadget content is injected into the DOM after `$(document).ready` — the click handler cannot be bound at document-ready on static DOM. It must use event delegation: `$(document).on('click', '.gadget ol li a', handler)` or equivalent.
- **open_links_in_new_tab has no impact on tracking.** The click fires whether the link opens in the same tab or a new tab. A `target="_blank"` link fires the click event before the browser opens the new tab. Fire-and-forget POST works for both.
- **Deduplication is free.** The unique index on `(user_id, url)` plus a MySQL `INSERT IGNORE` or Rails `upsert` handles the same URL clicked multiple times and the same URL appearing in multiple gadgets. No application-level dedup logic needed.

---

## MVP Definition

### Build in v1.26

- [x] `visited_urls` table: `id`, `user_id` (NOT NULL), `url` (VARCHAR or TEXT, NOT NULL), `created_at` — unique index on `(user_id, url)` (or composite with a hash column if URL length exceeds MySQL index limit)
- [x] `VisitedUrl` model: `belongs_to :user`, `validates :url, presence: true`, `validates :url, uniqueness: { scope: :user_id }`
- [x] `POST /visited_urls` endpoint: `current_user` scoped, accepts `url` param, upserts (insert-ignore pattern), returns 200/204 — no body needed
- [x] JS click handler: event-delegated on `.gadget ol li a`; fires async POST to `/visited_urls` with the `href`; does not prevent default navigation
- [x] Server-side visited lookup in each gadget's `show` action: load current item URLs, query `VisitedUrl` for matches, pass a `visited_urls` set to the view
- [x] CSS class `visited` on `<a>` tags in all three `show` partials when URL is in the visited set
- [x] SCSS rule for `.gadget a.visited`: muted color / opacity to distinguish from unvisited links; consistent across all three themes

### Explicitly Defer

- Per-gadget unread count badges — query overhead not justified at 5–10 items per gadget
- Bulk mark-all-read — not needed for personal tool with small item counts
- Visit expiry/cleanup — table will not grow to problematic size for a single user
- Mark as unvisited / toggle — adds interaction complexity with no practical use case
- History page — out of scope; visited state is a rendering hint, not a browsable log
- Real-time cross-tab push — page reload is sufficient for cross-device sync

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| visited_urls table + model | HIGH (foundation) | LOW | P1 |
| POST endpoint (record visit) | HIGH | LOW | P1 |
| JS click handler | HIGH | LOW | P1 |
| Visited CSS class in partials | HIGH | LOW | P1 |
| Server-side visited lookup on render | HIGH | LOW | P1 |
| SCSS `.visited` style (all themes) | HIGH | LOW | P1 |
| URL dedup across gadgets | HIGH | FREE (index) | P1 |
| Per-gadget visited count badge | LOW | MEDIUM | P3 |
| Bulk mark-all-read | LOW | MEDIUM | P3 |
| Visit expiry job | NONE at this scale | MEDIUM | Never |
| History page | LOW | HIGH | Never |
| Real-time push | LOW | HIGH | Never |

---

## Implementation Constraints From Existing Code

These are hard constraints, not preferences:

1. **MySQL, not PostgreSQL.** The upsert pattern is `INSERT INTO visited_urls ... ON DUPLICATE KEY UPDATE id = id` or Rails `upsert` with `on_duplicate: :skip`. ActiveRecord `upsert` / `insert_or_ignore` is available in Rails 6+.

2. **URL column length.** MySQL VARCHAR index key limit is 767 bytes (utf8mb4: 191 chars for 3072-byte row format, or up to 3072 bytes with `innodb_large_prefix`). RSS entry URLs can exceed 191 characters. Options: use TEXT column (non-indexable directly) + add a separate `url_hash` VARCHAR(64) column for the unique index; or use VARCHAR(2048) with a prefix index; or use Rails `add_index` with `length:`. The safest MySQL-compatible approach: store `url` as TEXT, add `url_digest` VARCHAR(64) with a unique index on `(user_id, url_digest)`, where `url_digest = Digest::SHA256.hexdigest(url)`. Application generates the digest before insert.

   Alternative simpler approach: VARCHAR(2048) with prefix index `add_index :visited_urls, [:user_id, :url], unique: true, length: { url: 191 }`. This silently truncates URLs longer than 191 bytes, which can cause false deduplication. Not recommended.

   **Recommended: url + url_digest column with SHA256 hash for unique index.**

3. **JS event delegation is required.** Gadget content is AJAX-injected. Static `$(element).on('click')` won't work. Must use `$(document).on('click', '.gadget ol li a', fn)` pattern — already established in the codebase for other delegated events.

4. **No new npm packages / no bundler changes.** The POST can use `$.ajax({ method: 'POST', url: visitedUrlsPath, data: { url: href, authenticity_token: token } })`. Rails CSRF token is available in the meta tag (`$('meta[name="csrf-token"]').attr('content')`).

5. **The gadget header link (feed title, @account name) should NOT be tracked.** Only content item links — the `<ol><li><a>` links — should record visits. The header link is structural navigation, not content consumption.

6. **Ja/en locale strings needed.** The visited link label (if any tooltip or ARIA label is added) needs both locales. The POST endpoint itself needs no locale strings. The SCSS visited style needs none.

---

## Sources

- Codebase read directly: `app/views/feeds/show.html.erb`, `app/views/x_accounts/show.html.erb`, `app/views/mastodon_accounts/show.html.erb`, `app/views/welcome/_feed.html.erb`, `db/schema.rb`, `app/models/preference.rb`
- [Revisiting :visited — Joel Califa](https://joelcalifa.com/blog/revisiting-visited/) — visited link UX patterns, CSS `:visited` limitations
- [Miniflux mark-as-read UX issue #453](https://github.com/miniflux/v2/issues/453) — feed reader read-state conventions
- [Links and the Visited State — Baymard Institute](https://baymard.com/blog/links-visited-state) — user expectation for visited link visual differentiation
- [RSS feed deduplication patterns — FlipRSS/Medium](https://medium.com/fliprss/introducing-rss-feed-deduplication-28f86708ce5c) — URL dedup approaches
- [Unread Message Indicators — myshyft.com](https://www.myshyft.com/blog/unread-message-indicators/) — read-state UX conventions in dashboards

---

*Feature research for: visited link tracking in personal RSS/social feed dashboard*
*Researched: 2026-05-18*
