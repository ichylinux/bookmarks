---
plan: "075-001"
phase: 75
status: complete
date: "2026-05-17"
---

# Summary: 075-001 — Preferences UI + Locale + Tests

## What was built

Added the `show_icons` toggle control to `/preferences`: a checkbox (`f.check_box :show_icons`) with Japanese label 「アイコンを表示する」 and English equivalent "Show Icons". Added ja/en locale strings for the preference label and a passing i18n parity test. Minitest covers `Preference` model default (`show_icons` true), nil validation (rejected), and `PreferencesController` save round-trips (on→off, off→on). Tri-suite gate passed.

## Tasks completed

- [x] Added `show_icons` checkbox to `app/views/preferences/edit.html.erb`
- [x] Added `ja.yml` key `preferences.show_icons` → 「アイコンを表示する」
- [x] Added `en.yml` key `preferences.show_icons` → "Show Icons"
- [x] Permitted `:show_icons` in `PreferencesController` strong params
- [x] Added model tests: default true, nil rejected with validation error
- [x] Added controller tests: save false persists, save true persists
- [x] Added i18n parity test (show_icons key present in both locales)
- [x] Tri-suite gate: `yarn run lint` ✓ · `bin/rails test` 389 runs, 0 failures ✓ · `bundle exec rake dad:test` 25 scenarios, 0 failures ✓

## Verification

See `075-VERIFICATION.md` — 6/6 must-haves passed.

```
yarn run lint: green
bin/rails test: 389 runs, 1869 assertions, 0 failures, 0 errors, 0 skips
bundle exec rake dad:test: 25 scenarios (25 passed), 102 steps (102 passed)
```

## Files changed

- `app/views/preferences/edit.html.erb` (show_icons checkbox added)
- `app/controllers/preferences_controller.rb` (show_icons permitted)
- `config/locales/ja.yml` (preferences.show_icons key)
- `config/locales/en.yml` (preferences.show_icons key)
- `test/models/preference_test.rb` (default + nil validation tests)
- `test/controllers/preferences_controller_test.rb` (save round-trip tests)
- `test/i18n/i18n_parity_test.rb` (show_icons key parity assertion)
