# Phase 30: Persisted Mobile Column State - Context

## Scope

Persist and restore the active mobile portal column across revisits with safe fallback behavior.

## Decisions

- Use `localStorage` key `portalMobileActiveColumn` for state persistence.
- Persist only for mobile viewport (`max-width: 767px`) to avoid desktop-side effects.
- Invalid/missing restored value falls back to column index `0`.
- Reuse `activateColumn()` so restored state follows the same UI sync path as tab and swipe interactions.

## Files

- `app/assets/javascripts/portal_mobile_tabs.js`
- `features/03.モダンテーマ.feature`
- `features/step_definitions/modern_theme.rb`
- `test/assets/portal_mobile_tabs_js_contract_test.rb`
