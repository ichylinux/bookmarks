# Phase 20: Phase 05 Verification Closure - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.2 Phase 05 verification by creating reproducible, claim-level pass/fail evidence for THEME-01..03 in `.planning/phases/05-theme-foundation/05-VERIFICATION.md`, and apply only minimal, scope-bound fixes when a claim is proven mismatched.

</domain>

<decisions>
## Implementation Decisions

### Claim inventory boundary
- **D-01:** Scope claim inventory to Phase 05 requirements only (`THEME-01`, `THEME-02`, `THEME-03`).
- **D-02:** Use one claim per requirement ID; do not collapse all requirements into one claim.
- **D-03:** Cross-phase dependencies (for NAV/A11Y interactions) are captured as dependency notes with linked requirement IDs and target verification-file paths, not duplicated as Phase 05 claims.
- **D-04:** Inventory closure requires all three Phase 05 claims to have explicit `PASS`/`FAIL`, evidence links, and confidence.

### Evidence strategy per claim
- **D-05:** Evidence priority is automated test evidence first, then code reference; manual evidence only when automation is impractical.
- **D-06:** Accept claim-level Minitest/Cucumber assertions tied to each claim, plus baseline three-suite run record.
- **D-07:** Manual fallback must include explicit rationale and step-by-step record.
- **D-08:** Every evidence item must include exact artifact anchors (test name/line or selector) and run-record linkage.

### Mismatch handling policy
- **D-09:** Record `FAIL` with evidence first; never fix-first.
- **D-10:** Allow only localized, claim-coupled minimal fixes.
- **D-11:** If remediation expands to refactor-scale work, keep claim `FAIL` and defer explicitly.
- **D-12:** After minimal fix, re-verify affected claim in the same update with root cause, action taken, and new outcome.

### Closure and rerun logging
- **D-13:** Baseline gate in verification record must include `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`, and chained command line.
- **D-14:** Enforce one rerun max for `dad:test`: pass-on-rerun is logged as pre-existing flake; fail-on-rerun is regression/blocker.
- **D-15:** Flake log rows must include run number, command, outcome, classification, and short policy pointer to `CLAUDE.md`.
- **D-16:** Phase closure cannot be claimed while unresolved claim FAIL remains, unless explicitly deferred and synchronized truthfully across tracking docs.

### the agent's Discretion
No discretionary implementation areas were left open.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone truth
- `.planning/ROADMAP.md` — Phase 20 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `P05V-01` and `P05V-02` requirement contracts.
- `.planning/PROJECT.md` — milestone-level minimal-fix policy and scope boundaries.
- `.planning/STATE.md` — current milestone position and sequencing state.

### Verification contract and policy
- `.planning/phases/19-verification-rubric-traceability-baseline/19-CONTEXT.md` — locked decisions D-01..D-15 carried into closure phases.
- `.planning/phases/19-verification-rubric-traceability-baseline/19-VERIFICATION-RUBRIC.md` — canonical verification structure and evidence requirements.
- `CLAUDE.md` — three-suite gate and one-rerun flake policy.

### Source requirements for Phase 05 closure
- `.planning/milestones/v1.2-REQUIREMENTS.md` — canonical THEME requirement definitions (`THEME-01..03`).
- `.planning/milestones/v1.2-ROADMAP.md` — original Phase 5 success criteria and constraints.

### Codebase references used during discussion
- `.planning/codebase/TESTING.md` — established test-stack conventions and evidence sources.
- `.planning/codebase/CONVENTIONS.md` — project coding/testing conventions relevant to minimal-fix execution.
- `.planning/codebase/STRUCTURE.md` — repository structure and integration points for affected files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing three-suite verification command set and test harness (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`) are already standardized and reusable as baseline evidence.
- Archived v1.2 requirement and roadmap artifacts provide canonical anchors for Phase 05 claim mapping.

### Established Patterns
- Verification debt phases are evidence-first and requirement-anchored; fail-first and minimal-fix policies are already locked by Phase 19.
- Documentation artifacts under `.planning/` are the source of truth for closure status and traceability.

### Integration Points
- Primary deliverable path: `.planning/phases/05-theme-foundation/05-VERIFICATION.md`.
- Tracking sync points: `.planning/ROADMAP.md`, `.planning/STATE.md`, and phase-local artifacts for closure evidence updates.

</code_context>

<specifics>
## Specific Ideas

- Claim ID scheme should stay per requirement (e.g., `P05-C01`..`P05-C03`) with direct `THEME-01..03` mapping.
- Dependency notes should link out-of-scope coupled requirements to their owning verification files instead of duplicating ownership.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- `Extract drawer_ui? helper if condition grows to 4th case` — deferred; belongs to historical Phase 06 layout/view cleanup, not Phase 05 verification closure scope.
- `Gate drawer + drawer-overlay on theme for symmetry` — deferred; belongs to Phase 06 navigation/drawer behavior verification and follow-up.

</deferred>

---

*Phase: 20-Phase 05 Verification Closure*
*Context gathered: 2026-05-03*
