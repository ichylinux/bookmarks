---
status: resolved
trigger: "Unable to find checkbox ノートを表示する in features/04.ノート.feature modern theme scenario"
created: 2026-05-22
updated: 2026-05-22
root_cause: Before hook and modern_theme step defs used AR preference.update! from Cucumber process; dad:test Rails server under REPEATABLE READ did not see those writes. Secondary flake: @mobile_portal Before hook resized to mobile viewport before Background sign_in, making reset_preferences_via_browser! intermittently fail.
fix: Browser-driven preference reset via preferences_reset.rb in sign_in; removed AR pref.update! from hooks/modern_theme; deferred mobile viewport to ensure_mobile_viewport! after sign-in; name-based field selectors in notes/simple_theme steps.
verification: dad:test 31/31 x2 green; features/03:59+94 pair 15/15 green
files_changed: features/support/preferences_reset.rb, features/support/login.rb, features/support/hooks.rb, features/support/window_resize.rb, features/step_definitions/modern_theme.rb, features/step_definitions/notes.rb, features/step_definitions/simple_theme.rb, features/step_definitions/admin_x_api_usages.rb
---

## Current Focus

hypothesis: Before hook and modern_theme step defs still use AR preference.update! from Cucumber process; dad:test Rails server under REPEATABLE READ does not see those writes, so stale locale/theme from prior browser saves leaves English labels or wrong form state.
test: Remove AR preference writes; reset defaults via /preferences in sign_in using name-based field selectors.
expecting: check ノートを表示する finds checkbox after ja locale is set via browser.
next_action: DONE — verify full dad:test green
reasoning_checkpoint: resolved

## Symptoms

- Error: Capybara::ElementNotFound — Unable to find checkbox "ノートを表示する" that is not disabled
- Step: features/step_definitions/notes.rb:17 (モダンテーマでノートを有効にしてサインインします)
- Intermittent under full dad:test (order-dependent); same class as bce47df todos flake

## Evidence

- bce47df fixed step defs only; hooks.rb:12-22 and modern_theme.rb:2-13 still use pref.update!
- dad:test runs separate Rails server; test DB uses default REPEATABLE READ (READ COMMITTED removed in bce47df)
