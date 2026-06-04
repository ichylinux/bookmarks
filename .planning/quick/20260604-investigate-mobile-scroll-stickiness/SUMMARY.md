---
status: complete
---

# Summary: Mobile scroll stickiness root cause identified

## Findings
The "stuck" scrolling behavior on mobile is caused by the swipe detection logic in `app/assets/javascripts/portal_mobile_tabs.js`.

### Technical Details
- **Trigger:** When a touch moves more than 10px, the code checks if the movement is more horizontal than vertical (`Math.abs(dy) <= Math.abs(dx)`).
- **The Issue:** If the movement is even slightly horizontal, it calls `e.preventDefault()`. This disables the browser's native scrolling for the remainder of that touch session.
- **Result:** If a user starts a scroll with a slight horizontal jitter, the entire scroll is blocked, making the page feel "stuck" or unresponsive.

### Recommendation
Refine the `touchmove` logic to be more lenient, perhaps by:
1. Increasing the initial threshold before deciding to lock the gesture.
2. Requiring a higher horizontal-to-vertical ratio (e.g., `abs(dx) > abs(dy) * 1.5`) before calling `e.preventDefault()`.

## Next steps
- User will handle the fix later. Research is noted in `STATE.md`.
