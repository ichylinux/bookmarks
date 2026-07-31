---
status: complete
---

# Quick Task 260731-u3v Summary

## Problem

Feed gadget header shows "設定" on desktop hover, but on mobile the tap-to-reveal pattern failed because:
1. The header title is a navigable link — first tap navigated away instead of revealing settings
2. touch-punch on the drag handle suppressed click when tapping the icon (document-level `stopPropagation` ran too late)

## Fix

- `feed_gadget.js`: bind `stopImmediatePropagation` on `.gadgets` for the feed header (same layer as `portal_gadget_sort.js` link guard)
- Mobile header click: `preventDefault` on first tap to reveal settings; when settings are already visible, site-name link tap navigates normally

## Verification

- `yarn run lint` ✓
- `bin/rails test test/assets/feed_gadget_mobile_css_contract_test.rb` ✓ (6 tests)
- `bundle exec rake dad:test FEATURE=features/15.フィードガジェット.feature` ✓ (2 scenarios including new mobile scenario)

## Commits

Code commit includes feed_gadget.js, contract test, Cucumber feature/steps.
