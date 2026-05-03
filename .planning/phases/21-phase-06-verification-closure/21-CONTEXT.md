# Phase 21: Phase 06 Verification Closure - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.2 Phase 06 verification by producing `.planning/phases/06-html-structure/06-VERIFICATION.md` with evidence-backed outcomes for NAV-01/NAV-02 plus the non-modern behavior contract that must remain unaffected.

</domain>

<decisions>
## Implementation Decisions

### Claim inventory boundary
- **D-01:** Use exactly 3 claims: one each for NAV-01 and NAV-02, plus one non-modern unaffected contract claim.
- **D-02:** The non-modern claim must cover both `classic` and `simple` themes (not classic-only or simple-only).
- **D-03:** Map the non-modern claim to NAV-01/NAV-02 with an explicit Phase 6 criterion-4 anchor from `.planning/milestones/v1.2-ROADMAP.md`.

### Evidence strictness
- **D-04:** Non-modern unaffected behavior requires interaction-level proof (menu opens/dismisses) plus structural checks.
- **D-05:** Carry forward phase 19/20 verification discipline: automated-first evidence, fail-first mismatch handling, minimal fix scope, and one-rerun `dad:test` policy logging.

### the agent's Discretion
No discretionary implementation areas were left open.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone truth
- `.planning/ROADMAP.md` — Phase 21 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `P06V-01` and `P06V-02` requirement contracts.
- `.planning/PROJECT.md` — v1.5 boundary and minimal-fix policy.
- `.planning/STATE.md` — current sequencing state.

### Verification contract and carry-forward policy
- `.planning/phases/19-verification-rubric-traceability-baseline/19-CONTEXT.md` — locked evidence and failure-handling decisions.
- `.planning/phases/19-verification-rubric-traceability-baseline/19-VERIFICATION-RUBRIC.md` — canonical verification schema.
- `.planning/phases/20-phase-05-verification-closure/20-CONTEXT.md` — recent closure-phase decisions and policy continuity.
- `CLAUDE.md` — mandatory tri-suite gate and one-rerun flake handling.

### Source requirement and phase contract references
- `.planning/milestones/v1.2-REQUIREMENTS.md` — NAV requirement definitions.
- `.planning/milestones/v1.2-ROADMAP.md` — Phase 6 criterion including non-modern unaffected behavior.

### Code and test anchors for Phase 06 verification
- `app/helpers/welcome_helper.rb` — `drawer_ui?` theme-gating contract.
- `app/views/layouts/application.html.erb` — hamburger/drawer markup placement and simple-menu gating.
- `app/assets/javascripts/menu.js` — drawer interaction guard and handlers.
- `test/controllers/welcome_controller/layout_structure_test.rb` — modern/classic/simple structure assertions.
- `features/03.モダンテーマ.feature` — interaction behavior scenarios.

### Codebase references used during discussion
- `.planning/codebase/TESTING.md` — testing stack and evidence conventions.
- `.planning/codebase/CONVENTIONS.md` — JS and Rails coding/testing patterns.
- `.planning/codebase/STRUCTURE.md` — integration points for layout/helper/test files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WelcomeController::LayoutStructureTest` already validates theme-based drawer/hamburger structure including classic/simple paths.
- `features/03.モダンテーマ.feature` and step definitions provide interaction-level drawer behavior patterns that can be reused for verification evidence.
- Existing tri-suite commands and flake handling pattern from Phase 20 can be reused directly.

### Established Patterns
- Drawer visibility is controlled by `drawer_ui?` (`user_signed_in? && favorite_theme != 'simple'`), so classic and modern both participate in drawer UI behavior.
- Verification debt phases use claim tables with per-claim evidence blocks and explicit run linkage.
- Closure phases keep fix scope minimal and claim-coupled when mismatches are found.

### Integration Points
- Primary deliverable path: `.planning/phases/06-html-structure/06-VERIFICATION.md`.
- Primary code anchors: `welcome_helper.rb`, `application.html.erb`, `menu.js`, and existing layout/feature tests.
- Tracking sync points after execution: `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/MILESTONES.md`.

</code_context>

<specifics>
## Specific Ideas

- Preserve explicit evidence that classic must keep hamburger/drawer behavior; this is now a hard contract for Phase 21 verification.
- Treat non-modern unaffected behavior as first-class evidence, not a footnote.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 21-Phase 06 Verification Closure*
*Context gathered: 2026-05-03*
