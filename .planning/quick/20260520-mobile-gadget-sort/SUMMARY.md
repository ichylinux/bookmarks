---
status: complete
date: 2026-05-20
---

# Summary: Mobile Gadget Sort

## Done
- Added `jquery.ui.touch-punch` (touchstart mousemove omitted so sortable `delay` works as long-press).
- Added `portal_gadget_sort.js`: 450ms delay + 12px distance on mobile; `portal--gadget-sorting` expands columns for cross-column drag.
- Wired `_dashboard.html.erb` to `portalGadgetSort.init`.
- Disabled portal column swipe while sorting (`portal_mobile_tabs.js`).
- Mobile SCSS for sort mode and drag helper shadow.
- Contract tests in `portal_gadget_sort_js_contract_test.rb`.

## Verification
- `yarn run lint` — green
- `bin/rails test` — 489 runs, 0 failures

## Usage (mobile)
1. Long-press a gadget title bar (~0.45s).
2. Drag to reorder within a column or scroll horizontally to another column.
3. Release — layout saves via existing `save_state` endpoint.
