# Phase 102: User List View - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Render the user list table at `app/views/admin/users/index.html.erb` with all 7 required columns: id, email, x_user_name, admin_flag, last_sign_in_at, created_at, updated_at. All registered users including soft-deleted are shown. Controller sets `@users = User.all.includes(:x_accounts).order(:id)`.

</domain>

<decisions>
## Implementation Decisions

### Soft-deleted User Display
- No special visual styling for deleted users — plain rows identical to active users
- No extra columns beyond the 7 specified in the requirements
- Nil `last_sign_in_at` displays as `—`

### x_user_name Resolution
- Use `user.x_accounts.reject(&:deleted?).sort_by(&:id).first` — matches v1.29's `identity_label` non-deleted account pattern
- Display logic is inline in the view (no helper method) — simple read-only table, no reuse needed
- `admin_flag` renders `✓` for admins and `—` for regular users (matches spec exactly)

### Date Display Format
- Use `l(col, format: :short)` for all datetime columns (last_sign_in_at, created_at, updated_at)
- Nil `last_sign_in_at` (never signed in) displays as `—`
- Column order follows spec exactly: id, email, x_user_name, admin_flag, last_sign_in_at, created_at, updated_at

### Claude's Discretion
- View BEM class: `admin-users__table`, `admin-users__table-scroll`, matching v1.29 naming convention
- Minitest coverage: column structure via assert_select, soft-deleted user visible, blank x_user_name fallback, admin_flag indicator test

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/admin/x_api_usages/index.html.erb` — reference template for table structure, scroll wrapper, empty state
- `Admin::XApiUsagesController#index` — reference for controller loading pattern
- `User.all.includes(:x_accounts).order(:id)` — query specified in ROADMAP, prevents N+1

### Established Patterns
- View structure: `<section class="admin-{resource}" aria-labelledby="...heading">` + `<h1>` with locale key
- Table: `<div class="...table-scroll"><table class="...table">` wrapper for horizontal scroll
- Nil datetime: `l(col, format: :short) if col else '—'`
- User soft-delete: `user.deleted?` returns true when `users.deleted = true`

### Integration Points
- `app/views/admin/users/index.html.erb` (new)
- `app/controllers/admin/users_controller.rb` (Phase 101) — add `@users` assignment
- `config/locales/ja.yml` + `en.yml` — `admin.users.index.*` keys (added in Phase 103)
- Minitest: `test/controllers/admin/users_controller_test.rb`

</code_context>

<specifics>
## Specific Ideas

- Use placeholder locale keys in Phase 102 view (e.g., hardcoded column header strings) — Phase 103 will wire locale YAML
- OR add locale keys directly in Phase 102 alongside the view — acceptable since keys are simple

</specifics>

<deferred>
## Deferred Ideas

- Visual distinction for deleted users (muted rows, strikethrough) — not in scope for v1.30
- Sorting and filtering — explicitly deferred per requirements

</deferred>
