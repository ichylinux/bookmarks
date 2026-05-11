# Architecture Research — Mastodon Account Following

**Project:** Bookmarks v1.16
**Researched:** 2026-05-12
**Confidence:** HIGH (based on direct code inspection of all referenced files)

---

## New Components

| File | Type | Purpose |
|------|------|---------|
| `app/models/mastodon_account.rb` | Model | Per-user Mastodon account record; holds parsed instance_host + username; exposes `statuses`, `gadget_id`, `visible?` |
| `app/models/mastodon_client.rb` | Service class | Calls Mastodon REST API: `/api/v1/accounts/lookup` then `/api/v1/accounts/:id/statuses`; stateless; injected with instance_host + username |
| `app/controllers/mastodon_accounts_controller.rb` | Controller | CRUD mirroring FeedsController; `preload_mastodon_account` before_action; show fetches live statuses |
| `app/views/mastodon_accounts/index.html.erb` | View | Table of registered accounts (mirrors feeds/index) |
| `app/views/mastodon_accounts/new.html.erb` | View | Renders `_form` partial |
| `app/views/mastodon_accounts/edit.html.erb` | View | Renders `_form` partial |
| `app/views/mastodon_accounts/_form.html.erb` | Partial | Form with `profile_url`, `name`, `display_count` fields |
| `app/views/mastodon_accounts/show.html.erb` | View | Renders live statuses list (server-side, no XHR) |
| `app/views/welcome/_mastodon_account.html.erb` | Partial | Gadget panel; XHR-loads show action identical to `_feed.html.erb` pattern |
| `db/migrate/TIMESTAMP_create_mastodon_accounts.rb` | Migration | Creates `mastodon_accounts` table |
| `config/locales/ja.yml` (additions) | Locale | Keys for mastodon_accounts views |
| `config/locales/en.yml` (additions) | Locale | Keys for mastodon_accounts views |
| `test/models/mastodon_account_test.rb` | Test | URL parsing, validations, default display_count |
| `test/models/mastodon_client_test.rb` | Test | HTTP call contract with stubbed responses |
| `test/controllers/mastodon_accounts_controller_test.rb` | Test | CRUD actions, auth isolation |
| `features/mastodon_account.feature` | Cucumber | E2E: register account → welcome gadget appears |

---

## Modified Components

| File | Change |
|------|--------|
| `app/models/portal.rb` — `get_gadgets` | Add `MastodonAccount.where(user_id: user.id, deleted: false).each { |a| ret[a.gadget_id] = a }` block, mirroring the Feed loop at the bottom of `get_gadgets` |
| `config/routes.rb` | Add `resources :mastodon_accounts` |
| `config/locales/ja.yml` | Add `mastodon_accounts:` namespace |
| `config/locales/en.yml` | Add `mastodon_accounts:` namespace |

No changes required to `WelcomeController`, `ApplicationController`, or layout files. The portal machinery (`portal_column_section` partial + `Portal#get_gadgets`) already dispatches `render g.class.name.underscore, gadget: g` — adding `MastodonAccount` to `get_gadgets` is the only portal-level change needed.

---

## Data Model

### Table: `mastodon_accounts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | integer | PK | |
| `user_id` | integer | NOT NULL | FK to users; never in strong params |
| `name` | string | NOT NULL | User-supplied display label (like Feed#title) |
| `profile_url` | string | NOT NULL | Raw input: `https://mastodon.social/@alice` |
| `instance_host` | string | NOT NULL | Parsed from profile_url: `mastodon.social` |
| `username` | string | NOT NULL | Parsed from profile_url: `alice` |
| `display_count` | integer | NOT NULL, default: 5 | Max toots to show |
| `deleted` | boolean | NOT NULL, default: false | Soft-delete (matches Feed/Todo/Note pattern) |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

### Indexes

```ruby
add_index :mastodon_accounts, [:user_id, :deleted]
```

### Constraints / Validations (model layer)

- `validates :name, presence: true`
- `validates :profile_url, presence: true`
- `validates :instance_host, presence: true`
- `validates :username, presence: true`
- `validates :display_count, numericality: { greater_than: 0 }`
- `include Crud::ByUser` (provides `readable_by?`, `updatable_by?`, `deletable_by?`)

The `deleted` boolean (not `deleted_at` timestamp) matches every other soft-deleted model in this codebase (Feed, Todo, Note, Portal). Use `deleted: false` scope or `.not_deleted` — do not introduce `deleted_at`.

---

## API Client Design

### Decision: Separate service class (`MastodonClient`), not a model method

Feed uses private model methods (`retrieve_feed`, `base_url`, `request_path`, `request_params`) because the HTTP logic is tightly coupled to parsing the `feed_url` column. For Mastodon, the API interaction is a two-step operation (lookup by username to get numeric ID, then fetch statuses by that ID) and carries more error surface (rate limits, instance-level 404, JSON parsing vs Feedjira). Keeping it in a service class:

- Keeps `MastodonAccount` focused on persistence and gadget contract
- Makes the HTTP layer independently testable with stubbed responses
- Follows the same motivation as the Feed pattern but separates concerns more cleanly for a heavier API surface

### `MastodonClient` interface

```ruby
class MastodonClient
  class NetworkError < StandardError; end
  class AccountNotFound < StandardError; end
  class RateLimitError < StandardError; end
  class ApiError < StandardError
    attr_reader :status
    def initialize(msg, status: nil)
      super(msg)
      @status = status
    end
  end

  def initialize(instance_host)
    @instance_host = instance_host
    @base_url = "https://#{instance_host}"
  end

  # Step 1: GET /api/v1/accounts/lookup?acct=username => account_id
  # Step 2: GET /api/v1/accounts/:account_id/statuses?limit=N&exclude_replies=true&exclude_reblogs=true
  # Returns array of status hashes with :content, :url, :created_at
  def fetch_statuses(username, limit: 5)
    ...
  end
end
```

Use `Daddy::HttpClient` (already available, wraps Net::HTTP). Parse JSON with `JSON.parse`. Return plain Ruby hashes — no Feedjira-style parser objects needed.

### Mastodon public API endpoints used (HIGH confidence — official docs)

- `GET https://{instance}/api/v1/accounts/lookup?acct={username}` — no auth required; returns account JSON including `id`
- `GET https://{instance}/api/v1/accounts/{id}/statuses?limit=N&exclude_replies=true&exclude_reblogs=true` — public access; returns array of status JSON

Useful status fields: `url` (permalink), `content` (HTML), `created_at`.

### `MastodonAccount` model methods (gadget contract)

```ruby
def statuses
  return @statuses if defined?(@statuses)
  @statuses = fetch_statuses_safely
end

def gadget_id
  "mastodon_account_#{id}"
end

def visible?
  statuses.present?
end

def entries
  statuses.first(display_count)
end

private

def fetch_statuses_safely
  client = MastodonClient.new(instance_host)
  client.fetch_statuses(username, limit: display_count)
rescue => e
  Rails.logger.error "MastodonAccount##{id}: #{e.class} #{e.message}"
  []
end
```

The model memoizes `@statuses` (like Feed memoizes `@feed`) and swallows all errors to an empty array. This means `visible?` returns false on API failure and the gadget silently disappears — same behaviour as Feed when `feed?` is false. However, the XHR `.fail` path in the gadget partial still surfaces the error message to the user (see Error Handling section).

---

## Controller Pattern

`MastodonAccountsController` mirrors `FeedsController` exactly:

```
before_action :preload_mastodon_account, only: [:show, :edit, :update, :destroy]

index   => @accounts = MastodonAccount.where(user_id: current_user.id).not_deleted
show    => render layout: !request.xhr?   (same XHR pattern as FeedsController#show)
new     => @account = MastodonAccount.new
create  => save in conditional; redirect_to action: 'index' on success, render :new on failure
edit    => (preload_mastodon_account sets @account)
update  => save in conditional; redirect_to action: 'index' on success, render :edit on failure
destroy => destroy_logically! in transaction; redirect_to action: 'index'
```

### URL parsing: model `before_save` callback, not controller

Feed already sets defaults in `before_save :set_display_count`. URL parsing fits the same slot:

```ruby
before_save :parse_profile_url

def parse_profile_url
  return if profile_url.blank?
  uri = URI.parse(profile_url.strip)
  self.instance_host = uri.host
  self.username = uri.path.split('/').reject(&:blank?).last&.delete_prefix('@')
rescue URI::InvalidURIError
  errors.add(:profile_url, :invalid)
  throw :abort
end
```

Placing parse logic in the controller would require duplicating it for create and update, and would leave the model columns inconsistent if saved by any other path. `before_save` is the right place.

FeedsController uses `save!` with no rescue — this is acceptable for Feed because feed_url format is not validated server-side (the feed simply fails to load). For MastodonAccount, invalid URL format should produce a user-visible form error, so create/update must use `save` (not `save!`) and re-render the form on failure.

### Strong params

```ruby
def mastodon_account_params
  ret = params.require(:mastodon_account).permit(:name, :profile_url, :display_count)
  ret.merge!(user_id: current_user.id)
  ret
end
```

`instance_host` and `username` are never accepted from params — they are derived exclusively from `profile_url` in `before_save`. This prevents spoofing.

### `preload_mastodon_account`

```ruby
def preload_mastodon_account
  @account = MastodonAccount.find(params[:id])
  unless @account.readable_by?(current_user)
    head :not_found and return
  end
end
```

Identical pattern to `preload_feed`.

### Show action and XHR rendering

`show.html.erb` renders statuses as an `<ol>` with links (toot `url` + stripped `content`). The gadget partial issues `$.get(mastodon_account_path(gadget), {format: 'html'}, ...)` and injects the returned HTML, identical to `_feed.html.erb`. `render layout: !request.xhr?` in the show action suppresses the layout for XHR responses.

---

## Welcome Page Integration

### Gadget partial: `app/views/welcome/_mastodon_account.html.erb`

Mirrors `_feed.html.erb` directly:

```erb
<script>
  $(document).ready(function() {
    $.get('<%= mastodon_account_path(gadget) %>', {format: 'html'}, function(html) {
      $('#mastodon_account_<%= gadget.id %>').html(html);
    })
    .fail(function(xhr, status, error) {
      const container = $('#mastodon_account_<%= gadget.id %>');
      container.find('ol li span').first().text(container.data('fetchFailedMessage') + '(' + xhr.status + ')');
    });
  });
</script>

<div id="<%= gadget.gadget_id %>" class="gadget" data-fetch-failed-message="<%= t('.fetch_failed') %>">
  <div>
    <div class="title"><%= gadget.name %></div>
    <ol>
      <li>
        <span style="line-height: <%= gadget.display_count * 1.5 %>em;"><%= t('.loading') %></span>
      </li>
    </ol>
  </div>
</div>
```

### CSS class: same `.gadget` class, no new CSS required

All existing gadgets use `class="gadget"`. The existing `.gadget` rule in SCSS handles collapsibility and panel styling. Mastodon account gadgets use `class="gadget"` — no new CSS class required. If a Mastodon-specific visual treatment is ever needed, add `class="gadget mastodon"` as a later enhancement.

### Portal registration: `Portal#get_gadgets`

Add at the bottom of `get_gadgets`, after the Feed loop:

```ruby
MastodonAccount.where(user_id: user.id, deleted: false).each do |a|
  ret[a.gadget_id] = a
end
```

`portal_column_section` already calls `render g.class.name.underscore, gadget: g` which resolves `"mastodon_account"` to `welcome/_mastodon_account`. No other portal machinery changes needed.

### Why gadgets are always included (not gated by `visible?`)

`Portal#get_gadgets` includes Feed records unconditionally (all non-deleted feeds appear in the portal regardless of whether the feed is currently reachable). The same approach applies to MastodonAccount — the record is always registered as a gadget; the XHR failure message appears inside the panel if the API is down. This differs from `BookmarkGadget` and `TodoGadget` which gate on `visible?` because they represent preferences, not user-created records.

---

## Suggested Build Order

### Phase 1 — Data layer
- Migration: create `mastodon_accounts` table
- `MastodonAccount` model: columns, `Crud::ByUser`, `before_save :parse_profile_url`, `before_save :set_display_count`, validations, `gadget_id`
- Model tests: URL parsing (valid URL, `@`-prefixed username, missing `@`, invalid URL raises validation error), `gadget_id`, `set_display_count` default
- Locale keys: `activerecord.attributes.mastodon_account.*`

Rationale: everything downstream depends on the model. Parse logic here prevents duplication in controller.

### Phase 2 — CRUD controller + views (no API calls yet)
- `MastodonAccountsController`: index, new, create, edit, update, destroy (show deferred to Phase 3)
- Views: index, new, edit, `_form` partial
- Routes: `resources :mastodon_accounts`
- Controller tests: CRUD actions, ownership check (`readable_by?`), strong params excludes `instance_host`/`username`
- Locale keys: `mastodon_accounts.*` for all views
- Tri-suite green

Rationale: delivers a complete management UI before touching API or welcome page; phases are independently verifiable.

### Phase 3 — API client + show action
- `MastodonClient` service class with `fetch_statuses` and typed error classes
- `MastodonAccount#statuses`, `#entries`, `#visible?` using the client
- `MastodonAccountsController#show` with `render layout: !request.xhr?`
- `show.html.erb`
- Client tests with stubbed HTTP (network error, 404, 429, 200 with statuses)
- Controller test for show (XHR and full-page variants)

Rationale: API client is independently testable without the gadget. Show action proves the API contract before wiring to the welcome page.

### Phase 4 — Welcome page gadget
- `app/views/welcome/_mastodon_account.html.erb` partial
- `Portal#get_gadgets`: add MastodonAccount loop
- Welcome page locale keys for `.loading` and `.fetch_failed`
- Integration test: account registered → gadget appears on welcome page
- Cucumber E2E: register account → welcome page shows loading placeholder

Rationale: gadget integration is the last step; it depends on the show action existing and portal machinery recognizing the gadget_id format.

### Phase 5 — Test coverage and locale parity
- Ensure `ja.yml` / `en.yml` key parity (enforced by existing test contract)
- Minitest coverage sweep: any missed paths
- Cucumber: destroy scenario, edit scenario
- Tri-suite green gate before milestone close

---

## Error Handling

### API failures (network down, instance unreachable)

`MastodonAccount#fetch_statuses_safely` rescues all errors and returns `[]`. The show action returns 500:

```ruby
def show
  if @account.statuses.any?
    render layout: !request.xhr?
  else
    render plain: :internal_server_error, status: :internal_server_error
  end
end
```

The XHR `.fail` callback in the gadget partial writes the `data-fetch-failed-message` text (plus HTTP status code) into the placeholder span — identical to how Feed surfaced errors before the partial was introduced.

### Invalid profile URL (create/update form)

`before_save :parse_profile_url` calls `throw :abort` on `URI::InvalidURIError`, adding `errors.add(:profile_url, :invalid)`. Because create/update use `save` (not `save!`), the action re-renders the form with the validation error visible. This is the standard Rails form UX that FeedsController skips (it uses `save!`) — MastodonAccountsController does it correctly from the start.

### Rate limits (429 from Mastodon instance)

`MastodonClient` raises `MastodonClient::RateLimitError` on 429. `fetch_statuses_safely` rescues it to `[]`, logs the event. The gadget shows the fetch-failed message. No retry logic — public accounts with `display_count: 5` will not hit rate limits under normal personal-use volume.

### Account not found / moved (404 from lookup)

`fetch_statuses` raises `MastodonClient::AccountNotFound`, rescued to `[]`. The user sees the fetch-failed message in the gadget and can delete the account registration from `/mastodon_accounts`. No automatic cleanup — soft-delete only on explicit user action.

---

## Sources

- Mastodon accounts API — `GET /api/v1/accounts/lookup` and `GET /api/v1/accounts/:id/statuses` (HIGH confidence, official Mastodon documentation): https://docs.joinmastodon.org/methods/accounts/
- Feed pattern: direct code inspection of `app/models/feed.rb`, `app/controllers/feeds_controller.rb`, `app/views/welcome/_feed.html.erb`, `app/views/feeds/show.html.erb`
- Portal gadget dispatch: direct code inspection of `app/models/portal.rb`, `app/models/concerns/gadget.rb`, `app/views/welcome/_portal_column_section.html.erb`
- Soft-delete pattern: direct code inspection of `app/models/feed.rb`, `app/models/todo.rb`, `app/models/note.rb`, `app/models/crud/by_user.rb`
- Schema confirmation: direct inspection of `db/schema.rb`
