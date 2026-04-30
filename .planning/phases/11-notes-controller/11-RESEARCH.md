# Phase 11 — Technical Research — Notes Controller

## RESEARCH COMPLETE

**Purpose:** Lightweight pattern confirmation before PLAN.md generation (inline research — no blocker).

---

## Findings

### Controller / auth baseline

- `ApplicationController` sets `before_action :authenticate_user!` — unauthenticated POSTs redirect to Devise (`new_user_session_path` → `/users/sign_in`).
- `TodosController#todo_params` merges `user_id: current_user.id` inside `when 'create'` — **closest analog for `NotesController`**.
- Rails 8 stack; integration tests include `Devise::Test::IntegrationHelpers` globally (`ActionDispatch::IntegrationTest`).

### Routing vs deferred delete requirement

- `config/routes.rb` currently declares `resources :notes, only: [:create, :destroy]` (Phase 10).
- `.planning/REQUIREMENTS.md` defers **per-note delete** to a future requirement; `11-CONTEXT.md` directs planners to **`only: [:create]` until delete ships**, avoiding routed actions with no intentional implementation.

### Test patterns

- `test/controllers/bookmarks_controller_test.rb` — `sign_in user`, `post ... params: { ... }`, `assert_response :redirect`.
- Fixtures: `test/fixtures/notes.yml` has `one` / `two` for users 1 and 2 — usable for **cross-user isolation** assertions (no note created for another user).

### Note model

- `app/models/note.rb` — `validates :body, presence: true, length: { maximum: 4000 }`, `before_validation :strip_body` — blank/whitespace-only posts fail `save` → controller uses **redirect + flash** per CONTEXT D-01.

---

## Validation Architecture

> Required for Nyquist `VALIDATION.md` synthesis.

| Dimension | Strategy |
|-----------|----------|
| **Automated unit/integration** | `bin/rails test test/controllers/notes_controller_test.rb` after tasks touching controller or routes. |
| **Full regression** | `bin/rails test` before phase sign-off / verify-work. |
| **Security-relevant paths** | Auth redirect (unauthenticated POST), `user_id` mass-assignment resistance, per-user create scope — each mapped to a test method with explicit assertion. |
| **Feedback latency** | Single controller file + one test file — target &lt; 30s for focused test run on dev hardware. |

---

## Open items left to PLAN

- Exact flash string on failure: prefer model `errors.full_messages` (locale `:ja`) or fixed copy from CONTEXT D-03 — **PLAN locks to one approach**.
