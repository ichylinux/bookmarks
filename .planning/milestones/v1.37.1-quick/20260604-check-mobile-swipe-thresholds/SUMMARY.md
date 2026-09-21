---
status: complete
---

# Summary: Mobile swipe column switching thresholds identified

## Findings
The swipe logic for switching columns on mobile is implemented in `app/assets/javascripts/portal_mobile_tabs.js`.

The thresholds are based on distance rather than a specific duration:
- **Minimum distance to trigger a swipe**: 50 pixels (`Math.abs(totalDx) < 50`).
- **Vertical vs Horizontal lock**: If vertical movement is greater than horizontal movement at the start (specifically after the first 10px of movement), the swipe is ignored in favor of page scrolling (`Math.abs(dy) > Math.abs(dx)`).
- **Movement noise floor**: Movement under 10 pixels total (`Math.abs(dx) + Math.abs(dy) < 10`) is ignored.

There is no specific time limit (maximum duration) for the swipe; as long as the user moves 50px horizontally without triggering the vertical scroll lock, the column will switch upon `touchend`.

## Next steps
- Inform the user of the finding.
