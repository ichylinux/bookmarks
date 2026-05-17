---
plan: "073-002"
phase: 73
status: complete
date: "2026-05-17"
---

# Summary: 073-002 — Preference model — constant, validation, default_preference

## What was built

Updated `app/models/preference.rb` with three additions:

1. `SHOW_ICONS_DEFAULT = true` constant (after `PORTAL_COLUMN_COUNTS`)
2. `validates :show_icons, inclusion: { in: [true, false] }` — rejects nil
3. `ret.show_icons = SHOW_ICONS_DEFAULT` in `default_preference` (explicit default for new users)

## Tasks completed

- [x] Added `SHOW_ICONS_DEFAULT = true` constant
- [x] Added `validates :show_icons, inclusion: { in: [true, false] }`
- [x] Added `ret.show_icons = SHOW_ICONS_DEFAULT` in `default_preference`

## Verification

```
$ bin/rails runner "p = Preference.new; puts p.show_icons.inspect"
true   # DB column default picked up by Rails

$ bin/rails runner "p = Preference.new(show_icons: nil); p.valid?; puts p.errors[:show_icons].inspect"
["は一覧にありません"]   # nil rejected

$ bin/rails runner "puts Preference::SHOW_ICONS_DEFAULT.inspect"
true

$ bin/rails test test/models/preference_test.rb
7 runs, 39 assertions, 0 failures, 0 errors, 0 skips
```

## Files changed

- `app/models/preference.rb` (3 lines added)
