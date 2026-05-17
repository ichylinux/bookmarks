# Requirements: Bookmarks — v1.25 Portal Column Width Ratios

**Defined:** 2026-05-18
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.25 Requirements

Per-column width ratios on the desktop portal, configured via ratio sliders on the preferences screen. Builds on v1.20 `portal_column_count` (3 or 4 columns).

### Data Layer

- [ ] **COLW-01**: User's column width ratios are persisted on `preferences` (e.g. JSON array of integers summing to 100, one entry per active column); model validates length matches `portal_column_count`, each value is a positive integer, and the array sums to exactly 100
- [ ] **COLW-02**: When no custom ratios are stored (new user or migration default), desktop layout uses an equal split (3×33.33% / 4×25% equivalent) matching today's behavior; changing `portal_column_count` applies sensible defaults for the new column count (equal split) without corrupting saved ratios for the other count if stored separately or reset per count per product decision documented in phase plan

### Preferences UI

- [ ] **COLW-03**: Preferences page shows one ratio slider per column for the user's current `portal_column_count` (3 or 4 sliders); sliders are linked so the displayed ratios always sum to 100% before save
- [ ] **COLW-04**: Submitting the preferences form persists the ratios; reloading the preferences page shows the saved slider values; ja/en labels and help text for the control group

### Portal Rendering (Desktop)

- [ ] **COLW-05**: On desktop (`min-width: $portal-mobile-breakpoint`), welcome portal columns render at the saved width ratios (replacing fixed `33.33%` / `portal--4col` 25% equal split); all three themes (modern, classic, simple) share the same portal partial/CSS mechanism
- [ ] **COLW-06**: Mobile portal layout is unchanged: tab strip, one column visible at a time, `flex: 0 0 100%` per column — ratio preferences do not affect mobile viewport layout

### Safety & Tests

- [ ] **COLW-07**: Downgrade/upgrade between 3 and 4 columns remains safe for gadget placement (v1.20 COL-06 behavior preserved); width ratio UI and stored values stay consistent when column count changes
- [ ] **COLW-08**: Minitest covers model validation, preferences save/reload, and welcome-page desktop markup or computed widths for at least 3-column unequal and 4-column unequal examples; locale key parity for new strings
- [ ] **COLW-09**: Tri-suite gate green at milestone close (`yarn run lint` + `bin/rails test` + `bundle exec rake dad:test`)

## Future Requirements (deferred)

- Drag-to-resize column boundaries on the live dashboard
- Per-column width presets only (narrow/normal/wide) without continuous sliders
- Different width ratios for mobile vs desktop
- Column counts other than 3 or 4

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mobile column width customization | User confirmed mobile stays as-is; tab strip already shows one full-width column |
| Dashboard drag-resize of columns | Ratio sliders on preferences only for v1.25 |
| Changing `portal_column_count` options (still 3/4 only) | v1.20 scope; this milestone only adjusts widths within chosen count |
| New frontend framework or npm bundler | Project constraint — Sprockets + jQuery |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| COLW-01 | Phase 80 | Pending |
| COLW-02 | Phase 80 | Pending |
| COLW-03 | Phase 81 | Pending |
| COLW-04 | Phase 81 | Pending |
| COLW-05 | Phase 82 | Pending |
| COLW-06 | Phase 82 | Pending |
| COLW-07 | Phase 82 | Pending |
| COLW-08 | Phase 83 | Pending |
| COLW-09 | Phase 83 | Pending |

**Coverage:**
- v1.25 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-18*
*Last updated: 2026-05-18 after roadmap creation*
