# Domain Pitfalls: v1.32 Admin Account Purge

**Domain:** Adding admin hard-delete/purge to an existing Rails app with soft-delete
**Researched:** 2026-05-22
**Scope:** Pitfalls specific to adding `DELETE /admin/users/:id/purge` to a system that already has
soft-delete (`users.deleted`/`users.deleted_at`), Devise authentication, an existing admin gate
(`Admin::BaseController#require_admin`), and multiple association tables without `dependent:` on most.

---

## Critical Pitfalls

### Pitfall 1: Purge action has no soft-delete guard — active users can be hard-deleted

**Risk level:** CRITICAL

**What goes wrong:**
`Admin::UsersController#purge` calls `user.destroy` (or a purge method) on the user found by
`params[:id]`. The route is reachable by any admin. If the view only shows a Purge button for
soft-deleted users, the route itself is unguarded — a direct HTTP `DELETE` request from curl or
a browser can purge any user, including currently active ones.

**Why it happens:**
Developers build the view guard (button only visible for `deleted? && old enough`) but skip the
server-side guard, trusting UI flow. Rails never enforces UI assumptions server-side.

**Consequences:**
Hard-deletion of an active user: all their bookmarks, notes, todos, feeds, mastodon_accounts,
x_accounts, portal_layouts, preferences, and visited_links are destroyed. This is
unrecoverable — soft-delete is gone, there is no recycle bin.

**Prevention:**
The purge action MUST validate both conditions at the model/controller level before destroying:

```ruby
def purge
  @user = User.find(params[:id])
  unless @user.deleted? && @user.deleted_at <= 90.days.ago
    head :not_found and return
  end
  # proceed with purge
end
```

Extract this as a model method `User#purgeable?` so it is testable in isolation and the controller
simply gates on it.

**Detection:**
Minitest: issue `DELETE admin_user_purge_path(active_user)` as an admin; assert `404` and that
the user row still exists. Issue `DELETE admin_user_purge_path(recently_deleted_user)` (deleted
< 90 days ago); assert `404`.

**Phase:** Phase 1 — model guard + controller. Write the eligibility test before the happy path.

---

### Pitfall 2: Association deletion order causes foreign-key violations or silent data orphans

**Risk level:** CRITICAL

**What goes wrong:**
MySQL with `InnoDB` enforces foreign-key constraints. Destroying the `users` row before deleting
child rows that have a `NOT NULL user_id` column raises `Mysql2::Error: Cannot delete or update a
parent row`. Conversely, destroying children before MySQL is aware of the parent deletion order
can cause phantom constraint violations on rows that reference intermediate tables.

In this codebase the concern is different: **most association tables have no `dependent:` clause
on `User`**. The only declared ones are:

| Association | Current declaration |
|-------------|---------------------|
| `x_api_calls` | `dependent: :delete_all` |
| `x_accounts` | `dependent: :destroy` |
| `preference` | no `dependent:` |
| `notes` | no `dependent:` |
| `portals` (via scoped has_many) | no `dependent:` |
| `portal_layouts` | no association on User at all |
| `bookmarks` | no `dependent:` |
| `todos` | no `dependent:` |
| `feeds` | no `dependent:` |
| `mastodon_accounts` | no `dependent:` |
| `visited_links` | no `dependent:` |

`portal_layouts` has no has_many on User at all — it will be orphaned silently if not explicitly
deleted.

**Why it happens:**
The existing comment in `user.rb` deliberately avoids `dependent: :destroy` to prevent
synchronous load-and-destroy of unbounded rows during the normal soft-delete lifecycle.
Hard-delete via a purge path has to handle this explicitly.

**Consequences:**
If `user.destroy` is called without removing children first, one of two things happens:
1. MySQL raises a FK error and the user row is not deleted (transaction rolled back); nothing is purged.
2. MySQL has no FK constraints defined (InnoDB may not have explicit FK DDL if Rails schema uses `add_foreign_key` — check schema.rb) and child rows become orphaned, consuming space and appearing in queries that do not filter by user existence.

Inspecting `db/schema.rb`: there are no `add_foreign_key` calls, so MySQL will not raise a FK
constraint error. However, orphaned rows accumulate in every table.

**Prevention:**
Implement a `User#purge_account!` method that explicitly deletes every child table in the correct
order inside a transaction, then destroys the user:

```ruby
def purge_account!
  raise "User is not eligible for purge" unless purgeable?

  transaction do
    # delete_all: no callbacks needed, efficient bulk delete
    PortalLayout.where(user_id: id).delete_all
    Bookmark.where(user_id: id).delete_all
    Note.where(user_id: id).delete_all
    Todo.where(user_id: id).delete_all
    Feed.where(user_id: id).delete_all
    MastodonAccount.where(user_id: id).delete_all
    VisitedLink.where(user_id: id).delete_all
    # x_accounts has dependent: :destroy on User already, but be explicit:
    XAccount.where(user_id: id).delete_all
    XApiCall.where(user_id: id).delete_all
    preference&.delete  # has_one, may not exist (unsaved default)
    # Portals have no dependent: declared — delete explicitly
    Portal.where(user_id: id).delete_all

    destroy!
  end
end
```

Use `delete_all` (not `destroy_all`) for child tables: no callbacks are needed, and it avoids
loading thousands of objects into memory.

**Detection:**
Minitest: create a user with at least one row in every associated table, call `purge_account!`,
and assert each table has zero rows for that `user_id`, and that the `users` row is gone.

**Phase:** Phase 1 — model. Must be fully covered before controller work starts.

---

### Pitfall 3: 90-day eligibility check is bypassed because `deleted_at` is nil

**Risk level:** CRITICAL

**What goes wrong:**
`User#destroy_account!` sets `deleted: true, deleted_at: Time.current`. But the column is nullable
(`deleted_at datetime` with no `NOT NULL`). An account that was soft-deleted before the v1.28
migration added `deleted_at` — or by a direct DB write that skips `destroy_account!` — can have
`deleted: true, deleted_at: nil`. The eligibility check `deleted_at <= 90.days.ago` raises
`NoMethodError` on nil, or worse, the nil comparison returns false in Ruby (`nil <= anything`
raises `ArgumentError`), causing a 500.

**Why it happens:**
The v1.28 migration added `deleted_at` but did not backfill historical soft-deleted rows. Any
integration test that directly calls `update_columns(deleted: true)` without setting `deleted_at`
(the pattern used in `test_削除済みユーザーも一覧に表示される`) produces this state.

**Consequences:**
- `purgeable?` raises `NoMethodError` or `ArgumentError` on nil-`deleted_at` users.
- In the worst case, `deleted_at.nil?` comparisons are treated as truthy and the user is purged when
  they should not be.

**Prevention:**
`User#purgeable?` must guard explicitly:

```ruby
def purgeable?
  deleted? && deleted_at.present? && deleted_at <= 90.days.ago
end
```

Also: the existing `test_削除済みユーザーも一覧に表示される` test creates a user with
`update_columns(deleted: true, deleted_at: Time.current)` — always ensure test setup for
soft-deleted users includes `deleted_at`. Document this in the test helper.

**Detection:**
Minitest: call `purgeable?` on a user with `deleted: true, deleted_at: nil`; assert it returns
`false`, not raises.

**Phase:** Phase 1 — model. Part of `User#purgeable?` unit tests.

---

## Moderate Pitfalls

### Pitfall 4: CSRF protection absent on the purge action

**Risk level:** HIGH

**What goes wrong:**
`DELETE /admin/users/:id/purge` is a destructive action. If it is wired to a link tag (`link_to`
with `method: :delete`) or a plain HTML link that relies on Rails UJS for the DELETE verb, the
CSRF token is not embedded in a form — it relies on the UJS adapter injecting it via Ajax headers.
If Turbo (Rails 7+) or an older UJS pattern sends the request without a CSRF token, Rails raises
`ActionController::InvalidAuthenticityToken`.

More dangerous: if CSRF verification is skipped on the admin controller (a mistake developers
make when UJS doesn't work and they "just want it to work"), the action becomes vulnerable to
cross-site request forgery by any authenticated admin.

**Why it happens:**
This codebase uses Rails UJS (not Turbo), and the existing admin actions are read-only (`GET`).
The first destructive admin action is new territory. Developers may use `link_to ... method: :delete`
assuming UJS handles it, without verifying CSRF token flow.

**Prevention:**
Use a proper `form_with` with `method: :delete` for the purge action, not a link tag.
This embeds an `authenticity_token` input in the form and guarantees CSRF protection.

```erb
<%= form_with url: purge_admin_user_path(@user), method: :delete do |f| %>
  <%= f.submit t('admin.users.purge.confirm_button') %>
<% end %>
```

Never add `protect_from_forgery except: [:purge]` or similar.

**Detection:**
Minitest integration test: issue `delete purge_admin_user_path(user)` without a CSRF token; assert
Rails rejects it. This is automatic — `ActionDispatch::IntegrationTest` includes CSRF tokens by
default in Rails 7+.

**Phase:** Phase 2 — controller + view. Wire the confirmation form with `form_with`.

---

### Pitfall 5: `portal_layouts` orphaned — no association declared on User, no dependent:

**Risk level:** HIGH

**What goes wrong:**
`portal_layouts` has `user_id integer NOT NULL` but `User` has no `has_many :portal_layouts`
declaration. There is no `dependent:` and no automatic cleanup. After purging a user, every
`portal_layouts` row for that user remains. These rows are not visible to any UI but accumulate
indefinitely.

**Why it happens:**
`portal_layouts` rows are managed exclusively through `Portal#update_layout` which
`PortalLayout.where(user_id: ...).each(&:destroy)` in-band. The User model has no direct
awareness of them.

**Consequences:**
Orphaned `portal_layouts` rows are invisible to users but pollute the table. More practically,
they will be included in aggregate DB size estimates and may cause confusion if the table is
ever queried by `user_id` in a report.

**Prevention:**
In `User#purge_account!`, explicitly include `PortalLayout.where(user_id: id).delete_all`.
Do not rely on `Portal`'s cascade — portals themselves must also be deleted.

**Detection:**
Minitest: create a portal and layout for a user, run purge, assert
`PortalLayout.where(user_id: user.id).count == 0` and `Portal.where(user_id: user.id).count == 0`.

**Phase:** Phase 1 — model, in the comprehensive association-coverage test.

---

### Pitfall 6: `Preference` is a `has_one` with possible unsaved default — `delete` vs `destroy`

**Risk level:** MEDIUM

**What goes wrong:**
`User#preference` overrides the ActiveRecord reader: if no DB row exists, it returns
`Preference.default_preference(user)` — an unsaved in-memory object. Calling `user.preference.destroy`
on a user whose preference was never persisted raises `ActiveRecord::RecordNotSaved`
("Cannot destroy a new record"). Calling `user.preference.delete` on an unsaved object is a no-op
but does not raise.

**Why it happens:**
The override is specific to this app (documented in ARCHITECTURE.md anti-patterns). Developers
who call `user.preference.destroy` in `purge_account!` without awareness of the override will
hit this.

**Prevention:**
In `purge_account!`, delete preference directly via SQL to avoid the override:

```ruby
Preference.where(user_id: id).delete_all
```

This is safe even if no preference row exists (deletes 0 rows cleanly).

**Detection:**
Minitest: call `purge_account!` on a user who has no persisted preference row; assert no exception
is raised and the user is destroyed.

**Phase:** Phase 1 — model.

---

### Pitfall 7: Race condition between two admin requests purging the same user

**Risk level:** MEDIUM

**What goes wrong:**
Two admin sessions submit the purge form for the same user simultaneously. Both requests pass the
`purgeable?` check (user is still there at check time). The first request destroys the user. The
second request's `User.find(params[:id])` raises `ActiveRecord::RecordNotFound` (or a MySQL FK
error if children are being deleted in parallel), resulting in an unrescued 500.

**Why it happens:**
`purgeable?` and `purge_account!` are not atomic. There is a TOCTOU (time-of-check/time-of-use)
window.

**Consequences:**
In practice, this is a personal app with one or very few admins and a small user base — a true
concurrent purge is astronomically unlikely. But the unrescued `RecordNotFound` causes a 500 page
rather than a clean redirect.

**Prevention:**
Wrap the purge in a rescue or use `find_by` instead of `find` in the controller, returning 404
gracefully if the record is already gone:

```ruby
@user = User.find_by(id: params[:id])
return head :not_found unless @user&.purgeable?
@user.purge_account!
```

If the user was already destroyed between the find and purge, `purge_account!` raises
`ActiveRecord::RecordNotFound` on `destroy!` — rescue it and redirect with a "already purged"
message.

**Detection:**
Minitest: test the `find_by` returns nil scenario gracefully (assert 404, not 500). True
concurrent test is not needed — the failure mode is the `RecordNotFound` path.

**Phase:** Phase 2 — controller.

---

### Pitfall 8: Cucumber test isolation — purged user fixture is referenced by other scenarios

**Risk level:** MEDIUM

**What goes wrong:**
Cucumber scenarios share DB state via explicit `Before`/`After` hooks rather than database_cleaner
transactions. The admin purge scenario creates or uses `user3` (fixture id: 3) to demonstrate
a soft-deleted user being purged. If the scenario's `After` hook does not recreate the user
fixture row (and all associated rows), subsequent scenarios that rely on `user3` (e.g.,
`@account_deletion` which explicitly restores user3) will fail because the row no longer exists.

**Why it happens:**
Hard-delete is irreversible at the DB level. The `@account_deletion` hook calls
`User.find(3).update_columns(...)` — if user3 was hard-deleted by the purge scenario, this raises
`ActiveRecord::RecordNotFound`.

**Consequences:**
Scenario-order-dependent failures, specifically in the `@account_deletion` tag scenarios. This
is the same class of cross-scenario state leakage that was fixed in `bce47df` (noted in CLAUDE.md).

**Prevention:**
The Cucumber purge scenario must NOT purge fixture users (id: 1, 2, 3, or `twitter_user`). Create
a fresh, non-fixture user in the `Before` hook and purge that user. The `After` hook deletes or
ignores it (it was hard-deleted by the scenario).

```ruby
Before('@admin_purge') do
  @purge_target = User.create!(
    email: 'purge_target@example.com',
    password: 'testtest123',
    otp_secret: User.generate_otp_secret,
    deleted: true,
    deleted_at: 91.days.ago
  )
end

After('@admin_purge') do
  # purge_target was hard-deleted by the scenario — nothing to clean up
  # But guard in case the scenario failed before purging:
  User.where(email: 'purge_target@example.com').delete_all
end
```

**Detection:**
Run `bundle exec rake dad:test` twice in sequence. If purge scenario uses a fixture user, the
second run will fail with `RecordNotFound` or a missing user error.

**Phase:** Phase 3 — Cucumber E2E. Non-fixture user creation in Before hook is mandatory.

---

### Pitfall 9: Minitest `ensure` cleanup for dynamically-created users must use `delete_all`, not `destroy`

**Risk level:** MEDIUM

**What goes wrong:**
Several existing admin controller tests create users dynamically and clean up in `ensure` blocks
using `u.destroy`. After the purge feature is added, a test that creates a purgeable user and
calls `purge_account!` on it has already hard-deleted the row by the time the `ensure` block
runs. `u.destroy` raises `ActiveRecord::RecordNotFound` or `ActiveRecord::StaleObjectError`
because the record is gone.

**Why it happens:**
The pattern `u.destroy` in `ensure` assumes the object is still persisted. Hard-delete via
`purge_account!` removes it from the DB. The in-memory `u` object still exists but its DB row
does not.

**Prevention:**
In `ensure` blocks that follow a purge operation, use:

```ruby
ensure
  User.where(id: @user.id).delete_all  # no-op if already purged; safe
```

Never `u.destroy` after a purge test.

**Detection:**
Run the purge test with `ensure u.destroy` in place — it will raise `ActiveRecord::RecordNotFound`
or silently succeed (because destroy on a gone record returns false in some Rails versions).
Use `User.where(id: ...).delete_all` throughout purge-related tests.

**Phase:** Phase 2 — Minitest coverage.

---

## Minor Pitfalls

### Pitfall 10: Flash messages and bilingual locale for purge action

**Risk level:** LOW

**What goes wrong:**
The purge action adds at least three locale key cases: success, ineligible, and not-found. Developers
add only the `ja` keys and forget `en`, breaking the i18n parity test that exists at
`test/i18n/admin_users_i18n_test.rb` (or wherever the parity test lives). The tri-suite gate
will fail at Minitest with a key-not-found error on the `en` locale path.

**Prevention:**
Add both `ja.admin.users.purge.*` and `en.admin.users.purge.*` locale keys simultaneously.
Run the existing i18n parity test after every locale file change (`bin/rails test test/i18n/`).

**Phase:** Phase 2 — locale keys. Zero extra effort if both files are edited together.

---

### Pitfall 11: Confirmation step — using GET instead of a two-step POST/DELETE flow

**Risk level:** LOW

**What goes wrong:**
The confirmation UI is implemented as a GET page (`/admin/users/:id/purge/confirm`) that renders
"Are you sure?" with a button. The button submits a POST to a `/confirm` route which then calls
`purge_account!`. This two-step flow works but the `confirm` route name conflicts with Rails
reserved helpers in some older setups, and the extra route adds surface area.

Alternatively, developers implement the confirmation step as a JavaScript `confirm()` dialog on
the purge form button. This is simpler but bypasses the server-side review step and is not
accessible.

**Prevention:**
Use a single `DELETE /admin/users/:id` route with a confirmation form (a modal or a separate
confirmation view). The form's submit button is the only entry point. Do not add a separate
`/confirm` GET route. Do not rely on JS `confirm()`.

The v1.28 precedent (`AccountDeletionsController`) uses a two-page flow: `GET /account_deletion/new`
renders the form, `DELETE /account_deletion` performs the action. Mirror this pattern for the admin
purge: a confirmation view (GET) and a purge action (DELETE).

**Phase:** Phase 2 — routing + view.

---

### Pitfall 12: `x_accounts` has `dependent: :destroy` — callbacks fire during purge

**Risk level:** LOW

**What goes wrong:**
`has_many :x_accounts, dependent: :destroy` on User means that when `user.destroy!` is called
(at the end of `purge_account!`), Rails will load all `x_accounts` rows and call `destroy` on each,
firing any callbacks on `XAccount`. Currently `XAccount` has a `before_save :set_display_count_default`
which only fires on save — not on destroy. But if a `before_destroy` or `after_destroy` is added to
`XAccount` in the future, the purge path will trigger it unexpectedly.

More immediately: `dependent: :destroy` loads all `XAccount` rows into memory to call `destroy`
on each. For a user with 50 x_accounts, this is 50 `SELECT` queries plus 50 `DELETE` statements.

**Prevention:**
In `purge_account!`, delete `XAccount` rows with `XAccount.where(user_id: id).delete_all` **before**
calling `destroy!` on the user. Because the rows are already gone, the `dependent: :destroy`
cascade on `user.destroy!` finds no rows to process. This skips callbacks, uses one query, and
prevents the N+1 pattern.

**Phase:** Phase 1 — model. The comprehensive `purge_account!` implementation should delete
all associations explicitly before the final `destroy!`.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Phase 1 — `User#purgeable?` + `purge_account!` model method | Pitfalls 1, 3 (nil deleted_at guard), 6 (preference override) | Write eligibility guard first; use `Preference.where(user_id:).delete_all`; explicit `PortalLayout.where(user_id:).delete_all` |
| Phase 1 — association-coverage Minitest | Pitfalls 2, 5 (portal_layouts orphan) | Assert every table has zero rows for purged user_id after calling `purge_account!` |
| Phase 2 — controller action | Pitfalls 1 (server-side guard), 4 (CSRF), 7 (race condition / RecordNotFound) | `find_by` not `find`; server-side `purgeable?` check; `form_with method: :delete` for purge button |
| Phase 2 — Minitest controller tests | Pitfall 9 (ensure cleanup) | Use `User.where(id:).delete_all` in ensure, not `u.destroy` |
| Phase 2 — locale keys | Pitfall 10 (parity) | Edit ja.yml and en.yml together; run i18n parity test immediately |
| Phase 3 — Cucumber E2E | Pitfall 8 (fixture isolation) | Non-fixture purge target created in `Before('@admin_purge')`; `After` guard with `User.where(email:).delete_all` |
| Phase 3 — routing | Pitfall 11 (confirmation step design) | Mirror `AccountDeletionsController` two-page pattern; no GET `/confirm` route |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Server-side guard bypass (Pitfall 1) | HIGH | Confirmed by code inspection: no guard exists on `Admin::UsersController`; route is open to any admin |
| Association coverage / PortalLayout orphan (Pitfalls 2, 5) | HIGH | Direct `db/schema.rb` inspection; no FK constraints; no `dependent:` on `portal_layouts`; `portal_layouts` has no User has_many at all |
| nil `deleted_at` eligibility check (Pitfall 3) | HIGH | Schema confirms nullable `deleted_at`; existing test `test_削除済みユーザーも一覧に表示される` uses `update_columns(deleted: true, deleted_at: Time.current)` — the pattern is safe but the guard must be explicit |
| CSRF on destructive admin action (Pitfall 4) | HIGH | Standard Rails pattern; `form_with method: :delete` is the established prevention; `link_to method: :delete` + UJS is brittle in this stack |
| Preference unsaved default (Pitfall 6) | HIGH | Documented in ARCHITECTURE.md anti-patterns; `User#preference` override confirmed in `user.rb` line 106 |
| Cucumber fixture isolation (Pitfall 8) | HIGH | `@account_deletion` hook confirmed to call `User.find(3).update_columns(...)` — would raise if user3 was hard-deleted |
| ensure-block destroy after purge (Pitfall 9) | HIGH | Existing test pattern (`test_削除済みユーザーも一覧に表示される`) uses `ensure u.destroy` — would fail if test calls `purge_account!` on same object |
| Race condition (Pitfall 7) | MEDIUM | Practically irrelevant for a personal app; `RecordNotFound` on `find` is a real code path; `find_by` + nil check is the standard mitigation |
| x_accounts dependent: :destroy N+1 (Pitfall 12) | MEDIUM | Code-level analysis; impact is minor for small datasets but correct to prevent proactively |
