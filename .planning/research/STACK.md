# Technology Stack — Device-Aware Font-Size Baseline

**Project:** Bookmarks  
**Scope:** Device-aware medium baseline (PC/mobile), relative small/large scaling, safe migration for existing users  
**Researched:** 2026-05-06

## Recommended Stack Changes (Minimal)

## Keep (no new runtime stack)
- Rails 8.1 + ActiveRecord + existing `preferences.font_size` string column
- Sprockets + SCSS in `app/assets/stylesheets/`
- Existing body class contract: `font-size-small|medium|large` from `WelcomeHelper#font_size_class`

## Change
1. **CSS only** for device-aware baseline and relative scaling.
2. **No DB schema migration** required for MVP.
3. Optional hardening: one-time data cleanup migration for invalid legacy `font_size` values.

---

## CSS Strategy (Recommended)

Use **px baseline + media query + relative multipliers** in `common.css.scss` (global scope), not JS/device detection.

```scss
/* app/assets/stylesheets/common.css.scss */

$font-medium-desktop: 12px;
$font-medium-mobile: 14px; // example target
$font-scale-small: 0.833333; // 10/12
$font-scale-large: 1.166667; // 14/12
$font-device-breakpoint: 768px; // align with existing mobile split

body {
  --font-medium: #{$font-medium-desktop};
  font-size: var(--font-medium);
}

@media (max-width: $font-device-breakpoint - 1px) {
  body { --font-medium: #{$font-medium-mobile}; }
}

body.font-size-medium { font-size: var(--font-medium); }
body.font-size-small  { font-size: calc(var(--font-medium) * #{$font-scale-small}); }
body.font-size-large  { font-size: calc(var(--font-medium) * #{$font-scale-large}); }
```

### Why this strategy
- Preserves existing preference values (`small|medium|large`) and helper/view behavior.
- Keeps behavior global across themes because class is on `<body>`.
- Avoids fragile UA sniffing and avoids introducing frontend build tooling.

---

## Rails Migration Approach (Safe)

## MVP (recommended)
- **No migration**.
- Keep `font_size` nullable and continue fallback to medium:
  - already present in helper (`font_size_class`)
  - already reflected in preferences UI selected default.

## Optional hardening migration
If you want to sanitize stale DB rows:
- Add migration with SQL or `update_all` to set invalid values to `NULL`.
- Do **not** change column type or enum now.

Example intent:
- invalid `font_size` -> `NULL` (render-time fallback to medium remains safe).

---

## Constants Placement

## Keep in Ruby (`app/models/preference.rb`)
- `FONT_SIZE_SMALL/MEDIUM/LARGE`
- `FONT_SIZES`
- Semantics only (allowed values), not pixel numbers.

## Put typography numbers in SCSS
- Baselines and scale multipliers in `common.css.scss` (or extracted `_typography_tokens.scss` imported there).
- Keep one source of truth for breakpoint and scaling.

---

## What NOT to Introduce

- No new gem for device detection (no UA parser).
- No JS-based font-size switching.
- No new preference fields like `mobile_font_size` / `desktop_font_size` for MVP.
- No enum/type migration for `font_size` yet.
- No SPA/frontend framework changes (out of scope for Sprockets app).

---

## Caveats / Regression Risk

1. **Cross-theme consistency risk:** many theme selectors use fixed `px`; these won't scale with body baseline.
   - Accept for MVP, then gradually convert critical text sizes to `rem` in theme files.
2. **Breakpoint consistency:** use existing mobile boundary (768 split) to avoid "font jumps" differing from layout behavior.
3. **Visual regression risk:** compact UI elements (header, breadcrumb buttons, drawer text) may wrap earlier on mobile after baseline increase.
   - Re-run existing controller/integration/Cucumber coverage and add a focused visual/system check for mobile typography.

---

## Minimal vs Optional Summary

## Minimal (do now)
- SCSS-only device-aware baseline + relative small/large scaling in `common.css.scss`.
- No DB migration.

## Optional (later)
- Data cleanup migration for invalid `font_size`.
- Theme-by-theme `px` -> `rem` conversion for deeper consistency.

---

## Sources (repo)
- `.planning/PROJECT.md`
- `app/models/preference.rb`
- `app/helpers/welcome_helper.rb`
- `app/assets/stylesheets/common.css.scss`
- `app/views/preferences/index.html.erb`
- `app/views/layouts/application.html.erb`
- `db/schema.rb`
- `app/assets/stylesheets/themes/*.css.scss`
- `test/controllers/preferences_controller_test.rb`
- `test/models/preference_test.rb`

## Non-Recommended (今回非推奨)

| Option | Why Not |
|--------|---------|
| New frontend framework (including React/Vue/Stimulus migration) | Violates milestone constraints and adds unnecessary migration cost |
| jQuery Mobile introduction | Officially end-of-life; high future maintenance risk |
| Premature gesture-library adoption (for example Hammer.js) | Over-scoped for left/right swipe + persistence requirements |
| Simultaneous migration to Webpack/Vite/esbuild | Out of scope and increases delivery risk |

## Compatibility Risks (Must Be Explicit During Implementation)

### 1) Sprockets

- **Risk:** Event initialization can break when file load order changes.  
- **Mitigation:** Keep manifest order deterministic and follow the existing non-Turbolinks initialization pattern used in `application.js`.

### 2) jQuery

- **Risk:** jQuery does not provide high-level swipe events; misusing `touchmove`/`pointermove` can interfere with scrolling.  
- **Mitigation:** Handle raw events explicitly with vertical-scroll-priority logic; keep jQuery limited to DOM selection/binding support.

### 3) Touch / Pointer Events

- **Risk:** Incorrect `preventDefault()` / passive listener usage can break intended gesture control.  
- **Mitigation:** Set `touch-action` intentionally and use non-passive listeners only where required.  
- **Risk:** Pointer/Touch API behavior differs by environment.  
- **Mitigation:** Use Pointer-first with Touch fallback and shared threshold logic to absorb differences.

### 4) localStorage

- **Risk:** `setItem` can throw in private mode or quota-limited environments.  
- **Mitigation:** Use availability checks and try/catch; continue safely with default column behavior on failure.

## Practical Recommendation for v1.8

- **Adopt:** Keep existing stack + implement swipe/localStorage in first-party code  
- **Why:** Best fit for constraints, lowest risk, fastest path to user value  
- **Acceptance gate:** All three suites green (`yarn run lint` / `bin/rails test` / `bundle exec rake dad:test`)

## Sources

- MDN: Pointer Events (Using Pointer Events) — https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events/Using_Pointer_Events  
- MDN: Web Storage API (Using the Web Storage API) — https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API  
- jQuery API documentation — https://api.jquery.com/  
- jQuery Mobile swipe docs (support ended notice) — https://api.jquerymobile.com/swipe/
