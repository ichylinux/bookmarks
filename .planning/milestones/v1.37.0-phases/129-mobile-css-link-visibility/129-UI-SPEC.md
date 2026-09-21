---
phase: 129
slug: mobile-css-link-visibility
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-26
---

# Phase 129 — UI Design Contract

> Visual and interaction contract for mobile CSS changes. CSS-only phase — no new components, no new HTML structure beyond a wrapper div.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — plain SCSS, existing Rails asset pipeline |
| Preset | not applicable |
| Component library | none |
| Icon library | none |
| Font | inherit from existing app (system font stack) |

---

## Spacing Scale

Existing project spacing is not token-based. The phase uses concrete px values matching established conventions:

| Usage | Value | Basis |
|-------|-------|-------|
| Mobile breakpoint | ≤767px | Existing `.todo` mobile block convention |
| Touch target | auto (full-width flex items) | MOB-02 wrap layout |
| Form padding | existing (no change) | No new padding introduced |

Exceptions: No new spacing tokens introduced — existing values preserved.

---

## Typography

No typography changes in this phase. `font-size: 1rem` on mobile form inputs is a functional fix (iOS zoom prevention), not a visual change.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Form inputs (mobile) | 1rem | inherit | inherit |
| All other elements | unchanged | unchanged | unchanged |

---

## Color

No color changes in this phase. All colors are inherited from existing styles.

| Role | Value | Usage |
|------|-------|-------|
| Dominant | inherited | No change |
| Secondary | inherited | No change |
| Accent | inherited | No change |

---

## Mobile Layout Contract

### MOB-01: Touch-Device Link Visibility

The `.todo-gadget-new-link` element on touch-only devices (`@media (hover: none)`):

| Property | Value | Context |
|----------|-------|---------|
| `opacity` | `1` | Always visible on touch devices |
| `pointer-events` | `auto` | Always tappable on touch devices |
| Placement | `margin-left: auto` (existing) | Pushed to right of gadget header |
| Visual style | unchanged (border + padding existing) | No new styling needed |

### MOB-02: Inline Form Wrap at ≤767px

The todo add form (`form.todo table.todo-form`) on mobile:

| TD Cell | Flex Behavior | Width |
|---------|---------------|-------|
| Priority select (`:first-child`) | `flex: 0 0 100%` | Full row |
| Title input (`:nth-child(2)`) | `flex: 1 1 100%` | Full row |
| Submit button (`:last-child`) | `flex: 0 0 100%; text-align: left` | Full row |

Row container: `flex-wrap: wrap` (overrides existing `flex-wrap: nowrap`)

### MOB-03: Standalone Page Wrapper

`new.html.erb` and `edit.html.erb` each gain:
```
<div class="todo">
  <%= render 'form' %>
</div>
```

No visual change to form appearance — wrapper enables `.todo`-scoped CSS to apply.

### MOB-04: iOS Zoom Prevention

`font-size: 1rem` applied to `form.todo td input[type="text"]` and `form.todo td select` inside `@media (max-width: 767px)` block. Prevents iOS Safari auto-zoom when tapping form fields.

---

## Copywriting Contract

No copy changes in this phase. The "追加" link text is preserved as-is (LOC-FUT-01 explicitly deferred).

| Element | Status |
|---------|--------|
| "追加" link label | unchanged — `t('welcome.todo_gadget.new_link')` |
| Form labels | unchanged |
| Submit button text | unchanged |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| No external registries | — | not applicable |

This phase modifies only project-owned SCSS files. No third-party CSS or component libraries introduced.

---

## Desktop Regression Guard

All new CSS rules MUST be strictly inside `@media (max-width: 767px)` or `@media (hover: none)` blocks. Desktop layout (>767px, pointer: fine) must be pixel-identical before and after this phase.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS — no copy changes; existing locale keys preserved
- [x] Dimension 2 Visuals: PASS — mobile-only changes; desktop unchanged; touch link made visible
- [x] Dimension 3 Color: PASS — no color changes
- [x] Dimension 4 Typography: PASS — font-size: 1rem is functional iOS fix, not a design change
- [x] Dimension 5 Spacing: PASS — flex-wrap layout uses full-width stacking, consistent with mobile conventions
- [x] Dimension 6 Registry Safety: PASS — no external registries; project-owned SCSS only

**Approval:** approved 2026-06-26
