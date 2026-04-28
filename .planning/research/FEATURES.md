# Feature Research

**Domain:** Modern CSS Theme — hamburger side-drawer nav and full-page restyle for a personal Rails bookmarks app
**Researched:** 2026-04-28
**Confidence:** HIGH (patterns well-established; app structure fully inspected)

---

## Existing Structure (What This Theme Overlays)

The current app uses a body class set by `favorite_theme` helper (e.g. `simple`, default blank).
Theme scoping is done via that body/html class — the "simple" theme already demonstrates the pattern:
`.simple { #header { display: none; } }`. The modern theme follows the same convention: `.modern { ... }`.

Navigation lives in `app/views/common/_menu.html.erb` inside `.wrapper > div.header > ul.navigation`.
The layout is `application.html.erb` with `<body class="<%= favorite_theme %>">`, a fixed `#header .head-box`
band at top, then `.wrapper` holding the menu partial and page content.

Components to restyle:
- `#header .head-box` — top app-name/icon band
- `.header` — the nav row (Home + user dropdown)
- `.wrapper` — page content padding/container
- `table` — bookmarks, todos, feeds, preferences all use plain `<table>`
- `.actions a` — action buttons (edit/delete links styled as pill buttons)
- `form` elements — preferences, bookmark/todo/feed create/edit forms
- `.breadcrumbs` — already has reasonable styling; needs theme-aware overrides
- Auth pages use `devise.css.scss` (separate concern, low priority)

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Hamburger button in header | The entire point of the milestone; app currently hides all nav in a dropdown | LOW | Three `<span>` lines, CSS transform to X on `.open`; jQuery `.toggleClass` fits the existing stack |
| Side drawer that slides in from left | Standard "hamburger opens side nav" UX contract | MEDIUM | `position: fixed`, `transform: translateX(-100%)` → `translateX(0)` with CSS `transition`; drawer sits above everything with `z-index` |
| Semi-transparent backdrop behind drawer | Without it the drawer floats with no affordance to close it | LOW | `position: fixed`, full-screen, `background: rgba(0,0,0,0.45)`, hidden by default, toggled alongside drawer |
| Click backdrop or Esc to close drawer | Users expect any off-drawer click to dismiss it | LOW | jQuery click on backdrop element + `$(document).keydown` for Esc key |
| All existing nav links visible in drawer | The whole point — links currently hidden unless dropdown open | LOW | Copy links from `_menu.html.erb` dropdown into drawer markup: Home, 設定, ブックマーク, タスク, カレンダー, フィード, ログアウト |
| Header bar with app title and hamburger | Replaces the current thin `.header` row; needs to feel like a real app header | LOW | Fixed or static top bar; hamburger left, app name/logo center or left, user name right |
| Body typography upgrade | 12px base font is legacy; modern theme should read clearly | LOW | `font-size: 16px` body base, `font-family` system stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`), `line-height: 1.5` |
| Clean table styling | All data screens are table-heavy; unstyled tables look broken in a "modern" theme | LOW | `border-collapse: collapse`, subtle `1px` borders or borderless with `border-bottom` rows, `padding: 10px 14px`, `tr:hover` background |
| Styled action buttons | Edit/Delete links look like raw text without theme styling | LOW | The existing `.actions a` pill pattern is a good base; modernize with consistent color tokens |
| Form layout polish | Preferences and CRUD forms use raw `<table>` form layout | MEDIUM | Scoped overrides for `input[type=text]`, `select`, `submit`; keep table-based form layout, just style the cells |

### Differentiators (Competitive Advantage)

This is a personal app, not a product competing in a market. "Differentiators" here means what makes the modern theme noticeably better than the default, justifying the effort.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hamburger animates to X when open | Communicates state without text; standard polish signal | LOW | CSS transforms on three `<span>` children; no extra JS |
| CSS custom properties (variables) for the color system | Single source of truth for all theme colors; easy to tweak | LOW | Define `--color-primary`, `--color-surface`, `--color-text` etc. inside `.modern {}` scope; all SCSS rules reference them |
| Drawer shows active/current page highlight | User knows where they are in the nav | LOW | Rails `current_page?` helper on each link, add `.active` class; style in CSS |
| Smooth CSS transitions throughout | Hover states, drawer slide, backdrop fade all transition; feels polished | LOW | `transition: all 0.2s ease` on interactive elements; purely CSS |
| Responsive-aware drawer (works on mobile and desktop) | The existing app has media queries but the nav is tiny on mobile | LOW | Drawer width `280px` fixed; on mobile it covers most of screen which is correct behavior; no JS breakpoint logic needed |

### Anti-Features (Things NOT to include in a personal app restyle)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Dark mode toggle | Trendy, often requested | Doubles the color system work; the preferences screen already has a theme switcher — dark mode would be a third independent axis | If dark mode is wanted later, add it as a separate theme option in preferences |
| Animations beyond slide + fade | Makes it feel "premium" | Increases complexity with no daily-use value; can cause motion sickness; conflicts with `prefers-reduced-motion` policy | Keep transitions short (`150–200ms`) and limited to drawer + hover states |
| Sticky/fixed sidebar always visible | Common in SaaS dashboards | Personal bookmarks app is not a dashboard; sidebar always visible wastes horizontal space for a content-first tool | Drawer on demand is the right call |
| Replacing `_menu.html.erb` entirely | Tempting to rewrite the partial | The partial serves both the default and modern theme; rewriting it breaks the default theme | Conditionally render drawer markup or use the theme class to show/hide different markup in the same partial |
| CSS framework import (Bootstrap, Tailwind) | Faster initial styling | These apps use Sprockets with `require_tree .`; adding a CDN CSS or npm package introduces either a new build step or an un-pinned external dependency | Hand-write the ~200 lines of SCSS needed; this is a personal app with minimal surface area |
| JavaScript-driven theme toggling (no page reload) | Feels dynamic | Session-based theme is already stored in DB and applied on page load via body class; JS toggling would be a shadow state that breaks on reload | Keep the existing preferences form save + redirect pattern |
| Per-component CSS animations (skeleton loaders, spinners) | Modern apps have them | Server-rendered Rails pages are fast on localhost; adding loading states creates complexity for zero perceived benefit in a personal tool | Omit entirely |
| CSS Grid for page layout | Modern layout technique | The `.wrapper` + table-based content layout works; introducing Grid for the page shell is scope creep for a theme-only milestone | Use Flexbox only where already in use (`head-box`, `breadcrumbs`); leave page layout alone |

---

## Feature Dependencies

```
[Theme body class `.modern`]
    └──scopes──> [All CSS rules below it]

[Hamburger button in header]
    └──requires──> [Drawer markup in DOM]
                       └──requires──> [Backdrop element in DOM]

[Hamburger → X animation]
    └──enhances──> [Hamburger button]

[Drawer slide-in]
    └──requires──> [CSS transform + transition on drawer element]
    └──requires──> [JS toggle of `.open` class]

[Backdrop close behavior]
    └──requires──> [Backdrop element]
    └──requires──> [Same JS toggle of `.open` class]

[CSS custom properties color system]
    └──enhances──> [All component styles (header, table, buttons, forms)]
```

### Dependency Notes

- **Drawer requires backdrop element:** The backdrop is the primary "close on outside click" affordance. Build both together.
- **Hamburger animation enhances hamburger button:** Pure CSS on top of the button; can be skipped if time is short but low cost.
- **CSS variables enhance all component styles:** Define variables first at the `.modern {}` scope level, then use them throughout. This makes later color tweaks trivial.
- **Theme class scoping must be in place before any other rule:** Every modern-theme rule needs `.modern` as its SCSS ancestor to avoid leaking into the default theme.

---

## MVP Definition

### Launch With (v1.2)

Minimum to make the modern theme feel complete and selectable.

- [ ] `modern` option added to preferences theme select — why essential: without it the theme is unreachable
- [ ] Hamburger button + drawer markup in `_menu.html.erb`, shown only under `.modern` — why essential: the milestone goal
- [ ] Drawer slides in/out, backdrop appears, outside-click and Esc close it — why essential: table stakes nav behavior
- [ ] Header bar restyle (app name + hamburger, replaces thin nav row) — why essential: first impression of the theme
- [ ] Body typography (font-size, font-family, line-height) — why essential: without it the rest looks incongruent
- [ ] Table styling (border-collapse, padding, hover) — why essential: every data screen is table-heavy
- [ ] `.actions a` button style update — why essential: edit/delete appear on every list and form page
- [ ] Basic form field styling (input, select, submit) scoped to `.modern` — why essential: preferences and all CRUD forms

### Add After Validation (v1.x)

- [ ] Hamburger → X animation — trigger: everything else works; low-effort polish
- [ ] Active nav link highlight in drawer — trigger: regular use makes the lack visible
- [ ] CSS custom properties refactor — trigger: if color tweaking is needed; purely internal

### Future Consideration (v2+)

- [ ] Dark mode as a separate theme — defer: orthogonal concern; medium complexity
- [ ] Mobile-specific breakpoint adjustments to drawer width — defer: personal app, desktop primary use
- [ ] Devise/auth page restyling in modern theme — defer: auth screens are rarely seen; not daily-use surfaces

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Hamburger + drawer (open/close) | HIGH | MEDIUM | P1 |
| Header bar restyle | HIGH | LOW | P1 |
| Body typography | HIGH | LOW | P1 |
| Table styling | HIGH | LOW | P1 |
| Action button styling | MEDIUM | LOW | P1 |
| Form field styling | MEDIUM | MEDIUM | P1 |
| Backdrop + outside-click close | HIGH | LOW | P1 |
| Hamburger → X animation | MEDIUM | LOW | P2 |
| Active link in drawer | LOW | LOW | P2 |
| CSS custom properties system | LOW | LOW | P2 |
| Dark mode | LOW | HIGH | P3 |
| Auth page restyle | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Implementation Notes by Category

### Navigation (Hamburger + Drawer)

The existing `_menu.html.erb` partial renders inside `.wrapper`. For the modern theme:

- The current `.header > ul.navigation` structure can remain for the default theme.
- Add a second block inside the partial, conditionally rendered or CSS-hidden, that contains the drawer markup.
- Drawer HTML: `<div class="modern-drawer">` with `<nav>` and links; `<div class="modern-backdrop">` as sibling.
- JS: jQuery (already loaded) toggles `.modern-drawer--open` on both elements. Keep the JS in a separate `modern_theme.js` asset to avoid polluting `common.js` or the inline script in the partial.
- The hamburger button belongs in the app layout's `#header .head-box`, visible only when `.modern` class is on body.

### Typography

- Base: `font-size: 16px` on `body` (remove the `62.5%` html trick that the existing code uses — this is scoped to `.modern` so it won't affect other themes).
- Font stack: `font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`.
- No web font download — the system stack is the right call for a personal app (zero latency, no GDPR concern).

### Color System

Define CSS custom properties at `.modern` scope:
```scss
.modern {
  --color-primary: #4f6ef7;
  --color-surface: #ffffff;
  --color-surface-alt: #f7f8fa;
  --color-border: #e0e3e8;
  --color-text: #1a1a2e;
  --color-text-muted: #6b7280;
  --color-hover-bg: #f0f2ff;
}
```
All component rules inside `.modern` reference these variables. This is a LOW-cost investment with HIGH maintainability payoff.

### Tables

Scoped to `.modern table`:
- `border-collapse: collapse`
- `th` and `td`: `padding: 10px 14px`; `border-bottom: 1px solid var(--color-border)`
- `thead th`: `background: var(--color-surface-alt)`, `font-weight: 600`, `text-align: left`
- `tr:hover td`: `background: var(--color-hover-bg)`
- Remove the `margin: 20px` from the global table rule (override in theme scope)

### Action Buttons

Existing `.actions a` uses `border: solid 1px #595757; border-radius: 8px`. In modern theme:
- Use `var(--color-primary)` for border and text
- Hover: `background: var(--color-primary); color: white`
- Consistent `border-radius: 6px`, `padding: 5px 12px`, `font-size: 14px`

### Forms

Scoped to `.modern`:
- `input[type=text], input[type=email], select, textarea`: `border: 1px solid var(--color-border); border-radius: 6px; padding: 6px 10px; font-size: 14px`
- Focus state: `border-color: var(--color-primary); outline: none; box-shadow: 0 0 0 2px rgba(79,110,247,0.15)`
- Submit button: treat as primary button; same hover pattern as action buttons

---

## Sources

- Existing codebase: `app/views/common/_menu.html.erb`, `app/assets/stylesheets/common.css.scss`, `app/assets/stylesheets/themes/simple.css.scss`, `app/views/layouts/application.html.erb`
- Side drawer CSS/JS pattern: [DEV Community — Easy hamburger menu with JS](https://dev.to/ljcdev/easy-hamburger-menu-with-js-2do0), [Flowbite Drawer docs](https://flowbite.com/docs/components/drawer/), [CodePen — Pure CSS Drawer Menu with overlay](https://codepen.io/equinusocio/pen/wPvvmv)
- Hamburger → X animation: [Animated hamburger menu icon to x — ryfarlane.com](https://www.ryfarlane.com/article/animated-hamburger-menu-icon-to-x-close-icon-css), [GeeksforGeeks](https://www.geeksforgeeks.org/how-to-convert-the-hamburger-icon-of-navigation-menu-to-x-on-click/)
- CSS theming in Rails: [thoughtbot — Scoping CSS in Rails](https://forum.upcase.com/t/scoping-css-in-rails-applications/5618), [mattboldt.com — Organizing CSS and Sass in Rails](https://mattboldt.com/organizing-css-and-sass-rails/)
- Modern table styling: [Piccalilli — Styling Tables the Modern CSS Way](https://piccalil.li/blog/styling-tables-the-modern-css-way/)
- Minimal CSS frameworks surveyed (considered but not adopted): [Pico CSS](https://picocss.com/), [Milligram](https://milligram.io/), [MVP.css](https://andybrewer.github.io/mvp/)

---
*Feature research for: Modern Theme (v1.2) — Bookmarks app*
*Researched: 2026-04-28*
