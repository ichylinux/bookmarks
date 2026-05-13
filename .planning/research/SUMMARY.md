# Research Summary — v1.18 X (Twitter) Account Following

**Project:** Bookmarks v1.18
**Domain:** X API v2 read-only following + tweets, OAuth 1.0a User Context, welcome gadget
**Synthesized:** 2026-05-14
**Confidence:** HIGH (all four researchers HIGH on their respective areas; remaining MEDIUM is concentrated in the OAuth-1.0a signing path choice, resolved below)

---

## Overview

v1.18 adds a read-only X (Twitter) following surface that mirrors v1.16 Mastodon: a management page at `/x_accounts` for picking which followed handles render as welcome-page gadgets, plus one AJAX-loaded gadget per selected handle showing recent tweets. The structural twist over v1.16 is that **every API call must be authenticated** with the user's OAuth 1.0a User Context tokens — there is no public X read path. That forces three things that v1.16 did not need: (1) persistence of OAuth tokens at sign-in, (2) an OAuth-signed Faraday client, and (3) a DB-cached snapshot of the user's following list (Basic-tier rate limits prohibit pulling it on every render).

The single most important pre-planning correction surfaced by this research is that **`users.name` is the Twitter *display* name, not the screen_name and not the numeric `uid`** that X API v2 endpoints actually consume. The current `from_omniauth` Twitter branch writes only `data['name']` and throws everything else (`uid`, `token`, `secret`) away. v1.18's foundation phase therefore has to (a) persist the four real OAuth fields, (b) re-base the Twitter-linked gate on `uid + token` (not `name`), and (c) explicitly *not* fix the v1.17 carry-forward bug of name-keyed account lookup (that's a follow-up — see Open Questions).

Touch only what you must: `MastodonClient` and `MastodonAccount` are independent and unchanged. The X feature reuses every shared seam (`Crud::ByUser`, `Portal#get_gadgets`, AJAX `show` with `render layout: !request.xhr?`, jQuery loader partial, ja/en parity test, tri-suite gate, `stub_*_result` test contract).

---

## Critical Findings (must read before planning)

### 1. `users.name` is the Twitter display name, not the screen_name

Per `PITFALLS.md` §3A (cross-checked against `omniauth-twitter` 1.4.0 source): omniauth-twitter populates `info.name` from `raw_info['name']` (the display name — mutable, often contains spaces / unicode / emoji) and `info.nickname` from `raw_info['screen_name']` (the `@handle`). The numeric `uid` comes from `access_token.params[:user_id]`. **X API v2 endpoints take the numeric id in the URL path** (`GET /2/users/:id/following`, `GET /2/users/:id/tweets`) and reject display names. They will accept screen_name only via a different endpoint (`/2/users/by/username/:username`) which is not in v1.18 scope.

**Impact:**
- `users.name` is *not* a usable X API handle. The milestone premise that read "we already have the X handle in `users.name`" is structurally wrong.
- `users.name` *is* still a serviceable "this account signed in via Twitter at least once" signal (any Google-only user has `name: nil`), but it is **not** authoritative — see Critical Finding #3.
- The actual X API identifier (`twitter_uid` / `users.uid`) is what gets stored, and it's what `XClient` passes to every endpoint.

**Recommended contract:** Store the numeric uid in a new persisted column (see Critical Finding #2 for naming). Never pass `users.name` to `XClient` or to an X API URL. If a screen_name is ever needed for display (e.g. "@handle" rendering), pull it from `auth.info.nickname` into a separate column or, simpler, store it on the cached `x_accounts` row when refresh runs (since the following-list response includes `username` per row anyway). v1.18 does not require persisting the signed-in user's own screen_name — every X API URL key in scope is the numeric id.

### 2. OAuth tokens are not currently persisted (v1.17 PITFALL-02 carry-forward, mandatory fix)

`db/schema.rb` lines 109/114/115 expose `users.provider`, `users.uid`, `users.token` columns — but `User.from_omniauth`'s Twitter branch (`app/models/user.rb:24-37`) writes **none of them**, and there is no column for the OAuth 1.0a **token secret** (required alongside `token` for every signed request). Without `(uid, token, token_secret)` persisted, `XClient` cannot make a single API call. Re-auth on an existing user also does not refresh credentials today (no `update!` on the `find` branch), so revocation produces silent 401 storms.

This is the **first phase** of v1.18 because every downstream phase depends on it. The two unresolved sub-decisions are:

- **Encrypt at rest?** All four researchers say yes. Rails 8 ActiveRecord encryption is already configured (`config/application.rb:30-32` reads encryption keys with dev/test dummy fallbacks; `support_unencrypted_data = true` in dev/test). OAuth 1.0a tokens **do not expire by clock** — a leaked token is valid forever until the user manually revokes it from x.com. That makes plaintext storage qualitatively worse than OAuth 2.0 access-token leaks. **Recommend `encrypts :token, :token_secret` on `User`** in the same migration phase. `uid` stays plaintext (public identifier, needed for indexed lookups).
- **Column naming.** ARCHITECTURE wants three *new* provider-scoped columns; STACK and PITFALLS want to reuse the existing dead columns and add only the missing secret. See "Disagreement Resolution → Column naming."

### 3. Gate-by-name is bypassable; gate must be `uid + token`

PITFALLS §7E confirms `:name` is permitted in `preferences_controller#user_params` (`app/controllers/preferences_controller.rb:44`). Any user — Google-only, no X session — can flip a `current_user.name.present?` gate by typing a name into preferences. They would then reach `/x_accounts`, fail the first API call, and see a confusing error.

**Recommended contract:**

```ruby
# app/controllers/concerns/twitter_linked.rb (or inline helper)
def require_twitter_linked
  return if current_user.uid.present? && current_user.token.present?
  redirect_to preferences_path, alert: t('x_accounts.errors.not_linked')
end
```

Apply as a `before_action` on every `XAccountsController` action, and gate the drawer / preferences entry-link on the same predicate (extracted into a `show_x_accounts_link?` helper). The `users.name.present?` check survives only as a *UI convenience signal* (drawer entry visibility for users who haven't completed the v1.18 re-auth backfill yet); never as the authoritative gate. `preferences_controller#user_params` does **not** need to drop `:name` from its permit list in v1.18 — the gate move makes the bypass harmless.

---

## Stack Additions (Recommended)

After reconciling STACK / PITFALLS / ARCHITECTURE, the recommended delta is:

**Gems (one new + use one existing transitive):**
- `gem 'faraday-oauth1'` (~> 1.0; pulls in `simple_oauth ~> 0.4` transitively). See Disagreement Resolution → OAuth 1.0a signing.
- No use of the `oauth` gem (it's a transitive but its `Net::HTTP`-coupled `OAuth::AccessToken` is rejected — see resolution).

**Columns:**
- `users.token_secret` (new; one of `string` or `text` — see "Column naming"). Whether the other three columns are reused (STACK/PITFALLS) or replaced with `twitter_*` siblings (ARCHITECTURE) is the open user decision below.
- `users` model gains `encrypts :token, :token_secret` (or the `twitter_oauth_*` equivalent under option B).
- New table `x_accounts` (single-table cache + selection, per ARCHITECTURE option (a) — see Architecture Outline).

**Services / controllers / views (all new):**
- `app/services/x_client.rb` — Faraday + `faraday-oauth1` middleware, two methods (`fetch_following`, `fetch_recent_tweets`), two class-level stub accessors, `MastodonClient`-shaped return contract with `:unauthorized` and `:rate_limited` added.
- `app/controllers/x_accounts_controller.rb` — `index` / `refresh` / `update` / `show`.
- `app/models/x_account.rb` — `Crud::ByUser` mixin, `gadget_id`, `title`, `derive_profile_url`.
- `app/views/x_accounts/{index,show}.html.erb` + `app/views/welcome/_x_account.html.erb`.

No new HTTP transport, no new JS bundler, no new background-infra (Q6 closed background sync), no `webmock` / `vcr`.

---

## Feature Table Stakes (v1)

From FEATURES.md, filtered to the must-haves:

**Management page (`/x_accounts`):**
- Composite gate (`uid + token`) at the controller; redirect to preferences on miss. (S)
- Manual "Refresh" button → `XClient#fetch_following` → diff-upsert into `x_accounts`. POST, CSRF-protected, idempotent. (M)
- Cached list display per row: avatar (`profile_image_url`), display name, `@handle`. (S)
- Per-row select-checkbox writes `selected: true/false` via PATCH `/x_accounts/:id`. (S)
- Default `display_count = 5` (X API `max_results` minimum). (S)
- Empty state + per-error-symbol localized refresh-failure states (`:timeout / :network / :api_error / :parse_error / :rate_limited / :unauthorized`). (M)
- Server-side guard: PATCH cannot mark `selected: true` on a row not in the user's cache. (S)
- "Last refreshed at {timestamp}" line above the table. (S)

**Welcome gadget:**
- `XAccountsController#show` with `render layout: !request.xhr?`. (S)
- Live fetch on every render via `XClient#fetch_recent_tweets`. (M)
- Each tweet: one-line truncated text (`PREVIEW_LENGTH = 100`, matches Mastodon), linked to `https://x.com/i/status/{id}`. (S)
- `?exclude=retweets,replies` on every call (X-specific; v1.16 toots have no equivalent). (S)
- t.co URL expansion via `entities.urls[].display_url` **before** truncation (PITFALL-4B; `strip_tags` is a no-op on X plain text). (S)
- `Portal#get_gadgets` registers only `XAccount.where(user_id:, selected: true).not_deleted`. (S)
- ja/en parity for every new key (existing parity test enforces). (S)
- Click target obeys `current_user.preference.open_links_in_new_tab?`. (S)
- `XClient.stub_fetch_following_result` + `XClient.stub_fetch_tweets_result` class accessors, cleared in Minitest `teardown` + Cucumber `After`. (S)

---

## Differentiators (defer / v2)

Worth picking up if the planner has slack, but explicitly **not required** for v1.18 ship:

- In-page client-side filter on the management list (S; substring match on handle + name; high value-to-effort if cache grows past a few dozen rows).
- Bio snippet (~140 chars) under display name on management page (S; one `user.fields=description` param).
- Verified / protected badges on management list (S).
- Bulk select-all / clear-all controls (S).
- Selected-count indicator `3 / 142 selected` (S).
- Relative timestamps next to tweets on the gadget (S; `tweet.fields=created_at` + `time_ago_in_words`).
- Pagination of cached list (M; defer until cache routinely exceeds ~200 rows).
- Pinned tweet rendered first (M; needs `user.fields=pinned_tweet_id` + extra fetch).
- Quote-tweet handling (M; `expansions=referenced_tweets.id`).
- Media indicator icon (S) — but media thumbnail rendering (L) defer.

---

## Anti-features (explicit out-of-scope)

Consolidated from FEATURES and PITFALLS, with rationale:

| Anti-feature | Reason |
|---|---|
| Posting / replying / liking / retweeting from the gadget | Write scopes not requested and not appropriate for a personal dashboard. v1.16 is also read-only. |
| Following / unfollowing accounts from `/x_accounts` | Same as above — write surface lives on x.com. |
| Embedded `widgets.js` / oEmbed | Third-party JS, breaks "no new client-side state" constraint, degrades as x.com changes embed rules. |
| Real-time updates (WebSocket / SSE / Turbo Streams) | No ActionCable; welcome-render-time fetch is the contract. |
| Auto-refresh of following list (cron / Solid Queue / background) | PROJECT.md: "新規バックグラウンドインフラは入れない." Manual button only. |
| Background jobs for tweet caching | Same — tweets fetched live per render. |
| Cross-platform merged Mastodon+X timeline | Couples two clients that fail independently; v1.16 set the per-platform separation precedent. |
| Threaded conversation view, DMs, Spaces, Communities | Out of Basic-tier scope and out of dashboard scope. |
| Per-tweet engagement-metric badges (RT / like counts) | Visual noise; doesn't help "what did this account say recently." |
| In-page OAuth re-connect / scope-upgrade flow | Redirect to standard `/users/auth/twitter` is sufficient for the revoked-token recovery path. |
| Mute words, content warnings, sentiment scoring | Users self-curate by selecting accounts. |
| Fixing the v1.17 PITFALL-02 `from_omniauth` name-lookup bug | Carry-forward only — `twitter_uid` (or `users.uid`) populated by v1.18 is the prerequisite; switching `find_by(name:)` → `find_by(uid:)` is a separate milestone because it touches identity semantics for pre-v1.18 users. |
| Dropping the `users.name` UNIQUE INDEX | Same reason as above — identity-touching, deferred. |
| Confirmable / mailer pipeline for X email | Carry-forward from v1.17; no new mailer infra in v1.18 either. |

---

## Architecture Outline

**Data model — single `x_accounts` table** (ARCHITECTURE option (a); FEATURES' two-table proposal rejected):

```ruby
create_table :x_accounts do |t|
  t.integer  :user_id,         null: false
  t.string   :x_user_id,       null: false   # X numeric id (snowflake; string-encoded per API)
  t.string   :username,        null: false   # handle, no @
  t.string   :name                            # display name; nullable per API
  t.text     :description                     # bio; management page only
  t.string   :profile_image_url
  t.string   :profile_url,     null: false   # derived: https://x.com/<username>
  t.boolean  :selected,        null: false, default: false
  t.integer  :display_count,   null: false, default: 5
  t.boolean  :deleted,         null: false, default: false
  t.datetime :fetched_at
  t.timestamps
end
add_index :x_accounts, [:user_id, :x_user_id], unique: true
add_index :x_accounts, [:user_id, :selected, :deleted]
```

Refresh diff semantics (ARCHITECTURE):
- API hit → upsert by `(user_id, x_user_id)`; re-set `deleted=false` if previously soft-deleted (user re-followed).
- Existing row not in the response → if `selected=true`, soft-delete (preserve the user's pin so the UI can show "X dropped from following"); else hard-delete.

**OAuth persistence** — see Critical Finding #2 + Column-naming resolution. Token rotation: every successful Twitter sign-in overwrites `(token, token_secret, uid)`. No backfill migration; pre-v1.18 Twitter users back-fill naturally on their next sign-in. Existing `users.name` lookup in `from_omniauth` is **not** changed in v1.18 (carry-forward).

**Service** — `XClient` is a PORO with `attr_accessor` class-level stub accessors, two public methods (`fetch_following`, `fetch_recent_tweets`), private Faraday connection builder with `faraday-oauth1` middleware. Same `CONNECT_TIMEOUT = 3` / `READ_TIMEOUT = 5` / `PREVIEW_LENGTH = 100` constants as `MastodonClient`. Errors return `{ success: false, error: <sym> }`; the symbol enum is `MastodonClient`'s plus `:unauthorized` (401 — token revoked, CTA: re-sign-in) and `:rate_limited` (429 — CTA: wait; surface `x-rate-limit-reset` if present). Optional future symbol: `:suspended` (PITFALL-3G; partial-error row-level signal alongside `data`).

**Controller + routes:**

```ruby
resources :x_accounts, only: %i[index show update] do
  collection { post 'refresh' }
end
```

No `new` / `create` / `destroy` — additions come from refresh, removal comes from `update selected=false` or the refresh-diff.

**Portal integration** — one block in `Portal#get_gadgets` after the existing `MastodonAccount` block, scoped to `selected: true`. Partial path `welcome/_x_account.html.erb` is derived from class name automatically. No new portal-layout work; no new preference column (selection presence is the on/off signal, matching the Mastodon precedent).

---

## Disagreement Resolution

### OAuth 1.0a signing

- **STACK recommended:** Add `faraday-oauth1 ~> 1.0` (Faraday-native request middleware; transitively depends on `simple_oauth 0.4.1`). Keeps Faraday-everywhere, keeps `:test` adapter parity with `mastodon_client_test.rb`.
- **PITFALLS recommended:** Use `OAuth::AccessToken` from the already-transitive `oauth 1.1.3` gem (no new dep; "use what we already ship").
- **ARCHITECTURE flagged as:** planner-level D-XX between (A) `oauth` gem direct = cheapest but Net::HTTP-coupled and loses Faraday `:test` adapter, vs (B) Faraday + middleware or hand-rolled = keeps Faraday parity but adds a gem or ~30 lines.

**Resolution: STACK's `faraday-oauth1`. Rationale:**

1. **Test-pattern parity is non-negotiable.** `mastodon_client_test.rb` is the project's documented pattern; PROJECT.md (key decisions row, line 162) explicitly avoids `webmock` / `vcr`. The `oauth` gem's `OAuth::AccessToken` uses `Net::HTTP` and would force WebMock or hand-built stubs *just for `XClient` tests*, fragmenting the project's two services across two test conventions.
2. **Two HTTP transports is more cost than one tiny middleware gem.** Mastodon uses Faraday; X via `OAuth::AccessToken` would use Net::HTTP. Two different timeout shapes, two different rescue trees, two different test-stub strategies — for two adjacent gadgets that are otherwise mirror-images.
3. **`faraday-oauth1` is fit-for-purpose, current, and small.** 1.0.0 released 2026-02-18, ~150 LOC MIT, declares `faraday (>= 1.10, < 3)` so it composes with the locked `faraday 1.10.5`. Signing is delegated to `simple_oauth` (41M downloads; battle-tested). Worst-case abandonment recovery is copying ~100 lines into `lib/`.
4. **Hand-rolled HMAC-SHA1 is rejected by all three researchers** for the same reason: parameter normalization, percent-encoding, nonce + timestamp assembly are footguns the community has solved.
5. **PITFALLS' "use what we already ship" argument is sound for `simple_oauth` (transitively pulled by `faraday-oauth1`), not for the `oauth` gem.** The `oauth` gem is transitive via `omniauth-oauth`, but its standalone use is awkward and undocumented as PITFALLS itself acknowledges. `faraday-oauth1` + `simple_oauth` *is* the modern Faraday-native equivalent of what `oauth` does.

**One open detail for the planner:** the `faraday-oauth1` middleware reads `consumer_key/consumer_secret/token/token_secret` from `f.request :oauth1, …` options. Those four values are read per-request from `Rails.application.config.app_config.omniauth_twitter_client_id/_secret` (consumer pair; already loaded for `config/initializers/devise.rb:262-264`) and the per-user `User#token / #token_secret` (or `twitter_oauth_token / _secret` under option B below). No new credentials surface.

### Column naming (new vs reuse existing dead columns)

- **STACK + PITFALLS recommended:** Reuse `users.provider`, `users.uid`, `users.token` (already in `db/schema.rb:109,114,115`; verified currently dead via repo grep). Add **one** new column `users.token_secret`. PROJECT.md explicitly frames v1.17 PITFALL-02 as "wire up the columns that already exist for this." Minimum migration.
- **ARCHITECTURE recommended:** Add **three** new explicit columns `users.twitter_uid`, `users.twitter_oauth_token`, `users.twitter_oauth_token_secret`. Rationale: (a) the existing columns are vestigial OmniAuth scaffolding with no semantic provider scope, (b) adding a second authenticated provider in the future would be ambiguous on shared columns, (c) Google OAuth 2.0's "access token" doesn't have a "secret" partner — co-locating both providers' creds on one column shape misrepresents the schema. Existing dead columns are pre-existing tech debt; deleting them is a separate task, explicitly out of v1.18 scope.

**Synthesizer's lean — recommend STACK/PITFALLS reuse (single new column `token_secret`). Rationale:**

1. **Two of three researchers agree**, and STACK's reasoning that PROJECT.md explicitly positions v1.17 PITFALL-02 closure as "use the columns already on the table" is a strong constraint.
2. **Minimum-code principle wins on tie.** Reuse = 1 new column + 1 model `encrypts` line. New = 3 new columns + 1 model `encrypts` line + (eventually) a column-drop migration for the dead trio.
3. **The provider-scope ambiguity ARCHITECTURE raises is real but small.** This codebase has two OAuth providers and one is OAuth 2.0 (Google) where we don't store tokens at all (no `from_omniauth` write of any Google credential), so there is no actual collision today. A future 3rd provider would re-open the question — but that is exactly the speculative-reuse rule asks us to defer.
4. **`provider`/`uid` semantics generalize cleanly across OAuth 1.0a and 2.0.** The "provider scope" objection only really binds at the `token` column because OAuth1's secret has no OAuth2 equivalent. That asymmetry is what `token_secret` (nullable) already captures.

**Decision required from user — flag prominently:**

> **Option 1 (recommended): Reuse `users.{provider, uid, token}`; add only `users.token_secret`.** One column added; `encrypts :token, :token_secret`. Aligns with PROJECT.md's framing of v1.17 PITFALL-02 carry-forward. Pre-existing dead columns become alive.
>
> **Option 2: Add `users.{twitter_uid, twitter_oauth_token, twitter_oauth_token_secret}`; leave `users.{provider, uid, token}` dead.** Three columns added; `encrypts :twitter_oauth_token, :twitter_oauth_token_secret`. Provider-scoped names; ARCHITECTURE-style. Pays a future cost: dead columns remain on the schema until a follow-up drops them.

Either option works with every other recommendation in this summary. The signing gem, controller shape, gate predicate, phase decomposition, and stub contract are **identical** between options — only the model attribute names change. Pick before phase 60 starts.

### Phase decomposition

- **ARCHITECTURE proposed 4 phases:** 60 OAuth persistence → 61 `XClient` service → 62 model + management UI + refresh → 63 welcome gadget + tests + tri-suite gate.
- **PITFALLS hinted at 6 phases:** OAuth persistence → `XClient` service → following-list sync → admin `/x_accounts` UI → welcome gadget → test/i18n/tri-suite gate.

**Resolution: 4 phases (ARCHITECTURE's), numbered 60–63. Rationale:**

1. **PITFALLS' "following-list sync" and "admin UI" are not separable.** The sync routine is the management page's reason to exist; there is no standalone-valuable phase that ships sync without a UI to consume it, and no UI that ships without sync because the management page is empty otherwise. Splitting them would create a phase whose deliverable is "plumbing with no user-visible effect" — anti-pattern under the project's phase-end gate policy.
2. **A separate "test/i18n/tri-suite" phase is anti-pattern.** Per `CLAUDE.md`, *every* phase ends with the tri-suite green-bar gate. Tests + locale parity must already be green at the end of each prior phase. A dedicated "tests" phase would either (a) be empty (already done) or (b) reveal that an earlier phase shipped without tests (process failure). The integration-test sweep belongs *inside* Phase 63 alongside the welcome gadget, which is where the Cucumber `@x_gadget` scenario naturally lives.
3. **4 maps cleanly to the dependency chain.** Auth persistence → service → cache + selection UI → welcome integration. Each phase has one primary deliverable, one tri-suite gate, and a clear seam to the next.
4. **3 is too coarse, 5–6 are over-decomposed.** A 3-phase plan (fuse 62 + 63) hides two distinct user-visible deliverables behind one phase-end gate. A 5+ plan splits seam-less work.

See "Suggested Build Order" table at the bottom.

---

## Watch Out For (top 5 pitfalls)

From PITFALLS.md, ranked by severity for the roadmapper:

1. **`users.name` is the display name, not the screen_name** (PITFALL-3A, CRITICAL). Resolved above. Codifies the entire v1.18 OAuth-persistence phase shape.
2. **No `token_secret` column today** (PITFALL-2A, CRITICAL). Without it, every signed request fails with 401. Resolved by Phase 60 migration.
3. **Twitter re-auth does not update stored credentials today** (PITFALL-2C, HIGH). `from_omniauth`'s Twitter branch has `User.where(name: …).first; user ||= User.create(…)` — no `update!` on the find path. Result: a revoked-then-re-authed user appears signed in but every API call 401s with stale tokens. Phase 60 must add `user.update!(…)` outside the `||=`.
4. **Cardinality + privacy combo on selection** (PITFALL-4C + 3F + 7B, HIGH). Mastodon's pattern assumes 3–5 accounts; X following routinely runs 500–5000. Welcome page must not fire N parallel XHRs unbounded. Hard cap selection at a low number (recommend ~9–12 to fit the 3-column portal cleanly on mobile; PITFALLS suggests ≤20). Plus: protected accounts that the OAuth1-signed user can read may leak to screenshots — default-off display for `protected: true` accounts with an explicit confirmation toggle, plus a "🔒" badge in the gadget title.
5. **OAuth 2.0 PKCE doc drift** (PITFALL-1A, MEDIUM). developer.x.com defaults its "Try it" snippets to OAuth 2.0 Bearer. Copy-pasting them into the OAuth 1.0a code path produces 401 with body `{"title":"Unauthorized"}` and no actionable hint. The signing-gem decision above forecloses this footgun in practice; capture in the phase 61 plan as a "verify Authorization header looks like `OAuth oauth_consumer_key=...`" smoke step.

Also flagged but lower-priority for the roadmapper (encode in phase plans as they apply):

- **PITFALL-3J** — `max_results` minimum is **5**; `display_count: 3` will 400. Clamp `XClient` request to `[display_count, 5].max.clamp(5, 100)` and slice client-side.
- **PITFALL-4B** — X tweet `text` is plain text with raw `t.co` URLs. Resolve via `entities.urls[].display_url` **before** truncation; do not auto-link.
- **PITFALL-3I** — Retweet / reply / quote handling: send `?exclude=retweets,replies` by default; render the original text on `referenced_tweets[].type == 'retweeted'` if retweets are ever included.
- **PITFALL-3D** — Pagination param is **`pagination_token`** (request) → `meta.next_token` (response). Don't reuse `next_token` for both. Cap pages at ~10 (≤1000 followings per sync).
- **PITFALL-3H** — Edit history: latest version's id is the **last** element of `edit_history_tweet_ids`. Render that. URL: `https://x.com/i/status/<latest_id>`.
- **PITFALL-7D** — Never `raw` / `html_safe` tweet text or URL. Hardcode the click-through URL construction inside `XClient`; never echo `entities.urls[].url`.
- **PITFALL-6A** — In `XClient` Minitest, **don't** install OAuth1 middleware on the `:test` Faraday connection. The signed-request assertion is out of scope for unit tests; optionally add one integration test that builds a real connection and asserts `Authorization` starts with `OAuth oauth_consumer_key=`.
- **PITFALL-6C** — Cucumber DB-state leakage (per `CLAUDE.md`'s flake note): extend the global `Before` to `XAccount.where(user_id: fixture_user.id).delete_all` and clear `XClient.stub_*_result` accessors. Otherwise scenario-order failures are inevitable.

---

## Stub Contract

Two class-level accessors on `XClient`, one per public method, mirroring `MastodonClient.stub_fetch_result`'s shape:

```ruby
# Following-list stub:
XClient.stub_fetch_following_result = {
  success: true,
  items: [
    { x_user_id: '12345', username: 'jack', name: 'Jack Dorsey',
      description: 'co-f…', profile_image_url: 'https://pbs.twimg.com/…' },
    # …
  ]
}

# Recent-tweets stub:
XClient.stub_fetch_tweets_result = {
  success: true,
  items: [
    { text: 'Cucumber stub tweet preview',
      url:  'https://x.com/i/status/9000000000000000001' },
    # …
  ]
}

# Error shape (either accessor):
XClient.stub_fetch_tweets_result = { success: false, error: :unauthorized }
# Allowed error symbols: :timeout, :network, :not_found, :api_error, :parse_error,
#                        :unauthorized, :rate_limited
# (Optional future addition: :suspended for row-level partial-failure signal.)
```

Naming rationale: `stub_fetch_*_result` literally mirrors `MastodonClient.stub_fetch_result` with the method-specific noun inserted, making the parallel between method and stub explicit (`fetch_following` ↔ `stub_fetch_following_result`).

Splitting into two accessors (vs one `{ following:, tweets: }` hash) is deliberate: most tests stub only one of the two methods, and a single accessor makes "forgot to clear the other" a real test footgun. Both accessors are cleared in Minitest `setup` + `teardown` (verbatim mirror of `test/services/mastodon_client_test.rb:4-10`) and in a Cucumber `After('@x_gadget')` hook.

Normalization helper (mirror of `MastodonClient.normalize_stub_result`): rejects non-Hash, coerces with `with_indifferent_access`, falls back to `{ success: false, error: :api_error }` on malformed input.

---

## Open Questions for the User

Keep this short — these block requirements-phase writing:

1. **Column naming (Option 1 reuse vs Option 2 new `twitter_*`)** — see Disagreement Resolution → Column naming. Recommend **Option 1** but flagged because ARCHITECTURE's provider-scope argument is real for any future 3rd provider.
2. **Selection cap value** — PITFALLS suggests ≤20; mobile portal-column ergonomics suggest ~9–12 (3 per column). Recommend **12** as the hard cap (validation in `XAccountsController#update`), with a soft warning at 9. The cap matters because welcome render fires N parallel XHRs and lives within the per-15-minute X rate window.
3. **Protected-account default behavior** — Recommend **default-off display with explicit per-account confirmation toggle on the management page** (PITFALL-3F / 7B). User can confirm whether this lighter-touch approach is acceptable or whether protected accounts should be excluded entirely from the cache.

Everything else (encryption at rest, ja/en parity, soft-delete-only-when-selected, `:exclude=retweets,replies` default, `max_results` clamp, OAuth-1.0a-via-`faraday-oauth1`, four phases) is sufficiently resolved by the research to proceed without confirmation.

---

## Suggested Build Order (Phases)

| Phase | Name | Goal | Why before next |
|-------|------|------|-----------------|
| 60 | User OAuth token persistence | Migration adds `token_secret` (Option 1) or `twitter_uid/oauth_token/oauth_token_secret` (Option 2); `User` model `encrypts`; rewrite `from_omniauth` Twitter branch to write all four fields on create AND update; OmniAuth test-mock hash; fixture user populated; `users.name`-bypass-bug closed by gate predicate switching to `uid + token`. No UI. | Every downstream phase reads `current_user.token` / `_secret` to talk to X. Without this, all later phases test against `nil`-token stubs only. |
| 61 | `XClient` service + stub contract | New `app/services/x_client.rb` + `test/services/x_client_test.rb`. `fetch_following`, `fetch_recent_tweets`, two `stub_fetch_*_result` class accessors, error matrix (`:unauthorized`, `:rate_limited` added). `faraday-oauth1` gem added; `Gemfile.lock` regenerated. `simple_oauth` middleware composed onto the Faraday connection. Pagination via `pagination_token`. `max_results` clamp. t.co expansion via `entities.urls`. Edit-history latest-id resolution. No UI. | Phase 62's controller instantiates `XClient` directly. The service must be tested and stub-callable before controller-level Cucumber scenarios can run. |
| 62 | `XAccount` model + management UI + refresh-diff | Migration `create_x_accounts`; `app/models/x_account.rb`; `XAccountsController#index/refresh/update`; `app/views/x_accounts/index.html.erb`; refresh diff-upsert routine; selection-cap validation; protected-badge UI; routes (sans `:show`); `require_twitter_linked` `before_action`; drawer link gated on the same predicate; ja/en locale keys for index + refresh outcomes + error messages. Cucumber-flake guard: add `XAccount.where(user_id: fixture_user.id).delete_all` to global Before. | The management page must exist and be usable in isolation before the welcome gadget can ship — there's nothing for the welcome gadget to enumerate without `selected: true` rows. Phase boundary delivers a complete-without-welcome MVP. |
| 63 | Welcome gadget integration + show action + tri-suite gate | Route `:show`; `XAccountsController#show` (HTML + XHR via `render layout: !request.xhr?`); `app/views/x_accounts/show.html.erb`; `app/views/welcome/_x_account.html.erb` (jQuery loader, `data-fetch-failed-message`); `Portal#get_gadgets` registers `XAccount.where(user_id:, selected: true).not_deleted`; `welcome.x_account.*` + `x_accounts.show.*` locale keys; integration test for layout count; Cucumber `features/06.X.feature` with `@x_gadget` Before/After hooks for `stub_fetch_*_result`. Tri-suite gate (with documented Cucumber flake rerun policy). | Welcome integration is the final user-visible deliverable. It depends on Phase 61 (service) and Phase 62 (selection rows in fixtures) and is the natural home for the end-to-end Cucumber scenario. |

Phase 60 is the riskiest single phase (touches identity-adjacent code); Phase 63 is the lowest-risk and highest user-visible-payoff per LOC.
