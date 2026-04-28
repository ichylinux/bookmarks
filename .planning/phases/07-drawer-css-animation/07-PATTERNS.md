# Phase 7 — Pattern Map

## Analog: theme SCSS scope

**Source:** `.planning/phases/05-theme-foundation/05-01-PLAN.md`  
**File:** `app/assets/stylesheets/themes/modern.css.scss`

**Excerpt (current):**

```scss
.modern {
  --modern-color-primary: #3b82f6;
  --modern-bg:            #ffffff;
  --modern-text:          #1a1a1a;
  --modern-header-bg:     #1e40af;
}
```

**Pattern:** All modern-theme rules extend **inside** the `.modern { ... }` block (or use `body.modern` compound selectors consistent with Sprockets compilation). Phase 7 adds drawer, overlay, and hamburger rules here — **no new stylesheet file**.

---

## Analog: layout DOM (read-only)

**Source:** `app/views/layouts/application.html.erb`  
**Relevant structure:**

- `body` class includes theme (`modern` when selected)
- `.hamburger-btn` last child of `#header .head-box`
- `.drawer` > `nav` > seven `link_to` anchors
- `.drawer-overlay` empty sibling after `.drawer`

**Pattern:** Selectors MUST match `.drawer`, `.drawer-overlay`, `button.hamburger-btn` exactly (Phase 6 locked names).

---

## Analog: high-specificity header

**Source:** `.planning/STATE.md` — `.modern #header .head-box` beats `common.css.scss`.

**Pattern:** When header-area rules conflict, prefer the long compound selector used in Phase 6 flex layout for `.head-box`.

---

## Data flow

```
body class (favorite_theme) 
  → .modern + .drawer-open (Phase 8 toggles second)
  → CSS transitions on .drawer / .drawer-overlay / .hamburger-btn pseudo-elements
```

No JS in Phase 7.
