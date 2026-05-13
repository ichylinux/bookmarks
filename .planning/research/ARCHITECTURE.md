# Architecture Research — v1.18 X (Twitter) Account Following

**Project:** Bookmarks v1.18
**Researched:** 2026-05-14
**Confidence:** HIGH (all findings traced directly through existing source files; one MEDIUM area called out for OAuth 1.0a signing wire-up)

## Summary

v1.18 adds three layers on top of the v1.16 Mastodon pattern, with one new ingredient: **authenticated** API access on behalf of the signed-in Twitter user. The feature decomposes into (1) **persist OAuth 1.0a credentials** on `users` from the existing `omniauth-twitter` callback (the missing piece that v1.17 flagged as PITFALL-02 territory), (2) a **`XClient` Faraday service** modeled on `MastodonClient` that signs requests with the per-user token + secret, and (3) a single **`x_accounts` cache table** (option a) with a `selected:boolean` pin flag — refreshed manually from `GET /2/users/:id/following`, surfaced as welcome-page gadgets via `Portal#get_gadgets` (mirror of v1.16) but enumerated only for `selected: true` rows. Everything else (per-user isolation via `Crud::ByUser`, AJAX `show` action, Cucumber `stub_fetch_result`, ja/en parity tests, tri-suite gate) is a direct lift of v1.16.

The only meaningful architectural divergence from v1.16: data flow is API → DB (refresh-driven cache) instead of user-input → DB (URL-typed by user). That changes the controller surface (`refresh` + `update :selected`, no `new`/`create`/`destroy`) and gives `deleted:boolean` a new semantic — "no longer in the user's X following list" rather than "user deleted the row". Every other pattern is preserved.

## Data Model

### Decision: option (a) — single `x_accounts` table with `selected:boolean`

**Why not (b) two tables (`x_followings` + `x_account_selections`):** The selection is a single column-level fact attached one-to-one to a following row. A second table buys nothing — no shared rows, no normalization win — and adds a join + an FK reconciliation path on refresh ("did the user pin a following that was just dropped from the cache?"). One table, one flag is the minimum that solves it.

**Why not (c) Mastodon-style "selected only":** Already ruled out by Q6=2 (DB caches the full following list + manual refresh). The management UX is "browse my following list, tick boxes", not "type a profile URL". The cache must hold all followings to power the browse, so (c) is structurally incompatible.

### Schema

New migration: `db/migrate/<ts>_create_x_accounts.rb`

```ruby
class CreateXAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :x_accounts do |t|
      t.integer :user_id,         null: false
      t.string  :x_user_id,       null: false              # X "id" (numeric snowflake, string-encoded by API)
      t.string  :username,        null: false              # X "username" (handle, no @)
      t.string  :name                                      # X "name" (display name); nullable per API contract
      t.text    :description                               # X "description"; may be long, nullable
      t.string  :profile_image_url                         # X "profile_image_url"; nullable
      t.string  :profile_url,     null: false              # derived: https://x.com/<username>
      t.boolean :selected,        null: false, default: false
      t.integer :display_count,   null: false, default: 5
      t.boolean :deleted,         null: false, default: false
      t.datetime :fetched_at                               # when this row was last refreshed from the API
      t.timestamps
    end

    add_index :x_accounts, [:user_id, :x_user_id], unique: true
    add_index :x_accounts, [:user_id, :selected, :deleted]   # gadget enumeration hot path
  end
end
```

**Column rationale (every column justified):**

| Column | Why |
|--------|-----|
| `x_user_id` (string) | X "id" is a 64-bit snowflake; JSON returns it as **string** to avoid JS number precision loss. Store as string. This is the API key, not username (handles can change). |
| `username` | Stable enough for display; rendered as `@username`. |
| `name` | X display name, separate from handle; shown in gadget title row. Nullable because the X API field is optional. |
| `description` | Shown on the `/x_accounts` management page so the user can decide who to pin; **not** shown in gadget. `text` (not `string`) — bio can be ~200 chars including emoji bytes. |
| `profile_image_url` | Shown in management list (favicon-like); not in gadget. Nullable. |
| `profile_url` | Derived `https://x.com/<username>`; stored for symmetry with `MastodonAccount#profile_url` and so the gadget title `link_to` doesn't have to compute it inline. Recomputed in a `before_save` callback when `username` changes. |
| `selected` | The pin flag. `false` by default — refresh never auto-pins. Gadget enumeration is `where(selected: true)`. |
| `display_count` | Same role as Mastodon's: tweets-per-gadget cap. Default 5, matches Mastodon. |
| `deleted` | Soft-delete flag for rows that **were** in following list but no longer are (see refresh strategy below). |
| `fetched_at` | Drives the "Last refreshed at …" timestamp shown on the management page so the user knows the cache age. Set on every upsert during refresh. |

**Uniqueness:** composite `(user_id, x_user_id)` — a Twitter account appears at most once per Bookmarks user. The natural key from the X API is `x_user_id`, not `username` (handles are mutable on X; IDs are immutable). On refresh, upsert by `(user_id, x_user_id)`.

**Indexes:**
- `(user_id, x_user_id)` unique — for refresh upsert lookup and identity.
- `(user_id, selected, deleted)` — covers `Portal#get_gadgets`'s `where(user_id:, selected: true).not_deleted` enumeration (3-column index, leftmost = `user_id`, also accelerates the management page's filtering).

### Soft-delete strategy

**Convention:** `deleted:boolean` is set **only** by the refresh-diff routine, not by a user-initiated destroy action (there is no destroy action in the v1.18 surface).

**Refresh diff semantics:**

```
For each fresh following from X API:
  upsert by (user_id, x_user_id):
    on hit (row exists):
      update username, name, description, profile_image_url, fetched_at
      if was deleted=true: clear deleted=false (user re-followed)
    on miss:
      insert with selected=false, deleted=false

For each existing row not present in the fresh response:
  if selected=true:
    set deleted=true                       # preserve the user's pin so they see "X dropped from following" rather than the gadget silently vanishing on next refresh; user can decide to unpin
  else:
    DELETE                                  # unselected + unfollowed: zero value to keep
```

This diverges from `MastodonAccount` (which only soft-deletes on user-initiated destroy), and the divergence is justified by data-source semantics: Mastodon rows are **created by user typing**, X rows are **synced from API**, and the API is the source of truth for "currently following". Keeping a `deleted=true` row only when `selected=true` preserves the user's intent across follow → unfollow → re-follow cycles on X without leaving dead pinning rows lying around.

`/x_accounts` index lists rows with `.not_deleted`; selected-but-deleted rows could optionally show a separate "Pinned, no longer in your X following" section (UX call — out of scope for the data-model decision).

### Model: `app/models/x_account.rb`

```ruby
module XAccountConst
  DEFAULT_DISPLAY_COUNT = 5
  PROFILE_URL_BASE = 'https://x.com'
end

class XAccount < ApplicationRecord
  include XAccountConst
  include Crud::ByUser

  belongs_to :user

  validates :x_user_id,   presence: true
  validates :username,    presence: true
  validates :profile_url, presence: true
  validates :display_count, numericality: { only_integer: true, greater_than: 0 }
  validates :x_user_id, uniqueness: { scope: :user_id }

  before_validation :derive_profile_url
  before_save :set_display_count

  def gadget_id
    "x_account_#{id}"
  end

  def title
    name.present? ? "#{name} (@#{username})" : "@#{username}"
  end

  private

  def derive_profile_url
    self.profile_url = "#{PROFILE_URL_BASE}/#{username}" if username.present?
  end

  def set_display_count
    self.display_count = DEFAULT_DISPLAY_COUNT if display_count.to_i == 0
  end
end
```

Mirrors `MastodonAccount` exactly: `Crud::ByUser`, `belongs_to :user`, `gadget_id`, `title`, default-count callback, parse-derived URL. The only `MastodonAccount` callback absent is `parse_profile_url` — `XAccount` derives its URL from the canonical `username` rather than user input, so the dataflow inverts.

## OAuth Token Persistence

### Decision: add three new columns to `users`; do NOT reuse existing `uid`/`token`/`provider`

```ruby
class AddTwitterOauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :twitter_uid,                 :string             # X numeric user id (snowflake)
    add_column :users, :twitter_oauth_token,         :text               # encrypted; ciphertext is larger than the plaintext
    add_column :users, :twitter_oauth_token_secret,  :text               # encrypted
  end
end
```

**Why new columns and not reuse `users.uid` / `users.token` / `users.provider`:**

A repo-wide grep (`Grep app/**/*.rb` for `\.uid`, `\.token`, `\.provider`) shows zero references — those columns are vestigial OmniAuth scaffolding that nothing reads or writes. Repurposing them would (a) be ambiguous in a future world with a second authenticated provider, (b) misrepresent OAuth 2.0 / OAuth 1.0a as one shape (Google OAuth 2.0 access tokens don't have a "secret" partner; Twitter OAuth 1.0a does), and (c) require updating any future code that may someday read the columns. New, explicit, provider-scoped columns are the cheap correct path. The dead columns are pre-existing tech debt; deleting them is a separate task and explicitly out of v1.18 scope.

**Why three columns and not two:** X API v2 endpoints take the **numeric user id** in the URL path (`GET /2/users/:id/following`, `GET /2/users/:id/tweets`). It's exposed by `omniauth-twitter` as `auth.uid` on every callback. Storing it spares an `/account/verify_credentials.json` round-trip on every refresh and means the `XClient` never has to call a "who am I?" endpoint to do work.

### Encryption at rest

Use Rails 8 ActiveRecord encryption:

```ruby
class User < ApplicationRecord
  encrypts :twitter_oauth_token, :twitter_oauth_token_secret
end
```

Encryption keys are already configured (`config/application.rb:30-32` reads `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `_DETERMINISTIC_KEY`, `_KEY_DERIVATION_SALT` from ENV with dev/test `'dev_dummy_key'` fallbacks; both dev and test set `config.active_record.encryption.support_unencrypted_data = true`). No new key infrastructure needed for v1.18. The fields are non-deterministic encrypted (default) — we never query by token value.

`twitter_uid` is **not** encrypted: it's a public identifier (visible on every X profile page) and we need to read/compare it in plaintext for refresh logic. Encrypting it would prevent indexing if we ever need to look up by it.

### `User.from_omniauth` — Twitter branch shape

Current:

```ruby
when :twitter
  user = User.where(name: data["name"]).first
  user ||= User.create(name: data['name'], email: "dummy_#{SecureRandom.uuid}@example.com",
                       password: Devise.friendly_token[0,20])
  user
```

Proposed:

```ruby
when :twitter
  user = User.where(name: data['name']).first
  user ||= User.create(name: data['name'],
                       email: "dummy_#{SecureRandom.uuid}@example.com",
                       password: Devise.friendly_token[0,20])
  user.update!(
    twitter_uid:                 access_token['uid'],
    twitter_oauth_token:         access_token.credentials.token,
    twitter_oauth_token_secret:  access_token.credentials.secret
  )
  user
```

**Token rotation:** OAuth 1.0a tokens don't expire by clock, but they can be revoked from x.com or rotated by Twitter on certain events (password reset, app permissions change). Every successful sign-in overwrites all three fields. This is correct: the most recent successful callback's credentials are the most likely to still be valid.

**Google-only users:** `from_omniauth` Google branch is untouched; `twitter_*` columns remain NULL. The `/x_accounts` controller's before_action gates on **both** `current_user.name.present?` (existing UI convention — Google sign-in users have no `name`) and `current_user.twitter_oauth_token.present?` (real prerequisite for any X API call). A Google user manually URL-fudging to `/x_accounts` gets redirected to preferences with a localized flash. The drawer entry should also gate on `current_user.name.present?` to avoid showing dead links.

**Re-link behavior:** A user signed up via Google who then signs in via Twitter (existing `from_omniauth` Twitter branch matches by `data['name']`, so this typically creates a second account — see PITFALL-02 carry-forward below) will, on second-and-subsequent Twitter sign-ins, refresh the three fields. Existing pre-v1.18 Twitter users will go through this update path on their next sign-in and back-fill the new columns naturally. No backfill migration is required.

**Pre-existing risk preserved (PITFALL-02, carry-forward from v1.17):** The Twitter lookup still matches by `data['name']`, not by `access_token['uid']`. Two Twitter users with the same display name still collide via the `users.name` UNIQUE index. A v1.18 milestone-internal task could change the lookup to `User.where(twitter_uid: access_token['uid'])`, but that touches identity semantics for existing users (anyone signed in pre-v1.18 has `twitter_uid=NULL`, so the lookup misses and a duplicate account is created on next sign-in). **Recommendation: do not fix in v1.18.** Log as carry-forward; the new `twitter_uid` column is the prerequisite for fixing it later. This must be called out in PITFALLS.md.

## Service Layer

### `app/services/x_client.rb` — mirror of `MastodonClient`

```ruby
class XClient
  class << self
    # Cucumber + controller-test short-circuits, one per method.
    attr_accessor :stub_following_result, :stub_tweets_result
  end

  CONNECT_TIMEOUT  = 3
  READ_TIMEOUT     = 5
  API_BASE         = 'https://api.twitter.com'
  PREVIEW_LENGTH   = 100

  def initialize(oauth_token:, oauth_token_secret:, connection: nil)
    @oauth_token        = oauth_token
    @oauth_token_secret = oauth_token_secret
    @forced_connection  = connection
  end

  # Returns { success: true, items: [{ x_user_id:, username:, name:, description:, profile_image_url: }, ...] }
  #      or { success: false, error: :timeout | :network | :unauthorized | :rate_limited | :api_error | :parse_error }
  def fetch_following(twitter_uid:, max_results: 100)
    stub = self.class.stub_following_result
    return normalize_following_stub(stub) if stub

    paginated_get("/2/users/#{twitter_uid}/following",
                  params: { 'max_results' => max_results,
                            'user.fields' => 'description,profile_image_url' }) do |row|
      row_to_following_item(row)
    end
  end

  # Returns { success: true, items: [{ text:, url: }, ...] }
  #      or { success: false, error: ... }
  def fetch_recent_tweets(twitter_uid:, max_results:)
    stub = self.class.stub_tweets_result
    return normalize_tweets_stub(stub) if stub

    response = signed_get("/2/users/#{twitter_uid}/tweets",
                          params: { 'max_results' => max_results, 'tweet.fields' => 'id' })
    # ... map rows -> { text: tweet['text'].truncate(PREVIEW_LENGTH),
    #                   url: "https://x.com/i/web/status/#{tweet['id']}" }
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    { success: false, error: :timeout }
  rescue Faraday::Error
    { success: false, error: :network }
  rescue JSON::ParserError
    { success: false, error: :parse_error }
  end

  private

  def build_connection
    @forced_connection || Faraday.new(url: API_BASE,
                                      request: { open_timeout: CONNECT_TIMEOUT,
                                                 timeout:      READ_TIMEOUT }) do |f|
      f.adapter Faraday.default_adapter
    end
  end

  def signed_get(path, params: {})
    conn = build_connection
    conn.get(path, params) { |req| req.headers['Authorization'] = oauth1_header(req, params) }
  end

  def oauth1_header(req, params)
    # Builds OAuth 1.0a HMAC-SHA1 Authorization header from per-user @oauth_token / @oauth_token_secret
    # and the consumer key/secret from app_config (omniauth_twitter_client_id / _secret).
  end

  # error categorization:
  #   401 -> :unauthorized   (token revoked / stale; surfaces in UI as "please re-link X")
  #   429 -> :rate_limited
  #   other non-2xx -> :api_error
end
```

### OAuth 1.0a signing — inside `XClient`, not a separate `XOAuthSigner`

The signing routine is ~30 lines of mechanical HMAC-SHA1 over a percent-encoded normalized parameter string. It has exactly one caller (the `XClient` private `signed_get`). Extracting it now would be speculative reuse and violates "Minimum code that solves the problem."

The signing material is already available without writing a single line of OAuth manually: `omniauth-twitter` declares `oauth (~> 1.1)` (the `oauth` gem, version 1.1.3 in `Gemfile.lock`) as a transitive dependency. `OAuth::Consumer` + `OAuth::AccessToken#sign!(request)` does the whole job. Using the gem we already ship is cheaper than rolling our own HMAC code and removes ~30 lines of signing logic from our maintenance surface:

```ruby
def signed_get(path, params: {})
  consumer = OAuth::Consumer.new(
    Rails.application.config.app_config.omniauth_twitter_client_id,
    Rails.application.config.app_config.omniauth_twitter_client_secret,
    site: API_BASE
  )
  access = OAuth::AccessToken.new(consumer, @oauth_token, @oauth_token_secret)
  response = access.get("#{path}?#{URI.encode_www_form(params)}",
                        { 'Accept' => 'application/json' },
                        open_timeout: CONNECT_TIMEOUT,
                        read_timeout: READ_TIMEOUT)
  # Wrap in a Faraday-shaped response struct so error-handling stays uniform with MastodonClient,
  # OR drop Faraday and use Net::HTTP via the oauth gem directly.
end
```

**Trade-off (called out for the planner):** the `oauth` gem uses `Net::HTTP` under the hood, **not** Faraday. This is a divergence from `MastodonClient`'s Faraday-everywhere pattern.

**Two paths the planner must pick between:**

- **A. Use `oauth` gem directly** — cheapest. Loses Faraday's `:test` adapter for the X service tests (would need WebMock or a custom Net::HTTP test stub). Timeout config via `open_timeout`/`read_timeout` on the `OAuth::AccessToken#get` call. Confidence: HIGH.
- **B. Use Faraday + the `simple_oauth` gem** (well-known OAuth 1.0a header builder, ~1k LOC, MIT) **or** hand-rolled HMAC-SHA1 header — keeps Faraday everywhere, keeps `:test` adapter in service tests, but adds a gem or ~30 lines. Confidence: MEDIUM (adds dependency or custom code).

**Recommendation:** A in initial phase if the planner accepts WebMock-or-stub-only for `XClient` tests; B (hand-rolled signing header within `XClient`, no new gem) if Faraday `:test` parity is non-negotiable. Document the choice as a v1.18 D-XX decision before phase 61 starts. The data model + controller layout is identical either way.

### Stub contract

Two separate class-level accessors, one per fetch method:

```ruby
XClient.stub_following_result = { success: true, items: [{ x_user_id: '123', username: 'jack', name: 'Jack', description: 'co-f...', profile_image_url: 'https://...' }] }
XClient.stub_tweets_result    = { success: true, items: [{ text: 'Cucumber stub tweet preview', url: 'https://x.com/i/web/status/9' }] }
```

`normalize_*_stub(h)` mirrors `MastodonClient.normalize_stub_result` shape: rejects non-Hash, coerces with `with_indifferent_access`, casts `:success`, falls back to `{ success: false, error: :api_error }` on any malformed payload. Cleared in test `setup`/`teardown` and a Cucumber `Before`/`After` hook (matches v1.16 contract).

Splitting into two accessors (vs one with `{ following: ..., tweets: ... }`) trades a tiny bit of API surface for far cleaner per-test setup — most tests will stub only one of the two methods, and a single accessor makes "I forgot to clear the other one between tests" a real footgun.

## Controller Layer

### Routes

```ruby
# config/routes.rb
resources :x_accounts, only: %i[index show update] do
  collection do
    post 'refresh'
  end
end
```

Generates:

| Verb   | Path                       | Action     | Purpose                                                           |
|--------|----------------------------|------------|-------------------------------------------------------------------|
| GET    | `/x_accounts`              | `index`    | Management page: list cached followings + select/unselect + refresh button |
| POST   | `/x_accounts/refresh`      | `refresh`  | Trigger an `XClient#fetch_following` + diff-upsert; redirect to `index` |
| PATCH  | `/x_accounts/:id`          | `update`   | Toggle `selected` (and edit `display_count`)                       |
| GET    | `/x_accounts/:id` (XHR)    | `show`     | Welcome-gadget AJAX fragment — calls `XClient#fetch_recent_tweets` |

No `new`/`create`/`destroy` — additions happen via `refresh` (X is the source of truth for "is this person in my following list?"); removal happens via `update selected=false` (user unpins the gadget) plus the refresh-diff (no longer following on X side).

### Controller skeleton: `app/controllers/x_accounts_controller.rb`

```ruby
class XAccountsController < ApplicationController
  before_action :require_twitter_authenticated_user
  before_action :preload_account, only: %i[show update]

  def index
    @x_accounts = XAccount.where(user_id: current_user.id).not_deleted.order(:username)
    @last_fetched_at = @x_accounts.maximum(:fetched_at)
  end

  def refresh
    client = XClient.new(oauth_token: current_user.twitter_oauth_token,
                         oauth_token_secret: current_user.twitter_oauth_token_secret)
    result = client.fetch_following(twitter_uid: current_user.twitter_uid)
    if result[:success]
      XAccount.transaction { sync_following!(result[:items]) }
      redirect_to x_accounts_path, notice: t('x_accounts.refresh.success')
    else
      redirect_to x_accounts_path, alert: t("x_accounts.refresh.errors.#{result[:error]}")
    end
  end

  def update
    @x_account.attributes = x_account_params
    @x_account.transaction { @x_account.save! }
    redirect_to x_accounts_path
  end

  def show
    client = XClient.new(oauth_token: current_user.twitter_oauth_token,
                         oauth_token_secret: current_user.twitter_oauth_token_secret)
    result = client.fetch_recent_tweets(twitter_uid: @x_account.x_user_id,
                                        max_results: @x_account.display_count)
    if result[:success]
      @x_items = result[:items]
      @x_error = nil
    else
      @x_items = []
      @x_error = result[:error]
    end
    render layout: !request.xhr?
  end

  private

  def require_twitter_authenticated_user
    return if current_user.name.present? && current_user.twitter_oauth_token.present?
    redirect_to preferences_path, alert: t('x_accounts.errors.not_linked')
  end

  def preload_account
    @x_account = XAccount.find(params[:id])
    head :not_found and return unless @x_account.readable_by?(current_user)
    head :not_found and return if @x_account.deleted?
  end

  def x_account_params
    params.require(:x_account).permit(:selected, :display_count).merge(user_id: current_user.id)
  end

  def sync_following!(api_items)
    # diff-upsert: hits keyed by (user_id, x_user_id); soft-delete missing+selected, hard-delete missing+unselected.
  end
end
```

### Guards

- **`require_twitter_authenticated_user`** (before_action on every action) — composite gate: `name.present?` (Twitter-signed UI convention) **AND** `twitter_oauth_token.present?` (real API prerequisite). Either failure redirects to preferences with a localized alert (e.g. "X account is not linked"). Both checks together protect against (a) Google-only users URL-fudging to `/x_accounts`, and (b) pre-v1.18 Twitter users who signed in before the OAuth-token-persistence migration shipped and haven't re-signed-in yet.
- **`preload_account`** (before_action on `show` + `update`) — exact same shape as `MastodonAccountsController#preload_account`: 404 on `readable_by?(current_user)` miss, 404 on `deleted?` (defense in depth — the index query already filters `.not_deleted`, but a stale URL or hand-crafted ID for a soft-deleted row should not surface tweets).

### Per-user isolation

`include Crud::ByUser` on the model gives the `readable_by?(user)` method, called from `preload_account`. Every controller query starts from `.where(user_id: current_user.id)`. This is the existing repo-wide convention (Mastodon, Feed, Bookmark, Todo, Note all do this manually — there is no global scope; manual `user_id` filtering is the contract).

`x_account_params` never permits `user_id` from form input; it's merged server-side. Matches v1.16 (and the project's Key Decision row: "`user_id` never in strong params — merged server-side").

## Portal Gadget Integration

### How `Portal#get_gadgets` enumerates today

`app/models/portal.rb:50-78` builds a `Hash[gadget_id => gadget_object]` and concatenates four sources:

1. `BookmarkGadget.new(user)` if `visible?`
2. `TodoGadget.new(...)` if `user.preference.use_todo?`
3. `CalendarGadget.new(user)` if `user.preference.use_calendar?`
4. `Feed.where(user_id:).not_deleted` (unconditional — every active feed is a gadget)
5. `MastodonAccount.where(user_id:).not_deleted` (unconditional — every active Mastodon account is a gadget)

Gadgets are then bucketed into three columns by `PortalLayout` rows; unlaid-out gadgets are spread across columns by `(index % 3)`. The view renders each via `render g.class.name.underscore, gadget: g` — so the partial path is derived from the model class name automatically (`XAccount` → `welcome/_x_account.html.erb`).

### Adding the X gadget

Inside `Portal#get_gadgets`, add **after** the `MastodonAccount` block:

```ruby
XAccount.where(user_id: user.id, selected: true).not_deleted.each do |x|
  ret[x.gadget_id] = x
end
```

**Two intentional divergences from MastodonAccount:**

1. **`selected: true` filter.** Mastodon enumerates all rows because every row in `mastodon_accounts` was manually added by the user (the existence of the row = the intent to gadget it). X enumerates only `selected: true` because every row in `x_accounts` came from the cache refresh, and the cache is much larger than the set the user wants on their welcome page. Without this filter the welcome page would render hundreds of gadgets.
2. **No preference gate.** Like Mastodon (and unlike `use_todo` / `use_calendar`), the presence of selected rows is itself the on/off signal. A user with zero `selected: true` rows sees no X gadgets — equivalent to "X feature off." No new preference column needed. If a future milestone wants an explicit `use_x` master toggle, it follows the existing `Preference` add-column pattern; it isn't required for v1.18.

### Gadget partial: `app/views/welcome/_x_account.html.erb`

Direct copy of `_mastodon_account.html.erb` structure:

```erb
<script>
  $(document).ready(function() {
    $.get('<%= x_account_path(gadget, format: :html) %>', { format: 'html' }, function(html) {
      $('#<%= gadget.gadget_id %>').html(html);
    })
    .fail(function(xhr) {
      const container = $('#<%= gadget.gadget_id %>');
      container.find('ol li span').first().text(container.data('fetchFailedMessage') + '(' + xhr.status + ')');
    });
  });
</script>

<div id="<%= gadget.gadget_id %>" class="gadget" data-fetch-failed-message="<%= t('.fetch_failed') %>">
  <div>
    <div class="title"><%= gadget.title %></div>
    <ol>
      <li>
        <span style="line-height: <%= gadget.display_count * 1.5 %>em;"><%= t('.loading') %></span>
      </li>
    </ol>
  </div>
</div>
```

### Show partial: `app/views/x_accounts/show.html.erb`

Direct copy of `mastodon_accounts/show.html.erb`, but iterating `@x_items` / `@x_error` and using `t('x_accounts.show.errors.*')` keys.

### Drawer link (optional but recommended)

`app/views/layouts/application.html.erb:35-48` already has a drawer with links to home/preferences/bookmarks/todos/feeds/**mastodon**/sign_out. Add `<%= link_to t('nav.x_account'), x_accounts_path if current_user.name.present? %>` between the mastodon link and sign_out. The `current_user.name.present?` gate keeps the link out for Google-only users (matches the controller `require_twitter_authenticated_user` gate; failing silently with a missing link is better UX than showing a link that redirects on click).

## Suggested Build Order

Four phases. Dependency chain runs **OAuth persistence → service skeleton → model + management UI + refresh → welcome gadget + tests + tri-suite gate**. Each phase ends with a tri-suite green gate (per CLAUDE.md policy).

### Phase 60 — User OAuth token persistence

**Scope:**
- Migration: `add_twitter_oauth_to_users` (3 cols).
- `User`: `encrypts :twitter_oauth_token, :twitter_oauth_token_secret`; update `from_omniauth` Twitter branch to write `twitter_uid` + token + secret on every callback (create AND existing-user sign-in path).
- Minitest: `from_omniauth` with a Twitter-shaped `OmniAuth::AuthHash` writes the three fields; existing user re-sign-in path overwrites them; columns are encrypted (read from `RawUserRecord` raw column ≠ plaintext); Google branch unchanged.
- ja/en locale keys: error string `x_accounts.errors.not_linked` (reserved for phase 62, declared here so parity test in this phase establishes the key namespace).

**Why first:** Every downstream phase needs `current_user.twitter_oauth_token` to be readable. Doing the migration last would block every other phase's tests on stubbed credentials. Doing it first means subsequent phases run integration tests with a real fixture user that has populated tokens (test fixture: `users.yml :twitter_user` gets `twitter_uid: '1'`, `twitter_oauth_token: 'fake_token'`, etc., which Rails encryption with the test-env `dev_dummy_key` will accept).

**No UI in this phase** — invisible plumbing.

### Phase 61 — `XClient` service + stub contract

**Scope:**
- `app/services/x_client.rb` with `fetch_following`, `fetch_recent_tweets`, `stub_following_result`, `stub_tweets_result`.
- Pick OAuth 1.0a signing path (A: `oauth` gem direct; B: Faraday + manual header) — log as a v1.18 decision row in `PROJECT.md`.
- Minitest: `test/services/x_client_test.rb` — happy path for both methods (Faraday `:test` adapter if path B; WebMock-or-`OAuth::AccessToken` instance stub if path A); 401 → `:unauthorized`; 429 → `:rate_limited`; timeout → `:timeout`; malformed JSON → `:parse_error`; stub_*_result short-circuits HTTP (matches the v1.16 `test_stub_fetch_result_short_circuits_http` shape).

**Why second:** The controller will instantiate `XClient` directly; the service has to exist and be tested before any controller test that does not stub it at the class level can pass. Phases 62–63 can mock via `stub_*_result` once the contract is established here.

**No UI in this phase** — service is internal.

### Phase 62 — `XAccount` model + management UI + refresh

**Scope:**
- Migration: `create_x_accounts` (per Data Model section above).
- `app/models/x_account.rb` (per skeleton).
- `app/controllers/x_accounts_controller.rb` actions: `index`, `refresh`, `update`. (Defer `show` to phase 63.)
- Views: `index.html.erb` (list with select checkboxes + refresh button), `_form` partial only if `update` uses a form (it's a simple checkbox toggle; can be inline in `index`).
- Routes: `resources :x_accounts, only: %i[index update]` + `collection { post 'refresh' }`. (`:show` added in phase 63.)
- `require_twitter_authenticated_user` before_action.
- ja/en strings: `x_accounts.index.*`, `x_accounts.refresh.*` (success + per-error keys), drawer `nav.x_account` (gated link).
- Minitest: model unit tests (uniqueness scope, `gadget_id`, `title`, `derive_profile_url`); controller integration tests with `XClient.stub_following_result` for refresh, plain DB writes for `update`, isolation 404 tests (mirror v1.16's `test_他人のアカウントは編集できない` pattern), guard redirect when `twitter_oauth_token` is blank.
- ja/en parity test.

**Why third:** This is the big phase. The model + management UI is the user-visible MVP minus the welcome integration. Splitting management UI from welcome gadget here means a phase boundary where the management page is fully usable in isolation — important UX checkpoint.

### Phase 63 — Welcome gadget integration + show action + tests sweep + tri-suite gate

**Scope:**
- Route: `resources :x_accounts, only: %i[index show update]` (add `:show`).
- Controller: `show` action + `preload_account` before_action (filter only `:show, :update`).
- View: `app/views/x_accounts/show.html.erb` (full + XHR-fragment).
- View: `app/views/welcome/_x_account.html.erb`.
- `Portal#get_gadgets`: add `XAccount.where(user_id:, selected: true).not_deleted` block.
- ja/en strings: `x_accounts.show.*` (errors + loading + fetch_failed), `welcome.x_account.*` if needed.
- Minitest: controller `show` tests (HTML + XHR; stub success + per-error case); welcome view integration test confirms partial renders when `selected: true` rows exist and is absent when not; locale parity for the new keys.
- Cucumber: `features/06.X.feature` (`@x_gadget` stub flow) — sign in as Twitter fixture user, refresh sets `selected: true` (fixture), visit `/`, assert gadget panel shows stubbed tweet text. Pattern lifts directly from `features/05.Mastodon.feature`.
- Tri-suite gate: `yarn run lint && bin/rails test && bundle exec rake dad:test` (with the documented Cucumber flake rerun policy).

**Why fourth and last:** Welcome gadget integration is the final "feature done" step. It depends on Phase 61 (service) and Phase 62 (model + selected flag + selected rows must exist in fixtures). Doing it last keeps the welcome page change scoped and reviewable.

**Rationale for choosing four phases (not three, not five):**

- A 3-phase plan that bundles model + controller + welcome (i.e. fuses 62 + 63) creates a single oversized phase with two distinct user-visible deliverables (management UI; welcome gadget). It also makes the phase-end gate ambiguous — what does "done" mean when failing welcome but passing management?
- A 5-phase plan that splits management UI from refresh-diff is over-decomposed: refresh-diff is the management UI's reason to exist. Splitting them creates a phase ("management UI without refresh") that doesn't deliver standalone value, just plumbing.
- Four maps cleanly to one prerequisite phase (auth), one infrastructure phase (service), one feature phase (cache + UI + refresh), one integration phase (welcome + tests). Each phase has a single primary deliverable, a tri-suite gate, and a clear seam to the next.

## Integration Risks

### Tests that will need updates

| Test / contract                                | Risk                                                                 | Mitigation                                                                                                       |
|------------------------------------------------|----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| `test/fixtures/users.yml`                      | Twitter fixture user needs `twitter_uid`, `twitter_oauth_token`, `_secret` for any controller test that hits `/x_accounts`. | Add to fixture file in Phase 60; values are plaintext strings — Rails encryption auto-encrypts on write, even from fixtures, when `support_unencrypted_data = true` is set (which it is in test env). |
| Locale parity test (`ja.yml` ↔ `en.yml`)       | Every new `x_accounts.*` / `nav.x_account` / `welcome.x_account.*` key must be present in both files. | Already enforced by existing parity test; mechanical fix per phase.                                              |
| `test/controllers/welcome_controller/layout_structure_test.rb` | Layout test currently does not assert anything about `x_account` panels; adding X gadgets via `Portal#get_gadgets` may add panel containers to the page that an `assert_select` count-based test could overshoot. | Audit the file for total-gadget-count assertions; if any exist, add an `XAccount.where(user_id:).delete_all` setup line to keep the count predictable.                                                                                       |
| Drawer link contract (theme tests)             | New `nav.x_account` drawer entry on layouts/application.html.erb may break theme-specific drawer count assertions (if any exist).               | Search for `nav.mastodon` in tests — wherever it's asserted, mirror with `nav.x_account` assertions (gated on `name.present?`).                                                                                       |
| Preferences i18n parity test                   | If a preferences entry-point row is added for `/x_accounts` (mirror of mastodon link), keys go under `preferences.index.x_accounts.*`. | Same parity-test pattern as v1.17 email registration entry.                                                  |
| Cucumber `@mastodon_gadget` Before/After hooks | If there's a hook that clears `MastodonClient.stub_fetch_result`, an analogous hook is needed for `XClient.stub_*_result` (both accessors). | Add to `features/support/`; same shape as mastodon hook.                                                       |
| Existing `from_omniauth` Twitter test (if any) | The Twitter branch test currently asserts only `name` + dummy email. The new behavior writes 3 more columns; existing tests should still pass but should be extended.                                                  | Extend the Twitter-branch test in `test/models/user_test.rb` (phase 60).                                       |
| Cucumber DB-state leak (known flake)           | `selected: true` rows from earlier scenarios may leak into later ones (per CLAUDE.md's "Cucumber suite — known flakiness" note).                                                | Mirror the mitigation pattern: Cucumber `Before` hook clears `XAccount.where(user_id: fixture_user.id).delete_all` (and the `stub_*_result` accessors).                                                          |

### Pre-existing risks the milestone inherits but does not introduce

- **PITFALL-02 (v1.17): Twitter `from_omniauth` matches by `name`, not `uid`.** Two Twitter users with the same display name collide on the `users.name` UNIQUE index. v1.18 makes the prerequisite (storing `twitter_uid`) but **does not fix** the lookup. Document as carry-forward in `PITFALLS.md`. A follow-up milestone can switch the lookup to `where(twitter_uid: access_token['uid'])` with a backfill or `OR`-fallback plan.
- **`User#admin?` uses `User.first.email`** — fragile, but unrelated to v1.18 surface.

### Things that should NOT change

- `MastodonClient` and `MastodonAccount` — independent feature; no overlap.
- Preferences columns — no new `use_x` flag; presence of `selected: true` rows is the enable signal.
- Devise modules — no add/remove; OAuth tokens stored as plain ActiveRecord columns, not via a Devise module.
- `Portal#portal_columns` layout algorithm — only `get_gadgets` is touched, the column-assignment logic is unchanged.

## Modified Files

| File                                                  | Phase | Change                                                                                          |
|-------------------------------------------------------|-------|-------------------------------------------------------------------------------------------------|
| `app/models/user.rb`                                  | 60    | Add `encrypts :twitter_oauth_token, :twitter_oauth_token_secret`; update Twitter branch of `from_omniauth` to write 3 new columns. |
| `app/models/portal.rb`                                | 63    | Add the `XAccount.where(user_id:, selected: true).not_deleted.each` block in `get_gadgets`.     |
| `app/views/layouts/application.html.erb`              | 62    | Add gated drawer link to `x_accounts_path`.                                                     |
| `config/routes.rb`                                    | 62/63 | Add `resources :x_accounts, only: %i[index show update] do collection { post 'refresh' } end`.  |
| `config/locales/en.yml`, `config/locales/ja.yml`      | 60–63 | New keys per phase: `x_accounts.errors.not_linked` (60), `x_accounts.index.*` + `x_accounts.refresh.*` + `nav.x_account` (62), `x_accounts.show.*` + `welcome.x_account.*` (63). Parity-test enforced. |
| `test/fixtures/users.yml`                             | 60    | Twitter fixture user gets `twitter_uid`, `twitter_oauth_token`, `twitter_oauth_token_secret` populated. |
| `test/controllers/welcome_controller/layout_structure_test.rb` | 63 | Audit + extend for `_x_account` panels if count-based.                                          |
| `test/models/user_test.rb`                            | 60    | Extend `from_omniauth` Twitter-branch tests for the 3 new columns + encryption assertion.       |
| `db/schema.rb`                                        | 60/62 | Regenerated by migrations.                                                                       |
| `features/support/` (any global Before/After file)    | 63    | Clear `XClient.stub_following_result` / `stub_tweets_result` between scenarios.                  |

## New Files

| File                                                                              | Phase | Purpose                                                                                                          |
|-----------------------------------------------------------------------------------|-------|------------------------------------------------------------------------------------------------------------------|
| `db/migrate/<ts>_add_twitter_oauth_to_users.rb`                                   | 60    | Adds `twitter_uid` (string), `twitter_oauth_token` (text, encrypted), `twitter_oauth_token_secret` (text, encrypted). |
| `db/migrate/<ts+1>_create_x_accounts.rb`                                          | 62    | Creates the `x_accounts` table per Data Model section.                                                            |
| `app/services/x_client.rb`                                                        | 61    | `XClient` Faraday service: `fetch_following`, `fetch_recent_tweets`, `stub_following_result`, `stub_tweets_result`, OAuth 1.0a signing. |
| `app/models/x_account.rb`                                                         | 62    | `XAccount` model: `include Crud::ByUser`, `gadget_id`, `title`, `derive_profile_url`, `set_display_count`.        |
| `app/controllers/x_accounts_controller.rb`                                        | 62/63 | `index`/`refresh`/`update` (62), `show` (63). `require_twitter_authenticated_user` guard.                          |
| `app/views/x_accounts/index.html.erb`                                             | 62    | Management page: cached list, refresh button, select/unselect checkboxes, `fetched_at` "last refreshed" indicator. |
| `app/views/x_accounts/show.html.erb`                                              | 63    | HTML + XHR fragment for the welcome gadget body (tweet list / error / empty).                                     |
| `app/views/welcome/_x_account.html.erb`                                           | 63    | jQuery AJAX loader stub for the gadget container — direct copy of `_mastodon_account.html.erb` shape.             |
| `test/models/x_account_test.rb`                                                   | 62    | Unit tests: uniqueness scope, `derive_profile_url`, `title`, `gadget_id`, `set_display_count`.                     |
| `test/services/x_client_test.rb`                                                  | 61    | `fetch_following` happy + error matrix; `fetch_recent_tweets` happy + error matrix; stub short-circuit.            |
| `test/controllers/x_accounts_controller_test.rb`                                  | 62/63 | `index`/`refresh`/`update`/`show` (HTML + XHR); ja/en assertions; isolation 404s; `not_linked` guard redirect.    |
| `test/fixtures/x_accounts.yml`                                                    | 62    | Twitter fixture user's seed rows (mix of selected + unselected, with `fetched_at` populated).                       |
| `test/support/x_accounts.rb` (mirror of `test/support/mastodon_accounts.rb`)      | 62    | Test helpers: `x_account_of(user_id)`, `x_account_params`.                                                         |
| `features/06.X.feature` (`@x_gadget`)                                             | 63    | Cucumber scenario: Twitter sign-in → refresh w/ `stub_following_result` → toggle `selected` → visit `/` → assert gadget shows stubbed tweet text. |
