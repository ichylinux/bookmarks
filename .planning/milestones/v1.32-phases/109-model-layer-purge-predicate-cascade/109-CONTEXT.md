# Phase 109: Model Layer — Purge Predicate & Cascade - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `User#purgeable?`, `User::PURGE_AFTER_DAYS`, `User.purgeable` scope, `User::NotPurgeableError`, and `User#purge!` with full 11-table cascade inside a transaction. No controller, view, or locale work — model layer only.

</domain>

<decisions>
## Implementation Decisions

### Eligibility & Error Design
- `purge!` checks `purgeable?` internally and raises `User::NotPurgeableError` if false — defensive, callers do not need to guard first
- `User::NotPurgeableError < StandardError` defined inside `user.rb` — no separate file
- `User.purgeable` class scope defined in Phase 109 alongside `purgeable?` — Phase 110 needs it for the admin list view
- `PURGE_AFTER_DAYS = 90` constant on User (mirrors `PORTAL_COLUMN_COUNTS` pattern) — used by both `purgeable?` and `User.purgeable` scope

### Cascade Implementation
- All deletes + final `user.delete` wrapped in `ApplicationRecord.transaction { }` — atomic, rollback if any delete fails
- Final step is `user.delete` (not `user.destroy!`) — explicit pre-deletes already handle x_accounts and x_api_calls; avoids double-running `dependent: :destroy` callbacks
- `x_accounts` deleted explicitly via `XAccount.where(user_id: id).delete_all` first — consistent with all other tables, no AR callback overhead
- Minitest: create user inline with `User.create!` + `update_columns(deleted_at: 91.days.ago)` — no new fixture

### Claude's Discretion
- Deletion order within `purge!`: bookmarks → feeds → mastodon_accounts → notes → portal_layouts → portals → preferences → todos → visited_links → x_accounts → x_api_calls → user.delete
- `purgeable?` nil-guard: `deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago`
- `User.purgeable` scope: `where(deleted: true).where.not(deleted_at: nil).where('deleted_at <= ?', PURGE_AFTER_DAYS.days.ago)`
- `Preference.where(user_id: id).delete_all` not `user.preference.destroy` (unsaved default raises error)
- `portal_layouts` explicitly via `PortalLayout.where(user_id: id).delete_all` (no `has_many` on User)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `User#destroy_account!` pattern: use `update_columns` for fast writes; `purge!` follows same class but hard-deletes
- `PORTAL_COLUMN_COUNTS` constant pattern on Preference: defines `PURGE_AFTER_DAYS = 90` on User same way
- `ApplicationRecord.transaction { }` available throughout
- `XAccount.where(user_id:).delete_all` pattern already used in tests

### Established Patterns
- Model constants: defined as class-level constants, not frozen hashes
- `scope :active` already on User — `scope :purgeable` follows same pattern
- `raise SomeError` with `rescue` in controller — `NotPurgeableError` will be rescued in Phase 110 controller
- Minitest: `user = users(:one)` or `User.create!` + `update_columns` for special states

### Integration Points
- Phase 110 will add `Admin::UsersController#destroy` + `#confirm_purge` that calls `user.purge!`
- Phase 110 will use `User.purgeable` scope OR `user.purgeable?` in the view to show/hide the button
- `User.purgeable` scope must be nil-safe (deleted_at is nullable)

### Tables requiring explicit delete_all in purge!
1. Bookmark.where(user_id: id).delete_all
2. Feed.where(user_id: id).delete_all
3. MastodonAccount.where(user_id: id).delete_all
4. Note.where(user_id: id).delete_all
5. PortalLayout.where(user_id: id).delete_all  ← no has_many on User
6. Portal.where(user_id: id).delete_all
7. Preference.where(user_id: id).delete_all    ← NOT user.preference.destroy
8. Todo.where(user_id: id).delete_all
9. VisitedLink.where(user_id: id).delete_all
10. XAccount.where(user_id: id).delete_all     ← pre-delete before user.delete
11. XApiCall.where(user_id: id).delete_all     ← pre-delete before user.delete
12. user.delete  ← final step, NOT user.destroy!

</code_context>

<specifics>
## Specific Ideas

- Minitest boundary cases required: `purgeable?` with `deleted_at` nil (no crash), 89 days ago (false), exactly 90 days ago (true), active user (false)
- `purge!` cascade test: assert every one of the 11 associated tables has 0 rows for the purged user after `purge!`
- `purge!` non-purgeable test: assert `NotPurgeableError` raised and no rows deleted on active user

</specifics>

<deferred>
## Deferred Ideas

- Background scheduled purge job (ACCT-FUT-01b) — not in this phase
- Bulk purge (PURGE-FUT-01) — not in this phase

</deferred>
