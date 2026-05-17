# Phase 74: CSS + View Layer - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning
**Mode:** Auto-generated (smart discuss — decisions clear from prior context and codebase)

<domain>
## Phase Boundary

When `show_icons` is false, the application layout emits `body.no-icons`. CSS rules hide `.gadget-title-icon` elements (gadget titles on welcome page and detail pages) and `.drawer-nav-icon` elements (modern-theme drawer). Landing page icons are unaffected.

No partial changes. No JS. Pure CSS + layout helper.

</domain>

<decisions>
## Implementation Decisions

### Body Class Pattern
- Follow exact `body.modern` / `font-size-medium` pattern: add a new helper method `no_icons_class` to `WelcomeHelper` that returns `'no-icons'` when user is signed in and `preference.show_icons == false`, else `''`
- Update layout `<body class="<%= [favorite_theme, font_size_class].join(' ') %>">` to `<%= [favorite_theme, font_size_class, no_icons_class].join(' ').strip %>`
- Guard: `user_signed_in? && current_user.preference&.show_icons == false` (not just `!show_icons` — guards nil/missing preference)

### CSS Location
- Add CSS rules to `app/assets/stylesheets/common.css.scss` — it already contains drawer rules (`.drawer`, `.drawer-overlay`) and is the natural home for cross-page structural rules
- Rules: `body.no-icons .gadget-title-icon { display: none !important; }` and `body.no-icons .drawer-nav-icon { display: none !important; }` — `!important` ensures specificity over any nested selectors

### Landing Page Safety
- `no_icons_class` returns `''` when `user_signed_in?` is false — landing page is an unauthenticated surface, so `body.no-icons` is never emitted there regardless of any other state

### Claude's Discretion
- Exact placement of the CSS block within common.css.scss (end of file is fine)
- Whether to use `display: none` or `visibility: hidden` — use `display: none` (consistent with how drawer is hidden on non-modern themes)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WelcomeHelper#favorite_theme` and `#font_size_class` — exact pattern to follow for `no_icons_class`
- `app/views/layouts/application.html.erb:16` — body tag with class array join
- `app/views/common/_drawer_nav_link.html.erb` — `.drawer-nav-icon` span
- `app/views/common/_gadget_title_with_icon.html.erb` — `.gadget-title-icon` span

### Established Patterns
- Body class: string join of helper method results, helper returns '' for default state
- CSS: `common.css.scss` for cross-page structural rules; theme-specific in `themes/`
- The drawer is already hidden via `display: none` when not modern theme

### Integration Points
- `app/helpers/welcome_helper.rb` — add `no_icons_class` method here
- `app/views/layouts/application.html.erb` — update body tag class
- `app/assets/stylesheets/common.css.scss` — add two CSS rules

</code_context>

<specifics>
## Specific Ideas

- STATE.md decision: "Icon suppression via `body.no-icons` CSS class on `<body>` — same pattern as `body.modern`"
- Target selectors confirmed from codebase: `.gadget-title-icon` (in `_gadget_title_with_icon.html.erb`) and `.drawer-nav-icon` (in `_drawer_nav_link.html.erb`)

</specifics>

<deferred>
## Deferred Ideas

None — scope is well-defined.

</deferred>
