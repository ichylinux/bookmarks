# v1.8 Mobile UX Enhancement — Integrated Summary

**Project:** Bookmarks  
**Scope:** Welcome/Portal mobile column UX  
**Researched:** 2026-05-05

## Stack additions

- **Adoption policy:** No new framework. Keep `Rails + Sprockets + jQuery`, and implement required behavior with first-party JavaScript.
- **Input handling:** Prefer `Pointer Events`, with `touch*` as fallback only when needed. Use jQuery for DOM selection/binding support only.
- **State persistence:** Use `localStorage` via `getItem/setItem`; if storage fails, continue with non-persistent fallback behavior.
- **Key design:** Namespace keys (for example `bookmarks:v1.8:mobile:activeColumn`) and include a version segment for forward compatibility.
- **Non-goals:** React/Vue/Stimulus migration, gesture-library addition, and build-system migration (Webpack/Vite/esbuild) are out of scope.

## Feature table stakes

- **Must-have 1: Swipe column switching (left/right)**
  - Update the same active index used by tabs so state management remains unified.
  - Reduce false positives with threshold + direction checks (`abs(dx) > abs(dy)`).
- **Must-have 2: Persist/restore last viewed column**
  - On revisit, restore saved column; if missing/invalid, safely fall back to column 1.
- **Must-have 3: Consistent behavior between tap and swipe**
  - Keep `portal--column-active-N` and tab active state fully synchronized from either interaction path.
- **Recommended defer for v1.8**
  - ENH-03 (full mobile drag-and-drop reorder implementation)
  - Full user-editable label UI for ENH-01 (DB/settings-UI expansion)

## Integration plan

1. **Internal JS consolidation (low-risk start)**
   - Add `setActiveColumn` in `app/assets/javascripts/portal_mobile_tabs.js` and route existing click updates through it.
2. **Add persistence/restore**
   - Implement `saveActiveColumn` / `loadActiveColumn` with bounds validation during initial restore.
3. **Add swipe handling**
   - Implement left/right detection in `bindSwipe`, and always route state updates through `setActiveColumn`.
4. **Minimal CSS tuning (only when needed)**
   - Add only helper rules such as `touch-action` under mobile scope in `app/assets/stylesheets/welcome.css.scss`.
   - Keep `modern.css.scss` / `classic.css.scss` changes minimal and visual-only if required.
5. **Expand tests**
   - Add E2E checks for left/right swipe transition, no-switch on vertical scroll intent, and revisit restore.
   - Acceptance gate remains green on `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test` (with rerun policy when needed).

## Watch out for

- **Frequent false swipe triggers**
  - Cause: weak thresholds and no direction lock.
  - Mitigation: minimum-distance gate + direction-priority check + one-switch-per-gesture rule.
- **Scroll interaction conflicts**
  - Cause: overuse of `preventDefault()` and poor `touch-action` design.
  - Mitigation: scope gesture handling to target areas and preserve native vertical scrolling.
- **Accessibility regression (swipe-only behavior)**
  - Cause: tab interaction path becomes secondary or broken.
  - Mitigation: keep tab path fully active and operable for keyboard/assistive technology users.
- **`localStorage` inconsistency**
  - Cause: out-of-range values, non-numeric values, or unavailable storage.
  - Mitigation: strict validation + exception handling + fallback to default column.
- **Theme-specific drift**
  - Cause: DOM contract differences across modern/classic/simple.
  - Mitigation: preserve common selector contract and require regression checks on all three themes.
