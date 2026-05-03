# Phase 21: Phase 06 Verification Closure - Research

**Researched:** 2026-05-03  
**Domain:** Verification-evidence closure for Phase 06 NAV contracts (modern + non-modern behavior)  
**Confidence:** HIGH

## User Constraints (from 21-CONTEXT.md)

- **D-01:** Exactly 3 claims: NAV-01, NAV-02, and non-modern unaffected behavior.
- **D-02:** Non-modern claim must cover both `classic` and `simple`.
- **D-03:** Non-modern claim maps to NAV-01/NAV-02 with explicit Phase 6 criterion-4 anchor.
- **D-04:** Non-modern evidence must be interaction-level + structural checks.
- **D-05:** Carry forward Phase 19/20 policy: automated-first evidence, fail-first mismatch logging, minimal-fix scope, one-rerun `dad:test` classification.

## Phase Requirements Mapping

| ID | Requirement | Research support |
|---|---|---|
| P06V-01 | Complete `.planning/phases/06-html-structure/06-VERIFICATION.md` with pass/fail outcomes | Reuse Phase-19 rubric structure (baseline runs + claim table + per-claim blocks); create the missing Phase-06 verification file path. |
| P06V-02 | Verify modern and non-modern navigation/drawer behavior contracts | Keep locked 3-claim model; include explicit classic + simple interaction evidence and structure evidence. |

## Current Code Reality (verified)

- `drawer_ui?` enables drawer UI for signed-in users except `simple` theme:
  - `app/helpers/welcome_helper.rb`
- Layout renders hamburger/drawer when `drawer_ui?` is true and renders simple menu only for simple theme:
  - `app/views/layouts/application.html.erb`
- Drawer JS runs only for `modern` and `classic`:
  - `app/assets/javascripts/menu.js`
- Existing structural test coverage already includes modern/classic/simple branches:
  - `test/controllers/welcome_controller/layout_structure_test.rb`
- Existing Cucumber interaction coverage is modern-focused:
  - `features/03.モダンテーマ.feature`

## Key Gaps / Risks

1. `.planning/phases/06-html-structure/06-VERIFICATION.md` does not exist yet.
2. Non-modern interaction proof is weaker than modern interaction proof; likely needs explicit automation for classic/simple interaction behavior to satisfy D-04.
3. Risk of claim drift (adding NAV-03 or narrowing non-modern scope); Phase 21 must remain fixed at 3 claims.

## Recommended Planning Shape

1. Plan to create/populate `06-VERIFICATION.md` with rubric-compliant sections and three claims.
2. Plan to add/extend automated interaction evidence for:
   - classic branch interaction validity
   - simple branch unaffected behavior
3. Plan to run and log tri-suite gate with one-rerun `dad:test` policy.
4. Plan to handle mismatches with fail-first log + minimal fix + same-update re-verification.

## Suggested Claim Skeleton

| Claim ID | REQ-ID(s) | Summary |
|---|---|---|
| P06-C01 | NAV-01 | Hamburger button/header presence contract |
| P06-C02 | NAV-02 | Drawer structure/interaction contract |
| P06-C03 | NAV-01, NAV-02 (+ Phase 6 criterion-4) | Non-modern unaffected behavior contract (classic + simple) |

## Pitfalls to Avoid

- Treating non-modern as a dependency note instead of a first-class claim.
- Using structure-only evidence for non-modern behavior.
- Running fix-first when mismatches appear (must record FAIL evidence first).
- Forgetting to link criterion-4 anchor from `.planning/milestones/v1.2-ROADMAP.md`.

## Canonical Sources Used

- `.planning/phases/21-phase-06-verification-closure/21-CONTEXT.md`
- `.planning/phases/19-verification-rubric-traceability-baseline/19-VERIFICATION-RUBRIC.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/milestones/v1.2-ROADMAP.md`
- `.planning/milestones/v1.2-REQUIREMENTS.md`
- `app/helpers/welcome_helper.rb`
- `app/views/layouts/application.html.erb`
- `app/assets/javascripts/menu.js`
- `test/controllers/welcome_controller/layout_structure_test.rb`
- `features/03.モダンテーマ.feature`
- `CLAUDE.md`

---

Research is sufficient to plan Phase 21.
