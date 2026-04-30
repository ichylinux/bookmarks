---
phase: 11
phase_name: Notes Controller
phase_slug: notes-controller
milestone: v1.3
created: 2026-04-30
status: ready-to-plan
---

# Phase 11 Context — Notes Controller

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>

## Phase Boundary

Authenticated users can POST to `/notes` to create one persisted `Note` owned by `current_user`. `NotesController` enforces authentication (inherited guard), merges `user_id` only from `current_user`, rejects invalid payloads, redirects on success/failure appropriately for **full-page POST + redirect**, and is covered by `notes_controller_test.rb`. **No ERB/tab UI** in this phase (Phase 12+).

</domain>

<decisions>

## Implementation Decisions

### Validation failure (blank body / model validation failures)

- **D-01:** Use **`redirect_to root_path(tab: 'notes'), alert: <message>`** — not `422` / empty body for Phase 11. Aligns with full-page flows and roadmap success criterion 2 ("redirect with flash or unprocessable" — chosen **redirect with flash**).
- **D-02:** Preserve **`tab: 'notes'` on failure redirects** so the eventual welcome tab UX does not bounce to Home after an invalid POST.
- **D-03:** Failure flash copy: concise Japanese. **Suggested default for presence/blank body:** 「メモを入力してください」。Planners/implementors may unify wording if a project-wide flash style exists elsewhere.

### Claude's Discretion

- **Success redirect:** Already fixed by roadmap (`root_path(tab: 'notes')`). Whether to set `flash[:notice]` on success — **optional**; many flows use silent redirect. Pick one convention and cover in tests if a notice is set.
- **`destroy` action vs REQUIREMENTS defer:** Routes currently include `:destroy`; REQUIREMENTS marks per-note delete as **future/deferred**. Planner should either narrow `routes` to `only: [:create]` for Phase 11, add an explicit deferred stub, or schedule `destroy` in a later phase — **avoid leaving a routed action missing without an intentional routing change** (same as gray area 4 the user skipped).
- **Other model errors:** Reuse **same redirect + `tab: 'notes'` + `alert`** pattern (e.g. `length` violations) unless product later standardizes differently.

### Folded Todos

_None — drawer-related pending todos were reviewed as out of scope for this phase._

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 11 goal and success criteria
- `.planning/REQUIREMENTS.md` — NOTE-01; Future: delete-note deferral
- `.planning/PROJECT.md` — v1.3 scope, constraints
- `.planning/STATE.md` — v1.3 locked patterns (`user_id` from `current_user`, full-page POST, theme/tab direction)

### Prior phase foundation

- `.planning/phases/10-data-layer/10-CONTEXT.md` — `Note` model, `recent` scope, validations, routing added in Phase 10

### Implementation references

- `app/controllers/application_controller.rb` — `authenticate_user!` baseline
- `app/controllers/todos_controller.rb` — `todo_params` + `merge(user_id: current_user.id)` on create
- `app/models/note.rb` — validations and `Crud::ByUser`

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable assets

- **`TodosController#todo_params` + merge on `create`:** Model for **`note_params` + `merge(user_id: current_user.id)`** on allowed actions — **never permit `user_id`**.
- **`Note`:** `validates :body, presence: true, length: { maximum: 4000 }` — controller tests should cover at least absence (and length if exercised).

### Established patterns

- Global **`before_action :authenticate_user!`** — unauthenticated POST goes through Devise’s failure path per success criterion 3.

### Integration points

- `config/routes.rb` — `resources :notes` currently `only: [:create, :destroy]`; reconcile with deferred delete requirement during planning.

</code_context>

<specifics>

## Specific Ideas

User chose option **redirect + flash with `tab: 'notes'`** for validation failures; no bespoke flash wording was specified beyond planner default (D-03).

</specifics>

<deferred>

## Deferred Ideas

_None from scope creep._

### Reviewed Todos (not folded)

- **Extract `drawer_ui?` helper if condition grows to 4th case** — drawer/modern-theme UI; not part of Notes controller work.
- **Gate drawer + drawer-overlay on theme for symmetry** — same; belongs to theme/UI track, not Phase 11.

</deferred>

---

*Phase: 11-notes-controller*
*Context gathered: 2026-04-30*
