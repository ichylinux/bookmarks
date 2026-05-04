# Requirements — v1.6 Note Gadget for All Themes

## Milestone Goal

Extend the quick Note gadget — currently only visible on the "simple" theme — so users on modern and classic themes can also capture and view notes from the welcome page.

## v1.6 Requirements

### Note Access — Modern & Classic Themes

- [ ] **NOTE-01**: User on modern theme with `use_note` enabled, navigating to `/?tab=notes`, sees the note capture form and note list on the welcome page
- [ ] **NOTE-02**: User on classic theme with `use_note` enabled, navigating to `/?tab=notes`, sees the note capture form and note list on the welcome page
- [ ] **NOTE-03**: The drawer nav (modern and classic) shows a Note link (`t('nav.note')`) when `use_note` is enabled, linking to `root_path(tab: 'notes')`

### Presentation

- [ ] **NOTE-04**: The welcome page for modern/classic themes renders either the Home panel (portal gadgets) or the Note panel depending on `?tab=notes`, with the inactive panel hidden (SSR-driven, matching existing simple-theme pattern)
- [ ] **NOTE-05**: Note panel presentation fits modern theme visual design (consistent with existing modern CSS tokens and spacing)
- [ ] **NOTE-06**: Note panel presentation fits classic theme visual design (consistent with existing classic CSS)

### Localization

- [ ] **NOTE-07**: All Note UI labels (title, textarea label, submit button, empty-state message) render in ja/en via existing `t()` calls in the `_note_gadget` partial — verified end-to-end for modern and classic themes

### Verification

- [ ] **NOTE-08**: Minitest integration test covers: modern-theme note panel visible on `?tab=notes`, hidden on `/`, and drawer nav Note link present when `use_note` is enabled
- [ ] **NOTE-09**: Minitest integration test covers the same for classic theme
- [ ] **NOTE-10**: Cucumber E2E scenario covers modern-theme note capture flow (activate modern theme → navigate to `/?tab=notes` via drawer nav link → fill textarea → Save → note appears in list)

## Future Requirements (Deferred)

- Delete individual notes — deferred until core capture flow proves out on all themes
- Rich text / markdown editor — conflicts with no-new-JS-deps constraint
- Note gadget on simple theme without the `use_note` preference gate — intentionally preference-controlled

## Out of Scope

- New JavaScript framework or SPA-style tab switching — SSR-driven panel visibility is the established pattern
- TypeScript conversion
- Locale beyond ja/en — not planned
- `?locale=` URL parameter override — intentionally absent (Phase 14 D-04)

## Traceability

| REQ-ID  | Phase | Plan |
|---------|-------|------|
| NOTE-01 | —     | —    |
| NOTE-02 | —     | —    |
| NOTE-03 | —     | —    |
| NOTE-04 | —     | —    |
| NOTE-05 | —     | —    |
| NOTE-06 | —     | —    |
| NOTE-07 | —     | —    |
| NOTE-08 | —     | —    |
| NOTE-09 | —     | —    |
| NOTE-10 | —     | —    |

---
*Last updated: 2026-05-04 — v1.6 requirements defined.*
