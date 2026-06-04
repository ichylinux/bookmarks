---
status: complete
---

# Summary: Mobile drag-and-drop trigger duration identified

## Findings
The mobile drag-and-drop trigger duration for gadgets is defined in `app/assets/javascripts/portal_gadget_sort.js`.

The specific value is:
- `LONG_PRESS_MS = 2000` (2000 milliseconds, or 2 seconds).

This delay is applied when the viewport width is 767px or less.

## Next steps
- Inform the user of the finding.
