# Requirements: Bookmarks v1.5 Verification Debt Cleanup

**Defined:** 2026-05-03  
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### Verification Framework

> **Canonical rubric:** `.planning/phases/19-verification-rubric-traceability-baseline/19-VERIFICATION-RUBRIC.md`

- [ ] **VERF-01**: Maintainer can use a shared verification rubric for phases 05, 06, and 09 that defines required evidence fields (REQ-ID mapping, commit SHA, commands, outcomes, rerun notes).
- [ ] **VERF-02**: Maintainer can map each verification claim for phases 05, 06, and 09 to at least one concrete evidence source (test, code reference, or explicit manual check record).

### Phase 05 Closure

- [ ] **P05V-01**: Maintainer can complete `.planning/phases/05-theme-foundation/05-VERIFICATION.md` with pass/fail outcomes for all relevant v1.2 phase 05 requirements.
- [ ] **P05V-02**: Maintainer can apply only minimal supporting code/test fixes when phase 05 verification evidence reveals a real mismatch, then re-verify the affected claims.

### Phase 06 Closure

- [ ] **P06V-01**: Maintainer can complete `.planning/phases/06-html-structure/06-VERIFICATION.md` with pass/fail outcomes for all relevant v1.2 phase 06 requirements.
- [ ] **P06V-02**: Maintainer can verify modern and non-modern navigation/drawer behavior contracts in phase 06 evidence.

### Phase 09 Closure

- [ ] **P09V-01**: Maintainer can complete `.planning/phases/09-full-page-theme-styles/09-VERIFICATION.md` with pass/fail outcomes for all relevant v1.2 phase 09 requirements.
- [ ] **P09V-02**: Maintainer can include reproducible selector/style evidence for phase 09 visual assertions.

### Milestone Sync

- [ ] **MSYN-01**: Maintainer can update `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and `.planning/PROJECT.md` so verification debt status for phases 05/06/09 is accurately reflected after closure.

## Future Requirements

### Verification and Reliability

- **VFYF-01**: Maintainer can codify a formal flake taxonomy and rerun classification policy for Cucumber scenario-order failures.
- **VFYF-02**: Maintainer can define a project-wide minimum cross-phase integration evidence bar for all future verification documents.

### Debt Backlog

- **DEBT-01**: Maintainer can close remaining non-v1.5 deferred debt items (quick tasks, context questions, and non-05/06/09 verification gaps) in a later milestone.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New user-facing product features | v1.5 is verification debt closure only. |
| Broad refactors unrelated to failed verification claims | High risk and not necessary to satisfy milestone goal. |
| Toolchain or framework migrations | Unrelated to this milestone scope and timeline. |
| Closure of deferred items outside phase 05/06/09 verification debt | Explicitly deferred to future milestones. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| VERF-01 | Phase 19 | Pending |
| VERF-02 | Phase 19 | Pending |
| P05V-01 | Phase 20 | Pending |
| P05V-02 | Phase 20 | Pending |
| P06V-01 | Phase 21 | Pending |
| P06V-02 | Phase 21 | Pending |
| P09V-01 | Phase 22 | Pending |
| P09V-02 | Phase 22 | Pending |
| MSYN-01 | Phase 22 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-03*  
*Last updated: 2026-05-03 after v1.5 roadmap traceability validation*
