---
phase: 13
phase_name: Note Gadget + Integration Tests
phase_slug: note-gadget-integration-tests
milestone: v1.3
created: 2026-04-30
status: ready-to-plan
---

# Phase 13: Note Gadget + Integration Tests - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

The simple-theme Note tab panel becomes the real note gadget: it renders a textarea form, a Save button, and the current user's saved notes in reverse chronological order. Saving a note uses the existing full-page `POST /notes` flow and returns to the Note tab. This phase also finishes the requested test coverage for the complete note capture flow and folds in the drawer cleanup todos selected during discussion.

</domain>

<decisions>
## Implementation Decisions

### Test Strategy

- **D-01:** Keep Rails-side structural and data rendering checks in `WelcomeController` controller tests. Do not create `test/integration/` tests for this phase.
- **D-02:** `WelcomeController` tests should cover the Note tab panel structure, textarea, Save button, note list or container, and empty state.
- **D-03:** `WelcomeController` tests should verify that the current user's notes render in reverse chronological order.
- **D-04:** `WelcomeController` tests should verify that another user's notes are not shown in the Note tab panel.
- **D-05:** End-to-end browser coverage belongs in Cucumber, not Minitest integration tests. The Cucumber scenario should cover: simple theme user opens the Note tab, enters text, saves, returns to the Note tab, and sees the new note in the list.

### Note Gadget Rendering

- **D-06:** Render the Note tab content through a dedicated `_note_gadget.html.erb` partial so the welcome view keeps a stable mounting point and the gadget markup stays isolated.
- **D-07:** Keep the gadget plain and server-rendered: textarea, Save button, reverse-chronological note list, and empty-state copy. No new JavaScript dependency, no autosave, no rich text, no pagination, and no inline editing.
- **D-08:** Display each saved note's body and a readable timestamp, matching Phase 13 success criteria. Exact timestamp format is Claude's discretion, but it should be deterministic enough for tests.

### Folded Todos

- **D-09:** Fold `Extract drawer_ui? helper if condition grows to 4th case` into this phase. Add a helper such as `drawer_ui?` when updating `app/views/layouts/application.html.erb`, and replace the duplicated drawer eligibility checks with it.
- **D-10:** Fold `Gate drawer + drawer-overlay on theme for symmetry` into this phase. Drawer DOM should render only when `drawer_ui?` is true, so simple-theme pages do not render hidden drawer markup.
- **D-11:** Keep drawer cleanup separate from note gadget behavior in the plan structure if useful, but it may be implemented in the same phase because the user explicitly selected both todos for Phase 13.

### Claude's Discretion

- Exact note gadget spacing and class names under `.simple { }`, as long as they are scoped and consistent with `welcome.css.scss`.
- Whether the note form partial uses `form_with` or a more classic Rails form helper; follow existing project patterns while keeping the POST local/full-page.
- Whether drawer cleanup is a separate plan or a task inside a broader layout/view plan.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements

- `.planning/ROADMAP.md` — Phase 13 goal and success criteria for note form, reverse-chronological list, empty state, and tests.
- `.planning/REQUIREMENTS.md` — NOTE-01, NOTE-02, NOTE-03, and out-of-scope note capabilities.
- `.planning/PROJECT.md` — v1.3 scope, stack constraints, and target note gadget behavior.
- `.planning/STATE.md` — accumulated v1.3 decisions: zero new dependencies, full-page POST with redirect, tab query behavior, theme isolation.

### Prior Phase Alignment

- `.planning/phases/10-data-layer/10-CONTEXT.md` — `Note` model, `recent` ordering, ownership, and validation decisions.
- `.planning/phases/11-notes-controller/11-CONTEXT.md` — `NotesController#create`, failure redirect with `tab: 'notes'`, and strong parameter ownership.
- `.planning/phases/12-tab-ui/12-CONTEXT.md` — simple-theme tab shell, panel IDs, query param handling, and theme isolation.

### Folded Todos

- `.planning/todos/pending/2026-04-30-extract-drawer-ui-helper.md` — helper extraction trigger and intended `drawer_ui?` shape.
- `.planning/todos/pending/2026-04-30-gate-drawer-blocks-on-theme.md` — drawer DOM theme gate requirement.

### Code and Assets

- `app/views/welcome/index.html.erb` — Note tab panel insertion point and existing portal panel.
- `app/controllers/welcome_controller.rb` — currently only loads `@portal`; Phase 13 likely needs note data for the view.
- `app/controllers/notes_controller.rb` — existing create action and `root_path(tab: 'notes')` redirect.
- `app/models/note.rb` — validations and `recent` scope.
- `test/controllers/welcome_controller/welcome_controller_test.rb` — existing tab structure tests to extend.
- `features/` and `features/step_definitions/` — Cucumber feature and step definition patterns.
- `app/views/layouts/application.html.erb` — drawer helper cleanup and drawer DOM gate.
- `app/helpers/welcome_helper.rb` — existing `favorite_theme`; likely home for `drawer_ui?`.
- `app/assets/stylesheets/welcome.css.scss` — scoped simple-theme tab and note panel styles.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Note.recent` provides the intended reverse chronological ordering for `current_user.notes.recent`.
- `NotesController#create` already persists through a full-page POST and redirects to `root_path(tab: 'notes')`.
- `app/views/welcome/index.html.erb` already contains `#notes-tab-panel`, which is the target mount for the real note gadget.
- `WelcomeController` currently sets only `@portal`; adding `@note` and `@notes` there keeps rendering server-side and testable with `assert_select`.
- Cucumber support already includes sign-in helpers and Japanese feature/step conventions.

### Established Patterns

- Theme isolation requires both ERB gates (`favorite_theme == 'simple'`) and `.simple { }` SCSS scoping.
- Controller tests use `assert_select` for HTML structure and data assertions.
- Existing forms are mostly classic server-rendered Rails forms; Phase 13 should keep the local POST flow.
- User-owned data access should always start from `current_user`, not global `Note` queries.

### Integration Points

- `welcome/index` should render `_note_gadget.html.erb` inside `#notes-tab-panel`.
- `WelcomeController#index` should prepare only current-user note data.
- Cucumber should exercise the browser-visible save flow, while controller tests handle fast structural/data isolation assertions.
- `application.html.erb` drawer gates should be updated through a helper to avoid further duplicated theme logic.

</code_context>

<specifics>
## Specific Ideas

- User selected the testing gray area only.
- User explicitly chose `WelcomeController` tests for Rails-side coverage and said end-to-end should be covered by Cucumber.
- User chose Cucumber coverage for the save flow through seeing the newly saved note after redirect.
- User chose `WelcomeController` controller tests to cover structure plus displayed data, including reverse chronological order and other-user isolation.

</specifics>

<deferred>
## Deferred Ideas

- Delete individual notes remains a future requirement.
- Rich text / markdown editor, inline editing, autosave, and pagination remain out of scope per `.planning/REQUIREMENTS.md`.

</deferred>

---

*Phase: 13-note-gadget-integration-tests*
*Context gathered: 2026-04-30*
