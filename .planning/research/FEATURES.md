# Features Research — v1.18 X (Twitter) Account Following

**Project:** Bookmarks v1.18
**Researched:** 2026-05-14
**Confidence:** HIGH (v1.16 Mastodon code read directly; X API v2 surface and Basic-tier scopes are well-documented and stable; rate-limit ceilings carry MEDIUM confidence because Basic-tier quotas have shifted historically)

---

## Summary

v1.18 puts an X (Twitter) following list behind `/x_accounts` and renders one welcome-page gadget per selected handle, showing the latest N tweets with live AJAX fetch on every page render. It is the X-flavored mirror of v1.16 Mastodon, with three structural differences forced by X:

1. **Auth is required for every API call.** Public X read is no longer free; we must reuse the user's OAuth 1.0a credentials saved at sign-in (`uid` / `token` / OAuth1 `secret`) for both following-list and tweet fetches. v1.16 used purely public Mastodon endpoints with no token.
2. **Following list is a real list.** v1.16 took a profile URL one row at a time; v1.18 pulls a snapshot of `GET /2/users/:id/following` into a DB cache and the user selects from it. A new cache table is needed (`x_followings`) plus a manual "Refresh" affordance — there is no v1.16 equivalent.
3. **Surface is gated to Twitter sign-in users.** `users.name` (Twitter screen_name) is the gate; Google-only accounts never see `/x_accounts` or the gadget. v1.16 has no such gate.

Everywhere else, lean hard on the v1.16 contract: same one-line truncated-text-with-link gadget shape, same AJAX `show` action with `stub_fetch_result` test seam, same `Portal#get_gadgets` registration, same Faraday-with-explicit-timeouts client, same soft-delete via `Crud::ByUser`, same ja/en locale parity test, same `@x_gadget` Cucumber stub.

---

## Following-List Management Screen

The screen at `/x_accounts` has two concerns layered on the same page:

- **Cached list** — what the X API last said the user follows.
- **Selection state** — which of those handles render as gadgets on `/`.

These are intentionally one screen (not two) to keep the v1.16 single-CRUD surface familiar; selection is a checkbox per row, persisted into the `x_accounts` table on submit.

### Table Stakes

| Feature | Complexity | Why required |
|---------|-----------|--------------|
| `users.name`-gated route + controller (`require_twitter_signed_in` filter) | S | Google-only users have no X tokens; entering the screen would 401 the first API call and surface a confusing error. Gate at the controller layer, not the view, to keep the contract testable. |
| Manual "Refresh" button that calls `XClient#fetch_following` and upserts `x_followings` rows | M | The screen is useless without a way to populate / re-populate the cache. Q6 closed background sync, so this is the only refresh path. Must be POST (CSRF-protected) and idempotent. |
| Persistent `x_followings` cache (per-viewer snapshot: `target_user_id`, `username`, `display_name`, `avatar_url`, `synced_at`) | M | X Basic-tier rate limits prohibit re-pulling on every page load. Cache row is the join target for the selection table. Per-viewer (not global) because following lists are private to the viewer. |
| Per-row checkbox that toggles "show on welcome" → writes to `x_accounts` (selected handles) | S | The whole point of the screen. Submit via standard Rails form post; do not introduce per-row AJAX. |
| Display per row: avatar, display name, `@handle` | S | Without these three, users cannot recognize an account in a multi-hundred list. Avatar and display name come from the same `user.fields` expansion as the username; cost is one extra query parameter. |
| Empty state when cache is empty (never refreshed, or X returned zero follows) | S | First-time UX. Single locale key; render an explicit "Press Refresh to load your X following list" message instead of an empty table. |
| Error state for refresh failures (timeout, rate-limited, token-revoked, network) | M | Each maps to a different user action: timeout → retry, rate-limited → wait, token-revoked → re-sign-in, network → check connection. Single generic flash is insufficient. Mirror v1.16 `:timeout / :network / :not_found / :api_error / :parse_error` plus new `:rate_limited` and `:auth_failed` symbols. |
| ja/en localization with locale-key parity test | S | Project-wide standard; not optional. Reuses the parity test added in v1.4. |
| Soft-delete via `Crud::ByUser` on `x_accounts` | S | Matches `MastodonAccount` and `Feed`. Necessary so unselecting an account does not lose the user's `display_count` override on a future re-select. |
| Server-side enforcement that `x_accounts.target_user_id` exists in the viewer's current `x_followings` snapshot | S | Defense-in-depth: a crafted POST cannot create a gadget for an account the user does not actually follow. |
| `display_count` per account, default 5 | S | Mirrors `MastodonAccount#set_display_count`. X API `/2/users/:id/tweets` `max_results` minimum is 5 — using 5 as default is both natural and the smallest legal value. |

### Differentiators

| Feature | Complexity | Why nice |
|---------|-----------|----------|
| In-page client-side filter input (jQuery substring match on handle + display name) | S | Following lists run to hundreds. Pure DOM filter over already-rendered rows; no extra API, no new JS framework. High value-to-effort. |
| Bio snippet (~140 chars, truncated) under display name | S | One extra `user.fields=description` parameter; helps users disambiguate similar handles. |
| "Last refreshed at {timestamp}" line above the table | S | Communicates cache freshness; reduces panic when results look stale. Reuses `synced_at` already needed for the cache. |
| Pagination of the cached list (server-side, 50/page) if cache grows past ~200 rows | M | DOM size matters for filter responsiveness. Defer until lint/performance pressure observed; not required for v1 correctness. |
| Bulk select-all / clear-all controls | S | Convenience for users who want most-or-none. Pure form-state, no backend change. |
| Per-row link to `https://x.com/{handle}` | S | Lets users visit the source profile when in doubt. Trivial. |
| Selected-count indicator (`3 / 142 selected`) | S | Quick orientation; one helper call. |
| Verified / protected badges (`user.fields=verified,protected`) | S | Two-pixel UX wins; minor API-cost increase. |
| Followers-count column | S | Helps users decide which of two similar accounts to pick. |
| Fallback "Add by @handle" input for handles not yet in the cache (e.g., newly followed) | M | Edge case but worth allowing without forcing a full refresh; calls `XClient#lookup_user` and inserts a single `x_followings` row. |
| Sort toggle (alphabetical, by recent activity, by followers) | M | Diminishing returns past alphabetical; defer. |

### Anti-features

| Feature | Why excluded |
|---------|--------------|
| Following / unfollowing accounts from this screen | Write-side X API requires elevated scopes and explicit user intent we should not synthesize. v1.18 is strictly read-only, mirroring v1.16. |
| Muting, blocking, reporting | Same as above — write surfaces belong on x.com, not in a personal dashboard. |
| Drag-and-drop reordering of selected accounts into portal columns | The welcome page already has a portal-layout mechanism (`PortalLayout`); reordering belongs there, not on `/x_accounts`. Adds DnD JS that violates the no-new-client-state constraint. |
| Auto-refresh of following list (cron / Solid Queue / on every welcome render) | Q6 explicitly closed this. Manual button only. Background infra is out of scope for v1.18. |
| Cross-platform merged list (Mastodon + X in one view) | Surfaces are intentionally separate; merging them couples two clients that fail independently. v1.16 set the precedent. |
| Real-time updates via WebSocket / Turbo Streams | The app is Sprockets + jQuery + standard Rails responses; no ActionCable in stack. |
| Lists / Bookmarks / Saved-from-Twitter integration | Each requires extra API surface and per-resource scopes. Out of v1.18 scope. |
| Inline tweet preview inside the following row | Conflates two distinct features; the welcome gadget is where tweets render. |
| OAuth re-connect / scope upgrade flow inside `/x_accounts` | If the token is revoked, redirect to standard sign-out → re-sign-in. Building an in-page reconnect is more surface area than the failure mode justifies. |
| Importing the following list from a CSV / Twitter archive | One-time migration tool; no recurring user value. |

---

## Welcome-Page Gadget

Each selected X account renders as one gadget panel on `/`, identical in shape to v1.16 Mastodon: the server renders a placeholder with a `<script>` block, jQuery fires a single XHR to `MastodonAccountsController#show`-equivalent (`XAccountsController#show`), and the response is HTML for the gadget body.

### Table Stakes

| Feature | Complexity | Why required |
|---------|-----------|--------------|
| `XAccountsController#show` returns HTML fragment when `request.xhr?`, full layout otherwise | S | Exact v1.16 contract; reuse the `render layout: !request.xhr?` line verbatim. |
| Live fetch on every render via `XClient#fetch_recent_tweets(target_user_id:, limit:)` | M | Q6=2 confirmed. No tweet caching layer. Same in-request fetch shape as `MastodonClient#fetch_recent_status_previews`. |
| Each tweet rendered as one-line truncated text linked to `https://x.com/{handle}/status/{id}` | S | Direct port of v1.16 `_mastodon_account.html.erb` ol/li shape. Truncation length ~140 (X tweets average longer than toots; 100 chars looks cramped but 140 still fits one line in all three themes). |
| Link target obeys `current_user.preference.open_links_in_new_tab?` | S | Site-wide UX contract; same line as v1.16. |
| Default tweet count = 5; per-account override via `display_count` | S | X API `max_results` minimum is 5; using anything smaller costs an extra slice. Matches Mastodon default. |
| Exclude retweets AND replies by default (`exclude=retweets,replies` query param) | S | Without exclusion, RT-heavy accounts produce a gadget of "@handle: …" lines that all link out to other users. Defeats the "what this account said" premise. v1.16 toots have no equivalent retweet concept so this is X-specific. |
| Plain-text rendering (strip URLs to display text, no HTML embedding) | S | Same `strip_tags` + `squish` + `truncate` chain as `MastodonClient#build_preview_item`. X returns plain text in `data.text` already, but URLs come as `t.co` short links — should be replaced with `entities.urls[].display_url` before truncation. |
| Empty state (account has zero qualifying tweets in the fetched window) | S | Locale key `x_accounts.show.empty`; same shape as Mastodon. |
| Error states with distinct symbols: `:timeout`, `:network`, `:not_found`, `:rate_limited`, `:auth_failed`, `:api_error`, `:parse_error` | M | `:rate_limited` and `:auth_failed` are X-specific additions. `:not_found` covers deleted / suspended / private accounts. Each gets its own locale key so the user can act on the message. |
| Gadget title links to `https://x.com/{handle}` profile | S | Mirrors `mastodon_account.title` link. |
| `XClient.stub_fetch_result` class accessor for Cucumber + integration tests | S | Required by the project's no-WebMock testing contract. Direct lift of `MastodonClient.stub_fetch_result`. |
| Faraday with explicit `CONNECT_TIMEOUT` + `READ_TIMEOUT` constants | S | Project-wide pattern (Mastodon, Daddy::HttpClient). Non-negotiable; default Faraday timeouts hang Puma threads. |
| `Portal#get_gadgets` registers one entry per `XAccount.where(user_id: ...).not_deleted` row | S | One-line addition in the existing method, after the Mastodon block. |
| `welcome/_x_account.html.erb` partial parallel to `_mastodon_account.html.erb` | S | Same structure, same loading message, same `data-fetch-failed-message` data attribute. |

### Differentiators

| Feature | Complexity | Why nice |
|---------|-----------|----------|
| Pinned tweet rendered first (always), then the timeline (N − 1 items) | M | Adds one extra `tweets/:id` lookup OR an `expansions=pinned_tweet_id` on user lookup. Significant UX win because the pinned tweet is usually the account's most relevant message. Requires extra rate-limit budget per gadget render. |
| Relative timestamp ("2h", "3d") next to each tweet | S | `tweet.fields=created_at` plus a `time_ago_in_words` helper. Cheap and adds temporal context Mastodon previews lack. |
| Quote-tweet handling: append `→ quoted: {short-text-or-handle}` | M | Requires `expansions=referenced_tweets.id` and walking `referenced_tweets`. Without this, quote tweets read as bare commentary with no context. |
| Media indicator icon (📎 or similar) when tweet has attachments | S | `tweet.fields=attachments` is enough to detect presence; no media expansion needed. Visual hint, no thumbnail rendering. |
| Media thumbnail (single 64–96px preview) | L | Needs `expansions=attachments.media_keys` + `media.fields=preview_image_url,url,type`. Heavier API payload, theme-specific CSS, link rules. Defer behind the media-indicator. |
| Verified-badge dot next to gadget title | S | One extra `user.fields=verified`; cheap. |
| Distinguish included retweets (when user has unchecked the default-exclude) with `RT @x:` prefix | S | Only relevant if the per-account preference grows a "include retweets" toggle. Skip in v1 unless that toggle ships. |
| Hover-tooltip with full untruncated tweet text | S | jQuery `title` attribute; zero-cost accessibility-questionable but common pattern. |
| Loading shimmer or spinner instead of static "loading…" line | S | Cosmetic. Reuses existing AJAX-loading affordance pattern if one exists. |
| Per-gadget "refresh" link (re-fires the same XHR) | S | The page-load fetch is already the refresh; an explicit button is rarely used. Low value. |

### Anti-features

| Feature | Why excluded |
|---------|--------------|
| Posting tweets / replying / liking / retweeting from the gadget | Read-only contract carries over from v1.16. Posting requires write scopes we have not requested and would not request for a personal dashboard. |
| Embedded x.com widgets / oEmbed / `widgets.js` | Introduces third-party JS, breaks the "no new client-side state / no new bundler" constraint, and degrades over time as x.com changes embed rules. |
| Threaded conversation view (replies expanded under the parent) | Each thread costs N more API calls per gadget render against Basic-tier limits. Out of scope; click-through to x.com is the answer. |
| Real-time updates (WebSocket / SSE / Turbo Streams) | No ActionCable in stack; the welcome-render-time fetch is the contract. |
| Push notifications | No notification infrastructure exists; v1.17 explicitly skipped the mailer beyond `ApplicationMailer`. |
| Per-gadget auto-refresh on a timer | Wastes Basic-tier quota and provides marginal value. The whole-page reload is the refresh. |
| Inline video / GIF playback | Heavy, third-party-dependent, theme-conflicting. Link out instead. |
| Per-tweet engagement metric badges (replies / RTs / likes counts) | Available via `tweet.fields=public_metrics` but adds visual noise that does not help "what did this account say recently". |
| Smart filters (mute words, content warnings, sentiment scoring) | Out of scope; users self-curate by selecting accounts. |
| Cross-account merged timeline ("all selected X accounts in one stream") | Breaks the "one gadget per account" v1.16 parity contract and adds sorting / dedup complexity. |
| DMs, Spaces, Communities surfaces | Out of Basic-tier scope and out of dashboard scope. |
| Posting-as-gadget composer | Same as "posting tweets" above. |
| In-gadget tweet search | Out of scope; users can click out. |

---

## Feature Dependencies

A few features are not standalone — they require specific API expansions, schema columns, or upstream features. Calling these out so the implementation order is unambiguous.

| Dependent feature | Depends on |
|-------------------|-----------|
| Selection checkbox writes (`x_accounts.target_user_id`) | `x_followings` cache table populated by a successful Refresh |
| `Portal#get_gadgets` X registration | `XAccount` model + `Crud::ByUser` mixin |
| Welcome AJAX fetch | `XAccountsController#show` + `XClient#fetch_recent_tweets` + `XClient.stub_fetch_result` |
| `XClient#fetch_recent_tweets` | `users.token` and `users.secret` persisted at OAuth callback (v1.17 PITFALL-02 fix); without these, every call returns `:auth_failed` |
| `XClient#fetch_following` | Same as above + a Faraday connection with `Authorization: OAuth …` header signed via `omniauth-twitter`'s underlying `OAuth::Consumer` (or a thin replacement) |
| `:rate_limited` error state | `XClient` must inspect `x-rate-limit-remaining` and 429 status; this is X-specific and absent from v1.16 |
| `:auth_failed` error state | `XClient` must distinguish 401/403 from generic API errors; surfaces "re-sign-in" CTA |
| Pinned-tweet-first rendering | User lookup with `user.fields=pinned_tweet_id` cached in `x_followings`, plus an extra `GET /2/tweets/:id` OR `expansions=pinned_tweet_id` on the user lookup → carry into `fetch_recent_tweets` |
| Quote-tweet handling | `expansions=referenced_tweets.id,tweet.fields=referenced_tweets` on the timeline fetch |
| Media indicator | `tweet.fields=attachments` (presence only) |
| Media thumbnail | Media indicator + `expansions=attachments.media_keys` + `media.fields=preview_image_url,url,type` + theme CSS for the thumbnail box |
| Verified badge in following list | `user.fields=verified` on `/2/users/:id/following` request |
| Followers-count column | `user.fields=public_metrics` on the same request |
| Bio snippet | `user.fields=description` on the same request |
| Relative timestamp on tweets | `tweet.fields=created_at` (always include; near-zero cost) |
| In-page filter input | None — pure DOM filter over rendered rows |
| "Last refreshed at" line | `x_followings.synced_at` column (or a `x_following_syncs` summary row) |
| Pagination of cached list | `x_followings.synced_at` index + offset/limit on the index query |
| Bulk select-all / clear-all | Pure form-state; no backend dependency |
| `display_count` per X account | `x_accounts.display_count` column, default 5, mirrors `mastodon_accounts.display_count` |
| Soft-delete on `x_accounts` | `deleted` column + `Crud::ByUser` include |
| ja/en parity | Locale keys under `x_accounts.*` and `x_accounts.show.errors.*` mirroring `mastodon_accounts.*`; existing parity test picks up new keys automatically |
| `@x_gadget` Cucumber stub | `XClient.stub_fetch_result` set in a `Before('@x_gadget')` hook and cleared in `After('@x_gadget')` |

---

## Comparison to v1.16 Mastodon Pattern

### Keep parity with v1.16

- **Service-object shape.** `XClient` is a PORO with a class-level `stub_fetch_result` attr_accessor and a single public method per concern (`fetch_following`, `fetch_recent_tweets`). Errors come back as `{ success: false, error: <symbol> }` with the symbol set chosen for exhaustive `t('.errors.<sym>')` keys. No raised exceptions across the boundary.
- **Faraday with explicit timeouts.** `CONNECT_TIMEOUT = 3`, `READ_TIMEOUT = 5` is the project floor; X over HTTPS is comparable to Mastodon over HTTPS, so same numbers are fine.
- **`Portal#get_gadgets` registration.** One block after the existing `MastodonAccount.where(...)` block. Do not refactor the existing method shape — append, mirror, ship.
- **AJAX `show` action.** `render layout: !request.xhr?` — same line, same behavior, same test seams.
- **Welcome partial.** `welcome/_x_account.html.erb` is a near-clone of `_mastodon_account.html.erb`: `$(document).ready` → `$.get(x_account_path(gadget, format: :html))` → `.fail` writes a localized message into the first `<li>`. Same `data-fetch-failed-message` attribute pattern.
- **Truncation + strip.** `ActionController::Base.helpers.strip_tags(html).squish.truncate(LIMIT, omission: '…')` — same chain. Constant name: `XClient::PREVIEW_LENGTH`.
- **Soft-delete via `Crud::ByUser`.** Same mixin, same `not_deleted` scope, same `destroy_logically!` controller call.
- **Strong params with `merge!(user_id: current_user.id)`.** Direct port of `MastodonAccountsController#mastodon_account_params`. `target_user_id` and `display_count` are the writable fields; never accept `user_id` from the client.
- **Cucumber stubbing pattern.** `@x_gadget` tag → `Before` hook sets `XClient.stub_fetch_result = { success: true, items: [...] }`; `After` hook clears it. Mirrors `@mastodon_gadget`.
- **Locale-key parity test.** No new test infrastructure; the existing parity test picks up `x_accounts.*` keys once both `ja.yml` and `en.yml` carry the same shape.

### Diverge from v1.16 (justified)

- **OAuth credential plumbing.** Mastodon needs none. X needs `users.uid`, `users.token`, `users.secret` persisted at the OAuth callback (currently a v1.17 PITFALL-02 gap). Without this, `XClient` cannot make a single call. This is the single largest non-Mastodon item in v1.18 and blocks every API-touching feature.
- **`users.name` gate on the controller.** `MastodonAccountsController` is open to any signed-in user. `XAccountsController` must filter to Twitter-sign-in users (`current_user.name.present?` or an equivalent helper). Both the `/x_accounts` routes and the preferences entry link must enforce this.
- **Two-table data model.** Mastodon is one table (`mastodon_accounts`). X needs two:
  - `x_followings` — viewer-scoped snapshot of the X following list (cache; refreshed on demand).
  - `x_accounts` — selected handles that render as welcome gadgets; references `x_followings.target_user_id` for the viewer.
  The selection table is the analogue of `mastodon_accounts`; the cache table has no v1.16 equivalent.
- **Manual "Refresh" affordance.** A POST route + controller action that calls `XClient#fetch_following`, paginates, upserts cache rows, and removes rows no longer present in the response (without cascading into selected `x_accounts`, which keep their `display_count` overrides). Mastodon has no equivalent because each row is its own profile URL.
- **No profile-URL entry form on the index.** Selection replaces entry. Optional differentiator: a fallback "Add by @handle" input for handles not in the cache yet (calls `XClient#lookup_user`).
- **Error symbol set expanded.** Add `:rate_limited` (HTTP 429 / `x-rate-limit-remaining: 0`) and `:auth_failed` (HTTP 401 / 403) to the v1.16 set. The localized messages must steer the user to distinct actions (wait vs. re-sign-in).
- **Tweet-text post-processing.** X returns short `t.co` URLs in `text`; replace each via `entities.urls[]` (`url` → `display_url` or `expanded_url`) before truncation. Mastodon already returns HTML with anchor `display` text built in.
- **Exclude retweets and replies by default.** `?exclude=retweets,replies` on every `/2/users/:id/tweets` call. Mastodon's "what they posted" semantics are baked into `accounts/:id/statuses`; X needs the flag.
- **Rate-limit awareness.** Basic-tier `/2/users/:id/tweets` and `/2/users/:id/following` have tight per-15-minute ceilings. Two implications:
  1. Welcome-render fetch storms must be bounded — N selected accounts means N concurrent XHRs. Document the practical ceiling (suggest M cap on selected accounts, e.g. 5–10) and surface `:rate_limited` cleanly.
  2. Following-list Refresh button should disable itself for a cool-down window after a successful sync (CSS-only, no setTimeout state), or document the rate-limit error path and let the user retry.
- **Token-revocation recovery path.** If the user revokes the app from their X settings, every subsequent call returns 401. Render `:auth_failed` with a localized "Re-sign-in to X" message linking to the standard `/users/auth/twitter` start URL. Mastodon has no equivalent because no token exists.

### What is NOT different

- Theme integration, mobile portal layout, drawer nav gating, preferences entry row pattern — all reuse existing infrastructure unchanged. The X feature should not touch any of these surfaces beyond adding a single preferences-page link to `/x_accounts` (and gating that link on `users.name.present?`).
- Minitest patterns (Faraday `:test` adapter for unit tests, `stub_fetch_result` for integration / Cucumber) — identical conventions.
- The tri-suite green-bar gate.
