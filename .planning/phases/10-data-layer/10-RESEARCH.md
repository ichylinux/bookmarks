# Phase 10: Data Layer — Research

**Researched:** 2026-04-30
**Domain:** Rails 8.1 / ActiveRecord / MySQL data modeling — `notes` table + `Note` model + routes scaffold
**Confidence:** HIGH

## Summary

Phase 10 is a textbook Rails data-layer phase tightly constrained by existing project precedent. The `Bookmark` / `Todo` / `Feed` / `Calendar` models supply nearly verbatim templates — `Note` should mirror them with one deliberate departure: a composite index on `(user_id, created_at)` (older tables lack indexes; this is the modern default agreed in CONTEXT.md).

Three open questions in CONTEXT.md were resolved by reading the codebase and the `daddy` gem source:

1. **`not_deleted` lives in the `daddy` gem** (`Daddy::Models::QueryExtension`), not in app code. It is auto-included into every `ActiveRecord::Base` via a Railtie initializer. No model needs to define it; **`Note` will inherit it automatically.** Same is true for `destroy_logically!` (from `Daddy::Models::CrudExtension`).
2. **Migration version is `[7.2]`**, NOT `[8.1]`. Every migration in `db/migrate/` from 2024–2026 inherits from `ActiveRecord::Migration[7.2]`, including the most recent (`20260429025517_set_modern_theme_for_non_simple_users.rb`). The schema.rb header uses `[8.1]`, but project convention for new migrations is `[7.2]`.
3. **`notes.yml` fixture is required** — every other model has a YAML fixture (`bookmarks.yml`, `todos.yml`, `calendars.yml`, `feeds.yml`, `portals.yml`, `preferences.yml`, `users.yml`). Phase 10 should ship at least an empty `notes.yml` (`{}` or a header comment) so Rails fixture loading does not break for downstream phases (especially Phase 11 controller tests).

A correction to CONTEXT.md: the `Crud::ByUser` concern lives at **`app/models/crud/by_user.rb`** (not `app/models/concerns/crud/by_user.rb` as CONTEXT.md states). The `Crud` namespace is a top-level model module, not a `Concerns` subdirectory.

**Primary recommendation:** Mirror `Todo` for the model shape, mirror `Bookmark#destroy_logically!` for the soft-delete override, mirror the most recent migration files for the migration class header, add a fresh empty `notes.yml`, and add a single composite index. Do not introduce a foreign-key constraint, `default_scope`, or any new dependency.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **`body` column:** `text`, `null: false`, `validates :body, presence: true`, `validates :body, length: { maximum: 4000 }`, with `before_validation { body&.strip! }` so whitespace-only fails presence.
- **`user_id` column:** `t.integer :user_id, null: false` — no DB-level FK constraint. Rails-layer integrity only (matches every other table).
- **Composite index:** `add_index :notes, [:user_id, :created_at]`.
- **Ordering:** `scope :recent, -> { order(created_at: :desc) }` on `Note`. Do NOT use `default_scope`.
- **Soft-delete:** `t.boolean :deleted, null: false, default: false`. Override `destroy` (not `destroy_logically!`) on `Note` to call `update!(deleted: true)`, mirroring `Bookmark`.
- **User association:** `User.has_many :notes, dependent: :destroy`.
- **Routes:** `resources :notes, only: [:create, :destroy]` in `config/routes.rb`.
- **Authorization:** `include Crud::ByUser`.
- **Trace:** NOTE-03 (per-user data isolation).

### Claude's Discretion
- Exact migration timestamp (use a fresh UTC `YYYYMMDDHHMMSS`).
- Exact placement of `resources :notes` line in `config/routes.rb` (a sensible group with the other resource declarations).
- Whether `notes.yml` is empty (`{}`) or has a header comment — both work.

### Deferred Ideas (OUT OF SCOPE)
- Foreign-key constraint on `user_id` across the codebase — schema-wide modernization, not this phase.
- Note tagging, categories, rich text — explicitly out of scope per REQUIREMENTS.md.
- Controller actions, request handling, auth guards — Phase 11.
- Tab UI, theme isolation — Phase 12.
- View partials, integration tests, list rendering — Phase 13.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTE-03 | Notes are isolated per user — no user can read another user's notes | `belongs_to :user` + `include Crud::ByUser` (overrides `readable_by?`/`updatable_by?`/`deletable_by?` to require `user.id == user_id`). Phase 11 controller will scope queries via `current_user.notes`. The data layer’s job here is to make ownership representable and authorizable; enforcement happens in Phase 11. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `notes` table schema | Database / Storage | — | Persistence layer — schema is owned by ActiveRecord migration |
| `Note` model (validations, associations, scope, soft-delete override) | API / Backend (model) | — | Domain logic lives in models per project convention (no service objects) |
| `User.has_many :notes` | API / Backend (model) | — | Inverse association declared on `User` |
| `resources :notes` route | API / Backend (routing) | — | Phase 10 only declares the routes; controllers come in Phase 11 |
| `notes.yml` fixture | Test infrastructure | — | Required so Rails fixture loader does not break downstream phases |

## Standard Stack

This phase introduces **zero new dependencies** (locked decision in STATE.md). Everything used is already in the Gemfile.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails / ActiveRecord | 8.1.3 [VERIFIED: `Gemfile.lock`, `config/application.rb` `config.load_defaults 8.1`] | Migrations, model, validations, associations, scopes | Project framework |
| `daddy` gem | 0.12.0 [VERIFIED: `Gemfile.lock`, gem source at `~/.rbenv/.../daddy-0.12.0/`] | Provides auto-included `not_deleted` scope and `destroy_logically!` method on every AR model | In-house gem already wired via `Daddy::Rails::Railtie` |
| MySQL (mysql2 adapter) | `>= 0.4.4, < 0.6.0` [VERIFIED: `Gemfile.lock`] | Storage. `text` column is MySQL `TEXT` (max 65,535 bytes ≈ 64 KB). | Project DB |

### Supporting (already present)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Minitest | 5.x [VERIFIED: STACK.md] | Unit tests for the model (Phase 11 will add controller tests) | Optional in Phase 10 — no controller yet, but a model spec for validations is reasonable |
| `app/models/crud/by_user.rb` | in-tree | Authorization predicates `readable_by?`/`updatable_by?`/`deletable_by?` | Required by success criteria — `include Crud::ByUser` |

### Alternatives Considered
| Instead of | Could Use | Why we don't |
|------------|-----------|--------------|
| `t.integer :user_id, null: false` | `t.references :user, foreign_key: true` | Would split schema convention; CONTEXT.md explicitly defers FK adoption |
| `default_scope { order(created_at: :desc) }` | `scope :recent, ...` | `default_scope` leaks into counts, joins, fixtures — CONTEXT.md explicitly forbids it |
| Separate `created_at` index | Composite `(user_id, created_at)` | Composite covers `current_user.notes.recent` exactly; single-column index would still require sort |
| Hard-delete (`DELETE FROM`) | Soft-delete via `deleted` boolean | Project precedent (`Bookmark`, `Todo`, `Feed`, `Portal`, `Calendar`); `User`'s `dependent: :destroy` triggers per-record `destroy` which we override to soft-delete |

**Installation:** None. No new gems.

**Version verification:** Skipped — no new packages.

## Architecture Patterns

### System Architecture (Phase 10 scope only)

```
config/routes.rb ──── declares ────► resources :notes (create, destroy)
                                               │
                                               │ (Phase 11 will wire to controller)
                                               ▼
db/migrate/<ts>_create_notes.rb ── creates ──► notes table (MySQL)
                                                ├── id (pk)
                                                ├── user_id (int, not null, indexed via composite)
                                                ├── body (text, not null)
                                                ├── deleted (bool, not null, default false)
                                                ├── created_at, updated_at
                                                └── INDEX (user_id, created_at)
                                                          │
                              ┌───────────────────────────┘
                              ▼
app/models/note.rb ──── represents ──► notes row
   │
   ├── belongs_to :user
   ├── include Crud::ByUser            (overrides readable_by? etc. with ownership check)
   ├── validates :body, presence + length(<= 4000)
   ├── before_validation { body&.strip! }
   ├── scope :recent, -> { order(created_at: :desc) }
   ├── def destroy; update!(deleted: true); end   (soft-delete override)
   │
   └── (inherited via daddy gem on every AR::Base)
       ├── .not_deleted (class scope)
       └── #destroy_logically!  (NOTE: we don't call this; we override destroy directly)

app/models/user.rb ──── adds ──► has_many :notes, dependent: :destroy
test/fixtures/notes.yml ──── empty stub for fixture loader
```

### Component Responsibilities

| File | Responsibility |
|------|---------------|
| `db/migrate/<ts>_create_notes.rb` | Create table with all columns, defaults, and composite index |
| `app/models/note.rb` | Define associations, validations, scopes, soft-delete override |
| `app/models/user.rb` (edit) | Add `has_many :notes, dependent: :destroy` |
| `config/routes.rb` (edit) | Add `resources :notes, only: [:create, :destroy]` |
| `test/fixtures/notes.yml` | Empty stub so fixture loading does not break |
| `db/schema.rb` | Auto-regenerated by `rails db:migrate` — should not be hand-edited |

### Recommended Project Structure (no new directories)
```
app/models/
├── note.rb                    # NEW — model class
└── crud/by_user.rb            # EXISTING — already defines Crud::ByUser
db/migrate/
└── <YYYYMMDDHHMMSS>_create_notes.rb  # NEW — migration
test/fixtures/
└── notes.yml                  # NEW — empty stub
config/
└── routes.rb                  # EDIT — add resources :notes line
app/models/
└── user.rb                    # EDIT — add has_many :notes
```

### Pattern 1: Migration shape (mirror `20131015031309_create_todos.rb` + composite index)

```ruby
# Source: project convention — see db/migrate/20260420000000_*.rb (most recent uses [7.2])
#         db/migrate/20131015031309_create_todos.rb (column shape)
class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.integer :user_id, null: false
      t.text    :body,    null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end

    add_index :notes, [:user_id, :created_at]
  end
end
```

**Migration version note:** All migrations from 2024 onward use `ActiveRecord::Migration[7.2]`. The schema.rb header uses `[8.1]` (auto-generated by Rails 8.1). Recommendation: **use `[7.2]`** to match the convention every other migration follows. Using `[8.1]` would be the only such migration in the repo and would surface no benefit (no Rails 8.1-only migration features are needed here).

### Pattern 2: Model shape (mirror `Todo` + add `Bookmark`-style soft-delete + `recent` scope)

```ruby
# Source: app/models/todo.rb (base shape)
#         app/models/bookmark.rb:22-24 (soft-delete override)
class Note < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 4000 }

  scope :recent, -> { order(created_at: :desc) }

  def destroy
    update!(deleted: true)
  end

  private

  def strip_body
    body&.strip!
  end
end
```

Note: `ActiveRecord::Base` vs `ApplicationRecord` — the codebase is mixed (`Todo`, `Bookmark`, `Calendar` use `ActiveRecord::Base`; `Feed`, `Portal` use `ApplicationRecord`). Either works. Slight preference for `ApplicationRecord` (Rails-idiomatic, what generators emit), but `ActiveRecord::Base` matches the closest analog (`Todo`). Planner should pick one and document it.

### Pattern 3: User association edit

```ruby
# Add to app/models/user.rb (location: near other has_many declarations, after has_many :portals)
has_many :notes, dependent: :destroy
```

### Pattern 4: Routes edit

```ruby
# Add to config/routes.rb — group with other resource declarations
# (e.g., near `resources :todos do ... end` block — likely above or below)
resources :notes, only: [:create, :destroy]
```

### Pattern 5: Fixture stub

```yaml
# test/fixtures/notes.yml
# Phase 10: empty stub so Rails fixture loader does not break.
# Real fixtures will be added by Phase 11 / 13 tests.
```

(An empty file with just the comment is valid YAML for Rails fixtures — equivalent to `{}`.)

### Anti-Patterns to Avoid

- **`default_scope { order(created_at: :desc) }`** — leaks into counts, joins, and fixture loading. Use the explicit `:recent` scope instead.
- **DB-level `foreign_key: true`** — splits schema convention; deferred to a future phase per CONTEXT.md.
- **Defining a per-model `scope :not_deleted`** — already provided by `daddy` gem on every AR::Base; defining it again would shadow with identical behavior (harmless but pointless).
- **Defining `destroy_logically!`** — also provided by `daddy`. Bookmark redefines it but Note's success criteria asks for `destroy` to soft-delete (so Phase 11's `:destroy` route just works). Override `destroy` directly per CONTEXT.md.
- **Hand-rolled `validates_presence_of :user`** — modern Rails (since 5+) makes `belongs_to :user` validate presence by default. CONTEXT.md does not require it. (Only `Calendar` includes a separate `validates :user, presence: true` — a legacy artifact.)
- **Editing `db/schema.rb` by hand** — auto-generated. Run `rails db:migrate` and let Rails write it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `not_deleted` scope | `scope :not_deleted, -> { where(deleted: false) }` | Inherited from `Daddy::Models::QueryExtension` (auto-included on every AR::Base) | Already provided gem-wide |
| `destroy_logically!` | Custom method | Inherited from `Daddy::Models::CrudExtension` | Already provided gem-wide |
| Soft-delete framework | `paranoia`, `discard`, `acts_as_paranoid` gems | Project's existing `deleted` boolean + override pattern | Zero-deps constraint; existing precedent works |
| Validation DSL | Custom presence/length checks | `validates :body, presence: true, length: { maximum: N }` | Standard Rails validation API |
| Composite-index DSL | Raw SQL `CREATE INDEX` | `add_index :notes, [:user_id, :created_at]` | ActiveRecord migration native |

**Key insight:** The `daddy` gem (in-house) is already doing the soft-delete heavy lifting. The only reason `Note#destroy` needs an override is because Rails' `dependent: :destroy` from `User.has_many :notes` will call `destroy` (not `destroy_logically!`), and we want that call path to soft-delete rather than hard-delete. This is the same reason `Bookmark` has the override.

## Runtime State Inventory

> Not applicable — this is a greenfield phase (creating a new table/model). There is no pre-existing `notes` data, no migration to back-fill, no rename. STACK.md and CONVENTIONS.md confirm no existing `Note` model in the tree (`grep -rn "class Note" app/models/` returns nothing).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `notes` table does not yet exist (verified via `grep -i notes db/schema.rb`) | None |
| Live service config | None — no external service references `notes` | None |
| OS-registered state | None — no daemons, schedulers, or pm2 entries reference `notes` | None |
| Secrets/env vars | None | None |
| Build artifacts | None — no compiled artifacts depend on `Note` | None |

## Common Pitfalls

### Pitfall 1: Migration version mismatch
**What goes wrong:** Using `ActiveRecord::Migration[8.1]` instead of `[7.2]`.
**Why it happens:** Rails 8.1 generators may emit `[8.1]`; researchers may "upgrade" to match the framework version.
**How to avoid:** Match project convention — use `[7.2]`. All recent migrations confirm this.
**Warning signs:** A migration filename in `db/migrate/` whose class header is the only `[8.1]` in the directory.

### Pitfall 2: `default_scope` order leak
**What goes wrong:** `Note.count` returns wrong value or fixtures loading triggers spurious ORDER BY.
**Why it happens:** `default_scope { order(...) }` applies to every implicit query.
**How to avoid:** Use named `scope :recent` and call it explicitly. CONTEXT.md mandates this.
**Warning signs:** `default_scope` keyword appearing in `note.rb`.

### Pitfall 3: `before_validation` strip mutates frozen string
**What goes wrong:** `body&.strip!` raises `FrozenError` if `body` was assigned a frozen string.
**Why it happens:** `String#strip!` mutates in-place; some Ruby versions return frozen strings from literals.
**How to avoid:** Use `body = body.strip if body` (non-bang assignment) for safety, or accept that controller-supplied params strings are not frozen and `strip!` works. Either is fine for this codebase. Recommendation: keep `strip!` to match CONTEXT.md exactly; if frozen-string issues appear, revisit.
**Warning signs:** `FrozenError` in tests when params come from sources that produce frozen strings.

### Pitfall 4: Forgetting `notes.yml` breaks downstream tests
**What goes wrong:** Phase 11 controller test boots, Rails loads fixtures, missing `notes.yml` is silently OK in some setups but causes loading errors in others — and the moment any test references a notes fixture, it fails.
**Why it happens:** Rails fixtures are conventionally one-per-table; the loader does not strictly require all tables to have fixtures, but downstream code that calls `notes(:foo)` will fail.
**How to avoid:** Ship an empty `test/fixtures/notes.yml` in Phase 10 so subsequent phases can append fixtures without scaffolding.

### Pitfall 5: `dependent: :destroy` calls `destroy` not `destroy_logically!`
**What goes wrong:** Without the `Note#destroy` override, deleting a `User` would hard-delete their notes — inconsistent with `Bookmark`/`Todo`/`Feed` precedent.
**Why it happens:** Rails' `dependent: :destroy` invokes `record.destroy`, not `record.destroy_logically!`.
**How to avoid:** Override `destroy` per `Bookmark` (CONTEXT.md mandates this).
**Warning signs:** A note row vanishing from the DB instead of having `deleted: true`.

### Pitfall 6: `Crud::ByUser` path confusion
**What goes wrong:** Trying to load `app/models/concerns/crud/by_user.rb` (CONTEXT.md's path) — file doesn't exist there.
**Why it happens:** CONTEXT.md says `app/models/concerns/crud/by_user.rb`; the actual location is `app/models/crud/by_user.rb`.
**How to avoid:** Use `include Crud::ByUser` — Rails autoloading resolves `Crud::ByUser` from either path. The `include` statement does not depend on the path.
**Warning signs:** A planner trying to "fix" the concern path or move the file.

## Code Examples

### Migration (full file)
```ruby
# Source: db/migrate/20131015031309_create_todos.rb (shape)
#         db/migrate/20260420000000_*.rb (Migration[7.2] header)
# File: db/migrate/<YYYYMMDDHHMMSS>_create_notes.rb
class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.integer :user_id, null: false
      t.text    :body,    null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end

    add_index :notes, [:user_id, :created_at]
  end
end
```

### Note model (full file)
```ruby
# Source: app/models/todo.rb (shape)
#         app/models/bookmark.rb:22-24 (destroy override pattern)
# File: app/models/note.rb
class Note < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 4000 }

  scope :recent, -> { order(created_at: :desc) }

  def destroy
    update!(deleted: true)
  end

  private

  def strip_body
    body&.strip!
  end
end
```

### User edit (snippet)
```ruby
# File: app/models/user.rb — add near has_many :portals
has_many :notes, dependent: :destroy
```

### Routes edit (snippet)
```ruby
# File: config/routes.rb — add near resources :todos
resources :notes, only: [:create, :destroy]
```

### Empty fixture
```yaml
# File: test/fixtures/notes.yml
# Phase 10: empty stub so the fixture loader does not break.
# Phase 11 / 13 will populate this as tests require.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Older tables in this app: no indexes, hard-delete | New tables: composite indexes, soft-delete, validations | Implicit in CONTEXT.md decisions | New tables follow the modern pattern even though existing ones are not retro-fitted |
| `form_for` ERB style | Phase 11+ should use `form_with(local: true)` per STATE.md | v1.3 milestone | Not Phase 10's concern but worth noting for Phase 11 planner |

**Deprecated/outdated within this codebase:**
- `validates :user, presence: true` (only `Calendar` uses it; modern `belongs_to` validates presence by default since Rails 5).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Using `ActiveRecord::Base` (vs `ApplicationRecord`) is acceptable for `Note` | Pattern 2 | Low — both work; planner can pick. Project is mixed. |
| A2 | `before_validation { body&.strip! }` is functionally equivalent to a `before_validation :strip_body` private method calling `body&.strip!` | Pattern 2 | Negligible — both do the same thing. Used the named-method form for grep-ability. |
| A3 | An empty `notes.yml` (header comment only) is valid — equivalent to `{}` | Pattern 5 | Low — Rails fixture loader treats empty YAML as no fixtures, which is the desired Phase 10 state. |

All other claims are verified against the codebase or gem source.

## Open Questions

All three open questions from CONTEXT.md are now resolved:

1. ✅ `not_deleted` scope location — provided by `daddy` gem `Daddy::Models::QueryExtension` auto-included on every `ActiveRecord::Base`. **No per-model definition needed.** [VERIFIED: `~/.rbenv/.../daddy-0.12.0/lib/daddy/models/query_extension.rb` and `daddy/rails/railtie.rb`]
2. ✅ Migration version — `ActiveRecord::Migration[7.2]`. [VERIFIED: every migration from 2024–2026 in `db/migrate/`]
3. ✅ Fixture file — yes, create empty `test/fixtures/notes.yml`. [VERIFIED: every other model has a fixture; downstream phases will need it]

No remaining open questions for the planner.

## Environment Availability

> Phase 10 is code/config + a migration. The migration runs locally against MySQL. Listing only the dependencies relevant to executing this phase.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | Migration + tests | Assumed ✓ | 3.4.x [VERIFIED: `.ruby-version` = 3.4.9] | — |
| Rails | Migration + model | Assumed ✓ | 8.1.3 [VERIFIED: Gemfile.lock] | — |
| MySQL (mysql2) | Migration target | Assumed ✓ | mysql2 0.5.x [VERIFIED: Gemfile.lock] | — |
| `daddy` gem | `not_deleted` / `destroy_logically!` | ✓ | 0.12.0 [VERIFIED: Gemfile.lock + gem source on disk] | — |
| `bin/rails db:migrate` | Apply migration | Assumed ✓ | — | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest 5.x (Rails default) [VERIFIED: STACK.md] |
| Config file | `test/test_helper.rb` (standard Rails) |
| Quick run command | `bin/rails test test/models/note_test.rb` (file does not yet exist; Wave 0 if model spec is desired) |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTE-03 | Authorization predicates respect ownership (`readable_by?(other_user)` returns false) | unit (model) | `bin/rails test test/models/note_test.rb` | ❌ Wave 0 (optional) |
| Phase 10 SC#1 | `notes` table exists with correct schema after migrate | manual / `db:migrate` exit code | `bin/rails db:migrate` && `bin/rails db:schema:dump` (or check `db/schema.rb`) | ✅ — `db/schema.rb` writeback |
| Phase 10 SC#2 | `Note` model has correct associations + validations | unit (model) | `bin/rails test test/models/note_test.rb` | ❌ Wave 0 (optional) |
| Phase 10 SC#3 | `User.has_many :notes, dependent: :destroy` | unit (User model) | `bin/rails test test/models/user_test.rb` | Likely ❌ for this assertion |
| Phase 10 SC#4 | Routes registered | rake | `bin/rails routes \| grep notes` | ✅ — Rails built-in |
| Phase 10 SC#5 | `db:migrate` clean | smoke | `bin/rails db:migrate` exit code 0 | ✅ — Rails built-in |

**Note:** A formal `note_test.rb` is **not strictly required** by Phase 10's success criteria (which the controller phase will exercise). The planner should decide whether to bundle a minimal model test (validations + ownership) into Phase 10 or defer to Phase 11. Recommendation: include a short `note_test.rb` in Phase 10 — it's cheap and locks down the validation contract.

### Sampling Rate
- **Per task commit:** `bin/rails test test/models/note_test.rb` (if test added) + `bin/rails routes | grep notes`
- **Per wave merge:** `bin/rails test` (full suite)
- **Phase gate:** `bin/rails db:migrate` clean + full Minitest suite green + `db/schema.rb` reflects new table

### Wave 0 Gaps
- [ ] `test/fixtures/notes.yml` — empty stub (REQUIRED — downstream phases break without it)
- [ ] `test/models/note_test.rb` — model unit test (OPTIONAL but recommended)

*Existing test infrastructure (Minitest, fixture loader, `test_helper.rb`) is already in place.*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (Phase 11 will guard `notes#create` with Devise) | Devise (existing) |
| V3 Session Management | no | Devise session (existing) |
| V4 Access Control | **yes** — NOTE-03 demands per-user data isolation | `Crud::ByUser` predicates + Phase 11 controller scoping via `current_user.notes` |
| V5 Input Validation | **yes** — `body` length + presence + whitespace strip | Rails `validates` DSL |
| V6 Cryptography | no | — |

### Known Threat Patterns for Rails 8.1 + ActiveRecord

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mass-assignment of `user_id` | Tampering / Elevation | Strong params (Phase 11 — never permit `:user_id`); merge from `current_user.id` server-side per STATE.md |
| IDOR (read/destroy other user's note) | Information Disclosure / Tampering | `Crud::ByUser`'s `readable_by?` / `deletable_by?` checked in controller `before_action`; Phase 11 enforces. Phase 10 only provides the predicates. |
| SQL injection via `body` | Tampering | None needed — body is bound parameter via ActiveRecord; rendering encoding handled by ERB in Phase 13 |
| XSS via stored body | Tampering / Repudiation | Phase 13 must render via ERB's default HTML escaping (`<%= note.body %>`) — not Phase 10's concern, but flagging for downstream |
| Unbounded body size | DoS | `length: { maximum: 4000 }` validation (CONTEXT.md decision) |
| Whitespace-only body bypass | Input Validation gap | `before_validation { body&.strip! }` + `presence: true` (CONTEXT.md decision) |

Phase 10 implements V4 + V5 mitigations at the model layer. Controller-layer enforcement is Phase 11.

## Sources

### Primary (HIGH confidence)
- `app/models/todo.rb` — analog model shape (closest match)
- `app/models/bookmark.rb:22-24` — `destroy_logically!` override (we adapt to `destroy` override per CONTEXT.md)
- `app/models/crud/by_user.rb` — authorization concern (note: lives in `crud/`, NOT `concerns/crud/`)
- `app/models/user.rb` — where `has_many :notes` will be added
- `db/migrate/20131015031309_create_todos.rb` — column shape
- `db/migrate/20260429025517_set_modern_theme_for_non_simple_users.rb` — most recent migration; confirms `[7.2]` header
- `db/migrate/20260420000000_rename_open_bookmarks_in_new_tab_to_open_links_in_new_tab.rb` and four other 2024-2026 migrations — all `[7.2]`
- `db/schema.rb` — confirms table structure conventions (utf8mb4, no FKs)
- `config/routes.rb` — current routes layout
- `Gemfile.lock` — Rails 8.1.3, daddy 0.12.0
- `~/.rbenv/.../daddy-0.12.0/lib/daddy/models/query_extension.rb` — `not_deleted` definition
- `~/.rbenv/.../daddy-0.12.0/lib/daddy/models/crud_extension.rb` — `destroy_logically!` definition
- `~/.rbenv/.../daddy-0.12.0/lib/daddy/rails/railtie.rb` — auto-include on `ActiveRecord::Base`
- `test/fixtures/*.yml` — existing fixture files confirm the one-per-table convention
- `.planning/codebase/STACK.md` and `CONVENTIONS.md` — verified current

### Secondary (MEDIUM confidence)
- None — all decisions resolved by direct codebase inspection.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified directly against `Gemfile.lock` and gem source on disk
- Architecture: HIGH — every pattern has a verbatim analog in-tree
- Pitfalls: HIGH — mostly precedent-driven; the only novel risk is the migration-version inconsistency, also verified
- Open questions: HIGH — all three resolved by reading source

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (30 days — codebase is stable, no upstream framework churn expected in this window)
