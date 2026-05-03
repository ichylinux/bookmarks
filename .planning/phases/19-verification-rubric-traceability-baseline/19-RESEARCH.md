# Phase 19 — Technical Research

**Question:** What do maintainers need to know to plan a shared verification rubric for phases 05/06/09?

## Summary

Phase 19 is documentation-only: define one **hybrid** artifact pattern (coverage table + per-claim evidence blocks) so phases 20–22 can close `05-VERIFICATION.md`, `06-VERIFICATION.md`, and `09-VERIFICATION.md` without diverging schemas. The codebase already mandates a **three-suite gate** and a **one-rerun** Cucumber flake policy in `CLAUDE.md`; the rubric must embed those commands verbatim and require logged commit SHA plus run transcripts or equivalent outcomes.

Canonical requirement text for mapping lives in `.planning/milestones/v1.2-REQUIREMENTS.md` and phase goals in `.planning/milestones/v1.2-ROADMAP.md`. v1.5 `REQUIREMENTS.md` defines VERF-01 / VERF-02.

## Approaches Considered

| Approach | Pros | Cons |
|----------|------|------|
| Table-only rubric | Fast to scan | Poor reproducibility for nuanced UI/style claims |
| Narrative-only rubric | Flexible | Weak REQ-ID traceability; easy to skip SHA/commands |
| **Hybrid (chosen in CONTEXT)** | Coverage scan + deep evidence per claim | Slightly longer docs; needs template discipline |

## Stack & Commands (non-negotiable)

From `CLAUDE.md`:

| Suite | Command |
|-------|---------|
| Lint | `yarn run lint` |
| Minitest | `bin/rails test` |
| Cucumber | `bundle exec rake dad:test` |

Full local check: `yarn run lint && bin/rails test && bundle exec rake dad:test`.

Flake policy: one rerun after first `dad:test` failure; consistent failure across two runs = regression; single-run flake = pre-existing per project policy.

## Downstream Consumers

- Phase 20: `05-theme-foundation/05-VERIFICATION.md`
- Phase 21: `06-html-structure/06-VERIFICATION.md`
- Phase 22: `09-full-page-theme-styles/09-VERIFICATION.md` (+ milestone sync elsewhere)

Phase 19 does **not** fill those files; it ships the rubric template and traceability rules only.

## Risks

- **False closure:** Claims marked pass without SHA/commands — mitigated by mandatory baseline section and FAIL-if-no-evidence rule (CONTEXT D-05).
- **Schema drift:** Later phases invent columns — mitigated by single canonical rubric path referenced from `REQUIREMENTS.md`.

## Validation Architecture

This phase validates **documentation and planning artifacts**, not application runtime behavior.

**Dimensions:**

1. **Artifact completeness** — Rubric file exists at the canonical path; required sections present (baseline runs, hybrid templates, failure/flake policy).
2. **Traceability** — Every verification claim in downstream docs must cite REQ-ID (from v1.2 requirements archive), evidence type (test path / code reference / manual record), and confidence.
3. **Reproducibility** — Another maintainer can re-run the same commands at the logged SHA; rerun outcomes documented per D-12–D-14.

**Automated verification for Phase 19 execution:**

- After doc edits: full three-suite green bar from repo root (same as any phase completion).
- Optional grep checks: rubric contains exact command strings `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`.

**Sampling:** N/A — low risk doc phase; full suite on completion per project policy.

---

## RESEARCH COMPLETE
