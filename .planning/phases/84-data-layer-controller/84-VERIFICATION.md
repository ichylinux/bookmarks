# Phase 84 — Data Layer + Controller: VERIFICATION

**Phase:** 84-data-layer-controller  
**Plans verified:** 84-01 (Data Layer), 84-02 (Controller)  
**Verified:** 2026-05-18

---

## Phase Success Criteria Checklist

### Plan 01 — Data Layer (Migration + Model)

| Criterion | Status | Evidence |
|-----------|--------|---------|
| `visited_links` table created with correct columns | ✅ PASS | `db/schema.rb` contains `create_table "visited_links"` with `user_id`, `url` (limit: 2083), `visited_at`, `timestamps` |
| Unique prefix index `(user_id, url(767))` | ✅ PASS | `db/schema.rb` has `index_visited_links_on_user_id_and_url, unique: true, length: {url: 767}` |
| `VisitedLink.record!(user, url)` exists and is idempotent | ✅ PASS | Model has `def self.record!`; upsert via MySQL `ON DUPLICATE KEY UPDATE`; model tests verify 2 calls → 1 row |
| `VisitedLink.urls_for(user)` returns a Ruby Set | ✅ PASS | Model has `def self.urls_for`; returns `.pluck(:url).to_set` |
| `VisitedLink.normalize_url` strips fragment | ✅ PASS | Model has `def self.normalize_url`; `url.to_s.sub(/#.*$/, '')` |
| `belongs_to :user`, `validates :url, presence: true` | ✅ PASS | Model has both validations |
| Model unit tests pass | ✅ PASS | `bin/rails test test/models/visited_link_test.rb` — 12 runs, 0 failures |
| Full test suite green after Plan 01 | ✅ PASS | 429 runs, 0 failures (at Plan 01 completion) |

### Plan 02 — Controller

| Criterion | Status | Evidence |
|-----------|--------|---------|
| `app/controllers/visited_links_controller.rb` exists | ✅ PASS | File created; inherits `ApplicationController` |
| `POST /visited_links` route exists | ✅ PASS | `bin/rails routes` → `visited_links POST /visited_links(.:format) visited_links#create` |
| `create` action calls `VisitedLink.record!(current_user, params[:url])` | ✅ PASS | Controller body confirmed |
| `create` action returns 204 No Content | ✅ PASS | `head :no_content`; `test_successful_create` asserts `:no_content` |
| Unauthenticated POST returns Devise auth response | ✅ PASS | Redirects to `new_user_session_path` (Devise default for HTML); `test_unauthenticated_redirects_to_sign_in` passes |
| `authenticate_user!` inherited (no override in controller) | ✅ PASS | No `before_action :authenticate_user!` in `VisitedLinksController`; inherited from `ApplicationController` |
| Two identical POST requests → exactly 1 row | ✅ PASS | `test_idempotent_create`: 2 posts, `VisitedLink.count == 1` |
| Fragment URL stored normalized | ✅ PASS | `test_url_stored_normalized`: `#section` stripped; stored as `https://example.com/page` |
| `VisitedLink.delete_all` in Cucumber `Before` hook | ✅ PASS | `grep 'VisitedLink.delete_all' features/support/hooks.rb` → 1 match, line after `XAccount.delete_all` |
| Controller integration tests pass | ✅ PASS | `bin/rails test test/controllers/visited_links_controller_test.rb` → 5 runs, 18 assertions, 0 failures |
| Full test suite green after Plan 02 | ✅ PASS | `bin/rails test` → 434 runs, 1975 assertions, 0 failures, 0 errors, 0 skips |
| `bundle exec rake dad:test` (Cucumber) green | ⚠️ FLAKY | 24/25 scenarios pass; 1 scenario in `features/04.ノート.feature` fails randomly each run — **pre-existing flakiness** (different scenario fails each re-run; unrelated to visited_links changes; documented in CLAUDE.md) |

---

## Artifact Inventory

| File | Type | Status |
|------|------|--------|
| `db/migrate/20260518200000_create_visited_links.rb` | created | ✅ exists |
| `app/models/visited_link.rb` | created | ✅ exists |
| `test/models/visited_link_test.rb` | created | ✅ exists (12 tests) |
| `test/fixtures/visited_links.yml` | created | ✅ exists |
| `db/schema.rb` | modified | ✅ has visited_links table + index |
| `app/controllers/visited_links_controller.rb` | created | ✅ exists |
| `config/routes.rb` | modified | ✅ has `resources :visited_links, only: [:create]` |
| `features/support/hooks.rb` | modified | ✅ has `VisitedLink.delete_all` |
| `test/controllers/visited_links_controller_test.rb` | created | ✅ exists (5 tests, 54 lines) |

---

## Security Verification (Threat Model)

| Threat | Mitigation | Verified |
|--------|------------|---------|
| T-84-05: Unauthenticated POST access | `authenticate_user!` inherited from ApplicationController | ✅ `test_unauthenticated_redirects_to_sign_in` passes |
| T-84-06: User B records visits as User A | `current_user.id` hardcoded; no `params[:user_id]` accepted | ✅ Controller only takes `params[:url]`; user_id from session |
| T-84-07: CSRF on POST /visited_links | `protect_from_forgery with: :exception` inherited | ✅ Inherited; rails-ujs will inject X-CSRF-Token in Phase 87 |

---

## Commits

| Plan | Task | Commit | Message |
|------|------|--------|---------|
| 84-01 | Migration | 331c9d4 | feat(84-01): create visited_links table with prefix index |
| 84-01 | Model + Tests | 5059e4f | feat(84-01): add VisitedLink model with record!, urls_for, normalize_url; unit tests |
| 84-01 | Docs | 7342bfd | docs(84-01): complete data layer plan |
| 84-02 | Controller + Route | 2d26264 | feat(84-02): add VisitedLinksController#create and resources :visited_links route |
| 84-02 | Hook + Tests | 3974ba9 | feat(84-02): add VisitedLink.delete_all to Cucumber hook and controller integration tests |

---

## Overall Phase Verdict

**PASS** — All must-have success criteria for Phase 84 plans 01 and 02 are satisfied. The `POST /visited_links` endpoint is live, authenticated, idempotent, and isolated in the Cucumber test environment. Cucumber flakiness (1/25 scenarios, varying per run) is pre-existing and unrelated to this phase's changes.
