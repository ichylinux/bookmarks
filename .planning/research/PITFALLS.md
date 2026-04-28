# Pitfalls Research

**Domain:** Adding a CSS theme + hamburger side-drawer to an existing Rails 8.1 app (Sprockets + jQuery + SCSS)
**Researched:** 2026-04-28
**Confidence:** HIGH — based on direct inspection of all affected files in this repo

---

## Critical Pitfalls

### Pitfall 1: CSS Specificity War Between common.css.scss and the Modern Theme

**What goes wrong:**
`.modern {}` theme rules lose to bare element selectors in `common.css.scss`. For example, `common.css.scss` declares `table { margin: 20px; }`, `body { font-size: 12px; }`, `.header { ... }`, `.actions a { border: ... }`, etc. as flat selectors. A `.modern table { margin: 0; }` override has the same specificity as the original (one class + one element vs one element), so whichever appears later in the compiled output wins — but the theme file already appears after `common.css.scss` in the `require_tree .` traversal, so the theme wins by position — until someone adds another stylesheet after `themes/modern.css.scss` in alphabetical order. Any future stylesheet file whose name sorts after `t` will silently re-override theme rules.

**Why it happens:**
`require_tree .` in `application.css` includes files in alphabetical order, including subdirectories. The current compiled order (verified from `public/assets/application-*.css`) is:
```
jquery-ui → calendars → common → feeds → welcome → devise → themes/simple → todos
```
`themes/` sorts before `todos`, so theme files currently come before `todos.css.scss.erb`. This is fine for current files, but the relationship to `todos` is implicit and fragile. Adding `.modern` scoping (one extra class) gives theme rules `0,1,1` specificity vs the base `0,0,1` — one point higher, which is sufficient but only by accident. Any base rule promoted to `#id` selector (e.g., `#header .head-box`) beats `.modern #header .head-box` because ID selectors outweigh class selectors.

**How to avoid:**
- Scope every modern theme rule under `.modern` but also bump specificity where needed: `.modern.modern table` (doubled class) or use `:where(.modern) table` (zero-specificity wrapper, if the Sprockets Sass version supports it).
- Better: prefix all modern theme element overrides with `.modern body` or `.modern .wrapper` to add an extra specificity point without resorting to `!important`.
- Never use `!important` — it creates a one-way ratchet that propagates into maintenance hell.
- Document the compiled include order explicitly in a comment at the top of `themes/modern.css.scss`.

**Warning signs:**
- A base style in `common.css.scss` is visible when the modern theme is active and shouldn't be.
- Toggling the `.modern` class in DevTools browser inspector reveals the override is not taking effect (check "Computed" tab for which rule wins).
- Any new `.css.scss` file added to the root stylesheet directory that sorts after `t` alphabetically.

**Phase to address:** SCSS scaffolding phase (before any visual styling work begins).

---

### Pitfall 2: `$('html').click` in _menu.html.erb Fires and Closes the Side-Drawer

**What goes wrong:**
`_menu.html.erb` has a global `$('html').click(...)` handler that hides `.menu` whenever a click falls outside `.email`. The hamburger side-drawer will be a new overlay element. Any click on the drawer backdrop, or on links inside the drawer, will bubble up to `<html>`, trigger this handler, and close the `.menu` dropdown — but more critically, if the drawer's close button or backdrop click handler also propagates, it may interfere with the existing menu close logic or vice versa.

The reverse danger is worse: if the drawer's own `$('html').click` or `$(document).click` handler for closing the drawer is added naively without checking `e.target`, it will race with the existing handler and one will suppress the other.

**Why it happens:**
The existing menu code delegates to `$('html')` — the root of the DOM — as a catch-all dismiss handler. This is a common jQuery pattern but it means every click anywhere on the page passes through it. A second handler attached to the same target for the drawer will both fire. jQuery does not guarantee handler execution order (actually it does execute in attachment order, but both handlers run).

**How to avoid:**
- Reuse `toggle_menu()` or extract it into a named function accessible by both the existing menu code and the new drawer code.
- For the drawer close handler, attach to `$('html')` with an explicit guard: check `$(e.target).closest('.modern-drawer, .hamburger-btn').length === 0` before closing — mirroring the pattern already used in the existing handler.
- Move the inline `<script>` in `_menu.html.erb` to a proper JS file (e.g., `app/assets/javascripts/menu.js`) so the event handlers are defined once, not re-run if the partial is ever re-rendered by Turbolinks or similar.
- Explicitly call `e.stopPropagation()` inside the drawer open/close toggle so the event does not reach the `$('html')` handler when toggling the drawer via the hamburger button.

**Warning signs:**
- Clicking inside the drawer closes the email dropdown (or vice versa).
- The email dropdown closes immediately after opening when `.modern` theme is active.
- Console shows `toggle_menu is not defined` — the inline script ran before jQuery was available (a separate but related risk of inline scripts in partials).

**Phase to address:** JavaScript / drawer interaction phase.

---

### Pitfall 3: Two Separate `.header` / `#header` Concepts in common.css.scss

**What goes wrong:**
`common.css.scss` defines two distinct header selectors that serve different roles:
- `#header .head-box` — the static site-title bar rendered directly in `application.html.erb` (id-based, high specificity `1,1,0`).
- `.header` — the navigation row rendered by `_menu.html.erb` (class-based, specificity `0,1,0`).

A modern theme that intends to restyle the header must address both. Forgetting `.header` means the email/navigation row keeps legacy grey styling. Forgetting `#header` means the site-title bar is unstyled. Because `#header` uses an ID selector, `.modern #header` (specificity `0,1,0` + `1,0,0` = `1,1,0`) does beat `.modern .header` (`0,2,0`), so the ID rule always wins — any modern theme color applied to `#header .head-box` via a class-based rule will lose unless the theme also uses an ID selector.

**Why it happens:**
The header was built in two pieces at different times: `#header` is a layout wrapper in the layout template; `.header` is the navigation logic in a partial. They look like one thing visually but are styled separately. New theme authors assume "header" is one element.

**How to avoid:**
- In the modern theme stylesheet, always write overrides for both `#header .head-box` and `.modern .header` explicitly.
- For `#header`, use `.modern #header .head-box` (specificity `1,2,0`) which safely beats the base `#header .head-box` (`1,1,0`).
- Add a comment in `common.css.scss` near both selectors noting that they are separate header components.

**Warning signs:**
- The hamburger button sits inside `.header` but `.header` still has grey legacy background when `.modern` is applied.
- The site-title bar (`#header .head-box`) looks correct but the nav row below it is unstyled.

**Phase to address:** CSS scaffolding / theme skeleton phase.

---

### Pitfall 4: Sprockets `require_tree .` Includes themes/ Files in Alphabetical Subdirectory Order — But Only If `require_tree .` Is in the Root

**What goes wrong:**
`application.css` uses `require_tree .` which recursively includes all files in `app/assets/stylesheets/`. The `themes/` subdirectory is included as part of this traversal. Sprockets includes subdirectories after same-level files (alphabetical within each level). The current order places `themes/simple.css.scss` between `devise.css.scss` and `todos.css.scss.erb`. Adding `themes/modern.css.scss` in the same directory will include it immediately after `themes/simple.css.scss` — which is fine.

The pitfall: if someone creates a separate manifest file (e.g., `themes.css`) that does `require_tree ./themes` and also leaves `require_tree .` in `application.css`, the theme files are compiled TWICE. Sprockets deduplicates by default within a single manifest, but if two separate asset bundles are both served, the duplication causes bloat and possible ordering surprises.

**Why it happens:**
When a developer wants explicit control over theme loading they reach for a sub-manifest, not realising `require_tree .` already handles it.

**How to avoid:**
- Keep `themes/modern.css.scss` as a plain SCSS file in the `themes/` subdirectory. Do not create a `themes.css` manifest. `require_tree .` in `application.css` handles inclusion automatically.
- Verify inclusion order after adding the new file by running `bin/rake assets:precompile` locally and grep-checking the compiled output.
- Add a comment to `application.css` noting that `require_tree .` covers subdirectories including `themes/`.

**Warning signs:**
- After adding `themes/modern.css.scss`, running `rake assets:precompile` doubles the file count or produces an error about duplicate asset inclusion.
- Chrome DevTools shows theme rules duplicated in the `application.css` source map.

**Phase to address:** SCSS scaffolding phase.

---

### Pitfall 5: Side-Drawer Slides Under Other Positioned Elements (z-index stack)

**What goes wrong:**
The existing `.header .menu` dropdown is `position: absolute; z-index: 1`. A side-drawer that is `position: fixed` will appear above all static content but may appear under the `.menu` popup if the drawer's z-index is also 1 or lower. On mobile, if any element in the gadget column has `overflow: hidden` set (verified: `div.gadget div` in `welcome.css.scss` has `overflow: hidden`), a drawer using `transform: translateX()` or `position: fixed` can be clipped inside that overflow context.

**Why it happens:**
`overflow: hidden` on an ancestor creates a new stacking context. A `position: fixed` child is normally immune to ancestor overflow, but `transform`, `filter`, or `will-change` on any ancestor breaks that immunity and pins `position: fixed` to that container. Even without transforms, `z-index: 1` on the existing menu popup is low — any new overlay at z-index 1 is a race.

**How to avoid:**
- Assign the side-drawer a z-index of at least 100 (or a clearly documented high tier, e.g., `$z-drawer: 100; $z-menu-popup: 10;`).
- Do not apply `transform`, `filter`, or `will-change` to `body` or `.wrapper` as part of the drawer slide animation — use a wrapper `div.drawer-container` as the animation target instead.
- The drawer overlay (backdrop) should be `position: fixed` on `body` directly, not nested inside `.wrapper`.
- Verify on mobile: the gadget column's `overflow: hidden` should not clip the drawer. Keep drawer markup outside `.wrapper`.

**Warning signs:**
- Side-drawer appears behind the existing email dropdown popup on desktop.
- On mobile, the drawer slides in but is partially clipped at the right edge.
- Drawer backdrop does not cover the full viewport height on iOS Safari (body height shorter than viewport).

**Phase to address:** Side-drawer layout and animation phase.

---

### Pitfall 6: iOS Safari Mobile Viewport Height — Drawer Does Not Fill Screen

**What goes wrong:**
`body { margin: 0; padding: 0; }` is set in `common.css.scss` but there is no `min-height: 100vh` or `min-height: -webkit-fill-available`. On iOS Safari, `100vh` includes the browser chrome (address bar height) and can cause the drawer to visually fall short of the bottom of the visible area, with a white gap beneath it.

**Why it happens:**
iOS Safari's viewport height treatment differs from desktop browsers. `100vh` is calculated as the full viewport height including the collapsible top bar, so a fixed-height drawer covering `100vh` will overflow behind the toolbar when the page first loads, and will not reach the bottom when the toolbar is shown.

**How to avoid:**
- Use `min-height: 100dvh` for the drawer height (dynamic viewport height — supported in iOS 15.4+; this app's `preset-env` Babel config suggests modern browser targeting).
- As a fallback: set `height: 100%` on `html, body` (already partially done — `html { height: 100%; }` exists in `common.css.scss`) and use `min-height: 100%` on the drawer.
- Scope this fix inside the `.modern` theme block so it does not affect the existing theme.

**Warning signs:**
- On real iOS device or Safari DevTools device simulator, the drawer shows a white gap at the bottom.
- The drawer close button is unreachable (scrolled off above the fold).

**Phase to address:** Mobile viewport testing in the side-drawer phase.

---

### Pitfall 7: Inline `<script>` in `_menu.html.erb` Runs on Every Render — Event Handlers Stack

**What goes wrong:**
`_menu.html.erb` contains an inline `<script>` block with `$(document).ready(...)`. In a standard Rails server-rendered app without Turbolinks this fires once per full page load and is harmless. However, if Turbolinks or Hotwire Turbo is ever introduced (even accidentally via a gem), the partial will re-render without a full page reload and the `$(document).ready` block runs again, attaching a second (then third, then fourth...) set of click handlers. Each handler invocation triggers extra toggles.

For the v1.2 milestone: the new drawer JS will likely also live in a `$(document).ready` block, either inline or in a separate file. If both the menu partial and the drawer file attach handlers to `$('html').click`, and the menu partial is re-rendered or the page is navigated via any cache-aware mechanism, event stacking occurs.

**Why it happens:**
Inline scripts in Rails partials are an antipattern when combined with any kind of SPA-style navigation, but they work fine with full-page renders. The risk is introduced when new JS is written assuming the same "inline in partial" pattern.

**How to avoid:**
- Move the inline script from `_menu.html.erb` to `app/assets/javascripts/menu.js` as part of the v1.2 foundation work. This is a natural moment to do it.
- Write drawer JS in `app/assets/javascripts/modern_drawer.js` (a new dedicated file included via `require_tree .`).
- Use `$(document).on('click', ...)` delegation patterns rather than attaching handlers inside `$(document).ready` that reference local variables captured in a closure — closures referencing DOM elements stale after navigation.

**Warning signs:**
- The email dropdown requires two clicks to open (first click closes it immediately because the second stacked handler fires).
- `console.log` inside the click handler fires twice on first click.

**Phase to address:** JavaScript foundation phase (before adding drawer interactions).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `!important` overrides in modern theme to beat common.css.scss | Fast, obvious wins | Every future common.css.scss change requires a new `!important` escalation; impossible to override from user scripts | Never |
| Leave inline script in `_menu.html.erb` and add drawer JS inline in a new partial | Keeps everything together, no refactor needed | Event handler stacking risk if Turbolinks is ever added; cognitive overhead of two inline script blocks | Only if zero Turbolinks risk and milestone is time-boxed and followed by immediate cleanup |
| Write `.modern` overrides without a specificity convention | Faster initial writing | Unpredictable — depends on file include order, breaks silently when files are added | Never |
| Place drawer `<div>` inside `.wrapper` | Simpler markup | Drawer is clipped by ancestor `overflow: hidden` from gadget styles; also gets theme padding | Never — keep drawer outside `.wrapper` |
| Use `z-index: 9999` for everything | "It will always be on top" | Creates a z-index arms race; the existing `.menu` at z-index 1 will eventually need escalation too | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `_menu.html.erb` inline script + new drawer JS | Both attach `$('html').click` independently without coordinating guards | Add `e.stopPropagation()` on hamburger click; use a single shared dismiss handler that checks both `.email` and `.modern-drawer` |
| Sprockets `require_tree .` + themes/ subdirectory | Creating a separate `themes.css` manifest file, causing double-inclusion | Drop the file directly into `themes/` and rely on `require_tree .` — verify with a test precompile |
| `favorite_theme` helper returns `nil` for users without preferences | `<body class="<%= favorite_theme %>">` renders `class=""` which is valid, but `.modern {}` scoping never activates for nil | Confirm that `favorite_theme` returns `"modern"` (not `nil`) when a user selects the modern theme; add a test |
| `todos.css.scss.erb` (`.erb` extension) + new SCSS variables | Attempting to import a SCSS variable file from `todos.css.scss.erb` using `@import` or `@use` fails because `.erb` is processed before SCSS | Keep SCSS variables in a plain `.scss` partial; never import into `.erb` SCSS files |
| `position: fixed` drawer + `transform` on body | Adding a CSS `transform` to animate `body` (slide-body pattern for drawer) breaks `position: fixed` containment | Use a dedicated `div.drawer-container` for transforms; never transform `body` or `.wrapper` |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| All theme SCSS in one large `modern.css.scss` file | SCSS compilation slows; entire file recompiles on any change | Split into `themes/_modern-base.scss`, `themes/_modern-nav.scss` etc.; import from `modern.css.scss` | Not an issue at this scale — this is a personal app; acceptable as a single file for v1.2 |
| Drawer open/close on every `$('html').click` re-evaluating `closest()` | Slight jank on low-end mobile if DOM is deep | Guard with a boolean `drawerOpen` state variable; avoid repeated DOM traversal in hot path | Not a real risk at this scale |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Hamburger drawer renders navigation links before checking `user_signed_in?` | Nav links visible in HTML source to unauthenticated users (links present, not just hidden by CSS) | Wrap drawer markup in `<% if user_signed_in? %>` same as existing `render 'common/menu'` guard in `application.html.erb` |
| Inline theme value written directly into `<body class="">` without sanitization | Stored XSS if `preference.theme` is not validated to an allowlist | Validate `theme` column on the `Preference` model to an enum or allowlist (`["", "simple", "modern"]`) before storing; already implicitly safe if using a `select` form field but explicit validation is required |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Drawer does not close on `Escape` key | Keyboard/accessibility users cannot dismiss the drawer without clicking the close button or backdrop | Bind `$(document).on('keydown', ...)` checking `e.key === 'Escape'` to close the drawer |
| Drawer backdrop blocks scroll but body scrolls behind it | Mobile users see content scrolling behind the open drawer overlay | Apply `overflow: hidden` to `body` (scoped to `.modern.drawer-open body`) when drawer is open; remove on close |
| No `aria-expanded` / `aria-controls` on hamburger button | Screen readers cannot announce drawer state | Add `aria-expanded="false"` to the button; toggle to `"true"` when drawer opens; add `aria-controls="modern-drawer"` |
| Hamburger button appears in all themes (not just `.modern`) | The hamburger button is confusing when the full navigation bar is already visible | Only render or show the hamburger button when `body.modern` is active — either conditionally in ERB or via CSS `display: none` in non-modern themes |
| Existing `.header` nav (rendered by `_menu.html.erb`) still visible alongside the drawer in modern theme | Two navigation systems on screen at once | Hide `.header` navigation in `.modern` theme via `.modern .header { display: none; }` (same pattern as `.simple #header { display: none; }` in `simple.css.scss`) |

---

## "Looks Done But Isn't" Checklist

- [ ] **Modern theme body class:** `favorite_theme` returns `"modern"` (not `nil` or `"default"`) after selecting modern in preferences — verify by checking the helper and the DB value written by the form.
- [ ] **Existing `.header` nav hidden:** When `.modern` is active, the old navigation row (email dropdown, Home link) is hidden or replaced — not showing both old and new nav simultaneously.
- [ ] **Drawer closes on three triggers:** hamburger re-click, backdrop click, and Escape key — all three must work.
- [ ] **Asset precompile clean:** Run `rake assets:clobber && rake assets:precompile` — zero errors, `themes/modern.css.scss` appears in the compiled output only once.
- [ ] **No `!important` in theme file:** grep the compiled CSS for `!important` rules sourced from `themes/modern.css.scss`.
- [ ] **simple theme unbroken:** After adding modern theme, verify `.simple` theme still hides `#header` correctly — the new file must not introduce a rule that re-shows `#header` globally.
- [ ] **Inline script moved:** The inline `<script>` in `_menu.html.erb` is either removed (logic moved to `menu.js`) or verified not to interfere with drawer handlers.
- [ ] **Preference form updated:** The theme `<select>` in `preferences/index.html.erb` includes `'Modern' => 'modern'` as an option alongside the existing `'シンプル' => 'simple'`.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Specificity war — base styles bleed into modern theme | MEDIUM | Audit all common.css.scss selectors; increase theme selector specificity systematically; do not patch one-by-one with `!important` |
| jQuery event handler stacking after partial re-render | LOW–MEDIUM | Move inline script to `menu.js`; add `.off('click')` before `.on('click')` as a guard; or namespace events: `.on('click.menu', ...)` so `.off('.menu')` cleanly removes only menu handlers |
| Drawer clipped by overflow:hidden ancestor | LOW | Move drawer `<div>` to be a direct child of `<body>`, outside `#header` and `.wrapper` |
| themes/modern.css.scss compiled twice | LOW | Remove any sub-manifest that duplicates `require_tree .` coverage; run `rake assets:clobber && rake assets:precompile` to confirm |
| iOS Safari drawer height gap | LOW | Replace `height: 100vh` with `height: 100dvh` on the drawer element; test on iOS simulator |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| CSS specificity war (common vs theme) | SCSS scaffolding — define `.modern` selector convention before writing any rules | Toggle `.modern` class in DevTools on every page type; confirm no base style bleeds through |
| `$('html').click` handler conflict | JS foundation — move inline script, establish drawer handler pattern | Open email dropdown and drawer simultaneously; verify they dismiss independently |
| Two header selectors (`#header` vs `.header`) | SCSS scaffolding — document both, style both | Visual review with `.modern` active: both header elements properly styled |
| `require_tree .` double-inclusion | SCSS scaffolding | `rake assets:precompile`; grep compiled file for `themes/modern` — appears exactly once |
| z-index stack / drawer under menu popup | Side-drawer layout phase | Open both email dropdown and side-drawer; drawer must be on top |
| iOS Safari viewport height | Side-drawer mobile phase | Test on iOS Safari device or simulator at 375px width |
| Inline script event stacking | JS foundation phase | Add console.log to click handler; verify single invocation per click |
| Drawer visible outside `.modern` theme | CSS scaffolding | Switch to default theme; confirm hamburger button and drawer are invisible |

---

## Sources

- Direct inspection: `app/assets/stylesheets/common.css.scss`, `app/assets/stylesheets/themes/simple.css.scss`, `app/views/common/_menu.html.erb`, `app/views/layouts/application.html.erb`, `app/assets/stylesheets/application.css`, `app/assets/javascripts/application.js`
- Compiled asset order verified from: `public/assets/application-*.css` (line-number source comments)
- Sprockets `require_tree` traversal behavior: documented in Sprockets README (alphabetical, subdirectories included recursively)
- iOS Safari `100dvh` support: iOS 15.4+ (CSS Working Group dynamic viewport units spec)
- jQuery event handler stacking: standard jQuery `.on()` accumulation behavior (jQuery API docs)

---
*Pitfalls research for: v1.2 Modern Theme — Rails 8.1 + Sprockets + jQuery SCSS*
*Researched: 2026-04-28*
