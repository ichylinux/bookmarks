---
status: complete
completed: 2026-05-01
commit: 8dd9aca
---

# Quick Task 260501-qlk: Fix Gadget Title Link Visited Color

## Summary

Modern theme gadget title bars now force links to stay white across normal, visited, hover, active, and focus-visible states. This fixes feed gadget titles such as `Hacker News` turning visited-link purple on the blue title bar.

## Changed

- Updated `app/assets/stylesheets/themes/modern.css.scss`.
- Added a focused contract assertion in `test/assets/modern_full_page_theme_contract_test.rb`.

## Verification

- Passed: `bin/rails test test/assets/modern_full_page_theme_contract_test.rb`
- Not run successfully: `yarn run lint` could not start because nodenv reports Node `22.22.2` is not installed.
