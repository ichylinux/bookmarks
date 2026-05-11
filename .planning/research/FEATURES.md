# Features Research — Mastodon Account Following

**Domain:** Read-only Mastodon feed gadget in a personal Rails bookmarks app
**Researched:** 2026-05-12
**Confidence:** HIGH for API shape; MEDIUM for rate limit specifics (instance-variable)

---

## Mastodon Public API

### Two-step lookup: username → account ID → statuses

Mastodon does not allow fetching statuses directly by username. The required flow is:

**Step 1 — Resolve account ID by handle**

```
GET https://{instance}/api/v1/accounts/lookup?acct={username}
```

- `acct` parameter accepts bare username (for local accounts) or `username@domain` (for remote accounts).
- OAuth: **public** — no token required as of Mastodon 3.4.0+. (An older 2017 regression briefly made search require auth; `/lookup` was introduced specifically to provide a public, no-WebFinger resolution path.)
- Returns a single Account object. Key field: `id` (treat as opaque string, never cast to integer — some Mastodon forks use non-numeric IDs).
- Response shape (abbreviated):

```json
{
  "id": "109876543210",
  "username": "FastRuby",
  "acct": "FastRuby",
  "display_name": "Fast Ruby",
  "url": "https://ruby.social/@FastRuby",
  "avatar": "https://ruby.social/system/accounts/avatars/...",
  "followers_count": 1234,
  "following_count": 56,
  "statuses_count": 789
}
```

**Step 2 — Fetch statuses for that account ID**

```
GET https://{instance}/api/v1/accounts/{id}/statuses
```

Key parameters:
| Parameter | Default | Max | Notes |
|-----------|---------|-----|-------|
| `limit` | 20 | 40 | Number of statuses to return |
| `exclude_replies` | false | — | Set `true` to omit reply toots (recommended for feed view) |
| `exclude_reblogs` | false | — | Set `true` to omit boosted toots (optional, context-dependent) |
| `max_id` | — | — | Cursor for older-page pagination |

- OAuth: **public** for public-visibility statuses (visibility = "public" or "unlisted").
- Private-visibility statuses (followers-only, direct) are silently omitted from unauthenticated responses — no error is raised.
- Returns an array of Status objects (described below).

### Rate limits

Mastodon's documented limits (HIGH confidence for vanilla Mastodon, may vary per instance):
- **Authenticated per-account:** 300 requests per 5 minutes
- **Unauthenticated per-IP:** approximately 7,500 requests per 5 minutes (community-confirmed; not officially published in the rate-limits doc page)

For a personal dashboard fetching N accounts on page load, the per-IP limit is not a concern in practice. The two-request round-trip (lookup + statuses) per account is negligible. No server-side caching is strictly necessary for MVP, though adding a short TTL cache (e.g., Rails cache with 5-minute expiry) would be a courteous and performance-improving addition.

**Important caveat:** Some Mastodon instances disable public timeline access via admin settings. The lookup and account statuses endpoints are generally unaffected by this setting (they are profile-level, not timeline-level), but instance operators can impose additional restrictions. The API client must handle HTTP 401/403 and surface a user-friendly error rather than crashing.

### Sources
- [accounts API methods — Mastodon docs](https://docs.joinmastodon.org/methods/accounts/)
- [Playing with public data — Mastodon docs](https://docs.joinmastodon.org/client/public/)
- [Rate limits — Mastodon docs](https://docs.joinmastodon.org/api/rate-limits/)

---

## Profile URL Parsing

### Canonical format

Mastodon profile URLs follow a consistent pattern:

```
https://{instance_domain}/@{username}
```

Examples:
- `https://ruby.social/@FastRuby`
- `https://mastodon.social/@Gargron`
- `https://fosstodon.org/@user`

### Parsing strategy

Use `URI.parse` to extract the host (instance) and path. The username is the path component with the leading `/@` stripped.

```ruby
uri = URI.parse(profile_url)
instance = uri.host                          # "ruby.social"
username = uri.path.delete_prefix('/').delete_prefix('@')  # "FastRuby"
```

The `lookup?acct=` parameter accepts bare username when querying the correct instance, so no `@domain` suffix is needed in the API call.

### Edge cases to handle

| Case | Example | Handling |
|------|---------|----------|
| Trailing slash | `https://ruby.social/@FastRuby/` | `strip` + `chomp('/')` before parsing |
| Missing scheme | `ruby.social/@FastRuby` | Prepend `https://` if no `://` present |
| Wrong scheme (http) | `http://ruby.social/@FastRuby` | Accept; URI.parse handles it |
| Query string / fragment | `https://ruby.social/@FastRuby?ref=x` | Ignore; parse path only |
| Remote follow format | `@FastRuby@ruby.social` | Not a URL — validate that input starts with `http` |
| Subdomain instances | `https://social.example.co.uk/@user` | URI.parse handles multi-part TLDs correctly |
| No `@` prefix in path | Rare — some clients omit it | Guard: accept `/FastRuby` as well as `/@FastRuby` |

### Recommended model validation

```ruby
validates :profile_url, format: {
  with: %r{\Ahttps?://[^/]+/@?\w[\w.-]*\z}i,
  message: :invalid_mastodon_url
}
```

Store `instance` and `username` as derived columns (set in `before_validation` or `before_save`) so the API client does not re-parse on every fetch.

---

## Toot Display

### Which Status fields to use

| Field | Type | Use |
|-------|------|-----|
| `content` | HTML string | Toot body — strip tags for one-line preview |
| `url` | nullable string | Link to original toot on the instance |
| `created_at` | ISO 8601 datetime | Formatted date or "X min ago" |
| `spoiler_text` | string (may be empty) | Content warning — display instead of content when non-empty |
| `reblog` | nullable Status | Non-null means this is a boost; use `reblog['content']` and `reblog['url']` |
| `visibility` | enum string | Unauthenticated API only returns "public" and "unlisted" anyway |
| `reblogs_count` | integer | Optional engagement signal (lower priority) |
| `sensitive` | boolean | Could show a warning label, but low priority for read-only view |

### HTML stripping for one-line preview

Mastodon `content` is sanitized HTML. A typical toot looks like:

```html
<p>Interesting Ruby performance tip: avoid allocating objects in tight loops.
  <a href="https://example.com/article">https://example.com/article</a>
</p>
```

Rails provides `ActionView::Helpers::SanitizeHelper#strip_tags` (available in helpers and models via `ActionController::Base.helpers`). The recommended pipeline:

```ruby
def preview_text(status)
  raw = status['spoiler_text'].presence || status['content']
  plain = ActionController::Base.helpers.strip_tags(raw)
  plain.squish.truncate(100)
end
```

Key points:
- `spoiler_text` takes priority when present — it is the author's declared subject/warning.
- `.squish` collapses newlines and multiple spaces that remain after stripping `<p>` tags.
- Truncate at 100 chars with the default `...` ellipsis.
- For reblogs: use `status['reblog']['content']` (the original toot), not the outer status's empty content.

### One-line preview format (welcome page gadget)

Each toot renders as a single `<li>` with a link, matching the RSS feed gadget pattern exactly:

```erb
<li><%= link_to preview_text(toot), toot['url'], link_opts %></li>
```

This reuses the existing `open_links_in_new_tab` preference pattern from `feeds/show.html.erb`.

---

## Table Stakes

Features that must exist for this to be a useful read-only Mastodon follower. Missing any of these makes the feature feel incomplete.

| Feature | Why Essential | Complexity |
|---------|--------------|------------|
| Store profile URL + parsed instance/username | Without this, no API calls are possible | Low |
| `display_count` per account (default 5) | Matches Feed model pattern; user controls density | Low |
| CRUD at `/mastodon_accounts` (index, new, edit, destroy) | Standard management screen | Low–Med |
| API client: lookup → statuses two-step | Core fetching logic | Medium |
| Welcome page collapsible gadget per account | The actual product value | Medium |
| One-line toot preview with link to original | Minimum useful display | Low |
| Error handling when instance is unreachable | Network failures must not crash the page | Low |
| Per-user data isolation via `Crud::ByUser` | Security — same pattern as Feed | Low |
| Soft-delete (`deleted` boolean) | Matches all other models in this app | Low |
| Locale strings (ja/en) for all UI chrome | App contract — every surface is bilingual | Low |
| `exclude_replies: true` by default | Replies are usually out-of-context noise in a feed view | Low |

**Dependency on existing RSS feed pattern:**
The Feed model and its gadget partial (`_feed.html.erb`) provide the exact template to follow. The welcome page loads feed content via jQuery `$.get` to `feeds#show`; the Mastodon gadget should use the same approach — an equivalent `mastodon_accounts#show` endpoint returns an HTML fragment that the welcome partial injects via AJAX. This avoids new JS complexity and keeps the implementation consistent.

The `Portal#get_gadgets` method explicitly iterates `Feed.where(user_id:, deleted: false)` to add feed gadgets. A MastodonAccount will need to be added to this same iteration to appear in the portal column layout system. The model must expose `gadget_id` (e.g., `"mastodon_account_#{id}"`).

---

## Differentiators

Nice-to-have features that add value but are not required for the first iteration.

| Feature | Value | Complexity | Priority |
|---------|-------|-----------|----------|
| Short-TTL Rails cache (5 min) for API responses | Reduces instance load; faster repeated page loads | Low | High-ish — add in implementation phase |
| Show boost attribution ("boosted by @account") | More context for reblogged toots | Low | Medium |
| `exclude_reblogs` preference per account | Let user choose whether to see boosts | Medium | Low |
| Relative timestamps ("5 min ago") | More natural feel for live feed | Low | Low |
| Show `spoiler_text` toggle (expand/collapse CW) | Respects author intent for content warnings | Medium | Low |
| Show avatar in gadget header | Visual identity for the account | Low | Low |
| Account display name vs. username display | `display_name` is more human-readable than `username` | Low | Low |
| Show link to original profile in gadget header | `account.url` from the Account object | Low | Low |

---

## Anti-Features (Out of Scope)

These must be explicitly excluded. Building any of them would require OAuth, increase complexity significantly, or conflict with the app's personal-tool character.

| Anti-Feature | Why Out of Scope |
|--------------|-----------------|
| OAuth authentication flow | App is read-only; public API covers all needed endpoints. OAuth requires registering an app on each instance, token storage, and refresh flows — complexity far exceeding the value. |
| Posting / replying / boosting | This is a read-only feed viewer. Write operations require OAuth and conflict with the app's bookmark-tool identity. |
| Mastodon social graph follow/unfollow via API | "Following" in this feature means registering locally to watch — not sending a Mastodon follow request. The Mastodon social graph is irrelevant. |
| Notifications (mentions, favourites) | Requires OAuth + streaming. Out of scope. |
| WebSocket / streaming timeline | Server-sent events / streaming API requires auth and persistent connections. Page-load fetch is the correct pattern for this app. |
| Full toot rendering (custom emoji, polls, media) | Rich rendering requires parsing `emojis`, `poll`, and `media_attachments` arrays. One-line text preview is the target. |
| Search across followed accounts' toots | Local search over cached content. No caching layer exists. |
| Import/export followed accounts list | Nice for portability but irrelevant for v1.16 scope. |
| Multi-user / social features | This is a personal tool; all data is per-user already. |

---

## Feature Dependencies on Existing Code

| New Feature | Depends On | Notes |
|------------|-----------|-------|
| Portal gadget registration | `Portal#get_gadgets` | Must add `MastodonAccount.where(user_id:, deleted: false).each` block |
| `gadget_id` method | Feed model pattern | Return `"mastodon_account_#{id}"` |
| Welcome page partial | `_feed.html.erb` + `feeds/show.html.erb` | Mirror the jQuery `$.get` pattern |
| Soft delete | `Crud::ByUser` + `deleted` column | Same as Feed, Todo, Note, Bookmark |
| Locale strings | `config/locales/ja.yml` + `en.yml` | Key parity enforced by existing tests |
| User ownership security | `Crud::ByUser#readable_by?` | Never trust client-supplied `user_id` |
| Link-opening preference | `preference.open_links_in_new_tab?` | Already used in `feeds/show.html.erb` |
