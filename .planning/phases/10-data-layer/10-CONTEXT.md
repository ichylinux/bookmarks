---
phase: 10
phase_name: Data Layer
phase_slug: data-layer
milestone: v1.3
created: 2026-04-30
status: ready-to-plan
---

# Phase 10 Context — Data Layer

## Domain

Establish the persistence foundation for the Quick Note Gadget: a `notes` table, a `Note` model with user ownership and validation, and the routes scaffold. No controller logic, no views — the planner for Phase 11+ relies on this being correct and conventional before any request handling is touched.

## Locked Requirements (from ROADMAP.md success criteria)

1. `db/schema.rb` contains a `notes` table with `user_id`, `body` (text, not null), `created_at`, `updated_at`, and a composite index on `(user_id, created_at)`.
2. `Note` model has `belongs_to :user`, `validates :body, presence: true`, and `include Crud::ByUser`.
3. `User` model has `has_many :notes, dependent: :destroy`.
4. `resources :notes, only: [:create, :destroy]` is present in `config/routes.rb`.
5. `rails db:migrate` completes cleanly and the schema reflects the new table.

Requirement traced: **NOTE-03** (per-user data isolation).

## Decisions

### body column
- **Type:** `text` (MySQL TEXT — up to 65535 bytes, plenty for quick notes).
- **NOT NULL:** yes (`null: false`).
- **Length validation:** `validates :body, length: { maximum: 4000 }` — soft cap well below DB limit; protects forms and rendering from pathological inputs.
- **Whitespace handling:** `before_validation { body&.strip! }` so a textarea containing only whitespace fails the `presence: true` check rather than getting stored as a blank record.
- **Presence:** `validates :body, presence: true` (already in success criteria).

### user_id column
- **Match existing pattern:** `t.integer :user_id, null: false` — no DB-level foreign key constraint.
- Rationale: `bookmarks`, `todos`, `feeds`, `portals`, `calendars` all use the same shape. Introducing `foreign_key: true` only here would split the schema convention and add migration friction without a near-term win. Referential integrity is enforced at the Rails layer via `belongs_to :user` and `User.has_many :notes, dependent: :destroy`.

### Composite index
- `add_index :notes, [:user_id, :created_at]` — supports `current_user.notes.recent` (the dominant query for Phase 13's reverse-chronological list) without a separate sort.
- This is a deliberate departure from older tables (which lack indexes) — accept it as the modern default for new tables.

### Ordering implementation
- Add `scope :recent, -> { order(created_at: :desc) }` on `Note`.
- **Do NOT use `default_scope`** — it leaks into unrelated queries (counts, joins, fixtures) and historically causes surprises.
- Callers will write `current_user.notes.recent` — explicit and greppable.

### Soft-delete pattern (matches Todo / Bookmark / Feed / Portal)
- Migration adds `t.boolean :deleted, null: false, default: false`.
- Note model overrides `destroy` to soft-delete (mirroring `Bookmark#destroy` → `update!(deleted: true)`). The `routes` `:destroy` action will hit this override in a future phase.
- A `not_deleted` scope is referenced throughout the codebase (`Todo.not_deleted`, `Calendar.not_deleted`, `Portal.not_deleted`, `Feed`/`Bookmark` use `where(deleted: false)`). **Research action:** locate where `not_deleted` is defined (it is not visible in `app/models/`, `app/models/concerns/`, `lib/`, `config/initializers/`). The planner must determine whether it is a per-model `scope :not_deleted, -> { where(deleted: false) }` that needs to be added to `Note`, or whether it lives in a shared concern that should be included.
- `User.has_many :notes, dependent: :destroy` — when a user is destroyed, this calls `Note#destroy`, which (with the override) soft-deletes each note. This matches how `Bookmark` behaves and is the existing-codebase precedent.

## Code Context

### Reusable assets
- `app/models/concerns/crud/by_user.rb` — provides `readable_by?` / `updatable_by?` / `deletable_by?`. Pure authorization helpers; no scoping or validations. Already required by success criteria.
- `app/models/todo.rb` — closest analog. Same shape: `include Crud::ByUser`, `belongs_to :user`. Use as the reference for `Note` structure.
- `app/models/bookmark.rb:23` — overrides `destroy` with `update!(deleted: true)`. Use as the reference for soft-delete implementation in `Note#destroy`.
- `db/migrate/20131015031309_create_todos.rb` — pattern reference for the migration shape (integer user_id, null: false; deleted boolean default false; timestamps). Note: the new migration adds the composite index that older tables lack.

### Patterns to follow
- Migration filename: `db/migrate/YYYYMMDDHHMMSS_create_notes.rb` (use a fresh UTC timestamp at execution time).
- Test fixtures: existing models have YAML fixtures under `test/fixtures/` — Phase 11+ tests will need `notes.yml`. Phase 10 should create at least an empty `notes.yml` so Rails fixture loading does not break for downstream tests.

## Canonical Refs

- `.planning/ROADMAP.md` — Phase 10 success criteria (lines 62–72)
- `.planning/REQUIREMENTS.md` — NOTE-03 (per-user isolation)
- `.planning/PROJECT.md` — milestone scope, locked decisions
- `.planning/STATE.md` — accumulated v1.3 decisions ("zero new deps", "user_id from current_user.id", "Crud::ByUser pattern")
- `.planning/codebase/STACK.md`, `.planning/codebase/CONVENTIONS.md` — Rails 8.1 / MySQL conventions
- `app/models/concerns/crud/by_user.rb` — authorization concern
- `app/models/todo.rb` — analog model
- `app/models/bookmark.rb` — soft-delete `destroy` override pattern
- `db/migrate/20131015031309_create_todos.rb` — migration shape reference
- `config/routes.rb` — where `resources :notes, only: [:create, :destroy]` will be added

## Out of Scope (Phase 10)

- Controller actions, request handling, auth guards → **Phase 11**.
- Tab UI, theme isolation → **Phase 12**.
- View partials, integration tests, list rendering → **Phase 13**.

## Deferred Ideas (do not act on this phase)

- Foreign-key constraint on `user_id` across the whole codebase — would be a separate, schema-wide modernization phase.
- Note tagging, categories, or rich text — explicitly out of scope per `REQUIREMENTS.md`.

## Open Questions for Research / Planning

1. **`not_deleted` scope location** — find definition or confirm it is a per-model `scope :not_deleted, -> { where(deleted: false) }` that must be added to `Note`. If absent everywhere, that is itself a finding (other models may be silently broken in code paths that call `.not_deleted`).
2. **Migration version** — confirm the `ActiveRecord::Migration[X.Y]` version to inherit from (Rails 8.1 → likely `[8.1]`). Cross-check the most recent migration in `db/migrate/`.
3. **Fixture file** — confirm whether Rails fixture loader requires `notes.yml` to exist once the table is added; create an empty fixture if so to avoid breaking downstream test boots.

## Next Steps

`/gsd-plan-phase 10`
