# Feature Landscape — v1.5 Verification Debt Cleanup

**Domain:** Verification/documentation debt closure for shipped phases  
**Researched:** 2026-05-03

## Table Stakes

| Feature | Complexity | Notes |
|---------|------------|-------|
| Complete `05-VERIFICATION.md` | Medium | Must map each claim to concrete implementation/test evidence. |
| Complete `06-VERIFICATION.md` | Medium | Must include nav/drawer contract evidence and non-modern regression checks. |
| Complete `09-VERIFICATION.md` | Medium | Must include style/selector evidence and reproducible checks. |
| Requirement-to-evidence traceability | Medium | Each requirement claim links to proof (tests, files, command outputs, or explicit manual check). |
| Reproducible verification run records | Low | Commands, commit SHA, timestamps, and outcomes captured per phase. |

## Differentiators

| Feature | Complexity | Notes |
|---------|------------|-------|
| Common verification rubric across 05/06/09 | Low | Consistent quality bar for evidence completeness and acceptance. |
| Confidence labeling on claims | Low | HIGH/MEDIUM/LOW confidence reduces hidden risk in debt closure. |
| Cross-phase integration checks | Medium | Confirms phase-local docs still match current integrated app behavior. |

## Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| New user-facing features | Out of scope for this milestone. |
| Broad refactors | High risk with weak relevance to verification debt closure. |
| Tooling/platform migrations | Unrelated to v1.5 goal and likely to delay closure. |
| “Rerun until green” evidence | Masks regressions and undermines auditability. |

## Scope Recommendation

1. Close verification debt for 05/06/09 first.
2. Allow only minimal supporting fixes required by failed verification evidence.
3. Defer unrelated backlog/quick tasks to future milestones.
