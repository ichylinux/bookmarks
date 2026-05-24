---
status: complete
date: "2026-05-25"
commit: pending
---

# Quick Task Summary: Refresh landing page

## Done

- Hero uses gradient panel + brand lockup (icon, name, subtitle) aligned with auth surfaces
- Integrations section lists Google, X, Facebook, and Mastodon (2×2 grid)
- Changelog adds 2026-05-25 refresh plus v1.34 connected accounts and v1.33 Facebook entries
- `root_path_test` covers brand lockup and four integration cards

## Verification

- `yarn run lint` ✓
- `bin/rails test` 596/596 ✓
- `bundle exec rake dad:test` 37/38 (preferences sign-in flake in `preferences_reset.rb`; unrelated to landing)
