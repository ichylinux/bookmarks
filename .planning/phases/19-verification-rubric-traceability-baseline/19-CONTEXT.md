# Phase 19: Verification Rubric & Traceability Baseline - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Define one reusable, reproducible verification contract for phases 05/06/09 so downstream verification work uses the same evidence schema, acceptance threshold, and failure-handling policy.

</domain>

<decisions>
## Implementation Decisions

### Verification schema
- **D-01:** Use a **hybrid schema**: a core traceability table plus per-claim evidence blocks.
- **D-02:** Every verification file must include full 3-suite run evidence (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`) with commit SHA and outcomes.
- **D-03:** Per-claim confidence level (HIGH/MEDIUM/LOW) is required, with a short rationale.

### Evidence acceptance threshold
- **D-04:** Acceptance is **automated-first**; manual evidence is allowed only when automation is not practical and must include explicit justification.
- **D-05:** If a claim has no acceptable evidence, status is **FAIL** (not pending-pass).
- **D-06:** Minimum evidence bundle per claim: requirement row, artifact link/reference, run record reference, and confidence note.
- **D-07:** Reviewer sign-off is deferred; not a mandatory requirement for v1.5.

### Failure handling
- **D-08:** On failure, record FAIL first; apply only minimal in-scope supporting fixes when needed.
- **D-09:** Failed-claim entries must include short root-cause note, action taken, and re-verification result.
- **D-10:** If corrective scope expands into refactor-scale work, keep claim FAIL and defer with a tracked future item.
- **D-11:** Re-verification after minimal fixes is mandatory in the same verification update.

### Flake/rerun logging
- **D-12:** Rerun cap is one rerun after first failure.
- **D-13:** When rerun passes, record both first failure and rerun result, and classify as pre-existing flake/non-regression.
- **D-14:** If rerun also fails, classify as real regression/blocker for closure.
- **D-15:** Reference `CLAUDE.md` flake policy and include a concise inline summary in each verification doc.

### the agent's Discretion
No open "you decide" areas remain from this discussion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone scope
- `.planning/ROADMAP.md` — Phase 19 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — v1.5 requirement IDs and traceability mapping.
- `.planning/PROJECT.md` — milestone boundary and minimal-fix policy context.
- `.planning/STATE.md` — current milestone status and carry-forward constraints.

### Original requirement source for 05/06/09 verification
- `.planning/milestones/v1.2-REQUIREMENTS.md` — canonical THEME/NAV/STYLE/A11Y requirement definitions.
- `.planning/milestones/v1.2-ROADMAP.md` — original phase 5/6/9 success criteria and implementation constraints.

### Verification policy
- `CLAUDE.md` — mandatory 3-suite gate and one-rerun flake handling policy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing project verification commands and pipelines (`yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`) can be referenced directly in the rubric template.
- Archived v1.2 requirement and roadmap artifacts provide stable source material for requirement-to-evidence mapping in phases 20–22.

### Established Patterns
- Verification and planning artifacts are phase-scoped under `.planning/phases/{phase-slug}/`.
- Requirement IDs are treated as source-of-truth anchors for traceability.
- Scope guardrail is strict: no new feature capability inside verification debt phases.

### Integration Points
- Phase 19 outputs feed phases 20/21/22 verification doc updates.
- Milestone synchronization in phase 22 must align ROADMAP/STATE/MILESTONES/PROJECT with verification closure outcomes.

</code_context>

<specifics>
## Specific Ideas

- Hybrid verification layout:
  1. Core table for quick requirement coverage scan.
  2. Per-claim evidence blocks for reproducibility and nuanced outcomes.
- Explicit flake classification entries to separate true regressions from pre-existing scenario-order instability.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 19-Verification Rubric & Traceability Baseline*
*Context gathered: 2026-05-03*
