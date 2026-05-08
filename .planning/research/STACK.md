# Technology Stack - Guest Root Redirect to Landing

**Project:** Bookmarks  
**Scope:** v1.13 guest entry routing (`/` -> `/landing` for unauthenticated users)  
**Researched:** 2026-05-08

## Keep
- Rails 8.1 + Devise authentication flow
- Server-rendered controllers/views (no SPA migration)
- Existing `LandingController#show` and localized landing copy
- Existing test stack: Minitest + Cucumber + ESLint gate

## Change
1. Route/controller behavior for `root` based on auth state.
2. Guard locale-safe behavior for entry routing and landing CTAs.
3. Add regression tests for guest vs signed-in entry path.

## Recommended Implementation Direction
- Keep `root` path as single entry endpoint and branch by auth state in server-side logic.
- Preserve existing signed-in dashboard action (`WelcomeController#index`) as-is.
- Redirect only unauthenticated requests to `landing_path`.
- Keep `/landing` public via `skip_before_action :authenticate_user!`.

## What NOT to Add
- New frontend frameworks or client-side routing
- URL-parameter locale switching (`?locale=...`)
- News feature implementation in this milestone

## Verification Gate
- `yarn run lint`
- `bin/rails test`
- `bundle exec rake dad:test` (re-run once if known flake appears)
