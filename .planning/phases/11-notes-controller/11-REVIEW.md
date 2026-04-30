---
phase: 11-notes-controller
reviewed: 2026-04-30
status: clean
depth: standard
scope:
  - app/controllers/notes_controller.rb
  - test/controllers/notes_controller_test.rb
  - config/routes.rb
---

# Phase 11: Code Review

**Summary:** Notes create path follows strong-params + merge pattern; routes match deferred-delete policy; tests cover STRIDE-aligned cases from the plan threat register.

## Findings

| Severity | File | Finding |
|----------|------|---------|
| — | — | No blocking or high findings |

### Notes

- **Mass-assignment:** `permit(:body)` only with `merge(user_id: current_user.id)` — tested by injection case.
- **Auth:** Inherited `authenticate_user!` from `ApplicationController` — tested unauthenticated POST → `new_user_session_path`.
- **Route surface:** `only: [:create]` removes destroy — aligns with REQUIREMENTS deferral.

## Residual Risks

- None significant for Phase 11 scope (no view/tab integration yet).
