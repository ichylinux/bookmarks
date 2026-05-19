---
slug: mobile-gadget-sort
date: 2026-05-20
status: complete
---

# Mobile Gadget Sort (Long-Press Drag)

## Goal
On smartphones, let users reorder gadgets (within and across columns) via long-press then drag — similar to moving apps on a home screen.

## Approach
1. Vendor `jquery.ui.touch-punch` so jQuery UI sortable receives touch events.
2. `portal_gadget_sort.js`: mobile uses 450ms delay + 12px distance; desktop unchanged.
3. While dragging on mobile, add `portal--gadget-sorting` to expand the portal track (all columns visible, horizontal scroll) for cross-column moves.
4. Disable portal column swipe gestures during sort (`portal_mobile_tabs.js`).

## Files
- `vendor/assets/javascripts/jquery.ui.touch-punch.js`
- `app/assets/javascripts/portal_gadget_sort.js`
- `app/views/welcome/_dashboard.html.erb`
- `app/assets/javascripts/portal_mobile_tabs.js`
- `app/assets/stylesheets/welcome.css.scss`
- `test/assets/portal_gadget_sort_js_contract_test.rb`
