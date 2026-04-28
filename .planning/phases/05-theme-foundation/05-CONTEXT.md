# Phase 5: Theme Foundation - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Register `modern` as a selectable theme in the preferences UI; create `themes/modern.css.scss` with a `.modern {}` root scope and minimal CSS custom property color tokens; create `menu.js` with a `body.modern` guard that exits immediately when the theme is not active. No drawer markup, no animation, no full styling — those belong in Phases 6–9.

</domain>

<decisions>
## Implementation Decisions

### CSS Custom Property Naming

- **D-01:** All CSS custom properties use the `--modern-` prefix (e.g., `--modern-color-primary`), even though they are already selector-scoped inside `.modern {}`. This keeps token names self-documenting and prevents collisions if other themes later define their own properties.

### CSS Design Token Set (Phase 5 stub)

- **D-02:** Define only the 4 color tokens needed as a foundation for Phases 7–9. Drawer-specific and typography tokens are added in the phases that consume them.

  ```scss
  .modern {
    --modern-color-primary: #3b82f6;
    --modern-bg:            #ffffff;
    --modern-text:          #1a1a1a;
    --modern-header-bg:     #1e40af;
  }
  ```

### Preferences UI

- **D-03:** Add `'モダン' => 'modern'` to the theme select in `app/views/preferences/index.html.erb`, following the existing hash pattern `{'シンプル' => 'simple'}`.

### `menu.js` Guard

- **D-04:** All drawer logic is wrapped inside `$(function() { if (!$('body').hasClass('modern')) return; ... })`. The guard is the first statement inside the DOM-ready callback, so the file has zero side effects when `body.modern` is absent. (Decided in planning; confirmed by STATE.md entry.)

### Claude's Discretion

- Internal structure of `menu.js` stub beyond the guard (empty body, comment skeleton) — follow v1.1 JS conventions from `CONVENTIONS.md`.
- Exact SCSS nesting style inside `.modern {}` — follow `simple.css.scss` as reference.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Theme Infrastructure
- `app/assets/stylesheets/themes/simple.css.scss` — existing theme pattern; `.simple {}` root scope with nested rules. Phase 5 mirrors this structure for `.modern {}`.
- `app/helpers/welcome_helper.rb` — `favorite_theme` helper; returns `preference.theme` string applied as body class. No changes needed for `modern` to work.
- `app/views/layouts/application.html.erb` — `<body class="<%= favorite_theme %>">` — confirms how body class is applied.

### Preferences
- `app/views/preferences/index.html.erb` — theme `<select>` with `{'シンプル' => 'simple'}` hash and `include_blank: 'デフォルト'`. Add `'モダン' => 'modern'` here.
- `app/models/preference.rb` — `theme` attribute on `Preference`; no DB migration needed.

### Asset Pipeline
- `app/assets/stylesheets/application.css` — `require_tree .` manifest; auto-includes any new `.scss` under `stylesheets/`. No manifest change needed.
- `app/assets/javascripts/application.js` — `require_tree .` manifest; auto-includes any new `.js` under `javascripts/`. No manifest change needed.

### Requirements
- `.planning/REQUIREMENTS.md` §Theme Infrastructure — THEME-01, THEME-02, THEME-03 (all three assigned to Phase 5).
- `.planning/ROADMAP.md` §Phase 5 — success criteria (4 items) are the acceptance checklist.

### JS Conventions
- `.planning/codebase/CONVENTIONS.md` — v1.1 JS style (const/let, `$(function() {...})` pattern). `menu.js` must follow this.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/assets/stylesheets/themes/simple.css.scss`: Template for a theme file — `.simple {}` root scope with nested SCSS rules. Copy structure, change class name to `.modern`.
- `favorite_theme` helper (`welcome_helper.rb`): Already wired to body class. No changes needed for `modern` to activate.

### Established Patterns
- Theme select in preferences uses Ruby hash `{'Label' => 'value'}` with `include_blank:` for the default — add `'モダン' => 'modern'` to this hash.
- `require_tree .` in both manifests: new files in `stylesheets/themes/` and `javascripts/` are auto-compiled and included. No registration step.
- libsass limitation: CSS custom property values must be plain CSS values (e.g., `#3b82f6`), NOT SCSS variable references (e.g., `$primary-color`).

### Integration Points
- `app/views/preferences/index.html.erb` line with `f.select :theme` — the only file that needs a one-line addition for THEME-01.
- `app/assets/stylesheets/themes/` — drop `modern.css.scss` here (parallel to `simple.css.scss`) for THEME-02.
- `app/assets/javascripts/` — drop `menu.js` here for THEME-03.

</code_context>

<specifics>
## Specific Ideas

- CSS token values are set: `--modern-color-primary: #3b82f6` (blue), `--modern-bg: #ffffff`, `--modern-text: #1a1a1a`, `--modern-header-bg: #1e40af` (dark blue). These are the foundation for Phase 9 header/button styling.
- The `menu.js` guard exact form: `if (!$('body').hasClass('modern')) return;` as first statement inside the `$(function() {...})` callback.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 5-Theme Foundation*
*Context gathered: 2026-04-28*
