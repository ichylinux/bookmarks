---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Quick Note Gadget
status: planning
last_updated: "2026-04-30T00:00:00Z"
last_activity: 2026-04-30 - Milestone v1.3 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-30 — Milestone v1.3 started

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-30)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.
**Current milestone:** v1.3 — Quick Note Gadget — in planning.
**Shipped:** v1.1, v1.2 (see `.planning/MILESTONES.md`). Roadmap collapsed in `ROADMAP.md` with full detail in the milestone archives.

## Accumulated Context

### Key Decisions (v1.2)

- Strictly additive approach: two new files (`themes/modern.css.scss`, `menu.js`) + targeted edits to three existing files (layout, menu partial, preferences select). No new gems or npm packages.
- Drawer/backdrop HTML rendered unconditionally; CSS hides them when not in `.modern` theme. Existing `_menu.html.erb` inline `<script>` left intact.
- CSS custom properties must use plain CSS values (not `$variable` assignments) due to libsass bug.
- **Phase 7:** libsass cannot compile `min(88vw, 320px)`; drawer width implemented as `width: 88vw; max-width: 320px` with source comment documenting the `min()` contract.
- **Phase 8:** System tests use `headless_chrome`; `test_helper` may strip `/usr/local/bin` from `PATH` when a stale `chromedriver` sits there, and prepends `ActionDispatch::SystemTesting::Browser` so `Chrome::Service.driver_path` is not reused across incompatible resolutions.

### Critical Pitfalls to Track

- CSS specificity: `.modern #header .head-box` required (not `.modern .head-box`) to beat existing ID selectors in `common.css.scss`
- Drawer `<div>` must be a direct child of `<body>`, outside `.wrapper`, to avoid clipping
- `menu.js` must guard all logic with `if (!$('body').hasClass('modern')) return;`
- Both `#header .head-box` (ID) and `.header` (class) header selectors must be overridden in Phase 9
- Existing `$('html').click` handler: new drawer JS must use `e.stopPropagation()` on hamburger click

### From v1.1

- Prior local GSD phase completed work on automatic bookmark title fetch (`bookmarks.js`, `BookmarksController#fetch_title`); treat that behaviour as a regression test target for JS changes.
- See `.planning/codebase/` for stack and conventions snapshots.

### Phase 9 Decisions (added 2026-04-29)

- Top-level `.modern`-prefixed selectors (outside `.modern {}` block) used for STYLE-01/03/04 so literal selector strings appear in source for grep-based CI contracts.
- Four new tokens added as plain hex: `--modern-header-fg (#ffffff)`, `--modern-border (#d1d5db)`, `--modern-surface-alt (#f3f4f6)`, `--modern-danger (#dc2626)`.
- Typography (STYLE-02) placed inside `.modern {}` block as property declarations since `body` carries the class.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260429-q01 | convert rails test:system into cucumber feature | 2026-04-29 | 7646e35 | [260429-q01-convert-system-tests-to-cucumber](./quick/260429-q01-convert-system-tests-to-cucumber/) |
| 260429-q02 | default theme now is 'モダン', theme 'デフォルト' should be renamed to 'クラシック' | 2026-04-29 | 6fd342b | [260429-q02-rename-default-theme-to-classic](./quick/260429-q02-rename-default-theme-to-classic/) |
| 260430-q04 | check README.md for out dated information. | 2026-04-30 | fa1d758 | [260430-q04-check-readme-outdated-info](./quick/260430-q04-check-readme-outdated-info/) |

---
*State updated: 2026-04-30 — Quick task 260430-q04 corrected: README テーマ bullet updated to list all 3 themes*
