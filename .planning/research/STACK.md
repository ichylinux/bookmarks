# Technology Stack: v1.32 Admin Account Purge

**Project:** Bookmarks v1.32
**Researched:** 2026-05-22
**Confidence:** HIGH — based on direct inspection of codebase, schema, and existing models

---

## Summary

**Zero new gems required.** The purge feature is fully achievable with existing Rails 8.1
ActiveRecord, a `User#purge!` model method using explicit `delete_all` per table, and a new
controller action on the existing `Admin::UsersController`. No background job framework,
no new dependencies.

---

## Stack Additions

None. No changes to `Gemfile`.

---

## Why No Background Job Framework

Sidekiq, GoodJob, and Solid Queue are appropriate when work must run outside the request
cycle (long-running, retryable, scheduled). A single-user purge in this app does not meet
that bar:

**Row count is bounded.** Inspection of the schema shows all associated tables have a
`user_id` column scoped to a single user. A personal app user accumulates thousands of
rows at most across all tables combined. A transactional `delete_all` per table completes
in milliseconds.

**No job infrastructure exists.** The app has no ActiveJob backend configuration, no
`solid_queue` or `good_job` tables in the schema, no Redis dependency, and no
`config/initializers/` file for a job runner. Adding one for a single use case introduces
significant ops overhead (process management, queue monitoring, retry semantics) with no
payoff.

**Synchronous is fully testable.** The existing Minitest + Cucumber harness can exercise a
synchronous `User#purge!` method end-to-end in one request. Async jobs require job queue
setup in tests, which contradicts the project's preference for minimal test infrastructure.

**Eligibility gate limits blast radius.** Only accounts with `deleted_at >= 90 days ago`
are purgeable. The eligible set is tiny (personal app, bounded user base).

---

## Deletion Strategy: Explicit `delete_all` per Table in a Transaction

### Association Audit

The User model currently declares:

```ruby
has_many :x_api_calls, dependent: :delete_all   # already handled on destroy
has_many :x_accounts, dependent: :destroy        # callbacks are validations only
has_many :notes                                   # no dependent: — intentional
has_many :portals, ...                            # no dependent: — intentional
has_one  :preference, ...                         # no dependent:
# bookmarks, todos, feeds, mastodon_accounts,
# visited_links: no has_many on User at all
```

The existing code comment is definitive:

```
# No dependent: :destroy — disabling an account is the normal lifecycle; a rare
# hard-delete of User must not synchronously load/destroy unbounded notes (see ROADMAP).
```

**Do not add `dependent: :destroy` to any existing association.** That would change the
soft-delete lifecycle behavior and risk unintended cascade on future code paths.

### Tables requiring explicit deletion (all have `user_id`, no Rails cascade)

| Table | Access Pattern | Note |
|-------|---------------|------|
| `portal_layouts` | `PortalLayout.where(user_id:).delete_all` | No `belongs_to :user` on model; class is nearly empty; query directly |
| `portals` | `Portal.where(user_id:).delete_all` | Must delete before user row; no FK constraint but logical dependency |
| `preferences` | `Preference.where(user_id:).delete_all` | One-to-one; `has_one` on User |
| `notes` | `Note.where(user_id:).delete_all` | `Crud::ByUser`; no `dependent:` |
| `todos` | `Todo.where(user_id:).delete_all` | `Crud::ByUser`; no `dependent:` |
| `bookmarks` | `Bookmark.where(user_id:).delete_all` | `acts_as_tree` self-ref `parent_id`; no DB-level FK constraint; all user rows removed in one SQL DELETE |
| `feeds` | `Feed.where(user_id:).delete_all` | `Crud::ByUser`; no `has_many` on User |
| `mastodon_accounts` | `MastodonAccount.where(user_id:).delete_all` | No `dependent:` |
| `visited_links` | `VisitedLink.where(user_id:).delete_all` | Compound unique index `(user_id, url[767])`; `delete_all` removes cleanly |
| `x_api_calls` | `XApiCall.where(user_id:).delete_all` | Already `dependent: :delete_all`; explicit call in `purge!` keeps method self-contained |
| `x_accounts` | `XAccount.where(user_id:).delete_all` | Already `dependent: :destroy`; callbacks are validations (`selection_cap`, `protected_acknowledgement`) — no data side effects lost by skipping them |

### `acts_as_tree` on Bookmark — no special handling

`bookmarks.parent_id` is a self-referential column within the same table. The schema has
no explicit `FOREIGN KEY` constraint (MySQL InnoDB; none declared in `db/schema.rb`).
`Bookmark.where(user_id:).delete_all` issues `DELETE FROM bookmarks WHERE user_id = ?`
which removes all rows for the user in one statement, including both parent and child rows
atomically within the wrapping transaction. No ordering required.

### `portal_layouts` — no model association

`PortalLayout` has `user_id` in the schema but the model body is empty. `Portal` accesses
it with `PortalLayout.where(user_id: user.id)` directly — the `purge!` method does the
same.

### Recommended `User#purge!` implementation skeleton

```ruby
def purge!
  raise "cannot purge active account" unless deleted?

  transaction do
    PortalLayout.where(user_id: id).delete_all
    Portal.where(user_id: id).delete_all
    Preference.where(user_id: id).delete_all
    Note.where(user_id: id).delete_all
    Todo.where(user_id: id).delete_all
    Bookmark.where(user_id: id).delete_all
    Feed.where(user_id: id).delete_all
    MastodonAccount.where(user_id: id).delete_all
    VisitedLink.where(user_id: id).delete_all
    XApiCall.where(user_id: id).delete_all
    XAccount.where(user_id: id).delete_all
    destroy!
  end
end
```

All eleven `delete_all` calls are single-SQL DELETE statements. The wrapping transaction
ensures atomicity: either every table is cleaned and the user row is removed, or nothing
changes.

### Why `delete_all` over `destroy_all`

`destroy_all` instantiates every record and fires callbacks. For this schema, the
callbacks are validations and `before_save` nil-guards — none perform referential cleanup
that `delete_all` would miss. `delete_all` issues one `DELETE FROM ... WHERE user_id = ?`
per table, is faster, allocates no objects, and is transactionally equivalent here.

---

## Eligibility Check: Pure Ruby on Existing Columns

No schema changes required. `users.deleted` and `users.deleted_at` already exist (added
in v1.28).

```ruby
# On User model:
scope :purgeable, -> {
  where(deleted: true).where('deleted_at <= ?', 90.days.ago)
}

def purgeable?
  deleted? && deleted_at.present? && deleted_at <= 90.days.ago
end
```

The admin controller checks `purgeable?` before executing; if the record no longer
qualifies (e.g., tampered request), the action redirects with an error flash.

---

## Integration Points

### `Admin::UsersController` (existing)

Add a `purge` action. Route as a member action under the existing `admin/users` resource
to avoid collision with Rails `destroy` conventions:

```ruby
# config/routes.rb (inside admin namespace)
resources :users, only: [:index] do
  member do
    delete :purge
  end
end
# Produces: purge_admin_user_path(user) → DELETE /admin/users/:id/purge
```

The action is gated by the existing `require_admin` before-action in `Admin::BaseController`.
No new auth logic.

### Confirmation Flow

Follow the same two-step pattern as `AccountDeletionsController` (v1.28):
- `GET  /admin/users/:id/purge/confirm` — renders a warning page showing the user's id
  and email with a DELETE form
- `DELETE /admin/users/:id/purge` — executes `user.purge!` with eligibility re-check

This avoids JavaScript `confirm()` dialogs, which have reliability issues with the
Capybara + Selenium test harness. A full-page confirmation is consistent with the existing
account deletion pattern and is naturally testable in Cucumber with `rack_test` or
Selenium by visiting the confirmation page and submitting the form.

### Locale Keys

Add to both `config/locales/ja.yml` and `config/locales/en.yml` under `admin.users.*`:
- Purge button label
- Confirmation page title and body text
- Eligibility description (soft-deleted, 90+ days ago)
- Flash: purge success, purge ineligible

The existing i18n parity test will enforce key symmetry between `ja.yml` and `en.yml`.

### Admin Users Index View

Add a "Purge" button column or inline link on the `/admin/users` table for rows where
`user.purgeable?`. Non-purgeable rows show no button (or a disabled/grey indicator).
This is a pure view change on the existing partial with no new helpers required.

---

## What NOT to Add

| Rejected Technology | Reason |
|---|---|
| Sidekiq | No Redis, no existing job infra; row count is bounded; synchronous DELETE is sufficient |
| GoodJob | No existing ActiveJob backend; adds DB tables and process management with no payoff |
| Solid Queue | Rails 8.1 ships it but this app does not configure it; same overkill argument as GoodJob |
| `paranoia` / `discard` / `acts_as_paranoid` gems | Soft-delete is already hand-rolled on `users.deleted` / `deleted_at`; adding a gem would require migrating existing convention and is out of scope |
| `paper_trail` or audit gems | Purge is an intentional irreversible action; audit trail is out of scope for v1.32 |
| `dependent: :destroy` on existing User associations | The model comment explicitly forbids this for large tables; it would change the soft-delete lifecycle |
| `dependent: :nullify` | All `user_id` columns are `NOT NULL`; nullify would fail the DB constraint |
| Database-level CASCADE | Schema has no FK constraints; adding them is a separate architectural concern unrelated to this feature |
| New migration for purge | Not required; all needed columns exist |
| New model for purge audit log | Out of scope |

---

## Current Stack (Unchanged for v1.32)

| Layer | Technology | Version |
|---|---|---|
| Framework | Rails | 8.1.x |
| Ruby | Ruby | 3.4.x |
| Database | MySQL (mysql2 gem) | 0.4.4–0.5.x |
| Auth | Devise + devise-two-factor | current |
| HTTP | Faraday | current |
| Tests (unit) | Minitest | ~5.0 |
| Tests (E2E) | Cucumber + Capybara + Selenium | current |
| HTTP stubs | WebMock | 3.26.2 |
| Assets | Sprockets + Sass-Rails + jQuery | unchanged |

No additions to `Gemfile` are required for v1.32.

---

## Sources

- `/home/ichy/workspace/bookmarks/app/models/user.rb` — association declarations, `destroy_account!`, intentional no-`dependent:` comment
- `/home/ichy/workspace/bookmarks/db/schema.rb` — all tables with `user_id` columns
- `/home/ichy/workspace/bookmarks/Gemfile` — existing gem set (no job framework present)
- `/home/ichy/workspace/bookmarks/app/models/portal_layout.rb` — empty model, no associations
- `/home/ichy/workspace/bookmarks/app/models/portal.rb` — direct `PortalLayout.where(user_id:)` access pattern
- `/home/ichy/workspace/bookmarks/app/models/bookmark.rb` — `acts_as_tree`; no FK constraint in schema
- `/home/ichy/workspace/bookmarks/.planning/PROJECT.md` — v1.28 decision log (soft-delete rationale, ACCT-FUT-01 deferred purge job)
- Confidence HIGH throughout — all conclusions are grounded in direct code and schema reads, not training-data assumptions
