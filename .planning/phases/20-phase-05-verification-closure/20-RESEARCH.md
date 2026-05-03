# Phase 20: Phase 05 Verification Closure - Research

**Researched:** 2026-05-03  
**Domain:** Verification closure for v1.2 Phase 05 (`THEME-01..03`)  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- `Extract drawer_ui? helper if condition grows to 4th case` — deferred; belongs to historical Phase 06 layout/view cleanup, not Phase 05 verification closure scope.
- `Gate drawer + drawer-overlay on theme for symmetry` — deferred; belongs to Phase 06 navigation/drawer behavior verification and follow-up.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| P05V-01 | Complete `05-VERIFICATION.md` with pass/fail outcomes for relevant Phase 05 requirements | Claim template, evidence anchors, baseline gate commands, and file/path readiness checks |
| P05V-02 | Apply only minimal claim-coupled fixes when mismatch is found, then re-verify | Fail-first policy, minimal-fix boundary, rerun/reclassification rules, and likely mismatch hotspot (`THEME-03`) |
</phase_requirements>

## Summary

Phase 20 is a verification-and-traceability closure phase, not a feature-build phase. The key output is a complete `.planning/phases/05-theme-foundation/05-VERIFICATION.md` with three claim rows mapped 1:1 to `THEME-01..03`, each with `PASS`/`FAIL`, evidence anchors, run linkage, and confidence.

The project’s mandatory closure gate is the 3-suite chain (`yarn run lint && bin/rails test && bundle exec rake dad:test`) with one rerun max for `dad:test` failures.

A critical planning risk is requirement drift: `THEME-03` demands a `body.modern` guard, but current `menu.js` guard is `modern || classic`; this may require either a justified FAIL/defer or a minimal claim-coupled remediation decision.

**Primary recommendation:** Plan this phase as evidence production first, with explicit mismatch adjudication for `THEME-03` before any code edits.

## Project Constraints (from copilot-instructions.md)

`copilot-instructions.md` is not present in repo root.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| THEME-01 verification (theme select + body class) | Frontend Server (SSR) | Browser / Client | SSR view/controller renders and persists preference; browser confirms resulting body class |
| THEME-02 verification (modern stylesheet contract) | Browser / Client | CDN / Static | CSS tokens/selectors are client-applied static assets |
| THEME-03 verification (menu.js guard behavior) | Browser / Client | Frontend Server (SSR) | Guard executes in client JS; SSR only supplies body class/theme context |
| Baseline tri-suite reproducibility record | API / Backend | — | Test execution and command logs are backend/tooling responsibility |

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| Rails | 8.1.3 | App/test runtime (`bin/rails test`) | Existing project runtime and test harness |
| Minitest | 5.27.0 | Claim-level assertions for controller/assets checks | Existing repo test framework |
| Cucumber (`dad:test`) | 9.2.1 (`cucumber`), 4.0.1 (`cucumber-rails`) | Behavior-level evidence for UI interactions | Project policy mandates `bundle exec rake dad:test` |
| ESLint | 9.39.4 (locked) | JS lint baseline evidence | Explicitly required in baseline gate |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|---|---|---|---|
| Capybara | 3.40.0 | Browser assertions through Cucumber | For interactive claims/manual fallback reduction |
| Selenium WebDriver | 4.43.0 | Browser driver for Cucumber | Needed by `dad:test` execution path |
| Prettier | 3.8.3 (locked) | JS formatting consistency | Only if minimal JS fix is required |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| `bundle exec rake dad:test` | `bundle exec cucumber` | Conflicts with project policy in `CLAUDE.md`; avoid for closure evidence |

**Installation:**
```bash
bundle install
yarn install
```

## Architecture Patterns

### System Architecture Diagram

```text
v1.2 THEME requirements
        ↓
Claim inventory (P05-C01..C03, 1:1 mapping)
        ↓
Run baseline gate:
yarn lint → rails test → dad:test
        ↓
Collect evidence anchors
(test path/line, code path/selector, run record)
        ↓
Claim decision per THEME-01..03
 PASS ───────────────→ record PASS + confidence
 FAIL → record FAIL first → minimal fix? (only claim-coupled)
                         ↓
                     re-verify same update
```

### Recommended Project Structure

```text
.planning/
└── phases/
    ├── 05-theme-foundation/
    │   └── 05-VERIFICATION.md   # Target artifact (currently missing)
    └── 20-phase-05-verification-closure/
        ├── 20-CONTEXT.md
        ├── 20-UI-SPEC.md
        └── 20-RESEARCH.md
```

### Pattern 1: Hybrid Claim Verification Entry
**What:** Core claim table + per-claim evidence block with explicit artifact/run anchors.  
**When to use:** Every Phase 05 claim row (`THEME-01..03`).  
**Example:**
```markdown
### P05-C03 — menu.js guard behavior
- Requirement rows: THEME-03
- Evidence type: automated test + code reference
- Artifact: app/assets/javascripts/menu.js:2
- Run record: baseline §
- Confidence: HIGH — direct source match
```

### Anti-Patterns to Avoid
- **Fix-first verification:** Violates locked decision D-09; must record FAIL first.
- **Ad-hoc evidence notes without anchors:** Violates D-08 and rubric minimum bundle.
- **Phase bleed:** Adding NAV/A11Y as Phase 05 claims; must be dependency notes only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Verification schema | Custom markdown format | Phase 19 canonical rubric | Prevents schema drift across phases |
| Cucumber invocation policy | Direct cucumber command path | `bundle exec rake dad:test` | Required project gate semantics |
| Flake handling | Unlimited reruns/manual judgment | One rerun + classification table | Locked policy and reproducibility |

## Common Pitfalls

### Pitfall 1: Missing target artifact path
**What goes wrong:** Planner assumes `05-VERIFICATION.md` already exists.  
**How to avoid:** Include a first plan task to create `.planning/phases/05-theme-foundation/` and `05-VERIFICATION.md` if missing.

### Pitfall 2: THEME-03 requirement drift
**What goes wrong:** Requirement says `body.modern` guard, but code currently allows `classic` too.  
**How to avoid:** Explicitly decide PASS/FAIL criteria against archived requirement wording before touching code.

### Pitfall 3: False closure with incomplete baseline evidence
**What goes wrong:** Claim PASS without linked tri-suite run record.  
**How to avoid:** Make baseline section mandatory precondition for claim statuses.

### Pitfall 4: Misclassified Cucumber flake
**What goes wrong:** Single failing run treated as regression without allowed rerun classification.  
**How to avoid:** Enforce run-1/run-2 logging template with policy pointer.

## Code Examples

### Existing guard hotspot for THEME-03
```javascript
// app/assets/javascripts/menu.js
if (!$('body').hasClass('modern') && !$('body').hasClass('classic')) return;
```
Source: `app/assets/javascripts/menu.js:2`

### Existing THEME-01 UI source
```erb
<%= f.select :theme, { t('.theme_options.modern') => 'modern', t('.theme_options.classic') => 'classic', t('.theme_options.simple') => 'simple' } %>
```
Source: `app/views/preferences/index.html.erb:15`

