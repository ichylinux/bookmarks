# Feature Landscape: Admin Account Purge (v1.32)

**Domain:** Admin hard-delete of soft-deleted user accounts in a Rails app
**Researched:** 2026-05-22
**Scope:** SUBSEQUENT MILESTONE — builds on existing soft-delete, `/admin/users` list, `require_admin` gate

---

## Existing Infrastructure (Already Built — Do Not Re-Build)

| Already present | Location |
|-----------------|----------|
| `users.deleted` / `users.deleted_at` columns | `db/schema.rb` |
| `User#destroy_account!` — PII strip + soft-delete | `app/models/user.rb` |
| `User.active` scope | `app/models/user.rb` |
| `/admin/users` list (all users, incl. soft-deleted) | `Admin::UsersController#index` |
| `Admin::BaseController#require_admin` (404 non-admins) | `app/controllers/admin/base_controller.rb` |
| Bilingual ja/en locale infrastructure | `config/locales/ja.yml`, `en.yml` |
| Minitest admin controller tests | `test/controllers/admin/users_controller_test.rb` |
| Cucumber admin scenario | `features/11.管理者.feature` |

---

## Association Inventory (What Must Be Deleted)

Every table with a `user_id` column must be cleaned up. Current `dependent:` status matters for implementation.

| Table | Has `user_id` | Current `dependent:` on User | Purge strategy |
|-------|--------------|------------------------------|----------------|
| `bookmarks` | yes | none | explicit `delete_all` by `user_id` |
| `feeds` | yes | none | explicit `delete_all` by `user_id` |
| `notes` | yes | none | explicit `delete_all` by `user_id` |
| `todos` | yes | none | explicit `delete_all` by `user_id` |
| `portals` | yes | none (association scoped to `deleted: false`) | explicit `delete_all` by `user_id` — include soft-deleted |
| `portal_layouts` | yes | none | explicit `delete_all` by `user_id` |
| `preferences` | yes | none | explicit `delete_all` by `user_id` |
| `mastodon_accounts` | yes | none | explicit `delete_all` by `user_id` |
| `visited_links` | yes | none | explicit `delete_all` by `user_id` |
| `x_accounts` | yes | `dependent: :destroy` | runs callbacks; acceptable at purge time |
| `x_api_calls` | yes | `dependent: :delete_all` | already handled; still needs to be inside the transaction |

Implementation note: `user.destroy` would trigger `dependent: :destroy` on `x_accounts` and `dependent: :delete_all` on `x_api_calls` automatically — but it would also run Devise callbacks and potentially other Rails lifecycle hooks. Safer pattern: explicit `delete_all` for every table inside a transaction, then `user.delete` (no callbacks) as the final step. This is the standard Rails pattern for admin-initiated hard-delete at scale.

---

## Table Stakes

Features the admin expects. Missing = the purge feature is incomplete or unsafe.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Eligibility predicate: only accounts with `deleted_at <= 90.days.ago` are purgeable | Matches the 90-day erasure window committed to in privacy policy + ToS (v1.28); prevents accidental purge of recently deactivated accounts | Low | `User#purgeable?` predicate: `deleted? && deleted_at.present? && deleted_at <= 90.days.ago`. No new column needed. |
| Purge button visible only for eligible soft-deleted rows | Admin must not see a purge button on active users or recently-deleted users | Low | Conditional `button_to` (renders a `<form>` with DELETE method) in the view, guarded by `user.purgeable?`. |
| Confirmation step before purge executes | Hard-delete is irreversible; an accidental click must not destroy data | Low | `data-confirm` on the purge button (Rails UJS `confirm:` option) is the proportionate pattern for a routine admin operation. The typed-token pattern (`AccountDeletionsController`) is reserved for high-stakes self-service flows. |
| Hard-delete the `users` row and all associated records | The purpose of the feature — data erasure after the retention window | Med | `User#purge!` model method: validates eligibility, wraps in a transaction, `delete_all` for each of the 11 dependent tables, `user.delete` last. Use `delete_all` (no callbacks) for all child tables except `x_accounts` (which uses `destroy_all` due to its own `dependent:` chain — or explicit `delete_all` with a join). |
| Purge is atomic — wrapped in a transaction | Partial deletes leave orphaned rows | Low | `ActiveRecord::Base.transaction { ... }` in `User#purge!`. On any exception, the transaction rolls back and the user row remains. |
| `User#purge!` raises (or returns false) if account is not eligible | Prevents the controller from purging an account that was eligible when the button rendered but became ineligible by the time the request processed (e.g., `deleted_at` was recently set) | Low | Check `purgeable?` inside `purge!`. If false, raise `User::NotPurgeableError` (custom error) or return false — caller handles the flash. Raise is preferred: forces the controller to handle it explicitly. |
| Admin-only gate on the purge action | Consistent with all other admin routes; non-admin gets 404 | None | New controller inherits `Admin::BaseController` — `require_admin` is provided for free. Route: `DELETE /admin/users/:id` (override `destroy`) or a custom `DELETE /admin/users/:id/purge`. |
| Flash message on success and on ineligibility | Admin must know whether the purge happened | Low | Two keys: `admin.users.purge.success` and `admin.users.purge.ineligible`. Bilingual ja + en. |
| Bilingual ja/en labels | App mandate — all UI chrome is bilingual | Low | New locale keys: purge button label, confirm dialog text, flash success, flash ineligible, `deleted_at` column header (if adding that column to the list view). |
| Minitest coverage: model purge logic + controller access + eligibility | App mandate | Med | Three groups: (1) `User#purge!` unit tests (cascades all 11 tables, ineligible raises, transaction rollback on DB error), (2) controller access control (admin purges eligible user, admin gets ineligible flash, non-admin gets 404, guest redirects), (3) eligibility boundary conditions (exactly 90 days old, 89 days, 91 days). |
| Cucumber E2E for the admin purge flow | App mandate — E2E gates every milestone | Med | One scenario in Japanese: admin signs in, a soft-deleted-and-eligible user exists, admin opens user list, clicks purge, confirms, is redirected back to user list, user row is gone. Use `rack_test` driver (avoids JS dialog complexity) or Selenium `accept_confirm`. |

---

## Differentiators

Valuable additions that do not block the core purge from working.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `deleted_at` column in the `/admin/users` table | Admin can see when soft-delete happened, making the 90-day window visible without guessing | Low | Add an 8th column to `index.html.erb`. Format with `l(user.deleted_at, format: :admin_datetime)` — same pattern as `last_sign_in_at`. Show `—` when not deleted. |
| Visual row distinction: soft-deleted (ineligible) vs soft-deleted (purgeable) | Prevents admin confusion — different CSS classes convey state at a glance | Low | Two CSS row classes: `tr.user--deleted` (soft-deleted, not yet 90 days) and `tr.user--purgeable` (eligible). Added in the view via `user.purgeable?`. |
| `User#purgeable?` as a named public predicate | Makes eligibility testable in isolation; readable in views and controllers | None | Extracts `deleted? && deleted_at.present? && deleted_at <= 90.days.ago` into a method. Called by both the view (button guard) and `purge!` (safety check). |
| Ineligibility branch in flash distinguishes "not soft-deleted" from "too recent" | If admin directly POSTs a purge on a non-eligible user, the flash explains why | Low | Two sub-cases in `purge!` error path: `:not_deleted` and `:not_old_enough`. Separate locale keys or a single key with interpolation. |

---

## Anti-Features

Features to explicitly NOT build for this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Async background job for purge (Sidekiq, ActiveJob) | This app has no job infrastructure; user count is small; synchronous purge completes in milliseconds | Synchronous `purge!` in the controller is correct and fast |
| Undo / restore after purge | Hard-delete is irreversible by definition; undo contradicts the feature goal | The 90-day eligibility window is the safety valve |
| Audit log table for admin actions | Useful in enterprise apps but adds a schema migration, model, and test surface beyond the v1.32 goal | Can be added in a future milestone |
| Bulk purge (multi-select + purge all) | User count is tiny; adds checkbox UI, loop logic, and risk of accidental mass deletion | Single-row purge only |
| Email notification to the purged account | Account is already soft-deleted; the email field was anonymized by `destroy_account!`; SMTP infra not configured for this use | No notification |
| Typed-token confirmation ("type DELETE to confirm") | Appropriate for self-service destructive actions (high emotional cost); disproportionate for routine admin maintenance | `data-confirm` dialog is the right UX weight for admin purge |
| Column sorting/filtering on admin users list | Explicitly deferred in PROJECT.md out-of-scope section | Not in v1.32 |
| Pagination on admin users list | Explicitly deferred in PROJECT.md out-of-scope section | Not in v1.32 |
| Modifying `dependent:` declarations on the User model | Adding `dependent: :destroy` or `dependent: :delete_all` to all associations would silently cascade on any `user.destroy` call elsewhere in the app — a dangerous global side-effect. The purge logic belongs in `purge!`, not in ActiveRecord callbacks. | Explicit `delete_all` calls inside the transaction in `User#purge!` |

---

## Feature Dependencies

```
User#destroy_account! (soft-delete, v1.28)
    └── sets users.deleted = true, deleted_at = now
    └── required by --> User#purgeable? (deleted_at <= 90.days.ago)
    └── required by --> User#purge! (eligibility check)

Admin::BaseController#require_admin (v1.29)
    └── required by --> new purge controller action (inherited for free)

Admin::UsersController#index (v1.30)
    └── required by --> purge button column addition
    └── required by --> deleted_at column addition (differentiator)

User#purgeable?
    └── required by --> view guard (show/hide purge button)
    └── required by --> User#purge! (safety re-check inside transaction)

User#purge! (new)
    └── deletes: bookmarks, feeds, notes, todos,
                 portals, portal_layouts, preferences,
                 mastodon_accounts, visited_links,
                 x_accounts (via existing dependent: :destroy or explicit),
                 x_api_calls (via dependent: :delete_all or explicit),
                 then users row
    └── wrapped in: ActiveRecord::Base.transaction

Admin::PurgesController#destroy (new, or Admin::UsersController#destroy)
    └── calls: User.find(params[:id])
    └── calls: user.purge!
    └── rescues: User::NotPurgeableError → flash ineligible, redirect
    └── on success: flash success, redirect to admin_users_path
```

---

## Complexity Assessment

| Component | Effort estimate | Risk | Notes |
|-----------|----------------|------|-------|
| `User#purgeable?` predicate | Folded into purge! phase | Low | One-liner |
| `User#purge!` with full cascade | 1 phase | Med | Correctness-critical; must cover all 11 tables; transaction required; eligibility guard |
| `User::NotPurgeableError` custom error | Folded into purge! phase | Low | Subclass `StandardError` |
| Controller action + route | 0.5 phases | Low | Inherit `Admin::BaseController`, call `purge!`, handle error, redirect |
| View update (purge button + deleted_at column) | 0.5 phases | Low | Conditional `button_to` and new column in existing table |
| Locale keys (ja/en) | Folded into view phase | Low | 4–6 keys |
| Minitest (model + controller + eligibility) | 1 phase | Low | Unit tests for `purge!`; controller access; boundary conditions |
| Cucumber E2E | 0.5 phases | Low | One happy-path scenario |

**Total: 3–4 phases.** Smaller than v1.31 (5 phases). The heaviest correctness surface is `User#purge!` — all 11 table deletions and the transaction boundary.

---

## Sources

- Codebase inspection (HIGH confidence): `db/schema.rb`, `app/models/user.rb`, `app/controllers/admin/base_controller.rb`, `app/controllers/admin/users_controller.rb`, `app/views/admin/users/index.html.erb`, `app/controllers/users/account_deletions_controller.rb`
- PROJECT.md: v1.28 delivery (soft-delete + `destroy_account!`), v1.30 delivery (admin user list), out-of-scope section (pagination, column sort deferred)
- [Handling Has-Many Through Cascading Deletes in Rails](https://dustingoodman.dev/blog/20240608-handling-has-many-through-cascading-deletes-in-rails/) — MEDIUM confidence, verified pattern against schema
- [Rails ActiveRecord dependent: strategies](https://dev.to/nemwelboniface/what-happens-when-a-user-deletes-their-account-a-guide-to-rails-activerecord-dependent-strategies-1279) — LOW confidence (community post)
- [ActiveRecord models: GDPR-compliant data removal](https://www.globalapptesting.com/engineering/activerecord-models-how-to-remove-data-in-gdpr-compliant-way) — LOW confidence (general guidance; specific implementation derived from codebase)
