---
phase: 12-tab-ui
plan: 01
subsystem: ui
tags: [rails, erb, jquery, scss, simple-theme]

requires:
  - phase: "11-notes-controller"
    provides: "redirect root_path(tab: 'notes'); note create path shipped"
provides:
  - "simple-theme-only tab strip (ホーム/ノート) and dual panels on welcome#index"
  - "SSR allowlist initial visibility from params[:tab] == notes (boolean only)"
  - "notes_tabs.js guarded on body.simple; URLSearchParams; no History API mutations"
  - "tab styles scoped under .simple in welcome.css.scss only"
affects:
  - "13-note-gadget"

tech-stack:
  added: []
  patterns:
    - "ERB gate favorite_theme == simple mirrors layout menu injection"
    - "Tab switching via simple-tab-panel--hidden toggles without URL updates on click"

key-files:
  created:
    - app/assets/javascripts/notes_tabs.js
  modified:
    - app/views/welcome/index.html.erb
    - app/assets/stylesheets/welcome.css.scss

key-decisions:
  - "Used class toggling for panels (not show/hide) to stay aligned with SSR hidden state and CSS display:none."

patterns-established:
  - "welcome/index: duplicate portal subtree in simple vs non-simple branches to keep sortable selectors valid inside home panel only."

requirements-completed: [TAB-01, TAB-02, TAB-03]

duration: 10 min
completed: 2026-04-30
---

# Phase 12 Plan 01: Welcome tab chrome (simple theme) Summary

**Simple-theme welcome page now renders ホーム/ノート tabs, wraps the portal in `#simple-home-panel`, adds a `#notes-tab-panel` placeholder shell, scopes tab CSS under `.simple` in `welcome.css.scss`, and loads `notes_tabs.js` (body.simple + `URLSearchParams`, no `pushState`/`replaceState`) for client-side panel switching.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-30T08:57:00Z
- **Completed:** 2026-04-30T09:07:18Z
- **Tasks:** 3
- **Files modified:** 3 (2 modified, 1 created)

## Accomplishments

- Tab strip and two panels on `welcome/index` when `favorite_theme == 'simple'`, with `params[:tab].to_s == 'notes'` driving SSR classes only (no raw param echo).
- Styles for tabstrip, tabs, hidden panels, and notes placeholder typography live exclusively under `.simple` in `welcome.css.scss`; `common.css.scss` untouched.
- `notes_tabs.js` initializes from the query string and switches panels on button clicks without changing the URL.

## Task Commits

Each task was committed atomically:

1. **Task 1: welcome/index に simple 専用タブマークアップと二パネル構造** — `bb38978` (feat)
2. **Task 2: welcome.css.scss に .simple スコープのタブスタイル** — `88fd770` (feat)
3. **Task 3: notes_tabs.js — simple ガード・URLSearchParams・show/hide** — `fe1f1d3` (feat)

## Files Created/Modified

- `app/views/welcome/index.html.erb` — Simple branch with `nav.simple-tabstrip`, home/notes panels, portal preserved inside `#simple-home-panel`; non-simple unchanged portal-only path.
- `app/assets/stylesheets/welcome.css.scss` — `.simple` block: tabstrip margins, tab button reset/active/focus, `simple-tab-panel--hidden`, placeholder heading/body under `#notes-tab-panel`.
- `app/assets/javascripts/notes_tabs.js` — Theme guard, `URLSearchParams` bootstrap, click handlers syncing panels and `.simple-tab--active`.

## Decisions Made

- Panel visibility uses `simple-tab-panel--hidden` toggling in JS to mirror the SSR class strategy from Task 1 and the stylesheet’s `display: none` rule.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## Verification

Commands run (plan automated checks; `rg` was not available on PATH, equivalent `grep` used):

```bash
grep -q 'simple-home-panel' app/views/welcome/index.html.erb
grep -q 'notes-tab-panel' app/views/welcome/index.html.erb
grep -q 'data-simple-tab' app/views/welcome/index.html.erb
! grep -q '<%= params\[:tab\]' app/views/welcome/index.html.erb
grep -q '\.simple[[:space:]]*{' app/assets/stylesheets/welcome.css.scss
grep -q 'simple-tab' app/assets/stylesheets/welcome.css.scss
! grep -q 'simple-tab' app/assets/stylesheets/common.css.scss
test -f app/assets/javascripts/notes_tabs.js
grep -q "hasClass('simple')" app/assets/javascripts/notes_tabs.js
grep -q URLSearchParams app/assets/javascripts/notes_tabs.js
! grep -qE 'pushState|replaceState' app/assets/javascripts/notes_tabs.js
grep -q 'require_tree' app/assets/javascripts/application.js
```

Plan-level regression:

```bash
bin/rails test test/controllers/notes_controller_test.rb
```

Result: 7 runs, 37 assertions, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DOM/CSS/JS hooks for Phase 13 note gadget: stable `#notes-tab-panel`, simple-theme-only markup.
- Plan 02 can add automated theme-isolation/markup tests and manual UAT for no-reload tab clicks.

## Self-Check: PASSED

- All tasks in `12-01-PLAN.md` executed; acceptance criteria exercised via grep equivalents and notes controller tests.
- Per-task commits recorded above; SUMMARY committed as documentation.
- `params[:tab]` appears only in the `== 'notes'` comparison on the Ruby side.

---
*Phase: 12-tab-ui*
*Completed: 2026-04-30*
