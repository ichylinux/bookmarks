---
phase: 10-data-layer
plan: 03
subsystem: data-layer
tags: [rails, activerecord, association, routes, has-many]
requires: [10-01]
provides: [user-notes-association, notes-route-surface]
affects: [app/models/user.rb, config/routes.rb]
tech-stack:
  added: []
  patterns: [has_many-dependent-destroy, rails-resources-restful-routes]
key-files:
  created: []
  modified:
    - app/models/user.rb
    - config/routes.rb
decisions:
  - "Used `dependent: :destroy` (not `delete_all`) so `Note#destroy` soft-delete override is invoked when a user is destroyed — matches Bookmark/Todo/Feed/Portal precedent"
  - "Used symbol form `[:create, :destroy]` (not string form) to match CONTEXT.md SC#4 verbatim"
  - "Skipped `inverse_of` and scope on association — soft-delete filtering is `Note.not_deleted`'s responsibility (PATTERNS.md decision)"
  - "Placed `resources :notes` between `:todos` and `:welcome` to keep user-data resources grouped"
metrics:
  duration: ~3min
  completed: 2026-04-30
---

# Phase 10 Plan 03: User-Notes Association & Routes Summary

Wires `User.has_many :notes, dependent: :destroy` and registers `resources :notes, only: [:create, :destroy]`, completing Phase 10's foundation by connecting the Note model (built in Plan 02) to the User aggregate root and exposing the route surface for Phase 11's controller.

## What Was Built

- `User#has_many :notes, dependent: :destroy` association in `app/models/user.rb` (line 14)
- `resources :notes, only: [:create, :destroy]` route declaration in `config/routes.rb` (line 43)

## Tasks Completed

| Task | Name                                          | Commit  | Files                |
| ---- | --------------------------------------------- | ------- | -------------------- |
| 1    | Add has_many :notes association to User model | 906341d | app/models/user.rb   |
| 2    | Add resources :notes to routes.rb             | 9a784e5 | config/routes.rb     |

## Decisions Made

1. **`dependent: :destroy` (not `delete_all`)** — Plan 02 overrides `Note#destroy` to perform a soft-delete (`update!(deleted: true)`). Using `:destroy` ensures the override is invoked per-note when a user is destroyed; `:delete_all` would bypass the override and hard-delete via SQL. Matches the Bookmark/Todo/Feed/Portal precedent in this codebase.
2. **No association scope** — Did not mirror `has_many :portals, -> { where(deleted: false) }`. Per PATTERNS.md, soft-delete filtering at query time is `Note.not_deleted`'s responsibility (provided by daddy gem); the association definition stays clean.
3. **Symbol form `[:create, :destroy]`** — CONTEXT.md SC#4 specifies the exact form verbatim. String form (`['create', 'destroy']`) is also valid Rails but does not match the success criterion text.
4. **Route placement** — Inserted between `resources :todos ... end` and `resources :welcome` block to group with user-data resources.

## Verification

- `grep -c '^  has_many :notes, dependent: :destroy$' app/models/user.rb` → 1
- `grep -c '^  resources :notes, only: \[:create, :destroy\]$' config/routes.rb` → 1
- Skipped `bin/rails runner` and `bin/rails routes` checks: per worktree rails_environment guidance, the Note model is being built in parallel (Plan 10-02) in a separate worktree and does not exist in this one. The `User` model declaring `has_many :notes` would fail to load until orchestrator merges. Regex grep satisfies the literal must_have ("file contains line X").

## Deviations from Plan

None — plan executed exactly as written, modulo the documented worktree-specific verification adjustment (using grep instead of `bin/rails runner`/`bin/rails routes` because the Note model lives in a parallel worktree). This adjustment was pre-authorized by the executor prompt's `<rails_environment>` block.

## Threat Model Status

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-10-09 (hard-delete on user destroy) | mitigate | Mitigated — `dependent: :destroy` calls `Note#destroy`, which Plan 02 overrides to soft-delete |
| T-10-10 (unauthenticated POST /notes) | accept (this phase) | Accepted as documented; Phase 11 controller adds `before_action :authenticate_user!`. No requests succeed yet — controller does not exist (404). |
| T-10-11 (route enumeration) | accept | Accepted; standard Rails behavior |

## Self-Check: PASSED

- FOUND: app/models/user.rb (line `has_many :notes, dependent: :destroy`)
- FOUND: config/routes.rb (line `resources :notes, only: [:create, :destroy]`)
- FOUND commit: 906341d
- FOUND commit: 9a784e5
