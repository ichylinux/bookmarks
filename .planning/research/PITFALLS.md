# Pitfalls Research — v1.18 X (Twitter) Account Following

**Project:** Bookmarks v1.18
**Researched:** 2026-05-14
**Confidence:** HIGH (codebase directly inspected; X API behaviour cross-checked against developer.x.com / docs.x.com; omniauth-twitter 1.4.0 source confirmed)

---

## Summary

The dominant v1.18 risks come from **OAuth state that the app currently throws away** and from **conflating Twitter's display name with screen_name / numeric id**:

1. **CRITICAL — `users.name` is the Twitter *display name*, not the screen_name.** The current `User.from_omniauth` (`app/models/user.rb:29`) stores `data["name"]` which omniauth-twitter populates from `raw_info['name']` (display name), not `raw_info['screen_name']`. X API v2 endpoints take **numeric `uid`** (preferred) or **screen_name**. They will not accept the display name. Building gadgets on top of `users.name` will produce 404s and silently misroute renames. This converges with v1.17 PITFALL-02 and must be resolved in this milestone.
2. **CRITICAL — OAuth 1.0a tokens are never persisted** (`provider`, `uid`, `token` columns exist on `users` but the Twitter branch of `from_omniauth` writes none of them; no column exists for the OAuth 1.0a *token secret*). Without `(token, token_secret, uid)` saved, the app cannot make a single X API v2 user-context call. Re-auth on the existing user also does not refresh credentials today, so revocation produces silent 401 storms.
3. **HIGH — `users.name` is user-editable through `preferences_controller#user_params`** (`:name` is permitted on `app/controllers/preferences_controller.rb:44`). If `/x_accounts` gating uses `current_user.name.present?`, any non-Twitter user can flip the gate by setting a name in preferences. Gate must check `provider == 'twitter' && uid.present?` after the schema fix.
4. **HIGH — X API v2 OAuth-2.0 / OAuth-1.0a documentation drift.** Most copy-paste examples for `/2/users/:id/tweets` assume OAuth 2.0 PKCE (`Authorization: Bearer …`). This codebase is OAuth 1.0a (omniauth-twitter 1.4.0 → omniauth-oauth 1.2.1 → oauth 1.1.3, HMAC-SHA1). Picking the wrong code samples produces 401 with `"Unauthorized"` and no actionable hint.
5. **MEDIUM — Mastodon-pattern reuse hides cardinality and visibility mismatches.** Mastodon users add 3–5 accounts manually; an X following list is routinely 500–5000. Without a hard cap, pagination UI, and protected-tweet filtering, the welcome page is unbounded and may leak followers-only content into screenshots.

---

## 1. OAuth 1.0a Pitfalls

### PITFALL-1A: Copy-pasting OAuth 2.0 PKCE samples into an OAuth 1.0a app
- **Warning sign:** `Authorization: Bearer …` headers; tutorial uses `client_id` + `code_verifier`; 401 responses with body `{"title":"Unauthorized","type":"about:blank","status":401}`. Most of `developer.x.com`'s "Try it" snippets default to OAuth 2.0 PKCE because that's what the Postman collection ships with.
- **Prevention:** Build `XClient` on the `oauth` gem (`OAuth::AccessToken.new(consumer, token, token_secret)`) — it's already a transitive dependency of `omniauth-twitter`. Use `OAuth::Consumer.new(consumer_key, consumer_secret, site: 'https://api.x.com')` with `Rails.application.config.app_config.omniauth_twitter_client_id` / `_secret` (same values `config/initializers/devise.rb:262-264` already loads). Do **not** introduce a Bearer-token code path.
- **Phase:** `XClient` service phase (first phase that touches X API).

### PITFALL-1B: `oauth_token` (OAuth1) vs `access_token` (OAuth2) nomenclature
- **Warning sign:** Tests stub `Authorization: Bearer X` or model column named `access_token`; commits add a `refresh_token` column "for symmetry". OAuth 1.0a has no refresh token — tokens are long-lived until revoked.
- **Prevention:** Name the columns `token` (reuse existing) and `token_secret`. Do **not** add `refresh_token`, `access_token`, `expires_at`. In Ruby: store `auth.credentials.token` and `auth.credentials.secret` (per omniauth-twitter `info`/`credentials` schema, confirmed in `lib/omniauth/strategies/twitter.rb`). The `expires` field on Twitter credentials is always `false`.
- **Phase:** OAuth persistence phase (schema migration + `User.from_omniauth` update).

### PITFALL-1C: Hand-rolling HMAC-SHA1 signing
- **Warning sign:** PR introduces percent-encoding helpers, sorts params manually, builds a base string. Tests for the signer are passing locally but X returns `401 Could not authenticate you`.
- **Prevention:** Let the `oauth` gem sign. `OAuth::AccessToken#get(path, headers)` produces a correctly signed `Authorization: OAuth oauth_consumer_key="…", oauth_token="…", oauth_signature="…", oauth_signature_method="HMAC-SHA1", oauth_timestamp="…", oauth_nonce="…", oauth_version="1.0"` header. If Faraday is preferred for symmetry with `MastodonClient`, use `Faraday` + `simple_oauth` middleware (NOT manual). Never hand-write the signature base string.
- **Phase:** `XClient` service phase.

### PITFALL-1D: Host inconsistency between omniauth and API client
- **Warning sign:** OAuth callback works (`api.twitter.com`) but API client hits `api.x.com` (or vice versa) — signature is computed against the wrong host string and fails.
- **Prevention:** omniauth-twitter 1.4.0 already targets `https://api.x.com` (see strategy source: `client_options.site = 'https://api.x.com'`). Use `https://api.x.com` in the `XClient` Faraday/`OAuth::Consumer` `site:` too. Pin the host in a single constant.
- **Phase:** `XClient` service phase.

---

## 2. Token Storage / Rotation Pitfalls

### PITFALL-2A: No column for the OAuth 1.0a token *secret*
- **Warning sign:** Migration adds nothing because "uid, provider, token already exist." First API call signs with `nil` secret and X returns 401.
- **Prevention:** Add a migration `add_column :users, :token_secret, :string`. Both `token` AND `token_secret` are required for every signed request. `db/schema.rb` lines 96–120 currently expose only `token`, `uid`, `provider` — there is no secret column.
- **Phase:** OAuth persistence phase.

### PITFALL-2B: Storing OAuth credentials in plaintext
- **Warning sign:** `users.token` and the new `users.token_secret` are plain `:string` columns. A DB dump leaks every user's X session. `db/schema.rb:114` confirms plaintext storage today.
- **Prevention:** Use Rails 7+ `encrypts :token` / `encrypts :token_secret` on `User`. Confirm `config/credentials.yml.enc` carries an `active_record_encryption` block (Rails 8.1 default) before turning it on; otherwise the migration will fail in production. Add a Minitest that round-trips `User.create!(token: 'x', token_secret: 'y').reload.token == 'x'` to lock the contract.
- **Phase:** OAuth persistence phase (same migration; encryption is part of the model change, not a follow-up).

### PITFALL-2C: Twitter re-auth does not update stored credentials
- **Warning sign:** User revokes the app from X settings, then signs in again. The app still uses the old `token` / `token_secret` because `User.from_omniauth` has `user = User.where(name: ...).first; user ||= User.create(…)` — there is **no `update!` on the existing-user branch** (`app/models/user.rb:29–31`). Result: a clean re-auth from the user's perspective, but API calls keep 401-ing.
- **Prevention:** In the rewritten Twitter branch, on `find`, always `user.update!(token: auth.credentials.token, token_secret: auth.credentials.secret, uid: auth.uid, provider: 'twitter')`. Test by mocking `OmniAuth.config.mock_auth[:twitter]` with NEW credentials against an existing fixture user and asserting the row is overwritten.
- **Phase:** OAuth persistence phase.

### PITFALL-2D: 401 from X is not surfaced — caller sees `:api_error`
- **Warning sign:** Following list silently shows the cached "fetched_at: 3 days ago" forever; refresh button returns generic "fetch failed."
- **Prevention:** In `XClient`, distinguish HTTP 401 → `:unauthorized` from 4xx → `:api_error` and 5xx → `:upstream_error`. Render `:unauthorized` as a CTA in the `/x_accounts` view: "Re-authorize with X" → link to `user_twitter_omniauth_authorize_path` (Devise). Update the existing show-error t-key pattern (`t("x_accounts.show.errors.#{@x_error}")`, mirroring `mastodon_accounts/show.html.erb:6`) to include `:unauthorized` in both `ja.yml` and `en.yml`.
- **Phase:** `XClient` service phase + admin (`/x_accounts`) phase.

### PITFALL-2E: Multiple sign-ins for the "same human" rotate tokens but don't merge accounts
- **Warning sign:** A user already has v1.17-style email registered (real email + dummy provider/uid blank). They sign in again via Twitter — `from_omniauth` falls through to `User.create` because the row doesn't have `(provider, uid)`, producing a duplicate user.
- **Prevention:** New `from_omniauth` Twitter branch lookup order: (1) `User.find_by(provider: 'twitter', uid:)`, (2) if not found AND `data.info.email.present?` (rare from Twitter), `User.find_by(email:)` and backfill `provider`/`uid`/`token`/`token_secret`, (3) else `User.create!`. The `find_by(name:)` path **must be dropped**, not "kept as fallback" — display names are mutable and collide (see PITFALL-3A and v1.17 PITFALL-02).
- **Phase:** OAuth persistence phase.

### PITFALL-2F: Twitter user who later registered an email is now ambiguous
- **Warning sign:** v1.17 carry-forward: a Twitter user registered `alice@gmail.com`. They sign in via Google. `from_omniauth` Google branch (`User.where(email:).first`) finds them, but the user's `provider` is still nil (never persisted on the original Twitter create). `current_user.provider == 'twitter'` returns false — `/x_accounts` is hidden from them even though they still have a valid X session.
- **Prevention:** Gating predicate must be `current_user.uid.present? && current_user.token.present?` (data-driven, not provider-derived). When the OAuth persistence phase lands, backfill task: existing Twitter-originated rows (those whose email matches `/\Adummy_.+@example\.com\z/`) have no uid/token; they **must re-auth once** to populate. Document this as a one-time UX (banner in `/x_accounts/index` if `current_user.name.present? && current_user.uid.blank?`: "Sign in with X again to enable following").
- **Phase:** OAuth persistence phase (gating helper + backfill banner).

### PITFALL-2G: `filter_parameter_logging` does not match every name
- **Warning sign:** Request logs show `"credentials"=>{"token"=>"abc…", "secret"=>"def…"}` because Devise's `omniauth.auth` blob is serialized into the log.
- **Prevention:** `config/initializers/filter_parameter_logging.rb` already filters `:secret`, `:token` (partial match — `oauth_token` also matches). Verify by tailing `log/development.log` after a real Twitter sign-in and grepping for the token prefix. Do **not** log `request.env["omniauth.auth"]` from `Users::OmniauthCallbacksController` (currently it doesn't — `app/controllers/users/omniauth_callbacks_controller.rb` only calls `User.from_omniauth`; keep it that way).
- **Phase:** OAuth persistence phase (verification step, no code change expected).

---

## 3. X API v2 Specifics

### PITFALL-3A: `users.name` is the display name, NOT the screen_name (CRITICAL)
- **Warning sign:** Code passes `current_user.name` to `/2/users/by/username/:username` and gets 404 for users whose display name contains spaces or unicode (most). Or it works for the dev's own account because their handle and display name happen to match.
- **Prevention:** omniauth-twitter source (`lib/omniauth/strategies/twitter.rb`) maps `info.name → raw_info['name']` (display name) and `info.nickname → raw_info['screen_name']` (handle). The `uid` block is `access_token.params[:user_id]` (numeric id). Persist `uid` and never pass `users.name` to X API endpoints. All v2 user-keyed endpoints accept `:id` (numeric) — use that exclusively. If a screen_name display is needed, add a separate `twitter_screen_name` column populated from `auth.info.nickname`.
- **Phase:** OAuth persistence phase (drives the schema decision).

### PITFALL-3B: Endpoint availability differs by access tier
- **Warning sign:** Local dev with Basic plan works; another env using Free plan returns `403 Forbidden { "client_forbidden": true }` for `/2/users/:id/following`.
- **Prevention:** Pin Basic-plan endpoint use to two surfaces only: `GET /2/users/:id/following` (admin sync) and `GET /2/users/:id/tweets` (welcome gadget). Both are Basic-eligible. Do **not** opportunistically call `/2/tweets/search/recent` (Pro) or `/2/users/:id/mentions` (different rate bucket). Add a Minitest that asserts `XClient` only Faraday-hits these two paths (regex on stubbed request URLs).
- **Phase:** `XClient` service phase.

### PITFALL-3C: Rate limit headers / monthly cap not surfaced
- **Warning sign:** Welcome page silently shows stale tweets after the tenant blows past 10K monthly reads (legacy Basic) or 2M pay-per-use cap. The 429 response is logged once and indistinguishable from a transient timeout.
- **Prevention:** In `XClient`, read `x-rate-limit-remaining` / `x-rate-limit-reset` on every response and return them alongside `{ success:, items: }`. On 429, set `error: :rate_limited` and pass `reset_at` to the view. The welcome partial should display a localized "Try again at HH:MM" instead of the generic fetch_failed message. Source: `https://docs.x.com/x-api/fundamentals/rate-limits`. Also catch the monthly-cap signature — 429 with body `{"title":"UsageCapExceeded","period":"Monthly","scope":"Product"}` — and render a distinct admin-facing error key so the operator knows it's a billing issue, not a transient blip.
- **Phase:** `XClient` service phase.

### PITFALL-3D: Pagination token name varies by endpoint
- **Warning sign:** Code uses `next_token` everywhere; the second page of following list never loads because `/2/users/:id/following` uses `pagination_token` (request) → `meta.next_token` (response). Reusing `next_token` for both directions is the actual trap.
- **Prevention:** In `XClient`, name the request parameter `pagination_token:` explicitly and read the response's `meta['next_token']`. Source: `https://docs.x.com/x-api/users/follows/introduction`. Cap pages at e.g. 10 (1000 followed accounts) per sync to avoid pathological loops; X following lists have a 5000-account upper bound in practice.
- **Phase:** Following-list sync phase.

### PITFALL-3E: Default response shape is shallow
- **Warning sign:** Tweets render with no author info ("by null"), or retweets render as `"RT @somebody:"` truncated mid-username.
- **Prevention:** For `/2/users/:id/tweets`, always send:
  ```
  tweet.fields=created_at,text,entities,referenced_tweets,edit_history_tweet_ids,public_metrics
  expansions=referenced_tweets.id,attachments.media_keys
  media.fields=type,preview_image_url
  ```
  For `/2/users/:id/following`:
  ```
  user.fields=username,name,protected,verified,profile_image_url
  ```
  Document the field list in `XClient` as constants. Without `entities`, you have no way to render hashtag/URL entities safely (see PITFALL-7D).
- **Phase:** `XClient` service phase.

### PITFALL-3F: Protected (private) accounts visible to follower but unwelcome on a welcome page
- **Warning sign:** A protected account that the user follows shows tweets fetched fine via OAuth 1.0a user-context. User shares a screenshot — protected-tweet contents leak publicly.
- **Prevention:** In the admin selection UI, show a "Protected" badge when `user.protected == true` (from `user.fields=protected`). Block selection by default with a confirmation toggle "I understand this user's tweets may appear on my welcome page." Document this in the privacy notice. Conservative default: skip protected accounts in welcome gadgets unless explicitly opted in.
- **Phase:** Admin (`/x_accounts`) phase + welcome gadget phase.

### PITFALL-3G: Suspended / withheld accounts produce partial errors
- **Warning sign:** `/2/users/:id/tweets` returns `{ "data": [], "errors": [{ "title": "Authorization Error", "detail": "...account suspended..." }] }` — controller sees `data:[]` and renders "no tweets" forever, masking that the account is dead.
- **Prevention:** X API v2's contract: `errors` may appear *alongside* `data` for partial failures (source: `https://docs.x.com/x-api/fundamentals/consistency`). In `XClient`, treat `response.body['errors']` as advisory metadata, not a fatal flag. Surface a row-level `:suspended` symbol so the welcome gadget can show "@user is unavailable" with a localized message and a soft-delete suggestion in the admin UI.
- **Phase:** `XClient` service phase + welcome gadget phase.

### PITFALL-3H: Edit history — the requested tweet may not be the latest version
- **Warning sign:** A user edits a tweet on X (Blue/Premium feature) — the welcome gadget keeps showing the original text. Worse: original tweet was deleted in favor of edit, returning 404 on click-through.
- **Prevention:** When `edit_history_tweet_ids` length > 1, the latest version's id is the **last** element. Show that one's text. If `/2/users/:id/tweets` returns a tweet whose `id` is not the latest in its own `edit_history_tweet_ids`, log a warning (this would indicate an upstream API surprise). For URLs, use `https://x.com/i/status/<latest_id>` rather than the originally fetched id.
- **Phase:** `XClient` service phase.

### PITFALL-3I: Retweets / replies / quotes render as truncated junk by default
- **Warning sign:** Gadget rows show `"RT @verylongusername…"` (truncated to the per-tweet preview length). Reply chains look like context-free fragments.
- **Prevention:** Inspect `referenced_tweets[].type`:
  - `retweeted` → resolve via `expansions=referenced_tweets.id` and show the referenced tweet's text + " (RT @author)"; do NOT truncate the inner text at the boundary
  - `replied_to` → prefix with "↳ reply" badge; consider filtering out replies from the gadget feed entirely (Mastodon does)
  - `quoted` → show the user's own text; link to the quoted tweet without inlining
  Match the v1.16 Mastodon contract: gadget shows authored content only. Add a `XClient` constant `EXCLUDE_REPLIES = true` (default on); make the admin UI surface a toggle if needed later.
- **Phase:** `XClient` service phase + welcome gadget phase.

### PITFALL-3J: max_results minimum is 5 — requesting fewer 400s
- **Warning sign:** User configures `display_count: 3` (matches Mastodon default). Request fails with `400 { "title":"Invalid Request","detail":"max_results must be in the range 5..100" }`.
- **Prevention:** Clamp `XClient` request to `max_results = [display_count, 5].max.clamp(5, 100)` and slice client-side after parsing. Source: `https://developer.x.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-tweets`. Add a Minitest that verifies the clamp behaviour.
- **Phase:** `XClient` service phase.

---

## 4. Mastodon-Pattern Adaptation Pitfalls

### PITFALL-4A: `stub_fetch_result` class-level state leaks across tests
- **Warning sign:** `XClient.stub_fetch_result = {…}` set in one Cucumber scenario; a later (untagged) scenario hits live network or asserts the wrong stub.
- **Prevention:** Mirror the v1.16 contract exactly: in `features/support/hooks.rb`, add `After('@x_gadget') do XClient.stub_fetch_result = nil end`. In Minitest, add `setup` and `teardown` on every `XClient` test that sets `XClient.stub_fetch_result = nil` (verbatim from `test/services/mastodon_client_test.rb:4–10`). Add the same `XAccount.delete_all` + `user.update!(uid: nil, token: nil, token_secret: nil)` to the global `Before` to cover sign-in state leakage flagged by `CLAUDE.md` Cucumber flakiness.
- **Phase:** Test setup phase (concurrent with `XClient` service phase).

### PITFALL-4B: Tweet text + entities is not Mastodon HTML; sanitization path differs
- **Warning sign:** Re-using `ActionController::Base.helpers.strip_tags(html).squish.truncate(100, omission: '…')` (from `app/services/mastodon_client.rb:81–84`) on X API output. The X `text` field is **plain text with raw URLs/mentions/hashtags inline** (no HTML); `strip_tags` is a no-op. URLs aren't shortened; `https://t.co/abc123` appears literally and the preview line becomes a wall of t.co links.
- **Prevention:** Two-stage:
  1. Resolve t.co URLs via `entities.urls[].expanded_url` (or `display_url` for the preview).
  2. Replace each URL substring in the text with its `display_url` BEFORE `truncate(100)`. Don't `auto_link` — return plain text only (matching Mastodon gadget contract).
  Use `entities.mentions` to verify mentions render as-is (they're already `@name` in the text). Add a Minitest fixture with an actual tweet payload + t.co URL and assert the preview contains `example.com/article`, not `t.co/abc`.
- **Phase:** `XClient` service phase.

### PITFALL-4C: Cardinality explosion — Mastodon ~5, X following 500–5000
- **Warning sign:** Admin page hangs syncing 4000 followed accounts; user picks 200 to display; welcome page issues 200 parallel AJAX calls and exhausts the rate limit in 8 minutes.
- **Prevention:** Hard caps in code:
  - DB cache table `x_accounts_followed` stores up to N pages (10 × 1000) of following metadata; soft-cap.
  - A separate selection table or `display_on_welcome` boolean on the cache row, **capped at 20 active selections per user** (enforce in controller + model validation). Mirror MastodonAccount.display_count semantics but at the per-account level.
  - Welcome gadget AJAX is serial per gadget (existing pattern) — but consider lazy "View tweets" placeholders for 10+ gadget cardinalities so the page doesn't fire all requests on load.
  - Following-list refresh is **manual** (button), not on every page load (per PROJECT.md decision).
- **Phase:** Following-list sync phase + admin (`/x_accounts`) phase.

### PITFALL-4D: Two distinct concerns — cached following list vs selected gadgets
- **Warning sign:** Repurposing `MastodonAccount` shape (one row per gadget) for both "everyone I follow" AND "subset displayed on welcome" — the cache table grows unbounded with selection state mixed in; soft-delete of an unfollow stomps on display preferences.
- **Prevention:** Two responsibilities, two columns at minimum:
  - `x_followed_accounts` (cache): `user_id, target_user_id (numeric), screen_name, name, protected, fetched_at` with composite uniqueness `(user_id, target_user_id)`.
  - On the same row: `display_on_welcome` boolean (default false), `display_order` integer. Or split into `x_followed_accounts` + `x_gadget_selections` if foreign-key separation pays off; the simpler one-table form is sufficient for v1.18.
  - `Portal#get_gadgets` iterates `XFollowedAccount.where(user_id:, display_on_welcome: true).order(:display_order)` — pattern identical to `MastodonAccount.where(user_id:).not_deleted` at `app/models/portal.rb:73-75`.
- **Phase:** Schema / model phase.

### PITFALL-4E: Mobile portal layout exceeds 3 columns
- **Warning sign:** User selects 15 X accounts → 15 gadgets → `portal_columns` (3 fixed buckets in `app/models/portal.rb:13`) crams 5 gadgets per column; mobile portal tab strip (`portal-mobile-breakpoint` 768px) creates a column-3 tab with 5+ heavy AJAX-loading gadgets. Layout becomes unusable.
- **Prevention:** Don't widen portal columns. Cap selection at ~12 (PITFALL-4C cap suggests 20; for mobile considerations, default lower e.g. 9 = 3 per column visible; allow override but warn). Document the relationship between selection cap and mobile UX in `REQUIREMENTS.md`.
- **Phase:** Admin (`/x_accounts`) phase.

---

## 5. i18n / Theme Pitfalls

### PITFALL-5A: Locale key parity will fail if any error symbol is missing
- **Warning sign:** Adding error symbol `:rate_limited` (or `:unauthorized`, `:suspended`) to `XClient` but not to both `ja.yml` and `en.yml`. `LocalesParityTest` (existing gate, see v1.17 audit) fails.
- **Prevention:** Enumerate the symbol set in `XClient` as a constant `ERROR_KEYS = %i[timeout network not_found api_error parse_error unauthorized rate_limited suspended upstream_error]`. Add identically-keyed entries under `x_accounts.show.errors.*` in **both** locale files in the same commit. Mirror the Mastodon controller pattern at `app/views/mastodon_accounts/show.html.erb:6`.
- **Phase:** i18n phase (run during `XClient` service phase).

### PITFALL-5B: Translating user-generated tweet text
- **Warning sign:** Someone wraps `item[:text]` in `t(item[:text])` or runs the text through a localization helper. Tweets are user content — bookmark titles, note bodies, todo titles, mastodon previews are all untranslated by design (per PROJECT.md "user content remains untranslated").
- **Prevention:** Display tweet text via plain `<%= item[:text] %>` (ERB auto-escapes — sufficient for XSS since `XClient` returns plain text per PITFALL-4B). Translate only chrome: gadget title prefix, fetched-at relative time labels, error messages, refresh button, empty state. Document in a unit test that asserts `assert_no_match(/^Stub tweet text$/, I18n.t('x_accounts.show'))` for both locales.
- **Phase:** i18n phase.

### PITFALL-5C: Drawer / nav link gating contract differs by theme
- **Warning sign:** Modern theme drawer test asserts "no X link when not Twitter-signed-in"; classic header has no drawer; simple theme tabs ignore X entirely. Adding `nav.x_accounts` t-key but only wiring it into modern theme breaks the drawer-contract test pattern from v1.6.
- **Prevention:** Define the gate as a helper: `def show_x_accounts_link?; current_user.uid.present? && current_user.token.present?; end`. Use it in `_drawer.html.erb` AND the preferences page entry row (mirror v1.17 `email_registration` preferences row pattern). Theme tests must cover both `present` and `blank` token cases. The `users.name`-based gate (mentioned in the prompt) **must not** be used — see PITFALL-3A.
- **Phase:** Admin (`/x_accounts`) phase + preferences entry phase.

---

## 6. Testing Pitfalls

### PITFALL-6A: Faraday test adapter doesn't sign — and that's both a feature and a trap
- **Warning sign:** `Faraday::Adapter::Test::Stubs.new` matches request URLs/headers literally. With `simple_oauth` middleware installed, the adapter sees the SIGNED request and stubs that register the *unsigned* path may or may not match (`oauth_*` params live in the `Authorization` header, not the URL, so URL-only stubs do match — but if you build the stub on a `params:` matcher that asserts `oauth_signature` is present, it gets brittle).
- **Prevention:** Pattern-match URL only in `Faraday::Adapter::Test::Stubs.new` (regex), same as the existing `mastodon_client_test.rb:14`. In the `XClient` test path, **inject a connection** that already has `simple_oauth` middleware short-circuited (`f.adapter :test, stubs` is enough — don't install oauth middleware in the test connection). The test verifies `XClient` behaviour given a signed request *would have happened*; signing itself is the responsibility of the `oauth` gem and is out of test scope. Optionally add ONE integration-style test that builds a real connection (no live network) and asserts `Authorization` header starts with `OAuth oauth_consumer_key=`.
- **Phase:** `XClient` service phase (test wiring).

### PITFALL-6B: OmniAuth mock for the new fields
- **Warning sign:** Existing `OmniAuth.config.mock_auth[:twitter]` fixture lacks `uid` and `credentials`. New `User.from_omniauth` tests fail because `auth.uid` returns nil.
- **Prevention:** Update the test helper (likely `test/test_helper.rb` or a Cucumber `features/support/login.rb` analogue) so the mock auth hash includes:
  ```ruby
  OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
    provider: 'twitter',
    uid: '123456789',
    info: { name: 'Test User', nickname: 'testuser' },
    credentials: { token: 'mock-token', secret: 'mock-token-secret' }
  )
  ```
  Add explicit Minitest cases for: new user create (persists all four fields), existing user re-auth (overwrites token/token_secret), and existing user found by `uid` even after display-name change. Mirror the `omniauth-twitter` `info` schema (confirmed in strategy source).
- **Phase:** OAuth persistence phase.

### PITFALL-6C: Cucumber DB state leakage for X tables (per CLAUDE.md known flakiness)
- **Warning sign:** Scenario A creates `XFollowedAccount` rows with `display_on_welcome: true`; scenario B (untagged) hits `/` and sees stale X gadgets, asserting against the wrong content.
- **Prevention:** Extend the global `Before` in `features/support/hooks.rb` to include `XFollowedAccount.delete_all` AND `user.update!(uid: nil, token: nil, token_secret: nil, provider: nil)`. After the OAuth persistence phase, any test that needs Twitter-linked state must set these explicitly (via a tagged `Before('@twitter_signed_in')`). This is the same fix the existing Cucumber flake document asks for; v1.18 should not paper over it.
- **Phase:** Test setup phase.

### PITFALL-6D: Devise OmniAuth callback test mode requires `OmniAuth.config.test_mode = true`
- **Warning sign:** Tests assert redirect after Twitter callback but get a Devise `omniauth.auth` extraction failure because test mode isn't on.
- **Prevention:** Verify `OmniAuth.config.test_mode = true` is set in `test/test_helper.rb`. If absent, add it in the same phase that touches OAuth code (do not split out into a "test plumbing" phase).
- **Phase:** OAuth persistence phase.

---

## 7. Privacy / Security Pitfalls

### PITFALL-7A: Plaintext token storage in DB
- **Warning sign:** `db/schema.rb` shows `t.string "token"` without `:encrypted`. DB backup → token leak → attacker gains full read access to the user's X account on the user's behalf.
- **Prevention:** Same fix as PITFALL-2B — `encrypts :token, :token_secret` on `User`. The deciding-factor here is that OAuth 1.0a tokens **do not expire**: a leaked token is valid forever until the user revokes. This is qualitatively worse than OAuth2 access-token leak.
- **Phase:** OAuth persistence phase.

### PITFALL-7B: Followers-only / protected tweets on a public-screenshot surface
- **Warning sign:** User screenshots their welcome page to share with a friend. The screenshot contains tweets from a protected account they follow. The protected user did not consent to their content appearing in a screenshot.
- **Prevention:** Default-off display for protected accounts (PITFALL-3F). Optionally: render a privacy badge ("🔒") next to gadget title for protected accounts so the user is aware before screenshotting. The `protected` boolean is available cheaply via `user.fields=protected` on the following-list response.
- **Phase:** Admin (`/x_accounts`) phase + welcome gadget phase.

### PITFALL-7C: Accidentally logging the auth hash
- **Warning sign:** A debug `Rails.logger.info request.env["omniauth.auth"].inspect` slipped into `Users::OmniauthCallbacksController#twitter` for diagnosis and was never reverted. Production log carries every user's token + secret.
- **Prevention:** `config/initializers/filter_parameter_logging.rb` (lines 6–8) covers `:token`, `:secret` via partial match — but `Rails.logger.info` bypasses parameter filtering. Convention: never log the omniauth blob; instead log `auth.uid` and `auth.provider` only. Add a grep-style Cucumber assertion or a Minitest check that the log file (under `tail -f log/test.log` during the Twitter sign-in test) contains no occurrence of the mock token string `"mock-token-secret"`.
- **Phase:** OAuth persistence phase (verification step).

### PITFALL-7D: Open-redirect / XSS via tweet click-through
- **Warning sign:** `link_to item[:text], item[:url], link_opts` in the gadget show view (mirror of `mastodon_accounts/show.html.erb:15`). If `XClient` ever sets `item[:url]` to anything not on `x.com`, clicking is an open redirect through the welcome page.
- **Prevention:** In `XClient`, hardcode the URL construction: `"https://x.com/i/status/#{latest_tweet_id}"`. Do not echo `tweet.entities.urls[].url` into the click-through href. If you must allow per-entity URLs (e.g., for the rich-link preview pattern), validate `URI.parse(url).host` is in a whitelist (`x.com`, `twitter.com`) before rendering. ERB's auto-escape handles XSS in the text via `<%= item[:text] %>` (PITFALL-5B) — but the `href` attribute is its own escape context: never use `raw` / `html_safe` on tweet content or URLs.
- **Phase:** `XClient` service phase + welcome gadget phase.

### PITFALL-7E: Gate bypass via user-editable `users.name`
- **Warning sign:** `current_user.name.present?` used as the Twitter-sign-in marker (the prompt suggests this). Any user can set their name via `/preferences` (`:name` is permitted in `app/controllers/preferences_controller.rb:44`). They then access `/x_accounts` and see API errors from a non-existent Twitter session.
- **Prevention:** Gate on `uid` + `token` presence (PITFALL-5C), not on `name`. Optionally tighten `preferences_controller#user_params` further by removing `:name` from the permit list now that name will be canonical from Twitter — but that's a behaviour change; document the decision.
- **Phase:** OAuth persistence phase + admin (`/x_accounts`) phase.

---

## Carry-Forward from v1.17

**v1.17 PITFALL-02 status: RESOLVED BY v1.18** (mandatory, not optional).

The v1.17 audit (`v1.17-MILESTONE-AUDIT.md`, `tech_debt[future]`) explicitly deferred `from_omniauth` Twitter name-based lookup as a pre-existing risk to not mix into v1.17's scope. v1.18 must now resolve it because every X API v2 endpoint requires a stable identifier (numeric `uid` or screen_name) and the current `User.where(name:)` lookup is structurally incompatible:

| Aspect | v1.17 state (carry-forward) | v1.18 resolution |
|---|---|---|
| Twitter lookup column | `users.name` (display name from `info.name`) | `users.uid` (numeric, from `auth.uid` = `access_token.params[:user_id]`) with `provider: 'twitter'` |
| `users.name` semantics | Treated as quasi-identifier (`UNIQUE INDEX`) | Continues to be the display name; **no longer used for OAuth identity**; can be safely renamed on Twitter without losing the account |
| Token persistence | None (token, uid, provider never written) | `token`, `token_secret` (NEW column), `uid`, `provider` all written on create AND on every re-auth |
| Token encryption | N/A (no tokens stored) | `encrypts :token, :token_secret` on `User` |
| Existing dummy-email users | Have `users.name` only | One-time re-auth banner ("Sign in with X again to enable following") in `/x_accounts` for `current_user.name.present? && current_user.uid.blank?` |
| Email-registered users (v1.17) | Real email, no provider/uid | Future Twitter re-auth populates uid/token via the new `from_omniauth` lookup chain (PITFALL-2E); existing Google sign-in path unchanged |
| `UNIQUE INDEX` on `users.name` | Source of confusing errors when display-name collides | Either drop the unique index (since name is no longer identity) or keep it as a soft constraint — explicit decision in the persistence phase; do not silently leave it |

The OAuth persistence phase is the **first phase in the v1.18 roadmap** because every later phase depends on `(uid, token, token_secret)` being available. Phase ordering hint:

1. OAuth persistence phase (schema migration, `User.from_omniauth` rewrite, encryption, gating helper, OmniAuth test mocks, log-leak verification, backfill banner)
2. `XClient` service phase (Faraday + `simple_oauth` or `OAuth::AccessToken`, the two endpoint methods, error symbol set, rate-limit surfacing, edit-history handling, t.co expansion, `stub_fetch_result` contract)
3. Following-list sync phase (cache table, pagination, refresh button, protected/suspended badges, cap enforcement)
4. Admin `/x_accounts` phase (CRUD-ish picker, gate, selection cap, mobile-layout-aware UI)
5. Welcome gadget phase (`Portal#get_gadgets` wiring, AJAX show partial, error states, click-through URL whitelist)
6. Test / i18n / tri-suite gate phase (Cucumber `@x_gadget` hook mirroring `@mastodon_gadget`, locale parity, ja/en strings, dad:test pass on rerun policy)

---

## Sources

- omniauth-twitter strategy (1.4.0): `https://raw.githubusercontent.com/arunagw/omniauth-twitter/master/lib/omniauth/strategies/twitter.rb` — confirms `uid = access_token.params[:user_id]`, `info.name = raw_info['name']`, `info.nickname = raw_info['screen_name']`, `:site => 'https://api.x.com'`
- OmniAuth auth hash schema: `https://github.com/omniauth/omniauth/wiki/auth-hash-schema` — confirms `credentials.token` / `credentials.secret` for OAuth1
- X API v2 follows endpoint: `https://docs.x.com/x-api/users/follows/introduction` — OAuth 1.0a User Context supported
- X API v2 user tweets endpoint: `https://developer.x.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-tweets` — 900 req/15min (OAuth1 user context), default 100, max 100 (`max_results` 5..100 for this endpoint), pagination via `pagination_token`
- X API v2 rate limits: `https://docs.x.com/x-api/fundamentals/rate-limits` — `x-rate-limit-remaining` / `x-rate-limit-reset` headers
- X API v2 consistency / response shape: `https://docs.x.com/x-api/fundamentals/consistency` — `{data, includes, meta, errors}`, partial errors alongside data
- X API v2 tweet caps: `https://developer.x.com/en/docs/twitter-api/tweet-caps` — Basic-tier monthly cap behaviour
- Codebase: `app/models/user.rb`, `app/services/mastodon_client.rb`, `app/controllers/mastodon_accounts_controller.rb`, `app/controllers/users/omniauth_callbacks_controller.rb`, `app/controllers/preferences_controller.rb`, `app/models/portal.rb`, `app/views/welcome/_mastodon_account.html.erb`, `app/views/mastodon_accounts/show.html.erb`, `db/schema.rb`, `config/initializers/devise.rb`, `config/initializers/filter_parameter_logging.rb`, `features/support/hooks.rb`, `test/services/mastodon_client_test.rb`, `Gemfile` / `Gemfile.lock`
- v1.17 carry-forward: `.planning/milestones/v1.17-MILESTONE-AUDIT.md`, `.planning/milestones/v1.17-research/PITFALLS.md`
- v1.16 reference: `.planning/milestones/v1.16-MILESTONE-AUDIT.md`
- Project policy: `.planning/PROJECT.md`, `CLAUDE.md` (Cucumber flakiness)
