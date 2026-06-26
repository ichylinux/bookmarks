# Phase 130: Test Coverage & Tri-Suite Gate - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add automated test coverage verifying the mobile CSS changes from Phase 129: one Minitest CSS structure test and one Cucumber @mobile_portal E2E scenario. Then run the full tri-suite gate to confirm all three suites pass green.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — this is a pure test infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

Key constraints from ROADMAP and STATE.md:
- TEST-01: Minitest asserts `welcome.css.scss` contains `@media (hover: none)` block with `.todo-gadget-new-link` at `opacity: 1` and `pointer-events: auto`
- TEST-02: Cucumber `@mobile_portal` scenario at 390px viewport: visits welcome page, taps "追加" link, fills title field, submits form, asserts new todo appears in gadget list
- TEST-03: The step that navigates to the welcome page MUST call `ensure_mobile_viewport!` before `visit root_path` — `@mobile_portal` tag alone does not resize
- TEST-03: `yarn run lint && bin/rails test && bundle exec rake dad:test` all exit 0 with 0 failures

### Minitest placement
- CSS structure tests exist in `test/` — check for existing pattern (e.g., `test/assets/` or `test/system/`) and follow convention
- The test reads `welcome.css.scss` as a string and asserts the mobile CSS patterns are present

### Cucumber placement
- Feature file in `features/` following existing naming convention (Japanese language features)
- Step definitions in `features/step_definitions/` — reuse `ensure_mobile_viewport!` from existing steps
- `@mobile_portal` tag with `Before`/`After` hooks to set 390px viewport and restore after scenario
- WebMock: the mobile portal scenario should not make external HTTP calls; check if any stubs are needed

### ensure_mobile_viewport! convention
- Already defined in step_definitions (used in existing mobile scenarios)
- Must be called explicitly in the step that visits root_path, not just via `@mobile_portal` hook
- Pattern: `ensure_mobile_viewport!` then `visit root_path`

</decisions>

<code_context>
## Existing Code Insights

### What Phase 129 built
- `welcome.css.scss`: `@media (hover: none) { .todo-gadget-new-link { opacity: 1; pointer-events: auto; } }`
- `todos.css.scss`: `flex-wrap: wrap` on `tr`, `flex: 0 0 100%` on `td`, `font-size: 1rem` on inputs — all inside `.todo @media (max-width: 767px)` block
- `new.html.erb` and `edit.html.erb`: wrapped in `<div class="todo">`

### Integration Points
- Minitest: new test file asserting CSS content of `welcome.css.scss`
- Cucumber: new feature file with `@mobile_portal` tag; new/extended step definitions
- `ensure_mobile_viewport!` helper must be called before `visit root_path`

</code_context>

<specifics>
## Specific Ideas

- The Minitest test should read `Rails.root.join('app/assets/stylesheets/welcome.css.scss').read` and assert the string contains the expected CSS patterns
- Cucumber scenario at 390px: resize browser, visit root, find and click "追加" link in todo gadget header, fill title, submit, assert todo appears
- Per CLAUDE.md: run with `bundle exec rake dad:test` (not `bundle exec cucumber` directly)

</specifics>

<deferred>
## Deferred Ideas

None — this phase covers all TEST requirements (TEST-01, TEST-02, TEST-03).

</deferred>
