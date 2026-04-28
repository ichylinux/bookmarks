---
phase: 05-theme-foundation
plan: "01"
subsystem: ui
tags: [scss, css-custom-properties, preferences, theme, sprockets]

# Dependency graph
requires: []
provides:
  - "'モダン' theme option in preferences dropdown (stores 'modern' as preference.theme)"
  - "app/assets/stylesheets/themes/modern.css.scss with 4 CSS custom property color tokens"
affects:
  - "05-02 (drawer/hamburger nav — depends on .modern body class being set)"
  - "Phases 7-9 (CSS token consumers — reference var(--modern-color-primary) etc.)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CSS custom properties scoped under .modern {} using plain hex values (no SCSS variables — libsass bug)"
    - "Theme select dropdown uses Japanese display labels mapped to English body class strings"

key-files:
  created:
    - app/assets/stylesheets/themes/modern.css.scss
  modified:
    - app/views/preferences/index.html.erb

key-decisions:
  - "CSS custom property values use plain hex literals, not $scss-variables, to avoid libsass compilation failure"
  - "Token names use --modern- prefix even inside .modern {} scope for self-documentation and collision-proofing across future themes"
  - "modern.css.scss filename mirrors simple.css.scss convention (.css.scss not .scss)"

patterns-established:
  - "Theme SCSS stub: flat .modern {} block containing only CSS custom property tokens, no nested selectors"
  - "New themes are auto-included by Sprockets require_tree . in application.css — no manifest change needed"

requirements-completed:
  - THEME-01
  - THEME-02

# Metrics
duration: 2min
completed: 2026-04-28
---

# Phase 5 Plan 01: Theme Foundation Summary

**Modern theme registered in preferences UI with 4 CSS custom property color tokens in modern.css.scss, enabling body class activation and Phase 9 token consumption**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-28T13:27:18Z
- **Completed:** 2026-04-28T13:28:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added 'モダン' => 'modern' to the preferences theme select; selecting it stores 'modern' in preference.theme which the favorite_theme helper applies verbatim as the body class
- Created modern.css.scss with `.modern {}` root scope containing 4 CSS design token custom properties (--modern-color-primary, --modern-bg, --modern-text, --modern-header-bg)
- Sprockets auto-includes modern.css.scss via require_tree . — no manifest change needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Add モダン option to theme select in preferences** - `dd9bba8` (feat)
2. **Task 2: Create modern.css.scss with .modern {} scope and CSS custom property tokens** - `ce62ff3` (feat)

**Plan metadata:** _(committed after SUMMARY.md creation)_

## Files Created/Modified
- `app/views/preferences/index.html.erb` - Added 'モダン' => 'modern' to the f.select :theme hash (one-line diff)
- `app/assets/stylesheets/themes/modern.css.scss` - New file: .modern {} root scope with 4 CSS custom property color tokens (6 lines)

## Decisions Made
- CSS custom property values use plain hex literals (`#3b82f6`, etc.) instead of `$scss-variables` to avoid a known libsass compilation failure (documented in STATE.md pitfalls)
- Token names carry the `--modern-` prefix even inside `.modern {}` scope — self-documenting and collision-proof when multiple themes share the same page in future phases
- Filename convention `modern.css.scss` mirrors `simple.css.scss` (not bare `modern.scss`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

One navigational issue during execution: the Edit tool initially targeted `/home/ichy/workspace/bookmarks/app/...` (main app) instead of the worktree path. Caught immediately via `git add` error; corrected by editing the correct path under the worktree. No data loss; main app file was reverted to original state by the worktree's git isolation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Theme Foundation (Plan 01) complete: .modern body class activates automatically when user selects モダン in preferences and saves
- modern.css.scss is compiled by Sprockets and ready for token consumers in Phases 7-9
- Plan 02 (drawer/hamburger nav) can now use .modern {} scope and var(--modern-*) tokens
- No blockers

## Threat Surface Scan

No new threat surface introduced. T-05-01 (theme string stored as body class — no code execution path) and T-05-02 (static CSS file with only hex values) are both accepted per the plan's threat model. No new endpoints, auth paths, file access patterns, or schema changes.

---

## Self-Check: PASSED

- FOUND: app/views/preferences/index.html.erb
- FOUND: app/assets/stylesheets/themes/modern.css.scss
- FOUND commit: dd9bba8
- FOUND commit: ce62ff3

---
*Phase: 05-theme-foundation*
*Completed: 2026-04-28*
