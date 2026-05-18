---
phase: 84-data-layer-controller
plan: "02"
subsystem: controller
tags: [controller, routing, visited-links, devise, cucumber-hooks, integration-tests]
dependency_graph:
  requires: [visited_links-table, VisitedLink-model, VisitedLink.record!]
  provides: [POST-visited_links-endpoint, visited_links-route, cucumber-visited-link-isolation]
  affects: [config/routes.rb, features/support/hooks.rb]
tech_stack:
  added: []
  patterns: [actioncontroller-head-204, devise-inherited-auth, activerecord-upsert-idempotency]
key_files:
  created:
    - app/controllers/visited_links_controller.rb
    - test/controllers/visited_links_controller_test.rb
  modified:
    - config/routes.rb
    - features/support/hooks.rb
decisions:
  - "authenticate_user! inherited from ApplicationController — no explicit before_action in VisitedLinksController"
  - "Unauthenticated requests redirect to new_user_session_path (Devise default for HTML requests), matching notes_controller_test pattern"
  - "head :no_content (204) is the sole response for successful create — no view, no redirect, no flash"
metrics:
  duration: "~10 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 2
---

# Phase 84 Plan 02: Controller — POST /visited_links endpoint

**One-liner:** Minimal `VisitedLinksController#create` returning 204, routed via `resources :visited_links, only: [:create]`, with Cucumber session isolation hook and 5 integration tests covering auth, idempotency, normalization, and routing.

## What Was Built

### Task 1: Controller + Route

`app/controllers/visited_links_controller.rb`:
- Inherits `ApplicationController` — `authenticate_user!` and `protect_from_forgery` are inherited globally; no override needed
- Single `create` action: calls `VisitedLink.record!(current_user, params[:url])` then `head :no_content`
- No view, no redirect, no flash

`config/routes.rb`:
- Added `resources :visited_links, only: [:create]` alongside existing resource declarations
- Route: `POST /visited_links(.:format) → visited_links#create`
- Route helper: `visited_links_path`

### Task 2: Cucumber Hook + Integration Tests

`features/support/hooks.rb`:
- Added `VisitedLink.delete_all` on the line immediately after `XAccount.delete_all` in the global `Before` block
- Prevents visited-state leakage across Cucumber scenarios from Phase 84 onward

`test/controllers/visited_links_controller_test.rb` — 5 tests:
- `test_successful_create`: sign_in → POST → 204 + VisitedLink.count increments by 1
- `test_idempotent_create`: two POSTs with same URL → 204 each, count stays at 1 (upsert idempotency)
- `test_unauthenticated_redirects_to_sign_in`: no sign_in → redirect to new_user_session_path (Devise default)
- `test_url_stored_normalized`: POST with fragment `#section` → stored URL has fragment stripped
- `test_routing_post_visited_links`: assert_routing confirms `POST /visited_links → visited_links#create`

## Deviations from Plan

None — plan executed exactly as written. The unauthenticated response is redirect (not 401) which matches the plan's explicitly allowed alternative: "if Devise redirects to sign_in path, assert_redirected_to new_user_session_path is also acceptable".

## Verification

- `bin/rails routes | grep visited_links` → `visited_links POST /visited_links(.:format) visited_links#create`
- `bin/rails test test/controllers/visited_links_controller_test.rb` → 5 runs, 18 assertions, 0 failures, 0 errors
- `grep 'VisitedLink.delete_all' features/support/hooks.rb` → 1 match
- `bin/rails test` → 434 runs, 1975 assertions, 0 failures, 0 errors, 0 skips
- `bundle exec rake dad:test` → 25 scenarios, 24 passed; 1 failure is pre-existing flakiness in `features/04.ノート.feature` (different scenario fails each run, confirmed by re-runs; unrelated to this plan's changes)

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 — Controller + Route | 2d26264 | feat(84-02): add VisitedLinksController#create and resources :visited_links route |
| 2 — Hook + Tests | 3974ba9 | feat(84-02): add VisitedLink.delete_all to Cucumber hook and controller integration tests |

## Known Stubs

None — the controller delegates entirely to `VisitedLink.record!` (fully implemented in Plan 01).

## Threat Flags

None — all threats from the plan's threat model are mitigated:
- T-84-05 (unauthenticated access): `authenticate_user!` inherited from ApplicationController; tested via `test_unauthenticated_redirects_to_sign_in`
- T-84-06 (user spoofing): `current_user.id` is the trust anchor; only `params[:url]` is accepted; verified by `test_successful_create` (user_id comes from session, not params)
- T-84-07 (CSRF): `protect_from_forgery with: :exception` inherited from ApplicationController

## Self-Check: PASSED

- [x] `app/controllers/visited_links_controller.rb` — FOUND
- [x] `config/routes.rb` contains `resources :visited_links` — FOUND
- [x] `features/support/hooks.rb` contains `VisitedLink.delete_all` — FOUND
- [x] `test/controllers/visited_links_controller_test.rb` — FOUND
- [x] Commit 2d26264 — FOUND
- [x] Commit 3974ba9 — FOUND
