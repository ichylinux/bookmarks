# Requirements: Bookmarks

**Defined:** 2026-04-28
**Milestone:** v1.2 — Modern Theme
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## v1.2 Requirements

### Theme Infrastructure

- [ ] **THEME-01**: User can select "modern" theme from the preferences screen
- [ ] **THEME-02**: `themes/modern.css.scss` exists with `.modern {}` scope and CSS custom property design tokens
- [ ] **THEME-03**: `menu.js` exists with `body.modern` guard for drawer interaction logic

### Navigation

- [ ] **NAV-01**: User sees a hamburger button in the header when using the modern theme
- [ ] **NAV-02**: User can open a side drawer containing all navigation links by clicking the hamburger
- [ ] **NAV-03**: User can close the drawer via backdrop click, Esc key, or clicking a nav link

### Visual Styling

- [ ] **STYLE-01**: Modern theme header bar is clean (replaces `#AAA` gray; covers both `#header` and `.header` selectors)
- [ ] **STYLE-02**: Modern theme uses 16px base typography with system font stack and improved line-height
- [ ] **STYLE-03**: Modern theme tables have modern row styling, padding, and hover states
- [ ] **STYLE-04**: Modern theme action buttons and form inputs/selects are visibly styled

### Accessibility

- [ ] **A11Y-01**: Drawer slide animation is disabled when `prefers-reduced-motion` is active

## Future Requirements

### Navigation

- **NAV-F01**: Hamburger icon animates to X when drawer is open
- **NAV-F02**: Active/current page is highlighted in the drawer nav links

### Accessibility

- **A11Y-F01**: `aria-expanded` attribute on hamburger button reflects open/close state
- **A11Y-F02**: Devise/auth pages restyled to match modern theme

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dark mode | Orthogonal axis to the clean/minimal direction; medium complexity, defer to later milestone |
| CSS framework (Bootstrap, Tailwind, etc.) | Would conflict with existing `common.css.scss` and require rewriting existing views |
| Replacing Sprockets / adding Vite | Out of scope for all milestones until explicitly opened |
| TypeScript conversion | Not required; may be revisited in a later milestone |
| Devise/auth page restyling | Low ROI for a personal app; these pages are rarely seen |
| Mobile breakpoint drawer width tuning | Defer to future polish pass |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| THEME-01 | Phase 5 | Pending |
| THEME-02 | Phase 5 | Pending |
| THEME-03 | Phase 5 | Pending |
| NAV-01 | Phase 6 | Pending |
| NAV-02 | Phase 6, 8 | Pending |
| NAV-03 | Phase 7, 8 | Pending |
| STYLE-01 | Phase 9 | Pending |
| STYLE-02 | Phase 9 | Pending |
| STYLE-03 | Phase 9 | Pending |
| STYLE-04 | Phase 9 | Pending |
| A11Y-01 | Phase 7 | Pending |

**Coverage:**
- v1.2 requirements: 11 total
- Mapped to phases: 11 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-28*
*Last updated: 2026-04-28 — traceability filled in after v1.2 roadmap created (Phases 5–9)*
