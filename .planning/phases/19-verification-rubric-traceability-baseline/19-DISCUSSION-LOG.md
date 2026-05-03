# Phase 19: Verification Rubric & Traceability Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 19-Verification Rubric & Traceability Baseline
**Areas discussed:** Verification evidence schema, Acceptable evidence threshold, Failure-handling policy, Flake/rerun logging policy

---

## Verification evidence schema

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid schema | Core traceability table + per-claim evidence blocks | ✓ |
| Compact table | Single lightweight table only | |
| Detailed single table | One large all-fields table | |
| You decide | Leave selection to the agent | |

**User's choice:** Hybrid schema.
**Notes:** Also required full 3-suite run records, per-claim confidence labels, and strict manual evidence format.

---

## Acceptable evidence threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Automated-first | Manual evidence only with explicit justification and strict format | ✓ |
| Automation-only | Manual evidence disallowed | |
| Flexible manual | Lightweight manual notes acceptable | |

**User's choice:** Automated-first.
**Notes:** Claims without acceptable evidence must remain FAIL; reviewer sign-off deferred for this milestone.

---

## Failure-handling policy

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal-fix policy | Record FAIL, then apply minimal in-scope fix if needed | ✓ |
| Always fix immediately | Fix regardless of scope size | |
| Doc-only failures | Never fix in v1.5 | |

**User's choice:** Minimal-fix policy.
**Notes:** Require root-cause/action/re-verification entries; broad refactors are deferred and claims remain FAIL until closed.

---

## Flake/rerun logging policy

| Option | Description | Selected |
|--------|-------------|----------|
| One rerun max | One rerun after first failure, with explicit classification | ✓ |
| Two reruns | Up to two reruns | |
| No reruns | Immediate fail only | |

**User's choice:** One rerun max.
**Notes:** Record both first failure and rerun result; repeated failure on rerun is treated as blocker/regression; reference CLAUDE policy in docs.

---

## the agent's Discretion

None.

## Deferred Ideas

None.
