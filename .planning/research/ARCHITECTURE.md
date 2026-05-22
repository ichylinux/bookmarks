# Architecture Patterns: Admin Hard-Delete / Purge

**Domain:** Admin purge of soft-deleted user accounts in an existing Rails 8.1 app
**Researched:** 2026-05-22
**Confidence:** HIGH — all findings from direct codebase inspection

---

## Integration Points with Existing Infrastructure

### Admin::BaseController

- `Admin::BaseController < ApplicationController` with `before_action :require_admin`
- `require_admin` calls `head :not_found` (not 403) when `!current_user&.admin?`
- New `Admin::UsersController#destroy` and `#confirm_purge` inherit this gate for free — no new access control code needed
- Unauthenticated requests redirect to sign-in via Devise (ApplicationController)

### Admin::UsersController (existing)

- Currently has only `#index` with `User.all.includes(:x_accounts).order(:id)`
- The purge actions extend this same controller — no new controller class required
- Route currently: `namespace :admin do; resources :users, only: [:index]; end`
- Change: extend `only:` to add `:destroy` and add a `member { get :confirm_purge }` action

### User Model (existing)

- Has `deleted boolean NOT NULL DEFAULT false` and `deleted_at datetime` columns from v1.28
- `destroy_account!` is the soft-delete method: sets `deleted: true`, `deleted_at: now` via `update_columns`
- **Critically, most associations on User intentionally have NO `dependent:` clause.** The comment in `user.rb` is explicit:
  > "No dependent: :destroy — disabling an account is the normal lifecycle; a rare hard-delete of User must not synchronously load/destroy unbounded notes"
- This was the v1.28 design decision anticipating the future purge milestone

**Exceptions already declared on User:**

| Association | dependent: | Effect on `user.destroy` |
|-------------|-----------|--------------------------|
| `has_many :x_accounts` | `:destroy` | Fires XAccount destroy callbacks one-by-one |
| `has_many :x_api_calls` | `:delete_all` | Single SQL DELETE, no callbacks |
| `has_one :preference` | none | Orphaned on `user.destroy` without explicit handling |
| `has_many :notes` | none | Orphaned (explicit design decision) |
| `has_many :portals` | none | Orphaned |

### Associations Requiring Explicit Deletion in Purge

All tables confirmed via schema.rb to have `user_id` columns:

| Table | Model | `dependent:` on User | Purge strategy |
|-------|-------|-----------------------|----------------|
| `notes` | `Note` | none (explicit comment) | `delete_all` before `destroy!` |
| `bookmarks` | `Bookmark` | none | `delete_all` before `destroy!` |
| `todos` | `Todo` | none | `delete_all` before `destroy!` |
| `feeds` | `Feed` | none | `delete_all` before `destroy!` |
| `mastodon_accounts` | `MastodonAccount` | none | `delete_all` before `destroy!` |
| `x_accounts` | `XAccount` | `:destroy` | `delete_all` before `destroy!` (faster; avoids N+1 callbacks) |
| `x_api_calls` | `XApiCall` | `:delete_all` | `delete_all` before `destroy!` (redundant but explicit) |
| `visited_links` | `VisitedLink` | none | `delete_all` before `destroy!` |
| `portal_layouts` | `PortalLayout` | none (no `belongs_to :user` in model, but `user_id` column exists in schema) | `delete_all` before `destroy!` |
| `portals` | `Portal` | none | `delete_all` before `destroy!` |
| `preferences` | `Preference` | none (`has_one` with no `dependent:`) | `delete_all` before `destroy!` |

`PortalLayout` has no model association from User but does have `user_id` in the DB. Must be explicitly deleted; it will not be caught by `dependent:` callbacks.

---

## Recommended Architecture

### Where Purge Logic Lives: `User#purge!` Instance Method

**Decision: `User#purge!` on the User model. Not a service object.**

Rationale:
- Consistent with `destroy_account!` — both are lifecycle operations on `User`
- `Admin::UsersController#destroy` stays thin: find user, call `user.purge!`, redirect with flash
- No service object infrastructure exists in this codebase; `app/services/` contains only HTTP clients (`XClient`, `MastodonClient`). Introducing a service object for this single operation adds an unfamiliar pattern without benefit
- `User#purge!` wraps everything in a transaction; any raised exception rolls back the entire deletion

### `User#purge!` Implementation Pattern

```ruby
def purge!
  raise "Cannot purge active account" unless purgeable?

  transaction do
    Note.where(user_id: id).delete_all
    Bookmark.where(user_id: id).delete_all
    Todo.where(user_id: id).delete_all
    Feed.where(user_id: id).delete_all
    MastodonAccount.where(user_id: id).delete_all
    VisitedLink.where(user_id: id).delete_all
    PortalLayout.where(user_id: id).delete_all
    Portal.where(user_id: id).delete_all
    Preference.where(user_id: id).delete_all
    XAccount.where(user_id: id).delete_all
    XApiCall.where(user_id: id).delete_all
    destroy!
  end
end
```

**Why `delete_all` and not `destroy_all`:** No callbacks are needed on associated records during admin hard-delete. `delete_all` is a single SQL DELETE per table, regardless of row count. `destroy_all` would load every record into Ruby and fire callbacks — unnecessary overhead for a purge operation.

**Why explicit ordering:** Child tables must be cleared before the parent `users` row is removed. Even without enforced FK constraints (MySQL is configured without them here), explicit ordering makes the transaction's intent clear and guards against future constraint additions.

**Why `destroy!` (not `delete`) on the user row itself:** After all associations are cleared, the `dependent:` callbacks on `x_accounts` and `x_api_calls` will be no-ops (nothing left to delete). `destroy!` raises `ActiveRecord::RecordNotDestroyed` on failure, ensuring the transaction rolls back correctly. `delete` bypasses callbacks entirely and returns a count, making failure detection harder.

### `User#purgeable?` Eligibility Predicate

```ruby
def purgeable?
  deleted? && deleted_at.present? && deleted_at <= 90.days.ago
end
```

- Enforced at model level (guard in `purge!`)
- Enforced at controller level (redirect with alert if not purgeable)
- Enforced at view level (button only rendered when `purgeable?`)

Three layers of enforcement for an irreversible destructive action.

---

## Route and Controller Action

### Route Change

```ruby
namespace :admin do
  resources :users, only: [:index, :destroy] do
    member do
      get :confirm_purge
    end
  end
end
```

- `DELETE /admin/users/:id` → `Admin::UsersController#destroy`
- `GET /admin/users/:id/confirm_purge` → `Admin::UsersController#confirm_purge`
- Route helpers: `admin_user_path(user)` (for DELETE), `confirm_purge_admin_user_path(user)` (for GET)

Using `:destroy` is semantically correct for hard-delete. The existing `resources :users` declaration is extended with `only:` and a member block, not replaced.

### Controller Actions

```ruby
module Admin
  class UsersController < BaseController
    def index
      @users = User.all.includes(:x_accounts).order(:id)
    end

    def confirm_purge
      @user = User.find(params[:id])
      head :not_found unless @user.purgeable?
    end

    def destroy
      @user = User.find(params[:id])

      unless @user.purgeable?
        redirect_to admin_users_path, alert: t('.not_purgeable')
        return
      end

      email = @user.email
      @user.purge!
      redirect_to admin_users_path, notice: t('.purged', email: email)
    rescue => e
      redirect_to admin_users_path, alert: t('.purge_failed')
    end
  end
end
```

`email` is captured before `purge!` because the user row will not exist after `destroy!`. The `rescue` is intentionally broad at the controller level — transaction failure or unexpected error surfaces as a flash alert rather than a 500 page.

---

## Confirm Flow Without JS (Server-Rendered)

**Two-step server-rendered flow, no JS required.**

The direct precedent is `Users::AccountDeletionsController` (v1.28):
- `GET /account_deletion/new` renders a dedicated confirmation page
- Page shows a warning and a form that submits `DELETE /account_deletion`
- Uses `form_tag ... method: :delete, data: { turbo: false }`
- No JavaScript confirmation dialog

For admin purge, the same pattern applies with one difference: no typed token ("DELETE") is required. The admin is authenticated via `require_admin`; the two-page flow (list → confirm → execute) provides sufficient friction for a deliberate irreversible action.

### `confirm_purge.html.erb` structure

```erb
<%# Shows: user id, email, deleted_at, warning text %>
<%# Form submits DELETE /admin/users/:id %>
<%= form_tag admin_user_path(@user), method: :delete,
      data: { turbo: false }, class: 'admin-purge-form' do %>
  <%= submit_tag t('.submit'), class: 'admin-purge-form__submit' %>
  <%= link_to t('.cancel'), admin_users_path %>
<% end %>
```

`data: { turbo: false }` is established by the account deletion view — required to prevent Turbo from intercepting the DELETE form submission. Consistent with the existing pattern.

### Why not a JavaScript `data-confirm` dialog

The codebase philosophy is server-rendered with no new JS for destructive flows. The `@account_deletion` Cucumber hook explicitly uses `:rack_test` driver because Selenium-based DELETE form submissions were unreliable. A dedicated server-rendered confirmation page is consistent, reliable in tests, and requires no JS.

---

## Component Inventory

### New Components

| Component | File | Purpose |
|-----------|------|---------|
| `User#purge!` | `app/models/user.rb` | Transactional hard-delete of user + all associated records |
| `User#purgeable?` | `app/models/user.rb` | Eligibility predicate (`deleted? && deleted_at <= 90.days.ago`) |
| `Admin::UsersController#destroy` | `app/controllers/admin/users_controller.rb` | DELETE action; calls `user.purge!`, redirects with flash |
| `Admin::UsersController#confirm_purge` | `app/controllers/admin/users_controller.rb` | GET; renders confirmation page for eligible accounts |
| `confirm_purge.html.erb` | `app/views/admin/users/confirm_purge.html.erb` | Confirmation page with user details and DELETE form |
| Locale keys (ja/en) | `config/locales/ja.yml`, `config/locales/en.yml` | All new `admin.users.*` keys for purge UI and flash messages |
| Cucumber feature | `features/12.管理者パージ.feature` | E2E scenario for admin purge flow |
| Cucumber step definitions | `features/step_definitions/admin_purge.rb` | Steps for purge scenario |

### Modified Components

| Component | File | Change |
|-----------|------|--------|
| `Admin::UsersController` | `app/controllers/admin/users_controller.rb` | Add `destroy` and `confirm_purge` actions |
| `User` model | `app/models/user.rb` | Add `purge!` method and `purgeable?` predicate |
| Routes | `config/routes.rb` | Extend `resources :users` with `:destroy` + `member { get :confirm_purge }` |
| Admin users index view | `app/views/admin/users/index.html.erb` | Add actions column; conditional purge button for `purgeable?` users |
| Locale files | `config/locales/ja.yml`, `config/locales/en.yml` | New keys under `admin.users.{destroy,confirm_purge,index}` |
| i18n parity test | `test/i18n/admin_users_i18n_test.rb` | Assert all new keys present in both locales |
| Cucumber hooks | `features/support/hooks.rb` | Add `@admin_purge` Before/After hooks |
| Admin users CSS | `app/assets/stylesheets/admin_users.css.scss` | Danger-style purge button styling |

---

## Build Order (with Dependencies)

### Phase 1: Model Layer

**Files:** `app/models/user.rb`

Build `User#purgeable?` and `User#purge!` first. All other phases depend on these methods existing.

Minitest coverage for this phase:
- `purgeable?` returns false for active (non-deleted) user
- `purgeable?` returns false for user deleted less than 90 days ago
- `purgeable?` returns false for user deleted exactly 89 days ago (boundary)
- `purgeable?` returns true for user deleted exactly 90 days ago and beyond
- `purge!` raises when user is not purgeable
- `purge!` removes user row
- `purge!` removes all associated rows (note, bookmark, todo, feed, mastodon_account, x_account, x_api_call, visited_link, portal, portal_layout, preference)
- `purge!` is transactional: stub one `delete_all` to raise, assert the user row still exists after the rescue

No new migrations. All required columns (`deleted`, `deleted_at`) already exist from v1.28.

### Phase 2: Routes + Controller

**Files:** `config/routes.rb`, `app/controllers/admin/users_controller.rb`

Depends on Phase 1 (`purgeable?` must exist for controller guard logic).

Minitest coverage (mirrors existing access control pattern from `test/controllers/admin/users_controller_test.rb`):
- Unauthenticated `DELETE /admin/users/:id` → redirect to sign-in
- Non-admin `DELETE /admin/users/:id` → 404
- Admin `DELETE` on non-purgeable (active) user → redirect to index with alert
- Admin `DELETE` on purgeable user → redirect to index with notice; user row destroyed
- Unauthenticated `GET confirm_purge` → redirect to sign-in
- Non-admin `GET confirm_purge` → 404
- Admin `GET confirm_purge` on non-purgeable user → 404
- Admin `GET confirm_purge` on purgeable user → 200

### Phase 3: Views + Locale

**Files:** `app/views/admin/users/index.html.erb`, `app/views/admin/users/confirm_purge.html.erb`, `config/locales/ja.yml`, `config/locales/en.yml`, `app/assets/stylesheets/admin_users.css.scss`

Depends on Phase 2 (route helpers `confirm_purge_admin_user_path` and `admin_user_path` must exist for view helpers to work).

Locale keys to add (both `ja.yml` and `en.yml`):
- `admin.users.index.col_actions`
- `admin.users.index.purge_button`
- `admin.users.destroy.purged` (with `%{email}` interpolation)
- `admin.users.destroy.not_purgeable`
- `admin.users.destroy.purge_failed`
- `admin.users.confirm_purge.title`
- `admin.users.confirm_purge.warning`
- `admin.users.confirm_purge.submit`
- `admin.users.confirm_purge.cancel`

Update i18n parity test to cover all new keys.

### Phase 4: Cucumber E2E + Tri-Suite Gate

**Files:** `features/12.管理者パージ.feature`, `features/step_definitions/admin_purge.rb`, `features/support/hooks.rb`

Depends on all prior phases.

Hook `@admin_purge` in `hooks.rb`:
- `Before`: create a purgeable test user (`deleted: true`, `deleted_at: 91.days.ago`), note their id
- `After`: destroy the test user if still present (cleanup guard)

Driver note: the admin purge flow does NOT require `:rack_test`. It uses a standard GET (confirm page) followed by a form POST/DELETE with `data: { turbo: false }` — Selenium handles this cleanly. Only use `:rack_test` if Selenium proves unreliable during implementation.

Scenarios:
1. Admin can purge an eligible soft-deleted account: navigate to admin users list → purge button visible for eligible user → click → confirmation page shows user details → submit → redirected to list with notice → user no longer in list
2. Purge button does not appear for non-eligible accounts (active or recently deleted)

---

## Edge Cases and Risks

| Concern | Risk | Mitigation |
|---------|------|------------|
| Purging an active account | HIGH (irreversible) | Three-layer guard: `purgeable?` in model raises, controller redirects, view button hidden |
| `portal_layouts` orphans | MEDIUM (no `User` has_many) | Explicit `PortalLayout.where(user_id: id).delete_all` in `purge!` |
| `preferences` orphan (has_one, no dependent:) | LOW | Explicit `Preference.where(user_id: id).delete_all` in `purge!` |
| Large data sets (many notes/bookmarks) | LOW for this personal app | `delete_all` is single SQL statement; acceptable at this scale |
| Concurrent purge of same user | VERY LOW (single admin) | Transaction + `destroy!` raises if row already gone |
| `x_accounts dependent: :destroy` double-fire | NONE | Explicit `XAccount.delete_all` before `destroy!` leaves no rows for the callback to process |
| Email captured before destroy | REQUIRED | `email = @user.email` in controller before calling `purge!`; user row will not exist after |

---

## Sources

All findings from direct codebase inspection:
- `/home/ichy/workspace/bookmarks/app/controllers/admin/base_controller.rb`
- `/home/ichy/workspace/bookmarks/app/controllers/admin/users_controller.rb`
- `/home/ichy/workspace/bookmarks/app/controllers/users/account_deletions_controller.rb`
- `/home/ichy/workspace/bookmarks/app/models/user.rb`
- `/home/ichy/workspace/bookmarks/app/models/preference.rb`
- `/home/ichy/workspace/bookmarks/app/models/portal.rb`
- `/home/ichy/workspace/bookmarks/app/models/portal_layout.rb`
- `/home/ichy/workspace/bookmarks/db/schema.rb`
- `/home/ichy/workspace/bookmarks/config/routes.rb`
- `/home/ichy/workspace/bookmarks/app/views/admin/users/index.html.erb`
- `/home/ichy/workspace/bookmarks/app/views/users/account_deletions/new.html.erb`
- `/home/ichy/workspace/bookmarks/features/support/hooks.rb`
- `/home/ichy/workspace/bookmarks/test/controllers/admin/users_controller_test.rb`
- `/home/ichy/workspace/bookmarks/.planning/PROJECT.md`
