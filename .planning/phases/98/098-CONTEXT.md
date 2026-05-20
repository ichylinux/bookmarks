# Phase 98: Admin Access Gate - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous)

<domain>
## Phase Boundary

Admin namespace routes with `Admin::BaseController#require_admin` — guests redirect to sign-in, non-admins get 404, admins get 200. Full report UI deferred to Phase 99.

</domain>

<decisions>
## Implementation Decisions

### Access Control
- `Admin::BaseController < ApplicationController` with `before_action :require_admin`
- `require_admin` calls `head :not_found` unless `current_user.admin?` — 404 obscures route (STATE.md)
- `authenticate_user!` from ApplicationController runs first — guests never reach require_admin

### Routing
- `namespace :admin { resources :x_api_usages, only: [:index] }` → `Admin::XApiUsagesController#index`

### Phase 98 View
- Minimal `index` action + empty-ish ERB so admin gets 200; Phase 99 replaces with full report

### Tests
- `test/controllers/admin/x_api_usages_controller_test.rb`
- Guest → redirect `new_user_session_path`
- User 2 (non-admin) → 404
- User 1 (admin fixture) → 200

</decisions>
