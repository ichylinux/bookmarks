# Shared verification rubric (Phases 05 / 06 / 09)

**Status:** Baseline for v1.5 Verification Debt Cleanup  
**Applies to:** `.planning/phases/05-theme-foundation/05-VERIFICATION.md`, `06-html-structure/06-VERIFICATION.md`, `09-full-page-theme-styles/09-VERIFICATION.md`  
**Requirements satisfied by this contract:** VERF-01, VERF-02 (see `.planning/REQUIREMENTS.md`)

This document is normative for how those verification files must be structured and what evidence is acceptable. Phases 20–22 populate the files; Phase 19 defines the contract only.

---

## 1. Mandatory baseline — repository verification runs

Every phase verification document that claims closure readiness MUST begin with a **baseline runs** subsection containing:

| Field | Required content |
|-------|------------------|
| **Commit SHA** | Full 40-character git SHA (or annotated tag + SHA) for the tree that was verified |
| **Recorded date** | ISO-8601 date/time and timezone |
| **Lint** | Exact command: `yarn run lint` — outcome (pass / fail) and brief log pointer or excerpt |
| **Minitest** | Exact command: `bin/rails test` — outcome and summary line (e.g. runs/assertions) |
| **Cucumber** | Exact command: `bundle exec rake dad:test` — outcome (0 failed scenarios or not) |
| **Combined full check** | Single line showing chained command: `yarn run lint && bin/rails test && bundle exec rake dad:test` |

If any baseline suite fails, the document MUST NOT claim milestone closure for that phase; record FAIL at baseline level before per-claim sections.

---

## 2. Hybrid layout — core table + per-claim blocks

### 2.1 Core traceability table (coverage scan)

Maintain one master table per verification file with minimum columns:

| Claim ID | REQ-ID(s) | Claim summary | Status (PASS/FAIL) | Confidence (HIGH/MEDIUM/LOW) | Evidence block § |
|----------|-----------|-----------------|-------------------|------------------------------|------------------|

**Claim ID** — Stable within the file: `P05-C01`, `P06-C12`, etc.

**REQ-ID(s)** — Anchors to `.planning/milestones/v1.2-REQUIREMENTS.md` (THEME/NAV/STYLE/A11Y IDs as applicable). Multiple IDs allowed per row.

**Confidence** — REQUIRED with one-line rationale in the linked evidence block (CONTEXT D-03).

### 2.2 Per-claim evidence block template

For each Claim ID row, include a subsection:

```markdown
### <Claim ID> — <short title>

- **Requirement rows:** (quote or cite REQ-ID + bullet text from v1.2 requirements archive)
- **Evidence type:** automated test | code reference | manual check record
- **Artifact:** path + anchor (e.g. `test/foo_test.rb:42`, `app/assets/stylesheets/modern.scss` selector `#header-nav`, or structured manual steps)
- **Run record:** pointer to baseline § or additional command transcript if claim-specific run was needed
- **Confidence:** HIGH | MEDIUM | LOW — rationale in one sentence
- **Manual justification:** (only if evidence type is manual) why automation is impractical
```

**Acceptance threshold (CONTEXT D-04–D-06):**

- Prefer automated evidence. Manual evidence is allowed only with explicit justification.
- If no acceptable evidence exists for a claim, status MUST be **FAIL**, not “pending pass”.
- Minimum bundle per claim: requirement citation + artifact + run reference + confidence note.

---

## 3. Failure handling

When a claim is FAIL (CONTEXT D-08–D-11):

1. Record FAIL first with evidence.
2. Apply only minimal in-scope code/test fixes if they directly remediate the mismatch; then re-verify **in the same verification update**.
3. Include: root cause (short), action taken, re-verification outcome.
4. If fixing would require refactor-scale work, leave FAIL and add an explicit deferred item referencing backlog/milestone — do not silently downgrade.

---

## 4. Flake and rerun logging (`dad:test`)

**Policy source:** `CLAUDE.md` — Cucumber scenario-order-dependent flakes; **at most one rerun** after first failure.

Each verification document MUST include a **Flake / rerun log** subsection summarizing:

| Run | Command | Outcome | Classification |
|-----|---------|---------|----------------|
| 1 | `bundle exec rake dad:test` | fail / pass | … |
| 2 (optional rerun) | same | fail / pass | pre-existing flake vs regression |

Rules (CONTEXT D-12–D-15):

- **Rerun cap:** one rerun after first failure.
- If rerun passes after first failure: record both runs; classify as pre-existing flake / non-regression when consistent with `CLAUDE.md` guidance.
- If rerun also fails: classify as regression / blocker for closure.
- Inline a one-line pointer that full flake symptoms and rationale live in `CLAUDE.md` § “Cucumber suite — known flakiness”.

---

## 5. Reproducibility

Another maintainer MUST be able to:

1. Check out the recorded **Commit SHA**.
2. Re-run the same commands from the baseline section.
3. Reconcile outcomes with the documented PASS/FAIL and flake classifications.

---

## 6. Reviewer sign-off

Formal reviewer sign-off is **not** required for v1.5 (CONTEXT D-07). Optional peer review is allowed.

---

*Canonical path:* `.planning/phases/19-verification-rubric-traceability-baseline/19-VERIFICATION-RUBRIC.md`
