---
slug: admin-section-separator
date: "2026-05-21"
---

# Quick Task: Admin section separator in drawer and menu

Separate admin-only items (x_api_usages) from regular user items in both the drawer nav (drawer UI) and the dropdown menu (simple theme), using a divider/separator.

## Changes

### 1. `app/views/layouts/application.html.erb`
- Move `x_api_usages` link out of `drawer-nav-section--primary`
- Add a conditional divider + `drawer-nav-section--admin` block (only visible to admins)

### 2. `app/views/common/_menu.html.erb`
- Move `x_api_usages` link out of `menu-section--primary`
- Add a conditional divider + `menu-section--admin` block (only visible to admins)

### 3. `app/assets/stylesheets/themes/_drawer_shared.scss`
- Add `.drawer-nav-section--admin` style (padding-top: 4px, like secondary)

### 4. `app/assets/stylesheets/common.css.scss`
- Add `.menu-section--admin` style (padding-top: 2px, like secondary)

## No new routes/controllers needed — purely view layer.
