# Phase 20: Phase 05 Verification Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 20-Phase 05 Verification Closure
**Areas discussed:** Verification claim inventory boundary, Evidence source strategy per claim, Mismatch handling (fail vs minimal fix), Closure gate and rerun logging format

---

## Verification claim inventory boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 05-only claim inventory | Restrict to `THEME-01..03`; capture coupled requirements as dependency notes | ✓ |
| Mixed phase inventory | Include directly-coupled NAV/A11Y claims in same file | |
| Broad milestone inventory | Use one shared v1.2 inventory in `05-VERIFICATION.md` | |

**User's choice:** Phase 05-only claim inventory with dependency notes for cross-phase items.
**Notes:** One claim per requirement ID; completion requires all three claims with `PASS`/`FAIL`, evidence link, and confidence.

---

## Evidence source strategy per claim

| Option | Description | Selected |
|--------|-------------|----------|
| Automated-first evidence | Claim-level test evidence first; code refs secondary; manual only with rationale | ✓ |
| Code-reference primary | Code references can stand as primary claim proof | |
| Manual-first flexibility | Manual checks can be primary where convenient | |

**User's choice:** Automated-first with strict manual fallback.
**Notes:** Accepted automated evidence must map to specific claim assertions; evidence entries require exact path anchors and baseline run linkage.

---

## Mismatch handling (fail vs minimal fix)

| Option | Description | Selected |
|--------|-------------|----------|
| Fail-first + minimal localized fix | Record `FAIL`, then apply smallest direct remediation when eligible | ✓ |
| Fix-first | Patch first, then backfill verification state | |
| No-fix verification-only | Never allow support fixes within the phase | |

**User's choice:** Fail-first with minimal localized remediation only.
**Notes:** Refactor-scale remediation remains deferred with explicit `FAIL`; re-verification in same update is mandatory.

---

## Closure gate and rerun logging format

| Option | Description | Selected |
|--------|-------------|----------|
| Full three-suite baseline + one-rerun policy | Record all commands/outcomes; one rerun cap for `dad:test` with classification | ✓ |
| Cucumber-only closure gate | Use `dad:test` only for closure decision | |
| Ad hoc command logging | Record whichever commands happened to run | |

**User's choice:** Full baseline gate with structured rerun logging.
**Notes:** Flake log rows must include run number, command, outcome, classification, and policy pointer; unresolved `FAIL` blocks closure unless explicitly deferred and synchronized.

---

## the agent's Discretion

None.

## Deferred Ideas

- `Extract drawer_ui? helper if condition grows to 4th case` — noted, out of Phase 20 scope.
- `Gate drawer + drawer-overlay on theme for symmetry` — noted, out of Phase 20 scope.
