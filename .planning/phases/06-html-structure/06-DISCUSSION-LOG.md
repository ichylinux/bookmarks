# Phase 6: HTML Structure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 6-HTML Structure
**Areas discussed:** Hamburger position

---

## Area Selection

| Area | Selected for discussion |
|------|------------------------|
| Hamburger position | ✓ |
| Drawer markup home | — (Claude's discretion) |
| Nav links in drawer | — (Claude's discretion) |

---

## Hamburger Position

### Q1: Where should the hamburger button sit relative to the app name/icon?

| Option | Description | Selected |
|--------|-------------|----------|
| Right side | Button floats to the right end of the header bar. Classic mobile hamburger position — Phase 7 CSS uses flexbox justify-content: space-between on .head-box. | ✓ |
| Left side | Button comes before the icon/title. Less common for a right-sliding drawer. | |
| You decide | Claude picks whatever works best with the existing header markup. | |

**User's choice:** Right side
**Notes:** None

---

### Q2: Where in the DOM does the hamburger button live?

| Option | Description | Selected |
|--------|-------------|----------|
| Inside .head-box | Button is a child of the existing .head-box div. Phase 7 applies flexbox to .head-box to push it right. Keeps the header a single block. | ✓ |
| Sibling in #header | Button sits next to .head-box inside #header. More independent, but adds a second child to #header. | |

**User's choice:** Inside .head-box
**Notes:** None

---

### Q3: What goes inside the hamburger `<button>` element?

| Option | Description | Selected |
|--------|-------------|----------|
| Three-line CSS | Empty button, Phase 7 CSS draws the three lines using ::before/::after/box-shadow. No icon dependency, animates to X cleanly. | ✓ |
| Unicode ≡ text | Plain text character in the button. Simple, no CSS tricks, but won't animate to X in Phase 7. | |
| Three `<span>` lines | Three explicit `<span>` children. Phase 7 can animate each span independently for the X transition. | |

**User's choice:** Three-line CSS
**Notes:** None

---

## Claude's Discretion

- **Drawer markup location**: Placed directly in `application.html.erb` after `.wrapper`, inside `if user_signed_in?`. Simple, no extra partial file.
- **Nav links approach**: Duplicated inline inside the drawer. The drawer and dropdown serve different structural purposes; keeping them independent avoids coupling.
- **Element naming**: `class="drawer"`, `class="drawer-overlay"`, `class="hamburger-btn"` — stable names for Phase 7 CSS and Phase 8 JS to target.

## Deferred Ideas

None — discussion stayed within phase scope.
