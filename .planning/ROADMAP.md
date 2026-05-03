# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- 🚧 **v1.5 — Verification Debt Cleanup** — Phases 19–22 (in progress)

## Phases

- [x] **Phase 19: Verification Rubric & Traceability Baseline** - Shared verification contract and evidence mapping for phases 05/06/09.
- [x] **Phase 20: Phase 05 Verification Closure** - Close phase 05 verification document with evidence-backed outcomes and minimal fixes only when required.
- [ ] **Phase 21: Phase 06 Verification Closure** - Close phase 06 verification document including modern/non-modern navigation and drawer contracts.
- [ ] **Phase 22: Phase 09 Verification Closure & Milestone Sync** - Close phase 09 verification evidence and synchronize milestone tracking documents.

## Phase Details

### Phase 19: Verification Rubric & Traceability Baseline
**Goal**: Maintainers can verify phases 05/06/09 using one reproducible evidence rubric with explicit requirement-to-evidence mappings.
**Depends on**: Phase 18.2
**Requirements**: VERF-01, VERF-02
**Success Criteria** (what must be TRUE):
  1. Maintainer can use a single rubric for phases 05/06/09 that captures REQ-ID mapping, commit SHA, commands run, outcomes, and rerun notes.
  2. For every verification claim in phases 05/06/09 scope, maintainer can point to at least one concrete evidence source (test, code reference, or manual check record).
  3. Verification records are reproducible by another maintainer using only the logged SHA and command history.
**Plans**: 01 — Verification rubric + canonical pointers

### Phase 20: Phase 05 Verification Closure
**Goal**: Maintainers can truthfully close v1.2 phase 05 verification with complete pass/fail evidence and only minimal scope-bound corrections.
**Depends on**: Phase 19
**Requirements**: P05V-01, P05V-02
**Success Criteria** (what must be TRUE):
  1. `.planning/phases/05-theme-foundation/05-VERIFICATION.md` is complete with pass/fail outcomes for all relevant v1.2 phase 05 requirements.
  2. Any failed claim is either recorded as fail with evidence or corrected with the smallest supporting code/test change directly tied to that claim.
  3. After any supporting fix, affected phase 05 claims are re-verified and evidence is updated in the same verification record.
**Plans**: 01 — Verification artifact and baseline evidence, 02 — THEME-03 fail-first remediation and re-verification
**UI hint**: yes

### Phase 21: Phase 06 Verification Closure
**Goal**: Maintainers can truthfully close v1.2 phase 06 verification including navigation and drawer behavior contracts across supported themes.
**Depends on**: Phase 19
**Requirements**: P06V-01, P06V-02
**Success Criteria** (what must be TRUE):
  1. `.planning/phases/06-html-structure/06-VERIFICATION.md` is complete with pass/fail outcomes for all relevant v1.2 phase 06 requirements.
  2. Verification evidence demonstrates modern-theme navigation/drawer behavior contracts under expected interactions.
  3. Verification evidence also demonstrates non-modern behavior contracts so regressions or false assumptions are visible.
**Plans**: 01 — Verification artifact + non-modern interaction evidence, 02 — Baseline closure + fail-first mismatch handling
**UI hint**: yes

### Phase 22: Phase 09 Verification Closure & Milestone Sync
**Goal**: Maintainers can close v1.2 phase 09 verification with reproducible style evidence and then accurately reflect closure status in milestone tracking artifacts.
**Depends on**: Phase 20, Phase 21
**Requirements**: P09V-01, P09V-02, MSYN-01
**Success Criteria** (what must be TRUE):
  1. `.planning/phases/09-full-page-theme-styles/09-VERIFICATION.md` is complete with pass/fail outcomes for all relevant v1.2 phase 09 requirements.
  2. Visual/style assertions in phase 09 include reproducible selector-level evidence that another maintainer can validate.
  3. After 05/06/09 closure, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and `.planning/PROJECT.md` consistently report the same verification debt status.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 19. Verification Rubric & Traceability Baseline | 1/1 | Complete | 2026-05-03 |
| 20. Phase 05 Verification Closure | 2/2 | Complete | 2026-05-03 |
| 21. Phase 06 Verification Closure | 0/2 | Planned | - |
| 22. Phase 09 Verification Closure & Milestone Sync | 0/TBD | Not started | - |

---
*Last updated: 2026-05-03 — Phase 21 discussed/UI-specified/planned; ready to execute.*
