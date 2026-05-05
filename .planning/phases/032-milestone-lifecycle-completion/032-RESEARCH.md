# Phase 32 Research: Milestone Lifecycle Completion

## Objective

Define a strict, reproducible lifecycle closure flow for v1.8 that guarantees zero inconsistency and same-day tri-suite evidence.

## Inputs Reviewed

- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/v1.8-MILESTONE-AUDIT.md`
- `.planning/phases/029-swipe-navigation-foundation/029-CONTEXT.md`
- `.planning/phases/030-persisted-mobile-column-state/030-CONTEXT.md`
- `.planning/phases/031-verification-gate/031-CONTEXT.md`
- `CLAUDE.md`

## Findings

### 1) Current milestone state is closure-ready but not closure-complete

- v1.8 phases 29-31 are marked complete, but milestone-level status is still planning/open.
- Existing audit already identifies concrete gaps (SWIPE-01, TEST-02 evidence depth) and traceability status drift in `REQUIREMENTS.md`.
- Phase 32 must treat these as closure blockers under strict-zero policy.

### 2) Strict policy needs an explicit re-audit loop

- A one-pass "audit then complete" flow is insufficient under D-01/D-02.
- Safer sequence:
  1. Baseline audit snapshot
  2. Fix inconsistency set
  3. Re-run tri-suite same day
  4. Re-audit
  5. Complete only when inconsistency set is empty

### 3) Tri-suite evidence must be command-backed and timestamped

- Policy requires same-day rerun for:
  - `yarn run lint`
  - `bin/rails test`
  - `bundle exec rake dad:test`
- `dad:test` requires flake handling:
  - First failure -> rerun once
  - Fails twice consistently -> regression
  - Fails once then passes -> record as known flake

### 4) Artifact consistency targets

At phase completion, these files must agree on status and narrative:

- `.planning/ROADMAP.md` (phase plan/progress rows and milestone status)
- `.planning/STATE.md` (current phase, progress, last activity, resume pointer)
- `.planning/v1.8-MILESTONE-AUDIT.md` (final status and evidence)
- Milestone completion/archive references (if produced in this phase)

### 5) Risk areas

- Completing lifecycle docs before final tri-suite rerun can create stale evidence.
- Updating roadmap/state without syncing audit conclusion causes contradiction.
- Gap closure for SWIPE-01/TEST-02 may spill into Phase 32.1; Phase 32 must explicitly gate completion on whether those items remain open.

## Recommended Planning Shape

Use two plans:

1. **032-01**: strict audit loop and inconsistency elimination
2. **032-02**: same-day tri-suite execution, final consistency sync, completion and cleanup

Dependency: 032-02 depends on 032-01.

## Verification Strategy

- Gate completion on explicit "inconsistency count = 0".
- Require tri-suite logs/results in final lifecycle artifact.
- Require post-update consistency check across `ROADMAP.md`, `STATE.md`, and milestone audit.
