# Architecture Research

**Domain:** Modern Theme — Hamburger + Side-Drawer Nav for Sprockets Rails app
**Researched:** 2026-04-28
**Confidence:** HIGH (all findings derived from direct source inspection)

## Standard Architecture

### System Overview

```
Browser
  │
  ▼
application.html.erb  ← body class="<%= favorite_theme %>"  (e.g. "modern")
  │
  ├── #header  (static HTML in layout)
  │     └── .head-box  ← hamburger button goes here (modern theme only, hidden by default CSS)
  │
  └── .wrapper
        ├── render 'common/menu'  ← drawer HTML + inline JS lives here
        │     ├── .modern-drawer           (new: side drawer panel)
        │     ├── .modern-drawer-overlay   (new: dimming overlay)
        │     └── .modern-hamburger        (new: hamburger button, also rendered in header area)
        └── yield  (page content)

app/assets/stylesheets/
  ├── application.css         (manifest — require_tree . pulls everything)
  ├── common.css.scss         (global base styles, theme-neutral)
  └── themes/
        ├── simple.css.scss   (existing theme — scoped to body.simple)
        └── modern.css.scss   (NEW — scoped to body.modern, full-page restyle + drawer)

app/assets/javascripts/
  ├── application.js          (manifest — require_tree . pulls everything)
  ├── menu.js                 (NEW — drawer toggle logic, loaded globally, runs only on .modern body)
  └── ...existing files...
```

### Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `application.html.erb` | Sets `body.modern` class, renders layout chrome | Modified |
| `_menu.html.erb` | Nav link list; drawer + overlay HTML; hamburger button | Modified |
| `themes/modern.css.scss` | All modern-theme styles scoped under `.modern` | New |
| `menu.js` | Drawer open/close toggle, overlay click to close | New |
| `preferences/index.html.erb` | Adds "モダン" option to theme select | Modified |

---

## Recommended Project Structure

```
app/
├── assets/
│   ├── javascripts/
│   │   ├── application.js          (manifest — unchanged)
│   │   └── menu.js                 (NEW — drawer toggle JS)
│   └── stylesheets/
│       ├── application.css         (manifest — unchanged, require_tree picks up new file)
│       ├── common.css.scss         (unchanged — no drawer styles here)
│       └── themes/
│           ├── simple.css.scss     (unchanged)
│           └── modern.css.scss     (NEW — full theme + drawer CSS)
└── views/
    ├── layouts/
    │   └── application.html.erb    (modified — hamburger button inside #header > .head-box)
    ├── common/
    │   └── _menu.html.erb          (modified — add drawer HTML, remove old inline <script>)
    └── preferences/
        └── index.html.erb          (modified — add 'モダン' => 'modern' to theme select)
```

### Structure Rationale

- **`themes/modern.css.scss`:** Mirrors the existing `simple.css.scss` pattern — a single file scoped to `body.modern { ... }`. Sprockets `require_tree .` in `application.css` automatically picks it up. No manifest changes needed.
- **`menu.js` (separate file, not inline `<script>`):** The existing inline `<script>` in `_menu.html.erb` is the pattern the old dropdown used, but v1.1 established ESLint on `app/assets/javascripts/`. Inline scripts are not linted. A separate `.js` file participates in `yarn run lint` and follows project conventions.
- **Hamburger in layout, drawer in partial:** The layout owns structural chrome (`#header`); the partial owns nav content. Placing the hamburger button inside `#header > .head-box` in `application.html.erb` is correct because: (a) it must always be visible in the header bar, (b) it is layout-level concern. The drawer panel itself belongs in `_menu.html.erb` because it contains the nav links.

---

## Architectural Patterns

### Pattern 1: Theme-Scoped CSS in `body.{theme}` Selector

**What:** All visual overrides for the modern theme are wrapped in a single `.modern { ... }` block inside `themes/modern.css.scss`. The drawer, header restyle, typography, tables, buttons, and forms are all children of this selector.

**When to use:** Always, for this theme. The `body` class is set server-side via `favorite_theme` helper, so no client-side class toggling is needed for activation.

**Trade-offs:** Specificity is slightly elevated, but this matches the existing `simple.css.scss` pattern and isolates the theme completely. Zero risk of leaking into other themes.

**Example:**
```scss
// app/assets/stylesheets/themes/modern.css.scss

.modern {
  // Header restyle
  #header .head-box {
    background: #1e293b;
    color: #f8fafc;
  }

  // Drawer panel
  .modern-drawer {
    position: fixed;
    top: 0;
    left: -280px;
    width: 280px;
    height: 100vh;
    background: #1e293b;
    transition: left 0.25s ease;
    z-index: 100;

    &.open {
      left: 0;
    }
  }

  // Overlay
  .modern-drawer-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.4);
    z-index: 99;

    &.visible {
      display: block;
    }
  }
}
```

### Pattern 2: Drawer Toggle in a Dedicated JS File

**What:** `app/assets/javascripts/menu.js` contains the `$(document).ready` handler that binds the hamburger click, overlay click, and Escape key to open/close the drawer. It guards itself with `if ($('body').hasClass('modern'))` so it is inert on non-modern themes.

**When to use:** Always for new JS in this project (per v1.1 convention). Keeps the ERB partial clean; participates in ESLint.

**Trade-offs:** The file is loaded globally (all pages), but the guard clause and the `if (user_signed_in?)` rendering of `_menu.html.erb` mean no-ops on other themes. Negligible overhead.

**Example:**
```javascript
// app/assets/javascripts/menu.js

$(document).ready(function () {
  if (!$('body').hasClass('modern')) return;

  const drawer = $('.modern-drawer');
  const overlay = $('.modern-drawer-overlay');
  const hamburger = $('.modern-hamburger');

  function openDrawer() {
    drawer.addClass('open');
    overlay.addClass('visible');
  }

  function closeDrawer() {
    drawer.removeClass('open');
    overlay.removeClass('visible');
  }

  hamburger.on('click', openDrawer);
  overlay.on('click', closeDrawer);

  $(document).on('keydown', function (e) {
    if (e.key === 'Escape') closeDrawer();
  });
});
```

### Pattern 3: Hamburger Button in Layout, Drawer Panel in Partial

**What:** The hamburger `<button>` is placed inside `#header > .head-box` in `application.html.erb`. The drawer `<div>` and overlay `<div>` are placed inside `_menu.html.erb` (outside the existing `.header` nav div, before or after it, at the top of the partial).

**When to use:** This split matches the existing responsibility boundary: the layout owns persistent page chrome; the partial owns navigation content.

**Trade-offs:** The hamburger is always rendered in the layout for signed-in users (the layout already conditionally renders `_menu.html.erb` with `if user_signed_in?`). Hide the hamburger on non-modern themes with `.modern #header .modern-hamburger { display: inline-flex; }` and a default `display: none` in `common.css.scss` or via `.modern`-scoped rules. Alternatively, hide it with an ERB conditional — both work, but the CSS approach avoids logic in ERB and is theme-symmetric with the simple theme's `#header { display: none }` pattern.

---

## Data Flow

### Theme Activation Flow

```
User selects "modern" in Preferences form
    ↓
PreferencesController saves preference.theme = "modern"
    ↓
Next request: WelcomeHelper#favorite_theme returns "modern"
    ↓
application.html.erb: <body class="modern">
    ↓
Sprockets-compiled application.css includes themes/modern.css.scss
    ↓
CSS rules under .modern { ... } activate — drawer, header, full-page styles applied
```

### Drawer Toggle Flow

```
User clicks hamburger button (.modern-hamburger)
    ↓
menu.js jQuery handler fires
    ↓
drawer.addClass('open')        → CSS transition: left 0 → slides in
overlay.addClass('visible')    → overlay fades in
    ↓
User clicks overlay OR presses Escape
    ↓
drawer.removeClass('open')     → CSS transition: slides out
overlay.removeClass('visible') → overlay hides
```

### Preferences Select — Adding "modern"

```
preferences/index.html.erb
  f.select :theme, {'シンプル' => 'simple', 'モダン' => 'modern'}, include_blank: 'デフォルト'
                                            ^^^^^^^^^^^^^^^^^^^
                                            one-line addition
```

No model changes, no migration, no new columns. `preference.theme` already stores a string.

---

## New vs Modified Files

### New Files

| File | Purpose |
|------|---------|
| `app/assets/stylesheets/themes/modern.css.scss` | Full modern theme — header, body, drawer, tables, buttons, forms. Scoped to `.modern { }`. |
| `app/assets/javascripts/menu.js` | Drawer open/close logic. Loaded globally; guards on `body.modern`. |

### Modified Files

| File | What Changes |
|------|-------------|
| `app/views/layouts/application.html.erb` | Add hamburger `<button class="modern-hamburger">` inside `#header > .head-box`. |
| `app/views/common/_menu.html.erb` | Add drawer `<div class="modern-drawer">` and overlay `<div class="modern-drawer-overlay">` with nav links. Remove existing inline `<script>` block (move logic to `menu.js`). |
| `app/views/preferences/index.html.erb` | Add `'モダン' => 'modern'` to the theme select options. |

### Unchanged Files (confirmed safe)

| File | Why Unchanged |
|------|---------------|
| `app/assets/stylesheets/application.css` | `require_tree .` already picks up new files under `themes/`. No manifest edit needed. |
| `app/assets/javascripts/application.js` | `require_tree .` already picks up `menu.js`. No manifest edit needed. |
| `app/assets/stylesheets/common.css.scss` | Base styles remain global. Theme-specific overrides belong in `modern.css.scss`. The only touch needed is a default `display: none` for `.modern-hamburger` if the element is unconditionally rendered in the layout — this can live in `common.css.scss` or in `modern.css.scss` (using `.modern .modern-hamburger { display: inline-flex }` with a base `display: none` rule outside the theme scope). Prefer adding it to `common.css.scss` for clarity: `.modern-hamburger { display: none; }` (one line). |
| `app/helpers/welcome_helper.rb` | `favorite_theme` already returns the raw string; "modern" works with no changes. |

---

## Integration Points

### Sprockets Compatibility

**Confirmed:** `application.css` uses `*= require_tree .` which recursively includes all `.css` and `.css.scss` files in `app/assets/stylesheets/` and subdirectories. A new file at `themes/modern.css.scss` is automatically included. No manual manifest entry needed.

**Confirmed:** `application.js` uses `//= require_tree .` which includes all `.js` files in `app/assets/javascripts/`. A new `menu.js` is automatically included. No manual manifest entry needed.

**Sprockets load order:** `require_tree .` includes files alphabetically. `common.css.scss` loads before `themes/modern.css.scss` — the base styles land first, the theme overrides second. This is the correct order.

### jQuery Compatibility

`menu.js` uses jQuery (globally available via `application.js`). The `$(document).ready` pattern and `.addClass`/`.removeClass` are jQuery 4-compatible. No jQuery UI is needed for the drawer (CSS transitions handle animation). The overlay pattern avoids `$(document).click` anti-patterns that caused issues in the existing menu.

### Existing Dropdown Menu — Migration Strategy

The existing `_menu.html.erb` has an inline `<script>` for the dropdown (`.email` click toggle). For the modern theme, the drawer replaces this dropdown entirely. Two options:

1. **Recommended:** Keep the inline `<script>` in the partial (it handles the non-modern `.header` dropdown), and add `menu.js` for the modern drawer. The guard `if (!$('body').hasClass('modern')) return;` in `menu.js` prevents conflicts. The inline script only affects `.email` and `.menu`, which are not rendered in the modern drawer layout.

2. **Alternative:** Migrate the inline script entirely to `menu.js` (handling both themes). This is cleaner long-term but wider scope — defer to a future refactor.

**Decision: Option 1 for this milestone.** Minimizes diff surface. The inline script and `menu.js` operate on different DOM elements with no overlap.

---

## Build Order (Phase Dependencies)

The natural implementation order respects file-level dependencies:

1. **Preferences select** (`preferences/index.html.erb`) — No dependencies. Allows switching to the new theme immediately for testing. One-line change.

2. **Drawer HTML in `_menu.html.erb`** — Structural HTML that the CSS and JS target. Must exist before CSS or JS can be verified visually.

3. **Hamburger button in `application.html.erb`** — Placed in layout header. CSS positions and shows/hides it. Must exist before theme CSS is meaningful.

4. **`themes/modern.css.scss`** — References the HTML structure from steps 2 and 3. Full theme: header, drawer, overlay, body typography, tables, buttons, forms.

5. **`menu.js`** — References `.modern-drawer`, `.modern-drawer-overlay`, `.modern-hamburger` classes established in steps 2 and 3. CSS transitions from step 4 animate the toggle.

Steps 2 and 3 are independent of each other and can be done in either order.

---

## Anti-Patterns

### Anti-Pattern 1: Putting Drawer CSS in `common.css.scss`

**What people do:** Add drawer and hamburger styles to `common.css.scss` because it is already the "shared" stylesheet.

**Why it's wrong:** `common.css.scss` contains theme-neutral base styles. Drawer styles are exclusively modern-theme concern. Mixing them breaks the isolation model established by `simple.css.scss` and makes it impossible to remove the theme cleanly later.

**Do this instead:** All drawer styles go in `themes/modern.css.scss` scoped under `.modern { }`.

### Anti-Pattern 2: Inline `<script>` in the Partial for New JS

**What people do:** Add drawer toggle JS as another `<script>` block inside `_menu.html.erb`, continuing the existing pattern.

**Why it's wrong:** Inline scripts bypass ESLint (`yarn run lint` only covers `app/assets/javascripts/**/*.js`). v1.1 established the linting baseline as a project requirement. Inline scripts also make the partial harder to read.

**Do this instead:** Create `app/assets/javascripts/menu.js`. Use `$(document).ready` with a `body.modern` guard.

### Anti-Pattern 3: Rendering Drawer HTML Conditionally in ERB

**What people do:** Wrap drawer HTML in `<% if current_user.preference.theme == 'modern' %>` inside the partial.

**Why it's wrong:** Bypasses the CSS-class theme system. The entire theme architecture is built around `body.{theme}` scoping — elements that should not appear simply have `display: none` in their default state and are shown by the theme CSS. ERB conditionals create a second, parallel activation mechanism that diverges from the established pattern.

**Do this instead:** Render the drawer HTML unconditionally inside `_menu.html.erb`. Hide it by default with `.modern-hamburger { display: none; }` in `common.css.scss`. The `.modern` scoped rules in `modern.css.scss` show it.

---

## Scaling Considerations

This is a personal-use app (single user or small group). Scaling is not a concern for this milestone. The CSS/JS pattern chosen (theme-scoped SCSS, one small JS file) has no scalability implications.

---

## Sources

- Direct inspection: `app/views/layouts/application.html.erb`, `app/views/common/_menu.html.erb`
- Direct inspection: `app/assets/stylesheets/application.css`, `app/assets/stylesheets/common.css.scss`
- Direct inspection: `app/assets/stylesheets/themes/simple.css.scss`
- Direct inspection: `app/assets/javascripts/application.js`
- Direct inspection: `app/views/preferences/index.html.erb`, `app/helpers/welcome_helper.rb`
- Direct inspection: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONVENTIONS.md`
- Sprockets `require_tree` behavior: established by existing manifest files (confirmed working in project)

---

*Architecture research for: Modern Theme — Hamburger + Side-Drawer Nav (v1.2)*
*Researched: 2026-04-28*
