---
slug: admin-section-separator
date: "2026-05-21"
status: complete
commit: 15142d0
---

# Summary: Admin section separator in drawer and menu

## What was done

Moved `x_api_usages` link out of the primary nav section in both the modern-theme drawer and the simple-theme dropdown menu. Admin-only items now live in a dedicated `drawer-nav-section--admin` / `menu-section--admin` block, separated from regular user links by `role=separator` dividers.

## Files changed

- `app/views/layouts/application.html.erb` — drawer: admin block with surrounding dividers
- `app/views/common/_menu.html.erb` — simple-theme menu: admin block with surrounding dividers
- `app/assets/stylesheets/themes/_drawer_shared.scss` — added `.drawer-nav-section--admin` style
- `app/assets/stylesheets/common.css.scss` — added `.menu-section--admin` style
- `test/controllers/welcome_controller/layout_structure_test.rb` — updated counts and added admin-section assertions

## Test results

- `yarn run lint` ✓
- `bin/rails test` 517/517 ✓
- `bundle exec rake dad:test` 30/30 ✓
