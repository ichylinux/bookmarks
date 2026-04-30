---
created: 2026-04-30T00:00:00Z
title: Extract drawer_ui? helper if condition grows to 4th case
area: ui
files:
  - app/views/layouts/application.html.erb:21
  - app/views/layouts/application.html.erb:29
---

## Problem

The condition `user_signed_in? && favorite_theme != 'simple'` (and its inverse) is duplicated in `app/views/layouts/application.html.erb`:

- Line 21: `<% if user_signed_in? && favorite_theme != 'simple' %>` (head-user-email + hamburger)
- Line 29: `<%= render 'common/menu' if user_signed_in? && favorite_theme == 'simple' %>` (inverse)
- Line 32: `<% if user_signed_in? %>` (drawer + drawer-overlay) — related, see sibling todo

Reviewer flagged the duplication but said extracting a helper for two lines isn't worth it yet. **Trigger: extract a `drawer_ui?` (or similarly named) helper when a 4th call site appears.**

## Solution

When the condition appears a 4th time, add to `ApplicationHelper`:

```ruby
def drawer_ui?
  user_signed_in? && favorite_theme != 'simple'
end
```

Replace the inline conditions in `application.html.erb` and any new sites. Keep the inverse (`!drawer_ui?` or equivalent) for the simple-theme menu render.
