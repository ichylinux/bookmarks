# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- **v1.2 — Modern Theme** — Phases 5–9 (in progress)

## Phases (v1.2 — Modern Theme)

- [ ] **Phase 5: Theme Foundation** - Add `modern` to preferences; create `modern.css.scss` stub with `.modern {}` skeleton and CSS custom property tokens; create `menu.js` stub with `body.modern` guard
- [ ] **Phase 6: HTML Structure** - Add hamburger button to layout; add drawer div and overlay div with all nav links to `_menu.html.erb` outside `.wrapper`
- [ ] **Phase 7: Drawer CSS + Animation** - Drawer slide, backdrop fade, z-index stack, hamburger-to-X animation, `prefers-reduced-motion` support
- [ ] **Phase 8: Drawer JS Interaction** - Wire jQuery toggle in `menu.js`: open/close handlers, backdrop click, Esc key, nav link close, stopPropagation guard
- [ ] **Phase 9: Full-Page Theme Styles** - Header bar, body typography, table styling, action buttons, form inputs/selects

## Phase Details

### Phase 5: Theme Foundation
**Goal**: The `modern` theme is selectable and active — switching to it applies the `.modern` body class and loads both the CSS and JS scaffolding without breaking any existing theme
**Depends on**: Nothing (first phase of v1.2)
**Requirements**: THEME-01, THEME-02, THEME-03
**Success Criteria** (what must be TRUE):
  1. User can open Preferences, select "Modern" (モダン), save, and the page reloads with `class="modern"` on `<body>`
  2. `themes/modern.css.scss` is compiled by Sprockets (no asset pipeline errors); `.modern {}` root scope exists with at least the CSS custom property tokens defined as plain CSS values
  3. `menu.js` is compiled and loaded; when `body` does not have class `modern`, the file exits immediately without side effects
  4. Selecting any other theme removes the `modern` class and restores prior behaviour
**Plans**: 2 plans

**Wave 1** *(both plans are independent — can run in parallel)*
- [x] 05-01-PLAN.md — Add モダン to theme select + create modern.css.scss with CSS custom property tokens
- [x] 05-02-PLAN.md — Create menu.js stub with body.modern guard

**Cross-cutting constraints:**
- libsass: CSS custom property values must be plain hex strings (no `$variable` refs)
- All JS must use `const`/`let` — `var` forbidden (ESLint `no-var` enforced)

**UI hint**: yes

### Phase 6: HTML Structure
**Goal**: The hamburger button and drawer markup exist in the DOM under the modern theme, correctly positioned so drawer can slide in without clipping
**Depends on**: Phase 5
**Requirements**: NAV-01, NAV-02
**Success Criteria** (what must be TRUE):
  1. When using the modern theme, a hamburger button element is visible in the header area
  2. The drawer `<div>` and overlay `<div>` are rendered as direct children of `<body>`, outside `.wrapper` (verifiable in browser DevTools)
  3. All navigation links that exist in the existing dropdown menu are also present inside the drawer markup
  4. The existing non-modern dropdown menu and its inline `<script>` are unaffected and continue to function when a non-modern theme is active
**Plans**: TBD
**UI hint**: yes

### Phase 7: Drawer CSS + Animation
**Goal**: The drawer slides in and out smoothly with a backdrop, and motion is suppressed for users who prefer reduced motion — all purely from CSS, with no JS wired yet
**Depends on**: Phase 6
**Requirements**: NAV-03, A11Y-01
**Success Criteria** (what must be TRUE):
  1. When `.drawer-open` class is applied to `<body>` manually (via DevTools), the drawer slides in from the left using `transform: translateX` and the backdrop fades in
  2. Removing `.drawer-open` reverses both animations
  3. The drawer has a z-index above all page content (verified by overlaying a table-heavy page)
  4. The hamburger button visually transforms to an X icon when `.drawer-open` is present on `<body>`
  5. When browser `prefers-reduced-motion: reduce` is active, the drawer appears and disappears instantly with no transition
**Plans**: TBD
**UI hint**: yes

### Phase 8: Drawer JS Interaction
**Goal**: Users can open and close the drawer through all supported interactions, and the new JS does not interfere with the existing `$('html').click` dismiss handler
**Depends on**: Phase 7
**Requirements**: NAV-02, NAV-03
**Success Criteria** (what must be TRUE):
  1. Clicking the hamburger button opens the drawer (adds `.drawer-open` to `<body>`) and clicking it again closes it
  2. Clicking the backdrop (outside the drawer panel) closes the drawer
  3. Pressing the Esc key while the drawer is open closes the drawer
  4. Clicking any navigation link inside the drawer closes the drawer before navigating
  5. The existing dropdown menu on non-modern themes continues to open and dismiss correctly — no JS conflict introduced
**Plans**: TBD

### Phase 9: Full-Page Theme Styles
**Goal**: Every major UI surface in the app looks clean and intentional under the modern theme, with no gray `#AAA` header or unstyled tables/forms visible
**Depends on**: Phase 8
**Requirements**: STYLE-01, STYLE-02, STYLE-03, STYLE-04
**Success Criteria** (what must be TRUE):
  1. The header bar (both `#header .head-box` and `.header` selectors) renders with the modern color scheme — no `#AAA` gray background visible
  2. Body text renders at 16px with a system font stack and improved line-height on all pages
  3. Data tables have visible row padding, alternating or hover-state row styling, and no unstyled appearance
  4. Action buttons (Edit, Delete, and primary form submit buttons) are visibly styled with the modern theme color tokens
  5. Form inputs and `<select>` elements on the Preferences page and CRUD forms have visible modern styling (border, padding, focus state)
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Theme Foundation | v1.2 | 0/2 | Not started | - |
| 6. HTML Structure | v1.2 | 0/? | Not started | - |
| 7. Drawer CSS + Animation | v1.2 | 0/? | Not started | - |
| 8. Drawer JS Interaction | v1.2 | 0/? | Not started | - |
| 9. Full-Page Theme Styles | v1.2 | 0/? | Not started | - |

## Phases (shipped: v1.1)

<details>
<summary>✅ v1.1 — Modern JavaScript (Phases 2–4) — SHIPPED 2026-04-27</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).

- [x] **Phase 2: JavaScript tooling baseline** (2/2 plans) — completed 2026-04-27
- [x] **Phase 3: Modernize application scripts** (2/2 plans) — completed 2026-04-27
- [x] **Phase 4: Verify and document** (2/2 plans) — completed 2026-04-27

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 2. JavaScript tooling | v1.1 | 2/2 | Complete | 2026-04-27 |
| 3. Modernize scripts | v1.1 | 2/2 | Complete | 2026-04-27 |
| 4. Verify and document | v1.1 | 2/2 | Complete | 2026-04-27 |

</details>

---
*Last updated: 2026-04-28 — Phase 5 planned (2 plans, Wave 1)*
