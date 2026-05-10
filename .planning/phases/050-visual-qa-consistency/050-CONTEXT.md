# Phase 50: Visual QA & Cross-theme Consistency Fixes - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify the preferences page and shared UI components (form controls, action links, flash messages) render correctly across modern, classic, and simple themes. Fix any visual inconsistencies found via code review. The QA method is CSS code review — not a running browser.

Key finding from codebase scout: `.modern .preferences-table th { text-align: right }` in `themes/modern.css.scss` is redundant with the base rule `.preferences-table th { text-align: right }` in `common.css.scss`. Remove the duplicate.

</domain>

<decisions>
## Implementation Decisions

### QA Method & Scope
- QA method: CSS code review — inspect selectors for each theme-specific path, no headless browser needed
- Remove redundant `.modern .preferences-table th { text-align: right }` from `modern.css.scss` (base rule in `common.css.scss` already applies to all themes)
- Classic form controls: intentionally minimal — browser defaults are acceptable; no new styling needed

### Consistency Fixes
- `.actions` links in classic/simple: grey border from `common.css.scss` is acceptable — no fix needed
- Flash messages (`.flash-notice`, `.flash-alert`): theme-neutral green/red is correct; no per-theme override needed
- Minitest: add test coverage asserting preferences form, table, and submit button render for all 3 themes

### Claude's Discretion
- Test placement: extend existing `PreferencesControllerTest` or create a new `preferences_theme_test.rb`
- Test approach: sign in as user with each theme set, GET preferences page, assert key selectors present

</decisions>

<code_context>
## Existing Code Insights

### Preferences Page
- View: `app/views/preferences/index.html.erb` — table-based form with `.preferences-form` and `.preferences-table`
- CSS: `app/assets/stylesheets/preferences.css.scss` — base submit button styles only (clean after Q-09)
- Theme overrides: each `themes/*.css.scss` file handles theme-specific submit button styles

### Redundancy to Remove
- `themes/modern.css.scss` line 141-143: `.modern .preferences-table th { text-align: right }` — redundant with `common.css.scss` `.preferences-table th { text-align: right }`

### Flash Messages
- Defined in `common.css.scss`: `.flash-message`, `.flash-notice`, `.flash-alert`, `.flash-dismiss`
- Consistent across all themes — no per-theme override needed

### Action Links
- `common.css.scss` `.actions a` — grey border, rounded, hover turns grey
- `themes/modern.css.scss` `.modern .actions a` — primary color border, hover fills with primary
- Classic/simple: inherit the neutral grey `common.css.scss` style — acceptable

### Existing Tests
- `test/controllers/preferences_controller_test.rb` — existing coverage for GET/PATCH preferences

</code_context>

<specifics>
## Specific Ideas

- Remove the redundant `.modern .preferences-table th { text-align: right }` from modern.css.scss
- Add Minitest assertions for preferences page rendering under modern, classic, and simple themes
- Keep changes minimal — this is QA + light cleanup, not a redesign

</specifics>

<deferred>
## Deferred Ideas

- Headless browser screenshot comparison — out of scope; code review is sufficient for this phase
- Classic/simple form control theming — intentionally deferred (minimal is appropriate)
- Theme-specific flash message colors — deferred; theme-neutral is correct for informational messages

</deferred>
