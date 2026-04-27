# Phase 4: Verify and document - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that Phases 2 and 3 introduced no regressions and lock conventions for the future. Deliverables: all automated test suites green, a manual smoke list executed and recorded for JS-touched flows, and CONVENTIONS.md confirmed complete for JavaScript. No new features; verification and documentation only.

</domain>

<decisions>
## Implementation Decisions

### Test suite execution (VERI-01)

- **D-01:** Full verification stack — run all three in sequence:
  1. `yarn run lint` — must exit 0 (already confirmed green in Phase 3; re-confirm after any Phase 4 doc edits)
  2. `bin/rails test` — 0 failures, 0 errors; covers unit/integration/system tests
  3. `bundle exec rake dad:test` — Cucumber suite using headless Chrome; this task spawns the Rails server automatically (no separate server setup required)
- **D-02:** A test run is considered **passing** when all three commands exit 0 with no new failures attributable to JS changes
- **D-03:** If pre-existing test failures exist (unrelated to JS), they must be identified and documented as pre-existing before Phase 4 is considered complete

### Smoke test scope (VERI-02 / VERI-03)

- **D-04:** Smoke targets are carried forward from Phase 3 validation planning:
  - Bookmark title auto-fill (`bookmarks.js` + `BookmarksController#fetch_title`)
  - Todo create/update flows including `.js.erb` responses (`app/views/todos/*.js.erb`)
  - Feed gadget behaviour
  - Calendar gadget behaviour
  - Portal page — double-click / actions with no console errors
- **D-05:** Smoke results are recorded in the plan's execution summary (checkboxes per flow) — no separate UAT doc required unless failures are found

### DOCS-01 completeness

- **D-06:** Phase 3 already wrote the JavaScript section in `CONVENTIONS.md` (D-07 from 03-CONTEXT, verified in 03-02-SUMMARY). Phase 4's job is to confirm the section is sufficient — review against VERI-01/02/03 outcomes and add any missing detail (e.g., ESLint config rationale, `no-var` exception procedure). If nothing is missing, mark DOCS-01 complete with no further edits.

### Claude's Discretion

- Format and structure of smoke test checkboxes in the execution summary
- Whether to update `REQUIREMENTS.md` to mark VERI-01/02/03 and DOCS-01 complete (recommended — keeps traceability clean)
- Order of tasks within the phase plan

</decisions>

<specifics>
## Specific Ideas

- Cucumber command is `bundle exec rake dad:test` (custom rake task from the `daddy` gem ecosystem — not `bundle exec cucumber` directly)
- System tests in Minitest use Capybara + headless Chrome; the `dad:test` Cucumber rake task independently spawns its own server and Chrome instance
- Bookmark title auto-fill is the primary regression-risk flow (it was explicitly called out as a regression test target in STATE.md)

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — VERI-01, VERI-02, VERI-03, DOCS-01 (the four open requirements this phase closes)
- `.planning/ROADMAP.md` — Phase 4 success criteria
- `.planning/PROJECT.md` — stack constraints and out-of-scope list

### Test commands

- `yarn run lint` — ESLint check; must exit 0
- `bin/rails test` — Minitest full suite; 0 failures/errors required
- `bundle exec rake dad:test` — Cucumber suite; spawns Rails server + headless Chrome automatically

### Conventions doc

- `.planning/codebase/CONVENTIONS.md` — JavaScript section (written in Phase 3); Phase 4 confirms it is complete and satisfies DOCS-01

### Phase 3 outputs (regression baseline)

- `.planning/phases/03-modernize-application-scripts/03-01-SUMMARY.md` — files changed (todos.js, feeds.js, calendars.js, bookmark_gadget.js, bookmarks.js)
- `.planning/phases/03-modernize-application-scripts/03-02-SUMMARY.md` — CONVENTIONS.md update, arrow/function rule, precompile baseline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `features/01.ブックマーク.feature` + `features/step_definitions/bookmarks.rb` — Cucumber scenario for bookmark creation including title auto-fill
- `features/02.タスク.feature` + `features/step_definitions/todos.rb` — Cucumber scenario for todo flows
- `test/` — Minitest suite (controllers, models, integration, system)

### Established Patterns

- JS-touched files: `todos.js`, `feeds.js`, `calendars.js`, `bookmark_gadget.js`, `bookmarks.js` — these are the regression surface for smoke testing
- `.js.erb` templates exist under `app/views/todos/` — UJS responses touched by Phase 3 changes

### Integration Points

- `BookmarksController#fetch_title` — server-side title fetch triggered by JS; primary smoke regression target
- Portal page (welcome/index) — renders bookmark_gadget, feed, todo_gadget, calendar widgets all at once; single smoke stop covers multiple gadgets

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-verify-and-document*
*Context gathered: 2026-04-27*
