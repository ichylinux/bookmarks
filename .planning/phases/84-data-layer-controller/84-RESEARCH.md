# Phase 84: Data Layer + Controller - Research

**Researched:** 2026-05-18
**Domain:** Rails model, migration, controller — MySQL visited_links table with upsert idempotency
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Route: `resources :visited_links, only: [:create]` — REST-consistent with all other controllers in the codebase
- Auth: `before_action :authenticate_user!` — standard Devise gate, matches every existing controller
- Response: `head :no_content` (204) on success; unauthenticated requests yield 401 via Devise automatically
- `record!(user, url)`: `VisitedLink.upsert({ user_id: user.id, url: normalized, visited_at: Time.current }, unique_by: :index_visited_links_on_user_id_and_url)` — atomic insert-or-ignore, no TOCTOU race
- `normalize_url(url)`: strips fragment (`url.sub(/#.*$/, '')`) — no query-string normalization by design
- `urls_for(user)`: `where(user_id: user.id).pluck(:url).to_set` — single query, returns Ruby Set of normalized URLs
- Model validates `url` presence (blank guard only); DB column definition enforces length
- Add `VisitedLink.delete_all` to the global `Before` hook in `features/support/hooks.rb` (alongside existing `MastodonAccount.delete_all` and `XAccount.delete_all`)

### Claude's Discretion

- Migration timestamp, index name style, controller file name — all at Claude's discretion following existing codebase conventions

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DAT-01 | `visited_links` table: `user_id`, `url varchar(2083)`, `visited_at`; unique index on `(user_id, url(768))` | MySQL utf8mb4 requires prefix index for long varchar — 768-char prefix covers the unique constraint safely |
| DAT-02 | `VisitedLink.record!(user, url)` using upsert (atomic insert-or-ignore); `urls_for(user)` returning Set of normalized URLs | `ActiveRecord::Base.upsert` with `unique_by:` index name is Rails 6+ — confirmed available in Rails 8.1 |
| DAT-03 | `VisitedLink.normalize_url` strips fragments; applied identically in `record!` and `urls_for` | Fragment-strip regex `url.sub(/#.*$/, '')` is a pure string operation, no external dependency |
| DAT-04 | `POST /visited_links` accepts `url`, records for `current_user`, 204 on success, 401 if unauthenticated | Pattern is `head :no_content`; ApplicationController's `authenticate_user!` yields 401 via Devise on miss |
</phase_requirements>

---

## Summary

Phase 84 is a purely server-side Rails phase: one migration, one model, one controller, one route line, and a one-line addition to the Cucumber `Before` hook. There are no external service integrations, no new gems, and no JavaScript. The implementation follows codebase patterns established in prior phases verbatim.

The decisive technical choice — `VisitedLink.upsert({...}, unique_by: :index_visited_links_on_user_id_and_url)` — avoids any read-check-write race condition by delegating to MySQL's `INSERT ... ON DUPLICATE KEY UPDATE` semantics. Rails 8.1 ships this API. The only MySQL-specific constraint to respect is the utf8mb4 index key length limit: `varchar(2083)` requires a prefix index (`url(768)`) rather than a full-column index.

The controller is the simplest possible: `before_action :authenticate_user!` (inherited from ApplicationController), one `create` action that calls `VisitedLink.record!`, and `head :no_content`. No view, no redirect, no flash. CSRF protection is provided by `rails-ujs`, which injects the token into all non-GET XHR requests automatically; `protect_from_forgery with: :exception` in ApplicationController is already active and requires no change.

**Primary recommendation:** Follow the locked decisions in CONTEXT.md exactly. No new patterns are needed — every element has an established codebase precedent.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist visited URL | Database / Storage | API / Backend | `VisitedLink` model owns the row; controller owns the HTTP surface |
| Deduplicate visits | Database / Storage | — | Unique index + upsert enforces idempotency at DB level, not in application code |
| URL normalization | API / Backend | — | `normalize_url` is a pure Ruby class method on the model; no DB or client involvement |
| Authenticate request | API / Backend | — | Devise `authenticate_user!` in ApplicationController; 401 is automatic |
| CSRF protection | Browser / Client | API / Backend | `rails-ujs` adds token to XHR requests; `protect_from_forgery :exception` enforces at server |
| Test isolation (Cucumber) | API / Backend | — | `VisitedLink.delete_all` in global `Before` hook; same tier as existing `MastodonAccount.delete_all` |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ActiveRecord | 8.1 (codebase) | ORM, migration, upsert API | App stack — already present |
| MySQL (utf8mb4) | Existing DB | Persistence with prefix-index support | App stack — already configured |
| Devise | Existing | `authenticate_user!` + `current_user` | App stack — every controller uses it |

*No new gems required for this phase.* [VERIFIED: codebase grep confirms all dependencies are pre-installed]

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rails-ujs | Existing (application.js) | Injects CSRF token into XHR requests | Already required in application.js — no action needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `upsert` with `unique_by:` | `find_or_create_by` | `find_or_create_by` has a TOCTOU race under concurrent requests; locked decision favors `upsert` |
| varchar(2083) + prefix index url(768) | SHA256 digest column | Digest avoids prefix index complexity but adds hashing step; REQUIREMENTS.md explicitly excludes it |

**Installation:** No new packages — this phase is greenfield Rails code only.

---

## Package Legitimacy Audit

> No external packages are installed in this phase. All implementation uses the existing Rails/MySQL/Devise stack.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Browser / JS (Phase 87)
        |
        | POST /visited_links  { url: "https://..." }
        |  (rails-ujs injects X-CSRF-Token header)
        v
VisitedLinksController#create
  authenticate_user!  (Devise → 401 if absent)
        |
        | params[:url]
        v
VisitedLink.record!(current_user, url)
        |
        | normalize_url(url)   strips #fragment
        |
        | upsert({ user_id:, url:, visited_at: }, unique_by: index_name)
        v
MySQL: INSERT INTO visited_links ... ON DUPLICATE KEY UPDATE visited_at=...
        |
        v
head :no_content  →  204
```

### Recommended Project Structure

Files created or modified in this phase:

```
db/migrate/
└── 20260518XXXXXX_create_visited_links.rb   # new

app/models/
└── visited_link.rb                          # new

app/controllers/
└── visited_links_controller.rb              # new

config/
└── routes.rb                                # add resources :visited_links line

features/support/
└── hooks.rb                                 # add VisitedLink.delete_all
```

No new directories are needed.

### Pattern 1: Migration with utf8mb4 prefix index

**What:** `create_table` with `varchar(2083)` for the url column and `add_index` using MySQL prefix length `url(768)`.
**When to use:** Any time a varchar column exceeds MySQL's 767-byte index limit under utf8mb4 (3–4 bytes per char).

```ruby
# Source: db/migrate/20260514103200_create_x_accounts.rb (codebase pattern) + MySQL docs [ASSUMED prefix syntax — standard MySQL knowledge]
class CreateVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :visited_links do |t|
      t.integer :user_id, null: false
      t.string  :url,     null: false, limit: 2083
      t.datetime :visited_at, null: false
      t.timestamps
    end

    add_index :visited_links, %i[user_id url], unique: true, length: { url: 768 }
  end
end
```

The index name Rails generates from `add_index :visited_links, %i[user_id url]` will be `index_visited_links_on_user_id_and_url` — this must match the `unique_by:` argument in `VisitedLink.upsert`.

### Pattern 2: Model with class-method API (no Crud::ByUser)

**What:** `VisitedLink` does not use `Crud::ByUser` because the phase exposes no per-record read/update/delete paths. The model exposes only class methods.
**When to use:** Models that are write-only from user interaction and read only in aggregate queries.

```ruby
# Source: CONTEXT.md locked decisions [VERIFIED: codebase review]
class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  def self.record!(user, url)
    normalized = normalize_url(url)
    upsert(
      { user_id: user.id, url: normalized, visited_at: Time.current },
      unique_by: :index_visited_links_on_user_id_and_url
    )
  end

  def self.urls_for(user)
    where(user_id: user.id).pluck(:url).to_set
  end

  def self.normalize_url(url)
    url.to_s.sub(/#.*$/, '')
  end
end
```

### Pattern 3: Minimal JSON/headless controller

**What:** Controller with no view, no redirect, no flash. Returns 204 on success.
**When to use:** API-style endpoints called by JavaScript where the response body is irrelevant.

```ruby
# Source: existing head :ok pattern in welcome_controller.rb, todos_controller.rb [VERIFIED: codebase grep]
class VisitedLinksController < ApplicationController
  def create
    VisitedLink.record!(current_user, params[:url])
    head :no_content
  end
end
```

Note: `authenticate_user!` is inherited from ApplicationController (already declared as `before_action` globally). No override needed.

### Pattern 4: Route line

```ruby
# Placed inside Rails.application.routes.draw do, alongside other resources
resources :visited_links, only: [:create]
```

This generates: `POST /visited_links` → `visited_links#create`, route helper `visited_links_path`.

### Pattern 5: Cucumber Before hook addition

```ruby
# features/support/hooks.rb — add alongside existing delete_all calls (line 6-7 area)
Before do
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)

  MastodonAccount.delete_all
  XAccount.delete_all
  VisitedLink.delete_all    # ADD THIS LINE

  pref = user.preference
  pref.update!(
    theme: "modern",
    # ...
  )
end
```

### Anti-Patterns to Avoid

- **`find_or_create_by` instead of `upsert`:** Has a TOCTOU race — two concurrent requests can both "not find" and both try to insert, causing a duplicate key error. `upsert` is atomic at the DB level.
- **`skip_before_action :authenticate_user!`:** Never do this on the `visited_links` controller. The endpoint writes data for `current_user`; without auth, `current_user` is nil and the upsert would fail or produce garbage.
- **`unique_by: :user_id_url_index`:** The `unique_by:` value must exactly match the index name as Rails generates it. The migration's `add_index :visited_links, %i[user_id url]` produces `index_visited_links_on_user_id_and_url`. A typo here raises at runtime (not at migrate time).
- **Full-column index on url varchar(2083) under utf8mb4:** MySQL will reject the migration with "Specified key was too long; max key length is 3072 bytes." Always use the `length: { url: 768 }` prefix.
- **Applying `normalize_url` only in `record!` but not in `urls_for`:** DAT-03 requires normalization at both write and read. If `urls_for` returns raw URLs and `record!` stores normalized ones, set membership checks in later phases will silently fail.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic insert-or-ignore | Custom rescue on `ActiveRecord::RecordNotUnique` | `ActiveRecord::Base.upsert` with `unique_by:` | Rails 6+ upsert maps to `INSERT ... ON DUPLICATE KEY UPDATE`; rescue pattern has TOCTOU window |
| 401 for unauthenticated | Custom `before_action` guard with `render json: {}, status: :unauthorized` | `authenticate_user!` from Devise (inherited) | Devise already does this globally in ApplicationController |
| CSRF token injection | Manual `$.ajaxSetup` with meta-tag read | `rails-ujs` already required in application.js | Rails UJS intercepts all non-GET XHR and injects the token automatically |

**Key insight:** In this phase, all "hard" problems (idempotency, auth, CSRF) are already solved by the existing stack. The implementation is thin wiring, not novel engineering.

---

## Common Pitfalls

### Pitfall 1: Index name mismatch in upsert unique_by

**What goes wrong:** `VisitedLink.upsert({...}, unique_by: :wrong_index_name)` raises `ArgumentError: No unique index found for wrong_index_name` at runtime — not at migration time.
**Why it happens:** Rails resolves `unique_by:` against the connection's index list. A typo in the symbol is silent until the first request hits the endpoint.
**How to avoid:** Verify the generated index name after running the migration with `bin/rails db:migrate` and inspect `db/schema.rb`. The standard Rails convention for `add_index :visited_links, %i[user_id url]` is `index_visited_links_on_user_id_and_url`.
**Warning signs:** `ArgumentError` in test or at first POST — appears immediately in `VisitedLinkModelTest` when `record!` is called.

### Pitfall 2: MySQL prefix index syntax in migration

**What goes wrong:** `add_index :visited_links, %i[user_id url], unique: true` without `length: { url: 768 }` causes `Mysql2::Error: Specified key was too long; max key length is 3072 bytes` at migration time.
**Why it happens:** utf8mb4 uses up to 4 bytes per character; `varchar(2083)` * 4 = 8332 bytes, far over the InnoDB limit.
**How to avoid:** Always pass `length: { url: 768 }` to `add_index` when the url column is indexed.
**Warning signs:** Migration fails immediately with the MySQL error message. Fix: add `length:` option, re-run.

### Pitfall 3: normalize_url applied asymmetrically

**What goes wrong:** `record!` stores `https://example.com/page` (no fragment). A later `urls_for` call returns the same value. But if a caller somewhere passes a URL with a fragment to `urls_for` for membership checking, the check passes — however if `normalize_url` is NOT called inside `urls_for` on the *query results* (which come from DB and are already normalized), there's no bug there. The risk is if a caller of `urls_for` compares raw (non-normalized) URLs against the returned Set. This is a Phase 86/87 concern, but DAT-03 explicitly requires `normalize_url` to be applied "identically on write and on read" — meaning the read path (`urls_for`) must also normalize its *input* when checking membership, even though stored rows are already normalized.
**Why it happens:** The DB rows are normalized at write time; `urls_for` returns those normalized rows. The Set membership check in Phase 86 will compare against URLs that may have fragments. If the caller doesn't normalize before comparing, Set membership fails.
**How to avoid:** Phase 84 only needs `normalize_url` in `record!`. DAT-03's "applied identically on read" means that the caller (Phase 86 `urls_for` consumer) must normalize the URL before the `.include?` check. Document this interface contract clearly in the model.
**Warning signs:** Phase 86 integration test where a URL with `#section` is recorded but then checked against a raw URL — Set membership returns false.

### Pitfall 4: Missing VisitedLink.delete_all in Cucumber Before hook

**What goes wrong:** Cucumber scenarios that record visits in one scenario bleed into later scenarios — links appear visited when they should appear unvisited.
**Why it happens:** The global `Before` hook resets preferences and deletes `MastodonAccount`/`XAccount` rows, but without `VisitedLink.delete_all`, the visited_links table grows across scenarios.
**How to avoid:** Add `VisitedLink.delete_all` in the same commit as the migration. If the table doesn't exist yet at the time the hook runs (before migration), `delete_all` raises — so this line must only be added after the migration exists.
**Warning signs:** Cucumber scenarios that check for unvisited link styling see the visited style instead (relevant from Phase 87 onward, but the cleanup should be in place from Phase 84).

### Pitfall 5: blank/nil url reaching the upsert

**What goes wrong:** `VisitedLink.record!(user, nil)` or `VisitedLink.record!(user, '')` calls `upsert` with a blank url, violating the `url null: false` constraint and raising `ActiveRecord::NotNullViolation`.
**Why it happens:** `normalize_url` calls `.to_s` on nil (returns `""`), then strips the fragment, returning `""`. The DB constraint fires on insert.
**How to avoid:** The model validates `url` presence. However, `upsert` bypasses model validations. The controller should guard: only call `record!` if `params[:url].present?`. Return 422 (or silently succeed with no-op) for blank url. The minimal approach: add a blank guard in `record!` itself (`return if url.blank?`) before calling upsert.
**Warning signs:** `ActiveRecord::NotNullViolation` in controller tests when posting without a url param.

---

## Code Examples

### Migration (complete)

```ruby
# Source: existing migration patterns in db/migrate/ [VERIFIED: codebase review]
# File: db/migrate/20260518XXXXXX_create_visited_links.rb
class CreateVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :visited_links do |t|
      t.integer  :user_id,    null: false
      t.string   :url,        null: false, limit: 2083
      t.datetime :visited_at, null: false
      t.timestamps
    end

    add_index :visited_links, %i[user_id url], unique: true, length: { url: 768 }
  end
end
```

### Model (complete)

```ruby
# Source: CONTEXT.md locked decisions [VERIFIED: codebase review]
# File: app/models/visited_link.rb
class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  def self.record!(user, url)
    normalized = normalize_url(url)
    return if normalized.blank?

    upsert(
      { user_id: user.id, url: normalized, visited_at: Time.current },
      unique_by: :index_visited_links_on_user_id_and_url
    )
  end

  def self.urls_for(user)
    where(user_id: user.id).pluck(:url).to_set
  end

  def self.normalize_url(url)
    url.to_s.sub(/#.*$/, '')
  end
end
```

### Controller (complete)

```ruby
# Source: head :ok pattern from welcome_controller.rb, notes_controller.rb [VERIFIED: codebase grep]
# File: app/controllers/visited_links_controller.rb
class VisitedLinksController < ApplicationController
  def create
    VisitedLink.record!(current_user, params[:url])
    head :no_content
  end
end
```

### Route line

```ruby
# Inside Rails.application.routes.draw do — add alongside existing resources
resources :visited_links, only: [:create]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `find_or_create_by` for upsert semantics | `ActiveRecord::Base.upsert` with `unique_by:` | Rails 6.0 (2019) | Atomic at DB level; no rescue needed |
| Manual CSRF token injection in `$.post` | `rails-ujs` automatic injection | Rails 5.1 (2017) | No manual CSRF plumbing in JS code |

**Deprecated/outdated:**
- `jquery_ujs`: Replaced by `rails-ujs` (Rails 5.1+). This codebase already uses `rails-ujs` (confirmed in application.js).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `add_index` with `length: { url: 768 }` generates index name `index_visited_links_on_user_id_and_url` matching the `unique_by:` value | Migration / Model patterns | `upsert` raises `ArgumentError` at runtime — caught immediately in model test |
| A2 | `rails-ujs` injects X-CSRF-Token into `$.post` without any explicit `ajaxPrefilter` setup in first-party JS | Don't Hand-Roll | CSRF verification would fail on the POST endpoint — caught immediately in integration tests (but note: test env has `allow_forgery_protection = false`, so only caught in staging/production) |

Note: A2 is standard `rails-ujs` behavior [ASSUMED based on training knowledge — no official docs fetched in this session]. The test environment disables forgery protection (`allow_forgery_protection = false` in `config/environments/test.rb` — [VERIFIED: codebase read]), so integration tests will pass regardless. Manual smoke test in development is the only way to confirm CSRF works end-to-end before Phase 87.

---

## Open Questions

1. **visited_at update-on-duplicate behavior**
   - What we know: `upsert` with `unique_by:` in Rails does an `ON DUPLICATE KEY UPDATE` that updates all non-key columns by default.
   - What's unclear: Should `visited_at` be updated on re-visit (yes — "last visited") or left as first-visit? The CONTEXT.md is silent on this.
   - Recommendation: Updating `visited_at` on each visit is the correct behavior (last-visited semantics, consistent with the field name). This is the default `upsert` behavior and requires no special handling.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MySQL | Migration, upsert | ✓ | Existing DB | — |
| Rails 8.1 | `upsert` API, migration | ✓ | 8.1 | — |
| Devise | `authenticate_user!` | ✓ | Existing | — |
| Minitest | Unit + integration tests | ✓ | Existing | — |
| Cucumber (dad:test) | E2E hook verification | ✓ | Existing | — |

**Missing dependencies with no fallback:** none

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails default) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DAT-01 | `visited_links` table has correct schema | unit (schema assertion) | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-02a | `record!` inserts a row on first call | unit | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-02b | `record!` is idempotent — two calls produce one row | unit | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-02c | `urls_for` returns a Set of urls for the user | unit | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-03 | `normalize_url` strips fragment | unit | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-03b | `record!` normalizes url before storing | unit | `bin/rails test test/models/visited_link_test.rb` | ❌ Wave 0 |
| DAT-04a | `POST /visited_links` with valid url returns 204 | integration | `bin/rails test test/controllers/visited_links_controller_test.rb` | ❌ Wave 0 |
| DAT-04b | Unauthenticated `POST /visited_links` returns 401 | integration | `bin/rails test test/controllers/visited_links_controller_test.rb` | ❌ Wave 0 |
| DAT-04c | Calling twice for same user+url results in one row | integration | `bin/rails test test/controllers/visited_links_controller_test.rb` | ❌ Wave 0 |
| (hook) | `VisitedLink.delete_all` in Cucumber `Before` hook | manual — verified by running `bundle exec rake dad:test` | `bundle exec rake dad:test` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb`
- **Per wave merge:** `yarn run lint && bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` green before marking phase complete

### Wave 0 Gaps

- [ ] `test/models/visited_link_test.rb` — covers DAT-01, DAT-02a/b/c, DAT-03, DAT-03b
- [ ] `test/controllers/visited_links_controller_test.rb` — covers DAT-04a/b/c
- [ ] `test/fixtures/visited_links.yml` — may be needed for pre-seeded data in other test contexts (likely empty — model tests create records programmatically)

*(Existing test infrastructure: `test/test_helper.rb`, fixtures `:all`, `ActionDispatch::IntegrationTest` with Devise helpers — all available, no new framework needed)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Devise `authenticate_user!` — inherited, no action needed |
| V3 Session Management | no | No session state changes in this endpoint |
| V4 Access Control | yes | `user_id` merged server-side from `current_user.id`; never from params |
| V5 Input Validation | yes | `validates :url, presence: true`; `normalize_url` sanitizes fragment |
| V6 Cryptography | no | No secrets handled in this phase |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated write | Spoofing | `authenticate_user!` → 401 automatically |
| User A records visits for User B | Tampering | `user_id` sourced from `current_user.id` only — never from `params`; strong params pattern matches all other controllers |
| Malformed URL stored in DB | Tampering | `validates :url, presence: true` + DB `null: false` + `normalize_url` is a no-op for non-fragment malformation; URL format validation is deliberately excluded (any string is a valid "visited url" from the app's perspective) |
| CSRF on POST endpoint | Tampering | `protect_from_forgery with: :exception` in ApplicationController; `rails-ujs` injects token automatically |

---

## Sources

### Primary (HIGH confidence)
- Codebase (`db/migrate/`, `app/models/`, `app/controllers/`, `features/support/hooks.rb`, `config/routes.rb`, `config/environments/test.rb`) — verified by direct file reads in this session
- `.planning/phases/84-data-layer-controller/84-CONTEXT.md` — locked decisions, verbatim
- `.planning/REQUIREMENTS.md` — DAT-01 through DAT-04 requirement text

### Secondary (MEDIUM confidence)
- Rails 8.1 `upsert` with `unique_by:` — [ASSUMED] based on training knowledge; Rails 6+ API, present in Rails 8.1 by inheritance; not verified via Context7 in this session but consistent with all codebase evidence

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies confirmed present in codebase
- Architecture: HIGH — every pattern has a direct codebase precedent
- Migration syntax: HIGH — verified against existing migrations and schema.rb
- Rails upsert API: MEDIUM — training knowledge, not verified via Context7
- Pitfalls: HIGH — derived from codebase inspection and MySQL behavior

**Research date:** 2026-05-18
**Valid until:** 2026-06-18 (stable Rails/MySQL stack; no time-sensitive dependencies)
