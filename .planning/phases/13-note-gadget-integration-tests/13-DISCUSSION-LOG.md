# Phase 13: Note Gadget + Integration Tests - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 13-note-gadget-integration-tests
**Areas discussed:** Folded todos, Test strategy

---

## Folded Todos

| Option | Description | Selected |
|--------|-------------|----------|
| Extract drawer_ui? helper if condition grows to 4th case | Add a helper for the duplicated `user_signed_in? && favorite_theme != 'simple'` checks when the next call site appears. | ✓ |
| Gate drawer + drawer-overlay on theme for symmetry | Render drawer DOM only for non-simple signed-in users instead of hiding it in simple theme CSS. | ✓ |
| Do not fold either todo into Phase 13 | Keep drawer cleanup outside the Note Gadget phase. | |

**User's choice:** Fold both pending todos into Phase 13 (`1, 2`).
**Notes:** The todos are UI/layout cleanup adjacent to the simple-theme work and should be planned with Phase 13.

---

## Test Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| WelcomeController controller tests | Keep Rails-side structure and rendering assertions in existing controller tests. | ✓ |
| New Minitest integration test | Add `test/integration/` coverage for the full request cycle. | |
| Split across NotesControllerTest and WelcomeControllerTest | Extend existing controller tests but avoid a single flow test. | |
| Claude decides | Default recommendation was a new integration test, but user corrected this. | |

**User's choice:** Use `WelcomeController` controller tests; end-to-end should be covered by Cucumber.
**Notes:** Do not add `test/integration/` for Phase 13.

---

## Cucumber Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Note tab display only | Open the Note tab and verify the form/empty state appears. | |
| Save flow | Open Note tab, enter text, save, return to Note tab, and see the new note. | ✓ |
| Save flow plus other-user isolation | Include cross-user data isolation in the browser scenario. | |
| Claude decides | Recommendation was save flow in Cucumber, with isolation in controller tests. | |

**User's choice:** Cover the save flow in Cucumber.
**Notes:** Other-user isolation remains a fast controller test concern.

---

## WelcomeController Test Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Structure only | Assert textarea, Save button, list container, and empty state exist. | |
| Structure plus displayed data | Also assert reverse chronological display and other-user notes are hidden. | ✓ |
| Minimal | Leave most behavior to Cucumber. | |
| Claude decides | Recommendation was structure plus displayed data. | |

**User's choice:** Cover structure plus displayed data in `WelcomeController` tests.
**Notes:** This locks the split: Cucumber proves the save flow, controller tests prove rendering details and isolation.

---

## Claude's Discretion

- Note gadget visual styling, exact CSS class names, and timestamp format.
- Whether drawer cleanup is a separate plan or a task within a broader layout/view plan.
- Exact implementation details of `_note_gadget.html.erb`, as long as the decisions in `13-CONTEXT.md` are honored.

## Deferred Ideas

- Delete individual notes.
- Rich text / markdown editing, inline editing, autosave, and pagination.
