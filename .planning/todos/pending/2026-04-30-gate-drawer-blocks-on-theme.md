---
created: 2026-04-30T00:00:00Z
title: Gate drawer + drawer-overlay on theme for symmetry
area: ui
files:
  - app/views/layouts/application.html.erb:32-45
---

## Problem

In `app/views/layouts/application.html.erb`, the `.drawer` and `.drawer-overlay` blocks (lines 32–45) are gated only on `user_signed_in?`, while the hamburger button that opens them (line 21) is gated on `user_signed_in? && favorite_theme != 'simple'`.

Currently fine in practice — CSS hides the drawer for the simple theme — but asymmetric with the rest of the file. Marked out of scope for the diff that introduced the line-21 gate.

## Solution

Update the line-32 guard to match line 21:

```erb
<% if user_signed_in? && favorite_theme != 'simple' %>
  <div class="drawer">...</div>
  <div class="drawer-overlay"></div>
<% end %>
```

If the sibling todo (extract `drawer_ui?` helper) lands first, use the helper here too. Verify simple-theme pages don't render the drawer DOM at all after the change (currently they do, just hidden).
