# Domain Pitfalls — v1.5 Verification Debt Cleanup

**Domain:** Backfilling verification docs in a mature Rails app  
**Researched:** 2026-05-03

## Critical Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| Claims without REQ-ID traceability | False “done” status | Require `REQ-ID -> evidence -> result` mapping in each verification doc. |
| Non-reproducible evidence | Audit cannot validate closure | Record commit SHA, exact commands, and outcomes for each verification run. |
| Skipping one suite (especially `dad:test`) | Integration regressions missed | Keep lint + rails test + dad:test as mandatory gate for changed code/tests. |
| Flake laundering (“rerun until green”) | Real bugs misclassified | Log first failure, allow one rerun for known flake pattern, document classification. |
| Scope creep from “minimal fixes” | Milestone slips into refactor | Allow only fixes directly required to make verification claims true. |
| STATE/ROADMAP not synced after closure | Debt remains visible as open | Update deferred-item ledger and phase status immediately after verification completion. |

## Phase-Specific Watchouts

| Target | Watchout | Mitigation |
|--------|----------|------------|
| Phase 05 | Theme claims not tied to THEME-IDs | Build traceability matrix from v1.2 requirements. |
| Phase 06 | Drawer checks ignore non-modern behavior | Include both modern and non-modern contract checks. |
| Phase 09 | Visual claims lack reproducible selector/test evidence | Capture selector-level proof and explicit validation steps. |

## Enforcement Rules

1. No verification doc is acceptable without REQ-ID mapping and concrete evidence.
2. No phase completion update without corresponding verification artifact.
3. No broad refactor under this milestone.
