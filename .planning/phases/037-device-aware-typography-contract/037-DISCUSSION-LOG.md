# Phase 37: Device-aware Typography Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 037-device-aware-typography-contract
**Areas discussed:** Theme precedence

---

## Theme precedence

| Option | Description | Selected |
|--------|-------------|----------|
| `common.css.scss` authoritative | Keep final font-size authority in `body.font-size-*`; themes follow with `inherit/rem` | ✓ |
| Theme-authoritative | Each theme owns base `body` font-size and overrides common contract | |
| Hybrid | Common default with selective theme overrides for some components | |

**User's choice:** `common.css.scss` as final authority; themes should follow with `inherit/rem`.
**Notes:** This is fixed for Phase 37 to avoid cascade ambiguity.

---

## Medium baseline source

| Option | Description | Selected |
|--------|-------------|----------|
| Shared CSS variables in common + existing mobile breakpoint | Define medium baseline in common and switch by responsive breakpoint | ✓ |
| Per-theme medium definitions | Allow each theme to define device baselines separately | |
| Ruby-side device branching | Determine device in Ruby and emit different classes | |

**User's choice:** Shared CSS variables in `common.css.scss` with existing breakpoint switching.
**Notes:** Keeps device logic in CSS and avoids server/device detection complexity.

---

## Theme px handling scope

| Option | Description | Selected |
|--------|-------------|----------|
| High-impact selectors only in Phase 37 | Targeted `inherit/rem` adjustments now; full conversion later | ✓ |
| Full theme conversion now | Convert broad theme typography to `rem` in this phase | |
| `!important` fallback | Force precedence via `!important` | |

**User's choice:** High-impact selectors only in Phase 37.
**Notes:** Full `px -> rem` normalization deferred.

---

## Phase 37 test contract

| Option | Description | Selected |
|--------|-------------|----------|
| Automated precedence + 3-theme representative selector checks | Add regression tests to lock cascade behavior in modern/classic/simple | ✓ |
| Minimal automation + manual checks | Keep tests light and rely on visual checks | |
| Defer test expansion to Phase 39 | Add no new tests in Phase 37 | |

**User's choice:** Add automated precedence contract tests in Phase 37.
**Notes:** This became a hard requirement for phase acceptance.

---

## the agent's Discretion

- Final selector shortlist per theme for "high-impact" adjustments is delegated to planning/research, constrained by the chosen precedence model.

## Deferred Ideas

- Full theme-wide typography conversion (`px -> rem`) in a future phase.
- Extra UX affordances (size preview/helper text) remain v2 scope.
