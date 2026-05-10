# Requirements: v1.15 CSS & UI Polish

## Milestone Goal

Audit all SCSS for architectural violations, migrate misplaced theme-specific styles to their correct theme files, and verify visual consistency across modern/classic/simple themes on all key surfaces.

---

## v1.15 Requirements

### ARCH — CSS Architecture

- [ ] **ARCH-01**: All non-theme SCSS files (`*.css.scss` outside `themes/`) are audited for selectors prefixed with `.modern`, `.classic`, or `.simple`
- [ ] **ARCH-02**: Any misplaced theme-specific selectors found in non-theme files are migrated to the appropriate `themes/` file
- [ ] **ARCH-03**: Shared/generic base styles remain in their originating file (un-prefixed rules stay in source file)

### PREFS — Preferences Page

- [ ] **PREFS-01**: Preferences page renders correctly on modern theme (form layout, labels, submit button, table alignment, spacing)
- [ ] **PREFS-02**: Preferences page renders correctly on classic theme
- [ ] **PREFS-03**: Preferences page renders correctly on simple theme

### CONS — Cross-theme Consistency

- [ ] **CONS-01**: Shared form controls (inputs, selects, textareas) render consistently across themes
- [ ] **CONS-02**: Action links and buttons render consistently across themes
- [ ] **CONS-03**: Flash/notice messages render consistently across themes

### MOB — Mobile/Responsive

- [ ] **MOB-01**: Key pages (welcome, preferences, bookmarks list) render usably at mobile widths on all 3 themes
- [ ] **MOB-02**: No layout overflow or broken stacking on narrow viewports

---

## Future Requirements

- Delete individual notes — deferred until core capture flow proves out on all themes
- Rich text / markdown editor — conflicts with no-new-JS-deps constraint
- Real-time autosave — explicit save is the correct UX
- Decide whether `/landing` replaces `/` after conversion evaluation

---

## Out of Scope

- New user-facing features
- New JavaScript or npm dependencies
- Database migrations
- Internationalization changes
- Locale beyond ja/en

---

## Traceability

| REQ-ID | Phase | Plan |
|--------|-------|------|
| ARCH-01 | 49 | — |
| ARCH-02 | 49 | — |
| ARCH-03 | 49 | — |
| PREFS-01 | 50 | — |
| PREFS-02 | 50 | — |
| PREFS-03 | 50 | — |
| CONS-01 | 50 | — |
| CONS-02 | 50 | — |
| CONS-03 | 50 | — |
| MOB-01 | 51 | — |
| MOB-02 | 51 | — |
