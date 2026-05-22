---
status: fixing
trigger: "Unable to find checkbox ノートを表示する in features/04.ノート.feature modern theme scenario"
created: 2026-05-22
updated: 2026-05-22
---

## Current Focus

hypothesis: Before hook and modern_theme step defs still use AR preference.update! from Cucumber process; dad:test Rails server under REPEATABLE READ does not see those writes, so stale locale/theme from prior browser saves leaves English labels or wrong form state.
test: Remove AR preference writes; reset defaults via /preferences in sign_in using name-based field selectors.
expecting: check ノートを表示する finds checkbox after ja locale is set via browser.
next_action: Implement preferences_reset.rb + wire Login#sign_in; remove hooks pref.update!
reasoning_checkpoint: pending

## Symptoms

- Error: Capybara::ElementNotFound — Unable to find checkbox "ノートを表示する" that is not disabled
- Step: features/step_definitions/notes.rb:17 (モダンテーマでノートを有効にしてサインインします)
- Intermittent under full dad:test (order-dependent); same class as bce47df todos flake

## Evidence

- bce47df fixed step defs only; hooks.rb:12-22 and modern_theme.rb:2-13 still use pref.update!
- dad:test runs separate Rails server; test DB uses default REPEATABLE READ (READ COMMITTED removed in bce47df)
