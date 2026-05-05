# Architecture Patterns — v1.8 Mobile UX Enhancement

**Domain:** Welcome portal mobile interaction (swipe + state restore)  
**Researched:** 2026-05-05

## Recommended Architecture

Keep the existing pattern as the core (render tabs/columns via SSR and switch `.portal--column-active-N` in JS), and add only two focused enhancements in v1.8.

1. **Input extension:** connect swipe handling to the same state-update function already used by click handlers
2. **State persistence:** store active column index in `localStorage` and restore on initial mobile render

Key principle: do not introduce new display-state classes. Continue using `portal--column-active-N` and `.portal-column-tab--active` only, so existing CSS and test assets remain reusable.

## Integration Points (DOM / CSS / JS)

### DOM

The existing partial structure is already sufficient for v1.8 and should require no or minimal extension.

| Existing Node | Current Role | v1.8 Integration |
|---|---|---|
| `.portal-column-tabs` | Tab-group container | Reuse as swipe boundary and event-delegation anchor |
| `.portal-column-tab[data-portal-column-index]` | Click-based column selection | Reuse as source of truth for active index |
| `.portal.portal--column-active-N` | CSS trigger for visible column | Keep same class update path for swipe/restore |
| `#column_N.gadgets.portal-column` | Real column content | Keep existing CSS show/hide logic unchanged |

### CSS

`welcome.css.scss` already implements "show one column by active class" for mobile, so no large CSS rewrite is needed for v1.8.

- Preserve existing display-switch behavior under `@media (max-width: $portal-mobile-breakpoint - 1px)`
- Add only minimal helper styles (for example `touch-action`) when needed for swipe UX
- Keep theme files (`modern.css.scss` / `classic.css.scss` / simple adjustments) focused on visuals while centralizing behavior in `welcome.css.scss` + JS

### JavaScript

`app/assets/javascripts/portal_mobile_tabs.js` を唯一の挙動オーナーとして拡張する。

- Reuse existing `syncPortalClasses($portal, index)` and unify click/swipe/restore behavior paths
- 追加候補関数:
  - `setActiveColumn($tabs, $portal, index)`（タブactive + class更新 + save）
  - `saveActiveColumn(index)` / `loadActiveColumn()`
  - `bindSwipe($tabs, $portal)`（`touchstart` / `touchend` の差分で左右判定）
- キー名は衝突回避のため名前空間化（例: `bookmarks.portal.activeColumn`）

## Concrete Change Targets

| Type | File | Planned Change |
|---|---|---|
| view partial | `app/views/welcome/_portal_column_section.html.erb` | Add only minimal data attributes if required; keep existing `data-portal-column-index` contract |
| js | `app/assets/javascripts/portal_mobile_tabs.js` | Implement unified state-update logic for click/swipe/restore |
| css | `app/assets/stylesheets/welcome.css.scss` | Add swipe helper styles only if needed under mobile media scope |
| css (theme) | `app/assets/stylesheets/themes/modern.css.scss` | No default changes; apply minimal visibility polish only when necessary |
| css (theme) | `app/assets/stylesheets/themes/classic.css.scss` | Same as above |
| test (controller) | `test/controllers/welcome_controller/layout_structure_test.rb` | Preserve existing DOM contract guarantees (tabs/active classes), with small adjustments only if needed |
| test (e2e steps) | `features/step_definitions/modern_theme.rb` | Add swipe steps and verify both `portal--column-active-N` and active tab sync |
| test (e2e feature) | `features/*.feature` (mobile portal scenarios) | Add revisit-restore and left/right swipe transition scenarios |

## Data Flow

`User gesture (click/swipe) -> setActiveColumn -> update portal--column-active-N + tab active -> save localStorage`

`Page load (mobile) -> load localStorage -> setActiveColumn -> show last viewed column`

## Low-Risk Implementation Order

1. **Refactor only (internal JS cleanup)**  
   Extract current click behavior into `setActiveColumn` and confirm no behavior change first.
2. **Add localStorage restore/save**  
   Save on click transitions and restore on initial load with strict range validation.
3. **Add swipe support**  
   Detect left/right via `touchstart/touchend` deltas and call the same `setActiveColumn`.
4. **Minimal CSS adjustments (only when needed)**  
   Add tiny mobile-only helper rules for usability.
5. **Expand tests**  
   Add swipe + restore E2E coverage while preserving existing controller tests as regression guardrails.

## Risk Controls

- If `localStorage` is unavailable (for example private-mode restrictions), fail safely and fall back to default `0`.
- Coerce saved values to numbers and clamp into `0..(tab_count - 1)`.
- Since tabs remain hidden on desktop, keep restore behavior active only under mobile conditions.
- Preserve the existing `portal--column-active-N` contract to avoid breaking CSS/test compatibility.
