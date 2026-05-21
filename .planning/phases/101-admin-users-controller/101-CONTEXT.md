# Phase 101: Admin Users Controller & Route - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Create `Admin::UsersController#index`, add route `/admin/users` in the `admin` namespace, apply the existing `require_admin` gate from `Admin::BaseController`. Produce a placeholder view (to be populated in Phase 102).

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase following established v1.29 patterns exactly:
- Controller: `Admin::UsersController < Admin::BaseController`, `index` action sets `@users = User.all.includes(:x_accounts).order(:id)`
- Route: add `resources :users, only: [:index]` inside existing `namespace :admin` block
- Placeholder view: `app/views/admin/users/index.html.erb` with minimal content (h1 heading)
- Minitest: 3 access-control scenarios (admin 200, non-admin 404, guest redirect) matching v1.29 pattern in `test/controllers/admin/users_controller_test.rb`

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Admin::BaseController` at `app/controllers/admin/base_controller.rb` — `before_action :require_admin` gate; `require_admin` returns 404 for non-admins
- `Admin::XApiUsagesController` — reference implementation for admin controller structure
- `test/controllers/admin/x_api_usages_controller_test.rb` — 3-scenario access test pattern (guest redirect, non-admin 404, admin 200)
- User fixtures: `users(:one)` = admin, `users(:two)` = regular user

### Established Patterns
- Admin namespace: `namespace :admin { resources :x_api_usages, only: [:index] }` in `config/routes.rb`
- Controller module: `module Admin; class XApiUsagesController < BaseController`
- Test pattern: `ActionDispatch::IntegrationTest`, `sign_in users(:one)` for admin, `sign_in users(:two)` for non-admin
- View structure: `<section class="admin-{resource}">` with `aria-labelledby` heading

### Integration Points
- `config/routes.rb` — add to existing `namespace :admin` block
- `app/controllers/admin/` directory
- `app/views/admin/users/` directory (new)
- `test/controllers/admin/` directory

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond what the ROADMAP specifies. Follow v1.29 pattern exactly.

</specifics>

<deferred>
## Deferred Ideas

None — discuss phase skipped (infrastructure).

</deferred>
