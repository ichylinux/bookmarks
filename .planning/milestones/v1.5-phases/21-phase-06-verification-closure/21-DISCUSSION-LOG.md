# Phase 21: Phase 06 Verification Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 21-Phase 06 Verification Closure
**Areas discussed:** Claim boundary

---

## Claim boundary

| Option | Description | Selected |
|--------|-------------|----------|
| 3 claims | NAV-01, NAV-02, and a non-modern unaffected contract claim | ✓ |
| 2 claims only | NAV-01 and NAV-02; non-modern handled as dependency note | |
| 4+ claims | Include NAV-03 in this phase too | |

**User's choice:** 3 claims (NAV-01, NAV-02, non-modern unaffected claim)
**Notes:** Non-modern contract must not be dropped to a dependency note.

| Option | Description | Selected |
|--------|-------------|----------|
| Both classic and simple | Existing non-modern menu behavior remains intact with no drawer-regression side effects | ✓ |
| Classic only | Verify dropdown/menu behavior for classic theme only | |
| Simple only | Verify simple-menu path only | |

**User's choice:** Both classic and simple
**Notes:** Non-modern verification scope is explicitly both themes.

| Option | Description | Selected |
|--------|-------------|----------|
| Interaction-level proof | Behavior evidence (menu opens/dismisses) plus structural checks | ✓ |
| Structure-only proof | Markup/theme gating checks only | |
| Manual-only proof | Manual evidence without automated assertions | |

**User's choice:** Interaction-level proof
**Notes:** Behavior parity is mandatory for the non-modern claim.

| Option | Description | Selected |
|--------|-------------|----------|
| NAV-01/NAV-02 + Phase-6 criterion-4 | Map non-modern claim to both IDs with explicit criterion anchor | ✓ |
| NAV-01 only | Map non-modern claim to NAV-01 only | |
| NAV-02 only | Map non-modern claim to NAV-02 only | |

**User's choice:** NAV-01/NAV-02 + Phase-6 criterion-4 anchor
**Notes:** Requirement mapping must explicitly reference the roadmap criterion text.

---

## the agent's Discretion

None.

## Deferred Ideas

None.
