# Stack Research

**Domain:** Modern CSS theme + hamburger side-drawer nav in Rails 8.1 / Sprockets / jQuery
**Researched:** 2026-04-28
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| sass-rails (sassc/libsass) | 6.0.0 (already installed) | Compile `themes/modern.css.scss` | Already in pipeline; no new gem needed for a scoped theme file |
| CSS custom properties | Native CSS (no version) | Design tokens (colors, spacing, radii) scoped to `.modern` | Cascade-native; readable; zero runtime cost; works through sassc as plain CSS passthrough |
| jQuery | 4.6.1 (already installed) | Toggle `.drawer-open` class on `<body>` for hamburger | Already available; two-line implementation; no new library justified |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dartsass-sprockets | 3.2.0 | Replace sassc with Dart Sass to get full, unambiguous CSS custom property support and remove libsass deprecation | Only if the team wants to eliminate the `#{$var}` interpolation workaround or sees libsass deprecation warnings as unacceptable. NOT required for this milestone. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| ESLint + Prettier (already configured) | Lint the drawer toggle JS added to `application.js` or a new `modern_theme.js` | Run `yarn run lint` before commit; conventions already in CONVENTIONS.md |

## Installation

No new gems or npm packages are required for this milestone.

The `themes/modern.css.scss` file is picked up automatically by `require_tree .` in `application.css`, which already includes `themes/` via the tree directive.

If `dartsass-sprockets` is adopted in a later milestone:

```ruby
# Gemfile — replace sass-rails line
gem 'dartsass-sprockets', '~> 3.2'
```

```bash
bundle install
```

## CSS Custom Properties in sassc (CRITICAL — Libsass Bug)

The project uses `sass-rails 6.0.0` backed by `sassc-rails 2.1.2` / libsass. Libsass has a known unfixed bug: assigning a SCSS variable directly to a CSS custom property silently outputs the SCSS variable name as a literal string instead of its value.

**Broken (libsass bug — sassc outputs `--color: $brand;` literally):**

```scss
$brand: #2563eb;
.modern {
  --color: $brand;   // WRONG — outputs literal "$brand"
}
```

**Correct workaround — use interpolation:**

```scss
$brand: #2563eb;
.modern {
  --color: #{$brand};   // CORRECT — outputs "#2563eb"
}
```

**Also correct — skip SCSS variables entirely, write plain CSS custom properties:**

```scss
.modern {
  --color-brand: #2563eb;   // CORRECT — plain CSS value passes through untouched
  --color-brand-hover: #1d4ed8;
}
```

**Recommendation:** For `modern.css.scss`, define all design tokens as plain CSS custom property declarations inside `.modern { :root }` or directly on `.modern`. Avoid assigning SCSS `$variables` to `--custom-properties` unless wrapped in `#{...}` interpolation. This is the safest pattern and avoids any libsass version ambiguity.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Hand-rolled CSS theme file | Bootstrap gem (`bootstrap-rubygem`) | Only if the team wants a full design system; massive overhead for one theme in one app — not justified here |
| Hand-rolled CSS theme file | Tailwind CSS (`tailwindcss-rails`) | Only if migrating entire app to utility classes — would require rewriting existing views, out of scope |
| jQuery class toggle for drawer | Standalone drawer JS library (e.g. `drawer` npm package) | Only if advanced features like touch gestures or multi-level menus are needed; not needed here |
| dartsass-sprockets (deferred) | Migrate to Propshaft + cssbundling-rails | Much larger pipeline migration; explicit out-of-scope constraint in PROJECT.md |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Any CSS framework gem (Bootstrap, Bulma) | Adds hundreds of KB to the compiled stylesheet for features that conflict with the existing `common.css.scss` baseline; theme-switching becomes fragile | Hand-rolled `themes/modern.css.scss` scoped to `.modern` |
| npm CSS packages in `node_modules` | Sprockets does not resolve `node_modules` by default without additional configuration; npm CSS is not on the `asset_path` | Vendor CSS in `vendor/assets/stylesheets/` if needed, or just write the CSS directly |
| Inline `<style>` blocks or `<script>` blocks in partials | The existing `_menu.html.erb` already has an inline `<script>` block; do not add more — it bypasses ESLint and breaks CSP | Separate JS file in `app/assets/javascripts/` |
| CSS `@import` inside the theme file for Sprockets-managed files | Sprockets `require_tree` and SCSS `@import` interact poorly; Sprockets processes files in isolation, so `@import` paths resolve differently | Keep the theme file self-contained; reference shared tokens via CSS custom properties set in the cascade |

## Stack Patterns

**Drawer pattern — CSS + jQuery (no library):**

```css
/* In themes/modern.css.scss */
.modern .nav-drawer {
  position: fixed;
  top: 0; left: 0;
  width: 280px; height: 100%;
  transform: translateX(-100%);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 200;
}
.modern.drawer-open .nav-drawer {
  transform: translateX(0);
}
.modern .drawer-overlay {
  display: none;
  position: fixed; inset: 0;
  z-index: 199;
}
.modern.drawer-open .drawer-overlay {
  display: block;
}
```

```javascript
// In app/assets/javascripts/modern_theme.js
$(document).ready(function () {
  const $body = $('body');

  $('#hamburger-btn').on('click', function () {
    $body.toggleClass('drawer-open');
  });

  $('.drawer-overlay, .drawer-close-btn').on('click', function () {
    $body.removeClass('drawer-open');
  });
});
```

**CSS custom properties design token pattern (safe for libsass):**

```scss
// themes/modern.css.scss
.modern {
  // All values are plain CSS — no SCSS $variable interpolation needed
  --color-brand:       #2563eb;
  --color-brand-hover: #1d4ed8;
  --color-bg:          #f8fafc;
  --color-surface:     #ffffff;
  --color-text:        #1e293b;
  --color-border:      #e2e8f0;
  --radius-sm:         4px;
  --radius-md:         8px;
  --shadow-sm:         0 1px 3px rgba(0,0,0,0.1);
  --font-sans:         system-ui, -apple-system, sans-serif;
  --spacing-4:         1rem;
}

// Use the tokens throughout the theme
.modern #header {
  background: var(--color-brand);
  color: #fff;
  font-family: var(--font-sans);
}
```

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| sass-rails 6.0.0 | sassc-rails 2.1.2, libsass (C impl) | CSS custom properties pass through as plain CSS; SCSS `$var` → `--prop` requires `#{$var}` interpolation |
| dartsass-sprockets 3.2.0 | Ruby 3.1+, Rails 6.1+, Sprockets | Drop-in for sass-rails; full Dart Sass custom property support; not needed this milestone |
| jQuery 4.6.1 | Already loaded via `jquery-rails` in application.js | Class toggling for drawer; no additional load |

## Sources

- https://github.com/sass/libsass/issues/2635 — Confirmed libsass bug: `--prop: $var` does not interpolate; `--prop: #{$var}` is the fix. Repository archived as read-only (libsass is end-of-life).
- https://sass-lang.com/libsass/ — Official deprecation notice for libsass; Dart Sass is the canonical implementation.
- https://github.com/tablecheck/dartsass-sprockets — dartsass-sprockets v3.2.0; drop-in Sprockets replacement using Dart Sass; Ruby 3.1+, Rails 6.1+.
- https://dev.to/felipperegazio/css-custom-properties-vars-with-sass-scss-a-practical-architecture-strategy-1m88 — Practical pattern: define design tokens as plain CSS custom properties, use SCSS only for structural nesting and mixins.
- https://blog.bitsrc.io/animate-a-mobile-hamburger-bar-menu-using-css-and-just-a-hint-of-javascript-f31f928eb992 — `transform: translateX` drawer pattern with `transition: transform 0.3s cubic-bezier(0.4,0,0.2,1)`.

---
*Stack research for: Modern CSS theme + hamburger side-drawer nav (Rails 8.1 / Sprockets / jQuery)*
*Researched: 2026-04-28*
