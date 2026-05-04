# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- **v1.6 — Note Gadget for All Themes** — Phases 23–25 (active)

## Phases

<details>
<summary>✅ v1.5 — Verification Debt Cleanup (Phases 19–22) — SHIPPED 2026-05-04</summary>

- [x] Phase 19: Verification Rubric & Traceability Baseline (1/1 plans) — completed 2026-05-03
- [x] Phase 20: Phase 05 Verification Closure (2/2 plans) — completed 2026-05-03
- [x] Phase 21: Phase 06 Verification Closure (2/2 plans) — completed 2026-05-03
- [x] Phase 22: Phase 09 Verification Closure & Milestone Sync (2/2 plans) — completed 2026-05-04

</details>

### v1.6 — Note Gadget for All Themes

- [ ] **Phase 23: View & Navigation Integration** — Render note panel for modern/classic themes and add drawer nav Note link
- [ ] **Phase 24: CSS Styling & Localization Verification** — Style note panel for modern and classic themes; verify all labels render in ja/en
- [ ] **Phase 25: Tests & Phase Gate** — Minitest integration tests for modern and classic note panel; Cucumber E2E for modern theme note capture

## Phase Details

### Phase 23: View & Navigation Integration
**Goal**: Users on modern and classic themes can reach and see the note gadget from the welcome page
**Depends on**: Nothing (continues from v1.5 Phase 22)
**Requirements**: NOTE-01, NOTE-02, NOTE-03, NOTE-04
**Success Criteria** (what must be TRUE):
  1. User on modern theme with `use_note` enabled navigates to `/?tab=notes` and sees the note capture form and note list
  2. User on classic theme with `use_note` enabled navigates to `/?tab=notes` and sees the note capture form and note list
  3. The drawer nav on both modern and classic themes shows a Note link when `use_note` is enabled, linking to `/?tab=notes`
  4. On the welcome page for modern/classic themes, Home panel and Note panel are mutually exclusive: `?tab=notes` shows the note panel with the home panel hidden, and the default `/` shows the home panel with the note panel hidden
**Plans**: TBD
**UI hint**: yes

### Phase 24: CSS Styling & Localization Verification
**Goal**: The note panel looks appropriate on modern and classic themes and all labels render in the active locale
**Depends on**: Phase 23
**Requirements**: NOTE-05, NOTE-06, NOTE-07
**Success Criteria** (what must be TRUE):
  1. Note panel on modern theme uses consistent spacing, font sizing, and visual tokens matching the existing modern CSS design (header bar, form controls, table/list styles)
  2. Note panel on classic theme uses spacing and presentation consistent with the existing classic theme appearance
  3. On modern theme with English locale, all fixed Note UI labels (title, textarea label, submit button, empty-state message) render in English
  4. On modern theme with Japanese locale, all fixed Note UI labels render in Japanese
  5. On classic theme, Note UI labels likewise follow the active locale
**Plans**: TBD
**UI hint**: yes

### Phase 25: Tests & Phase Gate
**Goal**: Automated test suite confirms note panel behavior for modern and classic themes and the full tri-suite gate is green
**Depends on**: Phase 24
**Requirements**: NOTE-08, NOTE-09, NOTE-10
**Success Criteria** (what must be TRUE):
  1. Minitest integration test asserts that the modern-theme note panel is present on `/?tab=notes`, absent on `/`, and that the drawer nav includes the Note link when `use_note` is enabled
  2. Minitest integration test asserts the same three behaviors for classic theme
  3. Cucumber E2E scenario passes: activate modern theme → navigate to `/?tab=notes` via drawer nav Note link → fill textarea → Save → note body appears in the note list
  4. `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test` all pass with 0 failures (or re-run confirms any failure is pre-existing flake)
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 19. Verification Rubric & Traceability Baseline | v1.5 | 1/1 | Complete | 2026-05-03 |
| 20. Phase 05 Verification Closure | v1.5 | 2/2 | Complete | 2026-05-03 |
| 21. Phase 06 Verification Closure | v1.5 | 2/2 | Complete | 2026-05-03 |
| 22. Phase 09 Verification Closure & Milestone Sync | v1.5 | 2/2 | Complete | 2026-05-04 |
| 23. View & Navigation Integration | v1.6 | 0/? | Not started | - |
| 24. CSS Styling & Localization Verification | v1.6 | 0/? | Not started | - |
| 25. Tests & Phase Gate | v1.6 | 0/? | Not started | - |

---
*Last updated: 2026-05-04 — v1.6 roadmap created (Phases 23–25).*
