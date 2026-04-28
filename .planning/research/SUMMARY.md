# Project Research Summary

**Project:** Bookmarks App — Modern Theme (v1.2)
**Domain:** CSS theme + hamburger side-drawer navigation in a Rails 8.1 / Sprockets / jQuery app
**Researched:** 2026-04-28
**Confidence:** HIGH

## Executive Summary

This milestone adds a "modern" visual theme and hamburger-triggered side-drawer navigation to an existing personal Rails bookmarks app. The app already has a working theme-switching mechanism: a `favorite_theme` helper sets the `<body>` class on every request, and a `simple` theme already demonstrates the `body.simple { ... }` SCSS scoping pattern. The modern theme follows the same convention exactly — a new `themes/modern.css.scss` file scoped under `.modern { }`, picked up automatically by Sprockets' `require_tree .` traversal, with no pipeline or gem changes required. The drawer itself is a standard CSS `transform: translateX` + `transition` pattern driven by a tiny jQuery class toggle in a new `menu.js` asset file.

The recommended approach is strictly additive: two new files (`modern.css.scss` and `menu.js`) plus small, targeted modifications to three existing files (layout, menu partial, preferences select). No new gems, npm packages, or build pipeline changes are needed.

## Key Findings

### Recommended Stack

No new dependencies needed. The existing `sass-rails 6.0.0` / `sassc-rails 2.1.2` (libsass) handles `modern.css.scss`; jQuery already loaded handles drawer toggling; `require_tree .` auto-picks up new files.

**Critical constraint:** libsass bug — SCSS `$variables` must not be assigned directly to CSS `--custom-properties`. Write all design tokens as plain CSS values (`--color-brand: #2563eb;`) or use `#{$var}` interpolation.

**Core technologies:**
- `sass-rails 6.0.0` (sassc/libsass) — compile `themes/modern.css.scss`, already installed
- CSS custom properties — design token system scoped to `.modern`, plain CSS values only
- jQuery (existing) — `.addClass`/`.removeClass` drawer toggle, already loaded globally

### Expected Features

**Must have (P1 — launch blockers):**
- Hamburger button in header + side drawer that slides in from left
- Semi-transparent backdrop with outside-click and Esc-key close
- All existing nav links visible inside the drawer
- Header bar restyle (app name + hamburger, replaces thin nav row)
- Body typography upgrade (16px base, system font stack)
- Clean table styling (every data screen is table-heavy)
- Styled action buttons (Edit/Delete appear on every list page)
- Basic form field styling (preferences and all CRUD forms)
- `modern` option added to preferences theme select

**Should have (P2):**
- Hamburger animates to X on open
- Active/current page highlight in drawer
- CSS custom properties color token system

**Defer (v2+):**
- Dark mode
- Mobile breakpoint adjustments to drawer width
- Devise/auth page restyling

### Architecture

Two new files, three modified files.

| File | Status | Purpose |
|------|--------|---------|
| `themes/modern.css.scss` | NEW | Full theme: header, drawer, overlay, typography, tables, buttons, forms; scoped to `.modern {}` |
| `app/assets/javascripts/menu.js` | NEW | Drawer open/close; guards on `body.modern`; Esc key handler |
| `app/views/layouts/application.html.erb` | MODIFIED | Add hamburger `<button class="modern-hamburger">` in `#header > .head-box` |
| `app/views/common/_menu.html.erb` | MODIFIED | Add drawer `<div>` + overlay `<div>` with nav links; existing dropdown untouched |
| `app/views/preferences/index.html.erb` | MODIFIED | Add `'モダン' => 'modern'` to theme select |

Drawer/backdrop HTML rendered unconditionally; CSS hides them outside the `.modern` theme. The existing inline `<script>` in `_menu.html.erb` stays in place — it targets different DOM elements.

### Critical Pitfalls

1. **CSS specificity war** — `common.css.scss` has ID selectors (`#header .head-box`, specificity 1,1,0) that beat plain `.modern` scoping. Use `.modern #header .head-box`; establish specificity convention before writing rules.

2. **`$('html').click` handler conflict** — existing inline script attaches a global dismiss handler. New drawer JS must use `e.stopPropagation()` on hamburger click and guard dismiss with `.closest('.modern-drawer, .modern-hamburger').length === 0`.

3. **Dual header selectors** — `#header .head-box` (ID-based) and `.header` (class-based) are two separate components; both must be explicitly overridden.

4. **Drawer clipping** — keep drawer `<div>` as a direct child of `<body>`, outside `.wrapper`. Never apply CSS `transform` to `body` or `.wrapper`. Drawer `z-index` must be 100+.

5. **libsass CSS custom property bug** — `--color: $variable;` silently emits literal string. Use plain values or `#{$variable}` interpolation.

## Roadmap Implications

### Recommended Phase Order (5 phases)

**Phase N: Foundation — Preferences + CSS/JS Scaffolding**
Activate theme path; establish `.modern {}` skeleton with CSS custom property tokens; `menu.js` stub with `body.modern` guard; confirm Sprockets include order.
*Avoids:* CSS specificity war established before any rules written.

**Phase N+1: HTML Structure — Hamburger + Drawer Markup**
Hamburger `<button>` in layout; drawer `<div>` + overlay `<div>` with all nav links in menu partial; keep drawer outside `.wrapper`.
*Avoids:* Dual-header pitfall; drawer clipping pitfall addressed from the start.

**Phase N+2: Drawer CSS + Animation**
Drawer slide (`transform: translateX`), backdrop fade, z-index stack, hamburger→X animation, iOS `100dvh` fix, `.modern.drawer-open` state.
*Avoids:* z-index and iOS Safari pitfalls; CSS verified in DevTools before JS wired.

**Phase N+3: Drawer JS Interaction**
`menu.js` open/close handlers; `e.stopPropagation()` on hamburger; Esc key handler; `overflow: hidden` on body; `aria-expanded` toggle.
*Avoids:* `$('html').click` handler conflict via explicit guards.

**Phase N+4: Full-Page Theme Styles**
Header bar restyle (both `#header .head-box` and `.header`); body typography; table styling; action button styling; form field styling.
*Note:* Purely visual, lowest risk, ordered last so color tweaks don't distract from structural correctness.

### Gaps to Address in Planning

- Confirm `favorite_theme` helper returns `"modern"` (not `nil`) after preference save; check model-level allowlist on `preference.theme`
- One-time compiled asset order check after adding `modern.css.scss` via `rake assets:precompile`

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are existing project dependencies |
| Features | HIGH | Existing codebase fully inspected; all surfaces to restyle enumerated |
| Architecture | HIGH | Derived entirely from direct source file inspection |
| Pitfalls | HIGH | Based on direct inspection of compiled asset order and all affected files |

**Overall:** HIGH — all phases have established patterns; no phase requires deeper research before planning.
