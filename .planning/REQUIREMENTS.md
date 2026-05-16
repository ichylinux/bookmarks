# Requirements: Bookmarks — v1.23 Icon Display Preference

**Defined:** 2026-05-17
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

### ICON — Icon Display Preference

- [ ] **ICON-01**: User can toggle icon display on/off from `/preferences`; preference persists as boolean `show_icons` (default: true, NOT NULL) on `preferences` table
- [ ] **ICON-02**: When icons are off, gadget-title icons are hidden across all authenticated pages (welcome gadgets, `/mastodon_accounts/show`, `/x_accounts/show`, `/feeds/show`)
- [ ] **ICON-03**: When icons are off, drawer navigation icons are hidden (modern-theme drawer)
- [ ] **ICON-04**: Preference control has ja/en locale strings; i18n key parity test passes
- [ ] **ICON-05**: Minitest covers preference model default + validation + controller save; integration or Cucumber test verifies icon suppression behavior; tri-suite green

## Future Requirements

*(None identified for this milestone)*

## Out of Scope

| Feature | Reason |
|---------|--------|
| Landing page icons | Unauthenticated surface — no preference context available |
| Per-surface icon granularity (e.g., nav only, gadgets only) | All-or-nothing toggle is sufficient; granularity adds complexity without clear user value |
| Icon animation or transition effects | Out of scope for a simple toggle preference |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ICON-01 | Phase 73 | Pending |
| ICON-02 | Phase 74 | Pending |
| ICON-03 | Phase 74 | Pending |
| ICON-04 | Phase 75 | Pending |
| ICON-05 | Phase 75 | Pending |

**Coverage:**
- v1 requirements: 5 total
- Mapped to phases: 5 (roadmap created 2026-05-17)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-17*
*Last updated: 2026-05-17 — traceability table filled after roadmap creation*
