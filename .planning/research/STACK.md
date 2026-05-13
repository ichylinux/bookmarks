# Stack Research — v1.18 X (Twitter) Account Following

**Project:** Bookmarks v1.18
**Researched:** 2026-05-14
**Confidence:** HIGH (gem versions verified on rubygems.org; OAuth hash structure
verified against omniauth-twitter docs; transitive deps confirmed in
`Gemfile.lock`)

---

## Summary

v1.18 introduces an authenticated HTTP client against `api.x.com` (X API v2) using
the same OAuth 1.0a User Context tokens that `omniauth-twitter` already returns at
sign-in. The minimum stack delta is:

1. One new dependency, `faraday-oauth1` (1.0.0, 2026-02-18), which adds an OAuth 1.0a
   request-signing middleware on top of the existing Faraday 1.10.5 already used by
   `MastodonClient`. Its only transitive runtime dependency is `simple_oauth`
   (0.4.1, 2026-04-20). No new HTTP transport, no new gem-bundled JS, no
   asset-pipeline impact.
2. One schema migration adding `users.oauth_token_secret` (string, nullable). The
   `users.token`, `users.uid`, `users.provider` columns already exist (verified at
   `db/schema.rb:109,114,115`) but are not currently written by `from_omniauth` —
   v1.18 wires them up, consistent with PROJECT.md's stated target features.
3. One new service object, `XClient`, modeled directly on `MastodonClient` (same
   timeout shape, same `stub_fetch_result` test hook, same Faraday-error rescue
   tree, same `{success:, items:|error:}` return contract).

We deliberately do **not** add the `x` gem (sferik), the legacy `twitter` gem, or
the `oauth` gem despite the latter already being a transitive dep — see [NOT
Adding](#not-adding-intentional).

---

## OAuth 1.0a Signing Approach

**Decision:** Add `faraday-oauth1` (~> 1.0) and stack it as a Faraday
request-middleware on the `XClient`'s connection. Sign per-request with the
user's stored `(consumer_key, consumer_secret, oauth_token, oauth_token_secret)`.

**Why:**

- Reuses the existing Faraday 1.10.5 already validated in `MastodonClient`
  (`app/services/mastodon_client.rb:65`). No new HTTP transport, no new
  rescue surfaces, no new test-adapter pattern.
- `faraday-oauth1` 1.0.0 (released 2026-02-18) explicitly targets `faraday
  (>= 1.10, < 3)` so it is compatible with the currently-locked `faraday 1.10.5`
  with zero version churn.
- Maintained: 1.0.0 is a 2026 release; underlying `simple_oauth` 0.4.1 (2026-04-20)
  added HMAC-SHA256 + RSA-SHA256 in 0.4.0 and runs on Ruby 3.2+, so 3.4.9 is fine.
- The middleware reads `:consumer_key/:consumer_secret/:token/:token_secret`
  options and writes the `Authorization: OAuth …` header — exactly the shape X
  expects for User Context calls.

**Alternatives evaluated and rejected:**

| Option | Verdict | Reason |
|---|---|---|
| (a) `faraday_middleware` 1.2.1 `FaradayMiddleware::OAuth` | Reject | Already in the Gemfile but [the legacy `faraday_middleware` gem is deprecated upstream](https://github.com/lostisland/faraday_middleware/blob/main/README.md) and being un-bundled into per-feature gems exactly like `faraday-oauth1`. We don't want to grow the dependency on the deprecated path. |
| (b) `simple_oauth` direct (no Faraday middleware) | Reject | Means hand-building the `Authorization` header in `XClient`. Same security profile as the middleware but more code we own and test. The middleware is a thin wrapper — there is no benefit to skipping it. |
| (c) Hand-rolled HMAC-SHA1 with `OpenSSL` | Reject | OAuth 1.0a parameter normalization, nonce + timestamp generation, percent-encoding rules, and signature base string assembly are error-prone. The community has had `simple_oauth` since 2010 specifically because rolling this is a footgun. "Minimum code that solves the problem" applies to risk-weighted code too. |
| (d) Reuse the `oauth` gem (1.1.3, already a transitive dep via `omniauth-oauth`) | Reject | The `oauth` gem couples its own HTTP transport (`Net::HTTP` via `OAuth::AccessToken`) into the request path. We'd have two HTTP transports in this app (Faraday for Mastodon, Net::HTTP via oauth for X). The signing helpers (`OAuth::Helper`, `OAuth::Client::Helper`) *can* be used standalone but the API is not designed for that and is much less obvious than `faraday-oauth1`'s middleware contract. |

**Risks:**
- `faraday-oauth1`'s only major version is 1.0.0 (single release in this series).
  Its source is ~150 lines, MIT-licensed, and just wraps `simple_oauth`. Low risk
  of abandonment-without-fork; in the worst case we copy ~100 lines into
  `lib/x_client/oauth1_middleware.rb`.

---

## X API v2 Client Approach

**Decision:** Hand-write `app/services/x_client.rb` against Faraday +
`faraday-oauth1`, modeled on `MastodonClient`. Two methods:
`fetch_following(user_id:, max_results:)` → `GET /2/users/:id/following`, and
`fetch_recent_tweets(user_id:, max_results:)` → `GET /2/users/:id/tweets`.
Same `stub_fetch_result` class-attr hook for Minitest + Cucumber.

**Why:**

- The `MastodonClient` pattern is already production-validated in this app
  (v1.16, shipped 2026-05-12) and the Cucumber + Minitest stub story works
  cleanly. Reusing the shape collapses cognitive load and makes the v1.16 →
  v1.18 review story trivial: "same client, OAuth-signed."
- v1.18's surface is only **two** read endpoints. A full SDK is overkill.
- Constraint from the prompt and PROJECT.md: "Touch only what you must — prefer
  reusing existing Faraday over adding a new HTTP gem." A hand-rolled client
  reusing the locked Faraday version respects this directly.

**Alternatives evaluated and rejected:**

| Option | Verdict | Reason |
|---|---|---|
| Add the `x` gem (sferik, 0.19.0, 2026-03-02) | Reject | The gem is actively maintained and supports OAuth 1.0a User Context (`api_key/api_key_secret/access_token/access_token_secret`). However it uses `Net::HTTP` directly — **no Faraday integration**. Adopting it would mean the app has two HTTP transports for two adjacent gadgets (Mastodon via Faraday, X via Net::HTTP), with two different timeout shapes, two different stub strategies, and two different error-rescue trees. For a two-endpoint read surface, the gem's value-add (request building, pagination helpers) does not pay for the transport split. Revisit if v1.19+ needs streaming or many endpoints. |
| Add the `twitter` gem (sferik, 8.3.0) | Reject (hard) | Maintainer explicitly states **v1.1 only** — no v2 support, and the maintainer's own README points new projects at the `x` gem. Useless for our endpoints. |
| `tweetkit` (julianfssen) | Reject | Smaller community, similar trade-offs to the `x` gem (own HTTP), no offsetting benefit. |

**HTTP timeout shape (decision):**

```ruby
CONNECT_TIMEOUT = 3   # match MastodonClient
READ_TIMEOUT    = 5   # match MastodonClient
```

These match `MastodonClient` and are appropriate: `api.x.com` is normally
fast (<500ms for these endpoints), and a 5s read budget keeps the welcome page
responsive when the gadget is being lazy-loaded. The Mastodon experience under
the same budget has been acceptable since v1.16.

**Rate limit handling (decision):**

- X API v2 rate limits are per-endpoint and split per-user under User Context.
  On the Basic ($200/mo) tier, `GET /2/users/:id/following` and
  `GET /2/users/:id/tweets` each have their own window. The Basic tier's
  10,000-posts/month cap is **read volume**, not rate; per-15-minute windows
  apply on top.
- Treat 429 as a first-class error in the same `{success: false, error: …}`
  shape: add `:rate_limited` to the error enum alongside the existing
  `:timeout / :network / :not_found / :api_error / :parse_error` set.
- Surface `:rate_limited` to the gadget partial with a localized message ("X の
  取得制限に達しました / Rate-limited by X"). Do **not** auto-retry — for a
  welcome-page lazy-loaded gadget, retry is the wrong UX; the user can reload.
- Cache the following list in DB with a manual "再取得" button (per PROJECT.md
  target features). The tweets call runs live on each welcome render of the
  gadget. The two-call-per-render budget on a per-user-per-window allowance is
  well within Basic limits for personal-use scale.

---

## Token Persistence

**Decision:** Add a single column to `users`: `oauth_token_secret` (string,
nullable). Wire `User.from_omniauth` (Twitter branch) to persist `provider`,
`uid`, `token`, `oauth_token_secret` on both create and update. **Do not**
introduce a new `x_oauth_credentials` table.

**Why:**

- `users` already has `provider`, `uid`, and `token` columns (verified at
  `db/schema.rb:109,114,115`) — they exist precisely for this purpose and are
  currently dead weight. PROJECT.md notes this is the v1.17 PITFALL-02 also
  being closed by v1.18. Adding `oauth_token_secret` is the symmetric fourth
  field; one migration, no new model, no new join.
- One user owns one X identity in this app (Twitter sign-in is one-account-
  per-user via Devise). There is no 1:N relationship to model — a side table
  would just be a `has_one` with extra ceremony.
- PROJECT.md positions this as a personal/single-user-ish app and explicitly
  prefers "simple over abstract."
- Storing `oauth_token_secret` on `users` is the same column granularity as
  `encrypted_password` and `otp_secret` already on the same table; sensitive
  but not categorically different from existing secrets there.

**Alternatives evaluated and rejected:**

| Option | Verdict | Reason |
|---|---|---|
| New `x_oauth_credentials` table | Reject | No 1:N requirement; just adds a join with a single row per user. Cleaner only if we expect multiple X identities per user — not in scope. |
| Encrypt with ActiveRecord encryption | Defer | Rails 8.1 supports per-attribute `encrypts :oauth_token, :oauth_token_secret`. Worth doing if we want at-rest encryption parity with TOTP secrets. **Out of scope for v1.18** — `otp_secret` is currently stored plain, so encrypting only the X tokens would be inconsistent. Capture as backlog: "Encrypt all OAuth + 2FA secrets together." |
| Store in Rails credentials | Reject | Per-user, not per-app. Wrong storage class. |
| Store in `session` only | Reject | Tweets are fetched on welcome render — the token must outlive a single session. Also the following-list cache + "再取得" flow implies background-eligible reads. |

**Migration shape (for plan-phase, not implementation):**

```ruby
class AddOauthTokenSecretToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :oauth_token_secret, :string
  end
end
```

No index, no NOT NULL (Google-only users will leave it nil).

---

## Required Gem Additions

| Gem | Version (target) | Purpose | Why this version |
|---|---|---|---|
| `faraday-oauth1` | `~> 1.0` (resolves to 1.0.0) | Faraday request middleware that signs OAuth 1.0a requests via `simple_oauth`. | 1.0.0 released 2026-02-18; requires `faraday (>= 1.10, < 3)` which matches the locked `faraday 1.10.5`. Ruby >= 2.6 (we run 3.4.9). |

Transitive (pulled in automatically by `faraday-oauth1`):

| Gem | Version | Purpose |
|---|---|---|
| `simple_oauth` | 0.4.1 (2026-04-20) | OAuth 1.0a header building/signing. Required Ruby >= 3.2 (we run 3.4.9). |

That is the entire gem delta for v1.18. The `Gemfile` change is one line:

```ruby
gem 'faraday-oauth1'
```

---

## NOT Adding (intentional)

| Considered | Rejected because |
|---|---|
| `x` gem (0.19.0, sferik) | Uses `Net::HTTP` internally — no Faraday integration. Would split this app across two HTTP transports for two adjacent gadgets. Re-evaluate if v1.19+ needs streaming, posting, or many endpoints. |
| `twitter` gem (8.3.0, sferik) | Maintainer explicitly states v1.1-only; will never support v2. Wrong API. |
| `tweetkit` | Smaller community than `x` gem with the same transport split downside. No reason to prefer it over `x` if we ever revisit. |
| Direct use of the transitive `oauth` (1.1.3) | Couples to `Net::HTTP` via `OAuth::AccessToken`; standalone use of its helpers is awkward and undocumented. `faraday-oauth1` is the modern, Faraday-native equivalent. |
| Hand-rolled HMAC-SHA1 signing in `XClient` | Parameter normalization + percent-encoding + nonce/timestamp are footguns. Reusing `simple_oauth` (battle-tested, 41M downloads) is correct. |
| `webmock` / `vcr` for X test stubs | The `stub_fetch_result` pattern from `MastodonClient` is already the project's contract and is documented as a "Key Decision" in PROJECT.md (line 162). Adding `webmock` for one new service would break that contract. |
| New `x_oauth_credentials` table | No 1:N requirement; single-account-per-user. Adds a join for no behavioral gain. |
| ActiveRecord encryption on `users.oauth_token_secret` only | Inconsistent with `otp_secret` which is currently plain. Worth doing as a separate, holistic "encrypt all per-user secrets" backlog item. |
| Background-job infra (Sidekiq/Resque) for following-list refresh | PROJECT.md explicitly says "新規バックグラウンドインフラは入れない." Manual "再取得" button + DB cache is the chosen UX. |
| `:confirmable` Devise module (X email confirmation) | Out of scope — v1.17 already handled email registration for Twitter users without `:confirmable` by design (`v1.17-research/STACK.md`). |

---

## Integration Points

### `User.from_omniauth` (Twitter branch)

Current code at `app/models/user.rb:24-37` ignores OAuth credentials entirely on
the Twitter branch. The v1.18 change is contained inside the existing `when
:twitter` branch:

```ruby
when :twitter
  user = User.where(name: data['name']).first
  user ||= User.create(name: data['name'], email: "dummy_#{SecureRandom.uuid}@example.com",
                       password: Devise.friendly_token[0, 20])
  user.update!(
    provider: access_token['provider'],
    uid:      access_token['uid'],
    token:             access_token.credentials.token,
    oauth_token_secret: access_token.credentials.secret
  )
  user
```

**Verified:** `omniauth-twitter` returns the OAuth 1.0a access token at
`auth["credentials"]["token"]` and the matching secret at
`auth["credentials"]["secret"]`. This is the standard OmniAuth auth hash
schema (https://github.com/omniauth/omniauth/wiki/auth-hash-schema) and is
documented for omniauth-twitter specifically. (The same secret is also
reachable via `auth["extra"]["access_token"].secret`, but the `credentials`
path is the canonical one and is what we'll use.) The
`access_token['provider']`/`['uid']` accessors are already exercised by the
existing `case` statement so we know that pathway is live.

### `XClient` (new service, mirrors `MastodonClient`)

Construction signature accepts a `User` (or just the four token fields) and
builds a Faraday connection with the OAuth 1.0a middleware stacked:

```ruby
Faraday.new(url: 'https://api.x.com', request: { open_timeout: 3, timeout: 5 }) do |f|
  f.request :oauth1,
    consumer_key:    Rails.application.config.app_config.omniauth_twitter_client_id,
    consumer_secret: Rails.application.config.app_config.omniauth_twitter_client_secret,
    token:           user.token,
    token_secret:    user.oauth_token_secret
  f.adapter Faraday.default_adapter
end
```

The same `app_config.omniauth_twitter_client_id/secret` values already feed
the omniauth-twitter strategy at `config/initializers/devise.rb:262-264`. No
new credentials surface.

Return contract identical to `MastodonClient`:
`{success: true, items: [...]}` or `{success: false, error: <sym>}`.

### `Portal#get_gadgets`

The Mastodon gadget is already wired through `Portal#get_gadgets` as of v1.16.
The X gadget slots in as a peer registration — no changes to the gadget
dispatch infrastructure are needed.

### Test stubbing (Minitest + Cucumber)

Same contract as `MastodonClient.stub_fetch_result`:

```ruby
XClient.stub_fetch_following_result = { success: true, items: [...] }
XClient.stub_fetch_tweets_result    = { success: true, items: [...] }
```

Two separate class attrs (one per method) keeps the test fixtures composable —
e.g. tests can stub a successful following list with a tweet-fetch failure to
exercise the partial-degradation UI. Cleared in Cucumber `After` hook and
Minitest `teardown`, same as v1.16. This satisfies the prompt's stated
requirement: "matching v1.16 MastodonClient.stub_fetch_result pattern."

---

## Verification Notes

### How to validate API behavior locally without paid API keys

The Basic-tier signup is a hard prerequisite for live calls — there is no
free tier that exposes `/2/users/:id/following` for arbitrary users. For
development without paid keys:

1. **Faraday test adapter for unit tests.** Same pattern as
   `test/services/mastodon_client_test.rb` (v1.16). Build a stub adapter,
   feed canned JSON, assert the return contract. The OAuth1 middleware
   composes cleanly with `Faraday::Adapter::Test` — the signature is added
   to the request and then ignored by the stub.
2. **`stub_fetch_*_result` for controller + Cucumber.** No Faraday at all
   in the request path; stub hands back the canonical hash. This is the
   v1.16-validated path.
3. **Live smoke against the developer's own account** during plan-phase /
   pre-merge: once Basic keys are present in `.env`, `bin/rails runner
   "puts XClient.new(user: User.first).fetch_following(...).inspect"` is
   sufficient. Document this in the verification artifact for the phase.

### Stub contract

Both stub return paths must accept:

```ruby
{ success: true, items: [{ id: 'NUMERIC_STRING', name: 'string', username: 'handle', text: 'string', url: 'https://x.com/...' }, ...] }
{ success: false, error: :timeout | :network | :not_found | :api_error | :parse_error | :rate_limited | :unauthorized }
```

`:unauthorized` is a v1.18 addition over `MastodonClient`'s error enum —
needed because OAuth tokens can be revoked by the user from x.com, returning
401. The gadget must distinguish "revoked → prompt re-auth" from "transient
network → just say retry."

### Gem-currency snapshot (verified 2026-05-14)

| Gem | Latest release | Date | Verdict |
|---|---|---|---|
| `faraday-oauth1` | 1.0.0 | 2026-02-18 | Current; only modern release |
| `simple_oauth` | 0.4.1 | 2026-04-20 | Current; actively maintained |
| `x` | 0.19.0 | 2026-03-02 | Current; rejected for transport split |
| `twitter` | 8.3.0 | 2026-03-30 | Current but **v1.1-only**; rejected |
| `oauth` (transitive) | 1.1.3 | (already in `Gemfile.lock:327`) | Maintained but transport-coupled; rejected |
| `faraday` (locked) | 1.10.5 | (already in `Gemfile.lock:196`) | Compatible with `faraday-oauth1` (>=1.10, <3) |

### Confidence assessment

| Area | Level | Reason |
|---|---|---|
| omniauth-twitter exposes `token` + `secret` in `credentials` | HIGH | Documented in OmniAuth auth-hash schema and omniauth-twitter README; multiple independent corroborations |
| `faraday-oauth1` is the right signing path | HIGH | Maintained, Faraday-native, locked-Faraday-compatible; signing delegated to `simple_oauth` (41M downloads) |
| Single-column schema on `users` is sufficient | HIGH | One-to-one identity, columns 3-of-4 already exist on the table, matches PROJECT.md target features |
| Hand-rolled `XClient` over the `x` gem | MEDIUM-HIGH | Confident the trade-off is right for 2 endpoints; revisit if scope expands |
| Rate-limit + revocation error handling shape | MEDIUM | Need to add `:rate_limited` + `:unauthorized` to the error enum; the gadget UI needs corresponding ja/en strings — capture in plan-phase, not a stack-research blocker |
