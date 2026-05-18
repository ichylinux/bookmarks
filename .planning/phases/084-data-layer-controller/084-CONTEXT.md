# Phase 84: Data Layer + Controller - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Server-side infrastructure for recording and retrieving visited URLs per user: `visited_links` migration, `VisitedLink` model with `record!`/`urls_for`/`normalize_url`, `POST /visited_links` endpoint, and Cucumber `Before` hook update to prevent visited-state leakage between scenarios.

</domain>

<decisions>
## Implementation Decisions

### Route & Controller Design
- Route: `resources :visited_links, only: [:create]` — REST-consistent with all other controllers in the codebase
- Auth: `before_action :authenticate_user!` — standard Devise gate, matches every existing controller
- Response: `head :no_content` (204) on success; unauthenticated requests yield 401 via Devise automatically

### Model Implementation
- `record!(user, url)`: `VisitedLink.upsert({ user_id: user.id, url: normalized, visited_at: Time.current }, unique_by: :index_visited_links_on_user_id_and_url)` — atomic insert-or-ignore, no TOCTOU race
- `normalize_url(url)`: strips fragment (`url.sub(/#.*$/, '')`) — no query-string normalization by design
- `urls_for(user)`: `where(user_id: user.id).pluck(:url).to_set` — single query, returns Ruby Set of normalized URLs
- Model validates `url` presence (blank guard only); DB column definition enforces length

### Cucumber Test Isolation
- Add `VisitedLink.delete_all` to the global `Before` hook in `features/support/hooks.rb` (alongside existing `MastodonAccount.delete_all` and `XAccount.delete_all`)

### Claude's Discretion
- Migration timestamp, index name style, controller file name — all at Claude's discretion following existing codebase conventions

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/models/concerns/crud/by_user.rb` — Crud::ByUser concern (scopes by user_id); may or may not be applicable to VisitedLink
- `ApplicationRecord` — base class for all models
- Existing `upsert` usage: `XAccount.refresh_cache_from_items!` uses `first_or_initialize + save!` (not Rails upsert); `VisitedLink` will be the first model to use `VisitedLink.upsert()`

### Established Patterns
- Controller auth: `before_action :authenticate_user!` used by all controllers that serve authenticated content
- Migration naming: `YYYYMMDDHHMMSS_create_<table>.rb` (see recent migrations in `db/migrate/`)
- Unique index naming: e.g., `add_index :x_accounts, [:user_id, :x_user_id], unique: true` — descriptive snake_case
- Controller structure: `before_action` for resource loading, `current_user` from Devise, redirect after mutation
- Strong params: merge `user_id: current_user.id` server-side; never in permitted params

### Integration Points
- Routes: `config/routes.rb` — add `resources :visited_links, only: [:create]` inside the `draw` block
- Before hook: `features/support/hooks.rb` line 6–7 area — add `VisitedLink.delete_all` to global `Before` block
- Controller: `app/controllers/visited_links_controller.rb` (new file)
- Model: `app/models/visited_link.rb` (new file)
- Migration: `db/migrate/TIMESTAMP_create_visited_links.rb` (new file)

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond what's in REQUIREMENTS.md and STATE.md — implementation follows established codebase patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
