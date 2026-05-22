# Project Research Summary

**Project:** Bookmarks v1.32 — Admin Account Purge
**Domain:** Admin hard-delete of soft-deleted user accounts in a Rails app
**Researched:** 2026-05-22
**Confidence:** HIGH

## Executive Summary

v1.32 adds a single, well-scoped capability: allow an admin to permanently delete user accounts that have been soft-deleted for 90 or more days. The v1.28 soft-delete foundation (`users.deleted`, `users.deleted_at`, `User#destroy_account!`) is already in place, and the admin controller and route namespace (`Admin::BaseController`, `Admin::UsersController`, `/admin/users`) were established in v1.29–v1.30. This milestone closes the loop by adding `User#purgeable?`, `User#purge!`, a two-step confirmation flow, and the corresponding view, locale, and test coverage. No new gems, no migrations, no background job infrastructure.

The recommended implementation puts all deletion logic in a `User#purge!` instance method — consistent with the existing `destroy_account!` pattern — that runs 11 explicit `delete_all` calls (one per associated table) inside a single transaction and finishes with `destroy!` on the user row. This approach is synchronous, fully testable, and correct: there are no FK constraints in the schema, row counts are bounded (personal app), and no job infrastructure exists to make an async approach practical. The controller stays thin, calling `user.purge!` and redirecting with a flash.

The critical risks are all guarded at the model layer. An unguarded purge action would allow any admin to hard-delete an active user by direct HTTP request — the UI-only guard is never sufficient. Additionally, `portal_layouts` has no `has_many` declared on `User` and will be silently orphaned if not explicitly deleted. Both risks are caught by writing the eligibility guard and association-coverage tests before any controller or view work.

---

## Key Findings

### Recommended Stack

No changes to `Gemfile`. The purge feature is fully achievable with Rails 8.1 ActiveRecord, a `User#purge!` model method, and a new action on `Admin::UsersController`. The existing columns (`users.deleted`, `users.deleted_at`) and the admin authentication gate (`require_admin`) are already present. No migration is required.

Background job frameworks (Sidekiq, GoodJob, Solid Queue) are explicitly ruled out: the app has no job infrastructure, row counts are bounded, and a synchronous transactional `delete_all` per table completes in milliseconds.

**Core technologies (unchanged for v1.32):**
- Rails 8.1 / Ruby 3.4 — application framework
- MySQL (mysql2) — no FK constraints defined; `delete_all` ordering is logical, not enforced
- Devise — authentication; `require_admin` gate inherited by all admin controllers
- Minitest — unit and controller tests
- Cucumber + Capybara + Selenium — E2E gate; `bundle exec rake dad:test`

### Expected Features

**Must have (table stakes):**
- `User#purgeable?` predicate: `deleted? && deleted_at.present? && deleted_at <= 90.days.ago` — guards both view and model
- `User#purge!` with full 11-table cascade inside a transaction — the core deletion method
- `User::NotPurgeableError` (or equivalent raise) inside `purge!` — forces controller to handle ineligibility explicitly
- Eligibility guard at the server side (controller) — view-only guard is insufficient; direct HTTP requests bypass it
- Two-step confirmation flow (GET confirm page, then DELETE) — mirrors `AccountDeletionsController` pattern; no JS `confirm()` dialog
- Admin-only gate — inherited from `Admin::BaseController#require_admin`
- Flash messages on success and on ineligibility — bilingual ja + en
- Minitest coverage: `purgeable?` boundary conditions, `purge!` cascade over all 11 tables, transaction rollback, controller access control
- Cucumber E2E scenario: admin purges eligible user, user disappears from list

**Should have (differentiators):**
- `deleted_at` column in `/admin/users` table — makes the 90-day window visible at a glance
- Visual row distinction (CSS class) for soft-deleted-ineligible vs purgeable rows
- Distinct ineligibility sub-cases in flash ("not deleted" vs "too recent")

**Defer (v2+):**
- Async background job for purge
- Audit log table for admin actions
- Bulk purge (multi-select)
- Email notification to purged account
- Typed-token confirmation ("type DELETE to confirm")
- Column sorting and pagination on admin users list (already deferred in PROJECT.md)

### Architecture Approach

All purge logic lives in `User#purge!` as an instance method, consistent with the existing `destroy_account!` lifecycle method. No service object is introduced — `app/services/` contains only HTTP clients and this codebase has no service-object convention for data mutations. The controller action (`Admin::UsersController#destroy`) is thin: find user, guard on `purgeable?`, call `purge!`, capture email before destroy, redirect with flash. The confirmation flow mirrors `Users::AccountDeletionsController` from v1.28: a GET renders the confirmation page, the DELETE executes the action, both using `data: { turbo: false }` to prevent Turbo interception.

**Major components:**

1. `User#purgeable?` + `User#purge!` (`app/models/user.rb`) — eligibility predicate and transactional hard-delete of all 11 associated tables plus the user row
2. `Admin::UsersController#destroy` + `#confirm_purge` (`app/controllers/admin/users_controller.rb`) — thin controller actions gated by inherited `require_admin`
3. `confirm_purge.html.erb` (`app/views/admin/users/`) — server-rendered confirmation page with DELETE form; no JS required
4. Route extension (`config/routes.rb`) — `resources :users, only: [:index, :destroy]` + `member { get :confirm_purge }`
5. Locale keys — `admin.users.{destroy,confirm_purge,index}.*` in both `ja.yml` and `en.yml`
6. Cucumber feature + hooks (`features/12.管理者パージ.feature`) — non-fixture purge target created in `Before` hook

### Critical Pitfalls

1. **No server-side eligibility guard** — any admin can hard-delete an active user via direct HTTP. Implement `purgeable?` check in both `purge!` (raises) and the controller (redirects). Write the ineligibility test before the happy-path test.

2. **`portal_layouts` silently orphaned** — `User` has no `has_many :portal_layouts`, so no `dependent:` catches it. Must explicitly include `PortalLayout.where(user_id: id).delete_all` in `purge!`. Catch this with a per-table assertion in the association-coverage Minitest.

3. **`nil deleted_at` causes crash in `purgeable?` check** — the column is nullable; accounts soft-deleted before v1.28 or via direct `update_columns(deleted: true)` without `deleted_at` will raise `ArgumentError` on the `<=` comparison. Guard with `deleted_at.present?` before the comparison.

4. **Cucumber scenario must use a non-fixture user** — the `@admin_purge` `Before` hook must create a fresh user (not user id 3). Hard-deleting a fixture user breaks subsequent scenarios that call `User.find(3)` (e.g., `@account_deletion` hook). Use `User.create!(...)` in the hook and `User.where(email: ...).delete_all` in `After` as a cleanup guard.

5. **`ensure` blocks in Minitest must use `User.where(id:).delete_all`, not `u.destroy`** — after `purge!` the row is gone; `u.destroy` on a missing record raises or silently fails depending on Rails version. Use the SQL path unconditionally in purge-related test teardown.

---

## Implications for Roadmap

### Phase 1: Model Layer — `User#purgeable?` + `User#purge!`

**Rationale:** All other phases depend on these two methods existing and being correct. The hardest correctness surface (all 11 table deletions, transaction boundary, eligibility guard) is isolated here with no UI risk. Write the ineligibility and association-coverage tests before the happy path.

**Delivers:** `User#purgeable?`, `User#purge!`, `User::NotPurgeableError`, `User.purgeable` scope; full Minitest coverage including boundary conditions, nil `deleted_at` guard, every table cleared, transaction rollback.

**Addresses:** Table stakes — eligibility predicate, atomic hard-delete cascade, eligibility guard inside model.

**Avoids:** Pitfall 1 (unguarded purge), Pitfall 2 (association ordering), Pitfall 3 (nil deleted_at), Pitfall 5 (portal_layouts orphan), Pitfall 6 (Preference unsaved default).

**No migration required.**

---

### Phase 2: Routes + Controller + Locale

**Rationale:** Depends on Phase 1 (`purgeable?` must exist for controller guard). Routes must exist before views can reference route helpers. Locale keys must be added simultaneously in both `ja.yml` and `en.yml` to satisfy the i18n parity test.

**Delivers:** `DELETE /admin/users/:id` and `GET /admin/users/:id/confirm_purge` routes; `Admin::UsersController#destroy` and `#confirm_purge` actions; all new locale keys in both locales; Minitest controller access-control tests.

**Implements:** Admin::UsersController extension, `require_admin` gate (inherited), `find_by` + nil guard for race condition, CSRF-safe `form_with method: :delete`.

**Avoids:** Pitfall 1 (server-side guard in controller), Pitfall 4 (CSRF — use `form_with`, not `link_to`), Pitfall 7 (RecordNotFound — use `find_by`), Pitfall 9 (ensure cleanup in Minitest), Pitfall 10 (i18n parity — edit both locale files together), Pitfall 11 (confirmation step design — mirror AccountDeletionsController).

---

### Phase 3: Views + CSS

**Rationale:** Depends on Phase 2 (route helpers must exist). Pure presentation layer — conditional purge button, `deleted_at` column, row CSS classes, confirmation page form.

**Delivers:** Updated `index.html.erb` with conditional purge button and `deleted_at` column; `confirm_purge.html.erb` with DELETE form and cancel link; danger-style CSS for purge button; i18n parity test updated for new keys.

**Implements:** Three-layer purgeable guard (model + controller + view), server-rendered confirmation flow with `data: { turbo: false }`, visual row distinction for purgeable vs soft-deleted rows.

**Avoids:** Pitfall 4 (CSRF — `form_tag`/`form_with` with embedded authenticity token, not `link_to method: :delete`), Pitfall 11 (two-page flow, not JS `confirm()`).

---

### Phase 4: Cucumber E2E + Tri-Suite Gate

**Rationale:** Depends on all prior phases. Final verification that the full flow works end-to-end under the same conditions as production (browser, Devise session, form submission).

**Delivers:** `features/12.管理者パージ.feature` with two scenarios (eligible user purged, ineligible user has no button); `Before`/`After` hooks using non-fixture purge target; all three test suites green.

**Avoids:** Pitfall 8 (fixture isolation — `Before` hook creates fresh non-fixture user; `After` guard with `delete_all`).

**Driver note:** Standard Selenium is preferred; fall back to `:rack_test` only if DELETE form submission proves unreliable.

---

### Phase Ordering Rationale

- Model first because all phases depend on `purgeable?` existing.
- Controller second because views need route helpers that only exist after routes are declared.
- Views third because they are pure rendering of already-verified logic.
- Cucumber last because it exercises the full stack assembled in phases 1–3.
- This is the same order used in v1.31 and follows the dependency chain identified in ARCHITECTURE.md.

### Research Flags

All phases use well-documented Rails patterns with HIGH-confidence findings grounded in direct codebase inspection. No phase requires additional research during planning.

- **Phase 1 (model):** Standard ActiveRecord transaction + `delete_all` pattern — no research needed.
- **Phase 2 (controller + locale):** Standard Rails admin controller + i18n — no research needed.
- **Phase 3 (views):** Existing `AccountDeletionsController` view is a direct template — no research needed.
- **Phase 4 (Cucumber):** Existing hook patterns from `features/support/hooks.rb` are the guide — no research needed.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct codebase inspection; Gemfile, schema.rb, and config confirmed no job infrastructure exists |
| Features | HIGH | Feature set derived from PROJECT.md decisions, existing admin infrastructure, and privacy-policy 90-day window established in v1.28 |
| Architecture | HIGH | All components identified from direct file reads: user.rb, base_controller.rb, routes.rb, account_deletions_controller.rb as precedent |
| Pitfalls | HIGH | All 12 pitfalls grounded in concrete code paths (nullable column, no FK constraints, no has_many on portal_layouts, fixture ids); not speculative |

**Overall confidence:** HIGH — this is a well-scoped feature on a fully-inspected codebase with clear precedents.

### Gaps to Address

- **`x_accounts dependent: :destroy` callback behavior:** Current `XAccount` callbacks are `before_save` only (no `before_destroy`). The purge method pre-deletes via `delete_all` making this moot, but any future `before_destroy` added to `XAccount` would be silently skipped. Not a gap for v1.32 — noted for future awareness.
- **`Preference` unsaved default:** `User#preference` returns an in-memory default when no DB row exists. The `purge!` implementation must use `Preference.where(user_id: id).delete_all` (not `user.preference.destroy`) to avoid `RecordNotSaved`. Validate the approach in Phase 1 tests.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)

- `/home/ichy/workspace/bookmarks/app/models/user.rb` — association declarations, `destroy_account!`, intentional no-`dependent:` comment, `User#preference` override
- `/home/ichy/workspace/bookmarks/db/schema.rb` — all tables with `user_id` columns, absence of FK constraints
- `/home/ichy/workspace/bookmarks/app/controllers/admin/base_controller.rb` — `require_admin` implementation
- `/home/ichy/workspace/bookmarks/app/controllers/admin/users_controller.rb` — current `#index` action
- `/home/ichy/workspace/bookmarks/app/controllers/users/account_deletions_controller.rb` — two-page confirmation precedent
- `/home/ichy/workspace/bookmarks/config/routes.rb` — current admin namespace structure
- `/home/ichy/workspace/bookmarks/Gemfile` — confirmed no job framework
- `/home/ichy/workspace/bookmarks/.planning/PROJECT.md` — v1.28 soft-delete rationale, deferred purge job (ACCT-FUT-01), out-of-scope items
- `/home/ichy/workspace/bookmarks/features/support/hooks.rb` — existing hook patterns and fixture user ids

### Secondary (MEDIUM confidence)

- [Handling Has-Many Through Cascading Deletes in Rails](https://dustingoodman.dev/blog/20240608-handling-has-many-through-cascading-deletes-in-rails/) — `delete_all` vs `destroy_all` strategy, verified against schema
- [ActiveRecord models: GDPR-compliant data removal](https://www.globalapptesting.com/engineering/activerecord-models-how-to-remove-data-in-gdpr-compliant-way) — general pattern guidance

### Tertiary (LOW confidence)

- [Rails ActiveRecord dependent: strategies](https://dev.to/nemwelboniface/what-happens-when-a-user-deletes-their-account-a-guide-to-rails-activerecord-dependent-strategies-1279) — community post; specific decisions derived from codebase inspection, not this source

---
*Research completed: 2026-05-22*
*Ready for roadmap: yes*
