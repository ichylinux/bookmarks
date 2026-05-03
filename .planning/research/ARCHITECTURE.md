# Architecture Patterns — v1.5 Verification Debt Cleanup

**Domain:** Planning + verification workflow integration  
**Researched:** 2026-05-03

## Recommended Architecture

Documentation-first flow:

1. Reconstruct evidence for Phase 05/06/09 from existing requirements + implementation.
2. Author missing verification artifacts.
3. Apply the smallest code/test patch only when evidence fails.
4. Re-verify and update milestone tracking docs.

## Components and Roles

| Component | Responsibility |
|-----------|----------------|
| `.planning/PROJECT.md` | v1.5 milestone goal and active requirements |
| `.planning/milestones/v1.2-REQUIREMENTS.md` | Canonical REQ IDs for phases 05/06/09 |
| `05/06/09-VERIFICATION.md` | Source-of-truth evidence records |
| `.planning/ROADMAP.md` | Phase mapping and completion state |
| `.planning/STATE.md` | Current position + deferred debt ledger updates |
| `.planning/MILESTONES.md` | Milestone closure summary and archived outcomes |

## Traceability Flow

`v1.2 requirements -> v1.5 verification docs -> ROADMAP/STATE status -> MILESTONES closeout`

No phase should move to complete status without verification artifacts containing concrete evidence.

## Safe Build Order

1. Build REQ-ID traceability matrix for 05/06/09.
2. Complete `05-VERIFICATION.md`.
3. Complete `06-VERIFICATION.md`.
4. Complete `09-VERIFICATION.md`.
5. Consolidate ROADMAP/STATE/MILESTONES/PROJECT updates.

## Anti-Patterns

- Marking phase complete before writing verification evidence
- Expanding scope into unrelated refactors
- Updating summary docs without links to verification artifacts
