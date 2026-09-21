---
slug: add-use-bookmark-preference
status: complete
date: 2026-05-26
---

## Task
Add a `use_bookmark` preference choice to control bookmark gadget visibility, replacing the current behavior where the gadget only appears when bookmark records exist.

## Changes
- Migration: `add_use_bookmark_to_preferences` — boolean column, `default: true`, `null: false`
- `Preference#default_preference`: set `use_bookmark = true`
- `Portal#get_gadgets`: check `user.preference.use_bookmark?` instead of `gadget.visible?`
- Preferences view: added `use_bookmark` checkbox row (above `use_todo`)
- Preferences controller: permitted `use_bookmark` param
- Locale files (ja/en): added `use_bookmark` attribute label
- `features/support/preferences_reset.rb`: reset ensures `use_bookmark` is checked

## Result
All three test suites green (lint, Minitest 596/0, Cucumber 38 scenarios/0 failed). Committed as `a40d087`.
