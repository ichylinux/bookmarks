---
phase: 10-data-layer
plan: 02
subsystem: notes-model
tags: [rails, activerecord, model, validation, soft-delete, crud-by-user]
requirements: [NOTE-03]
dependency_graph:
  requires:
    - "notes table (created in 10-01)"
    - "Crud::ByUser module (app/models/crud/by_user.rb)"
  provides:
    - "Note model with belongs_to :user, body validations, recent scope, soft-delete"
    - "test/fixtures/notes.yml stub (2 rows)"
    - "test/models/note_test.rb (8 tests)"
  affects:
    - "Phase 11 controller (will rely on Note + Crud::ByUser predicates)"
    - "Phase 13 view (will read Note records)"
tech_stack:
  added: []
  patterns:
    - "include Crud::ByUser for ownership predicates"
    - "before_validation :strip_body + presence to reject whitespace-only input"
    - "destroy override (update!(deleted: true)) for soft-delete (mirrors Bookmark#destroy_logically! adapted for dependent: :destroy)"
    - "explicit :recent scope (no default_scope per CONTEXT.md)"
key_files:
  created:
    - app/models/note.rb
    - test/fixtures/notes.yml
    - test/models/note_test.rb
  modified: []
decisions:
  - "Inherit from ActiveRecord::Base (matches Todo/Bookmark/Calendar), not ApplicationRecord"
  - "Override destroy directly (not destroy_logically!) so User.has_many :notes, dependent: :destroy triggers soft-delete"
  - "Body length cap: 4000 chars (DoS guard, well below MySQL TEXT 65535 limit)"
  - "before_validation :strip_body (named-method form, greppable) over inline block"
  - "No default_scope (CONTEXT.md + RESEARCH.md Pitfall 2)"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_created: 3
  files_modified: 0
  tests_added: 8
  completed: 2026-04-30
---

# Phase 10 Plan 02: Notes Model Summary

JST one-liner: Note model with belongs_to :user, Crud::ByUser ownership, body presence/length-4000 validations with whitespace strip, :recent scope, and soft-delete destroy override; backed by 8 model tests covering NOTE-03 ownership and validation contracts.

## What Was Built

- **app/models/note.rb** (21 lines) — `Note < ActiveRecord::Base` including `Crud::ByUser`, with `belongs_to :user`, `before_validation :strip_body`, `validates :body, presence: true, length: { maximum: 4000 }`, `scope :recent, -> { order(created_at: :desc) }`, and a `destroy` override calling `update!(deleted: true)`.
- **test/fixtures/notes.yml** — Two-row stub fixture (id 1 belonging to user 1, id 2 belonging to user 2) so the fixture loader does not break and the cross-user ownership test can find a note owned by a different user.
- **test/models/note_test.rb** — 8 tests:
  1. 他人のメモは参照できない — readable/updatable/deletable_by? false for other user
  2. 自分のメモは参照できる — predicates true for owner
  3. body_is_required — empty body fails presence
  4. whitespace_only_body_fails_presence — `'   '` fails presence after strip
  5. body_max_length_4000 — 4001 chars fails
  6. body_at_4000_chars_is_valid — 4000 chars passes
  7. recent_scope_orders_by_created_at_desc — SQL contains `ORDER BY ... created_at ... DESC`
  8. destroy_soft_deletes — after `note.destroy`, `Note.find(id)` returns row with `deleted: true`

## Verification

- `bin/rails runner 'Note; puts "ok"'` → `ok`
- `bin/rails test test/models/note_test.rb` → `8 runs, 18 assertions, 0 failures, 0 errors, 0 skips`
- `bin/rails test` (full suite) → `98 runs, 454 assertions, 0 failures, 0 errors, 0 skips`
- `app/models/note.rb` does NOT contain `default_scope` (verified)
- `app/models/note.rb` does NOT define `destroy_logically!` (verified — daddy gem provides it)
- `test/models/note_test.rb` does NOT call `creatable_by?` (Crud::ByUser does not define it)

## Commits

- `eefe2c1` feat(10-02): add Note model with Crud::ByUser and soft-delete
- `a2c4637` test(10-02): add notes fixture stub and Note model tests

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Status | Evidence |
|-----------|--------|----------|
| T-10-04 (cross-user note read, NOTE-03) | mitigated | `include Crud::ByUser`; tests `他人のメモは参照できない` / `自分のメモは参照できる` |
| T-10-05 (DoS via unbounded body) | mitigated | `length: { maximum: 4000 }`; tests at 4000 (ok) and 4001 (fail) |
| T-10-06 (whitespace-only body) | mitigated | `before_validation :strip_body` + `presence: true`; test `whitespace_only_body_fails_presence` |
| T-10-07 (unintended hard-delete) | mitigated | `def destroy; update!(deleted: true); end`; test `destroy_soft_deletes` re-finds the row |

No new threat surface introduced beyond the plan's threat_model.

## Self-Check: PASSED

- FOUND: app/models/note.rb
- FOUND: test/fixtures/notes.yml
- FOUND: test/models/note_test.rb
- FOUND: commit eefe2c1
- FOUND: commit a2c4637
