# Phase 6: HTML Structure - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a hamburger `<button>` to `#header .head-box` (right side, inside the existing head-box div); add `<div class="drawer">` and `<div class="drawer-overlay">` as direct children of `<body>`, outside `.wrapper`, containing all navigation links. All new HTML is rendered unconditionally — Phase 7 CSS controls visibility based on `.modern` body class. The existing `_menu.html.erb` dropdown and its inline `<script>` are untouched.

</domain>

<decisions>
## Implementation Decisions

### Hamburger Button

- **D-01:** Hamburger button sits on the **right side** of the header bar — the last child inside `.head-box`. Phase 7 applies `display: flex; justify-content: space-between` to `.modern .head-box` to push it to the far right.
- **D-02:** Button is a direct child of `.head-box` (not a sibling in `#header`). Markup: `<button class="hamburger-btn" aria-label="メニュー"></button>`. The `aria-label` is Japanese ("メニュー") matching the app locale.
- **D-03:** Button body is **empty** — Phase 7 CSS renders the three horizontal lines using `::before`, `::after`, and `box-shadow`. No inline content, no `<span>` children. This keeps Phase 6 HTML structure clean and gives Phase 7 full control over the animation to an X icon.

### Drawer and Overlay Markup

- **D-04:** Drawer + overlay HTML lives directly in `application.html.erb` (not a new partial). Both elements are inside the `if user_signed_in?` guard. Placement: after `</div>` closing `.wrapper`, before `</body>` — making them direct children of `<body>`.
- **D-05:** Element names: drawer = `<div class="drawer">`, overlay = `<div class="drawer-overlay">`. These class names are the stable surface that Phase 7 CSS and Phase 8 JS reference.

### Nav Links in Drawer

- **D-06:** Nav links are **duplicated inline** inside the drawer markup — not extracted to a shared partial. The drawer has a different structural role than the dropdown, and keeping them independent avoids coupling two different UI patterns. All 7 links from `_menu.html.erb` are reproduced: Home, 設定, ブックマーク, タスク, カレンダー, フィード, ログアウト (in the same order).

### Claude's Discretion

- Exact drawer inner markup (nav element vs. plain div list, link classes) — follow the link structure in `_menu.html.erb` as reference; use `link_to` helpers matching existing nav links.
- The `destroy_user_session_path` logout link requires `method: :delete` — must be preserved in the drawer links as in the existing dropdown.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Layout and Header
- `app/views/layouts/application.html.erb` — current layout structure; `#header .head-box`, `.wrapper`, `<body class="<%= favorite_theme %>">`. Hamburger goes inside `.head-box`; drawer/overlay go after `.wrapper`.

### Menu Partial (reference only — do not modify)
- `app/views/common/_menu.html.erb` — existing dropdown nav with inline `<script>`. Source of truth for which nav links to reproduce in the drawer. Must remain untouched.

### Theme Infrastructure (from Phase 5)
- `app/assets/stylesheets/themes/modern.css.scss` — Phase 7 will add drawer/hamburger CSS here. Phase 6 only adds HTML.
- `app/assets/javascripts/menu.js` — Phase 8 wires drawer JS here. Phase 6 only adds HTML.
- `app/helpers/welcome_helper.rb` — `favorite_theme` helper; confirms how `.modern` body class is applied.

### Requirements
- `.planning/ROADMAP.md` §Phase 6 — success criteria (4 items) are the acceptance checklist.
- `.planning/phases/05-theme-foundation/05-CONTEXT.md` — Phase 5 decisions (CSS token names, `body.modern` guard pattern).

### State Context
- `.planning/STATE.md` §Accumulated Context §Critical Pitfalls — "Drawer `<div>` must be a direct child of `<body>`, outside `.wrapper`, to avoid clipping" and other cross-phase constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/common/_menu.html.erb`: Source of nav links to mirror in the drawer. Contains: Home, 設定, ブックマーク, タスク, カレンダー, フィード, ログアウト (7 links). Use `link_to` helpers matching exact path helpers used there.

### Established Patterns
- `application.html.erb` `if user_signed_in?` pattern: The `render 'common/menu'` call is already guarded by `if user_signed_in?` — drawer/overlay must use the same guard.
- `require_tree .` in both manifests: no new asset registrations needed.
- `destroy_user_session_path` requires `method: :delete` in `link_to` — match the existing dropdown's logout link exactly.
- CSS custom property tokens from Phase 5 (`--modern-header-bg`, etc.) are available for Phase 7 to style the drawer.

### Integration Points
- `app/views/layouts/application.html.erb` line 17 (`<div id="header">`) — hamburger button goes inside `.head-box` here.
- `app/views/layouts/application.html.erb` after line 28 (`</div>` closing `.wrapper`) — drawer and overlay divs go here, before `</body>`.

</code_context>

<specifics>
## Specific Ideas

- Hamburger button markup exactly: `<button class="hamburger-btn" aria-label="メニュー"></button>` — empty body, CSS-drawn lines in Phase 7.
- Drawer structure: `<div class="drawer">` containing a nav block with `link_to` calls mirroring `_menu.html.erb`.
- Overlay: `<div class="drawer-overlay"></div>` — empty, Phase 7 CSS gives it the backdrop appearance; Phase 8 JS wires the click-to-close.
- Both drawer and overlay are siblings after `.wrapper` but before `</body>`, inside `if user_signed_in?`.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 6-HTML Structure*
*Context gathered: 2026-04-29*
