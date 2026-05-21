# Architecture Patterns: v1.31 X Account Manual Add (Non-Following)

**Domain:** Add-by-handle action layered on top of existing XAccountsController / XClient service
**Researched:** 2026-05-22
**Confidence:** HIGH — based on direct codebase inspection + X API v2 official documentation

---

## Existing Architecture Baseline

### What already exists

| Component | State | Key details |
|-----------|-------|-------------|
| `XClient` | Exists | OAuth2 Bearer token only. Public methods: `fetch_following(user:)`, `fetch_recent_tweets(user:, x_user_id:, limit:)`. Both return `{ success:, items: }` or `{ success: false, error: Symbol }`. |
| `XAccountsController` | Exists | `index`, `refresh`, `show`, `update`. Includes `TwitterLinkRequirement` (`require_twitter_linked` before_action). `record_x_api_call` private helper writes to `x_api_calls`. |
| `XAccount` model | Exists | `Crud::ByUser` concern, soft-delete, `selected` cap 12/warn 9, `protected_acknowledged` gate. `refresh_cache_from_items!` class method does diff-upsert against following payload. |
| `x_accounts` table | Exists | `user_id`, `x_user_id`, `username`, `display_name`, `avatar_url`, `protected`, `protected_acknowledged`, `selected`, `deleted`, `display_count`. Unique index on `(user_id, x_user_id)`. |
| `x_api_calls` table | Exists | Append-only log: `user_id`, `endpoint`, `success`, `error_code`, `called_at`. |

### What does NOT yet exist

- `x_accounts.manually_added` column
- `XClient#lookup_user_by_username` method
- A controller action to receive and process a handle submission
- Any view form for handle input on the `index` page

---

## New vs Modified Components

| Component | Status | Description |
|-----------|--------|-------------|
| `x_accounts` migration | **NEW** | Add `manually_added boolean NOT NULL DEFAULT false` |
| `XClient#lookup_user_by_username` | **NEW** | Calls `GET /2/users/by/username/:username`, returns normalized hash or error symbol |
| `XAccountsController#lookup_and_add` | **NEW** | POST collection action; calls `lookup_user_by_username`, upserts into `x_accounts` with `manually_added: true` |
| `XAccount.upsert_manual!` | **NEW** | Class method that creates or un-deletes an account with `manually_added: true` |
| `XAccount.refresh_cache_from_items!` | **MODIFIED** | Must preserve `manually_added` flag on existing rows; must NOT soft-delete manually-added rows that are absent from the following payload |
| `app/views/x_accounts/index.html.erb` | **MODIFIED** | Add handle input form that POSTs to `lookup_and_add_x_accounts_path` |
| `config/routes.rb` | **MODIFIED** | Add `post :lookup_and_add` to the `x_accounts` collection |
| `config/locales/ja.yml`, `en.yml` | **MODIFIED** | New keys under `x_accounts.lookup_and_add.*` |

---

## New Action: `lookup_and_add`

### Route

```ruby
resources :x_accounts, only: %i[index show update] do
  collection do
    post :refresh
    post :lookup_and_add   # NEW
  end
end
```

Route helper: `lookup_and_add_x_accounts_path` — `POST /x_accounts/lookup_and_add`

### Why a new collection action, not extending `refresh`

Refresh syncs the following list (one canonical source → replace). Lookup-and-add is a user-initiated point lookup (one username → upsert). They have different inputs, different API endpoints, different error semantics, and a different success path. Merging them into a single action would require branching on params and muddying both code paths. A dedicated action keeps both paths simple and testable independently.

### Controller action shape

```ruby
def lookup_and_add
  handle = params[:username].to_s.strip.delete_prefix('@').downcase
  if handle.blank? || handle !~ /\A[A-Za-z0-9_]{1,15}\z/
    flash[:alert] = t('x_accounts.lookup_and_add.invalid_handle')
    redirect_to x_accounts_path and return
  end

  result = XClient.new.lookup_user_by_username(user: current_user, username: handle)
  record_x_api_call(endpoint: 'lookup_user_by_username', result: result)

  unless result[:success]
    flash[:alert] = t("errors.x_client.#{result[:error]}")
    redirect_to x_accounts_path and return
  end

  XAccount.upsert_manual!(current_user, result[:item])
  flash[:notice] = t('x_accounts.lookup_and_add.success', handle: handle)
  redirect_to x_accounts_path
rescue ActiveRecord::RecordInvalid => e
  flash[:alert] = e.record.errors.full_messages.first
  redirect_to x_accounts_path
end
```

Handle normalisation (strip `@`, downcase, pattern check against `^[A-Za-z0-9_]{1,15}$`) must happen in the controller before calling the API — cheap and avoids a wasteful network round-trip for obvious bad input.

### Where validation lives

| Validation | Location | Rationale |
|------------|----------|-----------|
| Handle format (`/\A[A-Za-z0-9_]{1,15}\z/`) | Controller, before API call | Avoid network cost; this is a cheap guard |
| Account existence | XClient (API response status) | Only the API can confirm existence |
| Selection cap | XAccount model (`selection_cap` validation) | Already enforced by the model; no duplication |
| Protected-acknowledgement gate | XAccount model (`protected_acknowledgement` validation) | Already enforced; add-by-handle creates the row as unselected, so this gate is irrelevant at creation time; it fires when the user later toggles `selected: true`, which is the existing `update` flow |
| `manually_added` assignment | `XAccount.upsert_manual!` class method | Model layer owns the semantics of the flag |

Do not duplicate model validations in the controller. The controller's job is format-checking the raw string param and translating errors to flash messages.

---

## New XClient Method: `lookup_user_by_username`

### X API v2 endpoint

`GET /2/users/by/username/{username}`

Required: Bearer token (same as existing `fetch_following` / `fetch_recent_tweets`).

Response shape (200):
```json
{ "data": { "id": "...", "username": "...", "name": "...", "profile_image_url": "...", "protected": false } }
```

Not-found: 400 with `errors[0].title == "Invalid Request"` or 404 depending on API version. Treat both as `:not_found`.

### Method contract (same pattern as existing methods)

```ruby
# Returns { success: true, item: { id:, username:, name:, profile_image_url:, protected: } }
#      or { success: false, error: Symbol }
def lookup_user_by_username(user:, username:)
  res = connection_for(user).get("/2/users/by/username/#{CGI.escape(username)}") do |req|
    req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
  end

  parse_lookup_response(res)
rescue Faraday::TimeoutError, Faraday::ConnectionFailed
  { success: false, error: :timeout }
rescue Faraday::Error
  { success: false, error: :network }
rescue JSON::ParserError
  { success: false, error: :parse_error }
end
```

The private `parse_lookup_response` follows the same status-code pattern as `parse_following_response`:
- 200 → parse JSON, normalize to `item:` using `normalize_following_row` (identical shape)
- 401 → `:unauthorized`
- 404 → `:not_found`
- 400 → `:not_found` (X API returns 400 for unknown usernames in some API tiers)
- 429 → `:rate_limited`
- other → `:api_error`

`normalize_following_row` is already private on `XClient` and produces the exact hash shape the new method needs. Reuse it directly.

---

## `manually_added` Flag: Schema and Model

### Migration

```ruby
add_column :x_accounts, :manually_added, :boolean, null: false, default: false
```

A NOT NULL DEFAULT false column is safe to add to existing rows without a backfill: all existing rows are from `refresh_cache_from_items!` (follow-based) and should start as `false`.

### `XAccount.upsert_manual!`

```ruby
def self.upsert_manual!(user, item)
  item = item.with_indifferent_access
  xid  = item[:id].to_s
  raise ArgumentError, 'x_user_id blank' if xid.blank?

  acc = XAccount.where(user_id: user.id, x_user_id: xid).first_or_initialize
  acc.assign_attributes(
    username:        item[:username].to_s,
    display_name:    item[:name].to_s,
    avatar_url:      item[:profile_image_url].presence,
    protected:       ActiveModel::Type::Boolean.new.cast(item[:protected]),
    deleted:         false,
    manually_added:  true
  )
  acc.save!
  acc
end
```

Upsert semantics: if the account already exists (from following sync), it gains the `manually_added: true` flag and is un-deleted. If it was already manually added, idempotent. `acc.save!` will raise `ActiveRecord::RecordInvalid` if, say, `x_user_id` is blank — the controller rescues this.

Do NOT set `selected: true` on creation. The user manually selects the account after it appears in the list, using the existing `update` flow. This matches how follow-synced accounts work.

---

## Refresh Flow: Preserving `manually_added`

### The problem

`refresh_cache_from_items!` currently soft-deletes any `x_accounts` row NOT present in the following payload. Without changes, a manually-added account that the user does not follow would be soft-deleted on the next refresh, silently removing the user's intentional addition.

### The fix: skip soft-delete for `manually_added: true` rows

The current soft-delete loop in `refresh_cache_from_items!`:

```ruby
XAccount.where(user_id: user.id).find_each do |acc|
  next if seen[acc.x_user_id]
  acc.update!(deleted: true)
end
```

Change to:

```ruby
XAccount.where(user_id: user.id).find_each do |acc|
  next if seen[acc.x_user_id]
  next if acc.manually_added?   # NEW: preserve manually-added rows
  acc.update!(deleted: true)
end
```

This is a minimal, contained change. All test assertions for the existing behavior (soft-delete of unselected/selected rows absent from payload) remain valid — those test rows have `manually_added: false` (default). New tests cover the manual-add exception.

### When a manually-added account IS in the following payload

`refresh_cache_from_items!` upserts it normally (updates username/display_name/avatar, clears `deleted`). The `manually_added` flag must NOT be reset to `false` by refresh. The upsert block in `refresh_cache_from_items!` currently does not set `manually_added`, so no change is needed there. Confirm by reading the `assign_attributes` call in `refresh_cache_from_items!`:

```ruby
acc.assign_attributes(
  username: ..., display_name: ..., avatar_url: ..., protected: ..., deleted: false
)
```

`manually_added` is not in this list, so it is naturally preserved. No change required here.

---

## Data Flow: End-to-End for Add-by-Handle

```
User fills handle input form on /x_accounts (index page)
  └─ POST /x_accounts/lookup_and_add  params: { username: 'somehandle' }
       └─ XAccountsController#lookup_and_add
            ├─ require_twitter_linked (before_action — same gate as all other actions)
            ├─ normalize + format-validate handle
            ├─ XClient.new.lookup_user_by_username(user: current_user, username: handle)
            │     └─ GET https://api.twitter.com/2/users/by/username/somehandle?user.fields=...
            │          (uses connection_for(user) → Bearer token, same as fetch_following)
            ├─ record_x_api_call(endpoint: 'lookup_user_by_username', result:)
            │     └─ XApiCall.record!(...)     # writes to x_api_calls
            ├─ XAccount.upsert_manual!(current_user, result[:item])
            │     └─ first_or_initialize on (user_id, x_user_id)
            │          → assign_attributes + save!   (manually_added: true, deleted: false)
            └─ redirect_to x_accounts_path with flash
```

---

## Data Flow: Refresh Interaction with `manually_added`

```
POST /x_accounts/refresh
  └─ XAccountsController#refresh
       └─ XClient.new.fetch_following(user:)
            └─ XAccount.refresh_cache_from_items!(user, items)
                 ├─ For each item in payload → upsert (manually_added untouched)
                 └─ For each row NOT in payload:
                      ├─ if manually_added? → skip (NEW)
                      └─ else → soft-delete (existing behavior)
```

---

## View: Handle Input Form

Add above or below the existing accounts list on `index.html.erb`. A simple inline form:

```erb
<section class="x-accounts-page__add-manual">
  <%= form_with url: lookup_and_add_x_accounts_path, method: :post, local: true,
        html: { class: 'x-accounts-page__add-manual-form' } do |f| %>
    <%= f.label :username, t('x_accounts.lookup_and_add.label'), class: 'x-accounts-page__add-manual-label' %>
    <%= f.text_field :username, placeholder: '@username',
          pattern: '[A-Za-z0-9_]{1,15}',
          maxlength: 16,
          class: 'x-accounts-page__add-manual-input' %>
    <%= f.submit t('x_accounts.lookup_and_add.submit'), class: 'x-accounts-page__add-manual-btn' %>
  <% end %>
</section>
```

No JS required. Standard synchronous POST, redirect-after-POST pattern consistent with all other forms in the app.

The `@` prefix handling: accept input with or without `@`, strip it server-side in the controller. Do not rely on the HTML `pattern` attribute for security validation; it is UX only.

---

## Locale Keys Required

```yaml
x_accounts:
  lookup_and_add:
    label:          "ハンドルで追加"            # ja
    submit:         "追加"                     # ja
    success:        "@%{handle} を追加しました。"  # ja
    invalid_handle: "有効なXハンドルを入力してください（英数字・アンダースコア、1〜15文字）。"  # ja
```

`errors.x_client.not_found` (already exists in both locales) covers the API 404 path. `errors.x_client.unauthorized`, `timeout`, `rate_limited`, `api_error`, `parse_error` already exist and are reused.

English equivalents follow the same key paths under `en.yml`.

---

## Build Order

Dependencies flow strictly data-layer-first:

**Phase A — Schema migration**
Add `manually_added boolean NOT NULL DEFAULT false` to `x_accounts`. This must precede all other code changes since both the model and `refresh_cache_from_items!` change depend on the column existing.

**Phase B — XClient `lookup_user_by_username`**
New private `parse_lookup_response`; reuse `normalize_following_row` and `connection_for`. Add unit test with Faraday `:test` adapter. No controller changes yet.

**Phase C — XAccount model changes**
- `manually_added` attribute (column already exists from Phase A)
- `upsert_manual!` class method
- `refresh_cache_from_items!` modification (preserve `manually_added: true` rows)
- Model unit tests for `upsert_manual!`, refresh-preserves-manual, refresh-deletes-non-manual

**Phase D — Controller action + routes**
- `post :lookup_and_add` in routes
- `XAccountsController#lookup_and_add` action
- `record_x_api_call` call with `endpoint: 'lookup_user_by_username'`
- Controller integration tests (success path, not_found, rate_limited, invalid handle, other-user isolation)

**Phase E — View + locale strings**
- Handle input form on `index.html.erb`
- All new locale keys in `ja.yml` and `en.yml`
- i18n parity test covers new keys
- Can be done in the same phase as D or as a thin follow-on

**Phase F — Cucumber E2E + tri-suite gate**
- Feature scenario: sign in, open `/x_accounts`, submit a handle, confirm account appears in list
- WebMock stub for `GET /2/users/by/username/:username`
- Tri-suite green gate

---

## Interfaces That Change

| Interface | Change | Caller impact |
|-----------|--------|---------------|
| `XClient` | New public method `lookup_user_by_username` added | None — additive |
| `XAccount.refresh_cache_from_items!` | Soft-delete loop skips `manually_added?` rows | No existing callers affected; behavior only changes for rows that don't exist yet |
| `XAccountsController` | New `lookup_and_add` action | Route added; all other actions unchanged |
| `config/routes.rb` | `post :lookup_and_add` added to collection | No existing routes change |
| `x_accounts` table | `manually_added` column added with DEFAULT false | All existing rows read as `false`; no backfill needed |

---

## What NOT to Build (Scope Boundaries)

- **Separate `manually_added` flag display in the UI** — the index list shows all non-deleted accounts regardless of origin; a visual badge for manually-added accounts is a nice-to-have but out of scope for v1.31.
- **Bulk add or CSV import** — single-handle input only.
- **Explicit delete of manually-added accounts** — the existing soft-delete + refresh logic now preserves them; a dedicated remove action is a future enhancement.
- **Background job for lookup** — synchronous is consistent with all existing API calls in the app; no Sidekiq/ActiveJob infrastructure exists.
- **Rate-limit header parsing** — the existing `record_x_api_call` already has a `rate_limit_remaining` column; wire it only if the API returns it reliably for this endpoint; otherwise leave nil (existing behavior).

---

## Sources

- Direct inspection: `app/services/x_client.rb`
- Direct inspection: `app/controllers/x_accounts_controller.rb`
- Direct inspection: `app/models/x_account.rb`
- Direct inspection: `db/schema.rb`
- Direct inspection: `config/routes.rb`
- Direct inspection: `test/controllers/x_accounts_controller_test.rb`
- Direct inspection: `test/models/x_account_test.rb`
- Direct inspection: `app/views/x_accounts/index.html.erb`
- X API v2 official documentation: [GET /2/users/by/username/{username}](https://docs.x.com/x-api/users/get-user-by-username)
