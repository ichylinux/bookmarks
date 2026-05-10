# Phase 51: Mobile/Responsive Polish & Verification Gate - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix mobile layout issues on the preferences page and bookmarks list at ≤767px across all 3 themes. Verify the welcome page mobile layout (already implemented in v1.7). Run the final tri-suite gate to declare v1.15 shippable.

**Key finding from codebase scout:**
- `.preferences-table` has no mobile-responsive CSS — at narrow viewports the label/input columns are cramped
- `.bookmarks-table` has 4 columns (title, URL, edit, delete) with no mobile CSS — URL column causes overflow
- Welcome page: v1.7 already added mobile portal column tabs at ≤767px — no changes needed
- `.wrapper` padding already handled in `common.css.scss` at `≤480px` (10px) and `481px–768px` (20px)

</domain>

<decisions>
## Implementation Decisions

### Preferences Table Mobile
- [auto] At ≤767px: switch `.preferences-table` to block layout (display: block for table/tbody/tr/th/td) so labels stack above inputs
- Labels go full-width above their input; `text-align: right` is overridden to `text-align: left` at mobile
- Placed in `common.css.scss` under an `@media (max-width: 767px)` block (consistent with existing breakpoints)
- All 3 themes inherit this from common — no per-theme duplication needed

### Bookmarks Table Mobile
- [auto] At ≤767px: hide the URL column (`th:nth-child(2)` header + `td:nth-child(2)` cells) via `display: none`
- Keeps title + edit + delete columns visible and functional on narrow screens
- URL is accessible via the title link (target="_blank") so hiding it doesn't remove information
- Applied via `.bookmarks-table` selector in `common.css.scss`

### Welcome Page
- [auto] No changes needed — v1.7 delivered mobile portal column tabs at ≤767px for all 3 themes
- Verify tri-suite passes as-is

### Verification Gate
- Minitest: existing `bookmarks_controller_test.rb` and `preferences_controller_test.rb` cover HTTP 200 rendering — no new tests needed for the layout change itself (CSS not testable via controller tests)
- Add selector-level assertions for key mobile-relevant HTML structures: `.preferences-table`, `.bookmarks-table` present in response
- Cucumber: existing scenarios cover welcome page mobile tab behavior
- Final gate: `yarn run lint && bin/rails test && bundle exec rake dad:test` — all green = v1.15 ships

### Claude's Discretion
- Plan structure: single plan (051-01) covering CSS fixes + verification gate
- No per-theme override needed for mobile fixes — `common.css.scss` applies universally
- Breakpoint: use `767px` max-width (consistent with existing v1.7 mobile breakpoint in theme files)

</decisions>

<code_context>
## Existing Code Insights

### Preferences Page
- View: `app/views/preferences/index.html.erb` — `<table class="preferences-table">` with `<th>` labels and `<td>` inputs
- CSS: `common.css.scss` line 182: `.preferences-table { th { text-align: right } }` — no mobile overrides
- No existing responsive handling for this table

### Bookmarks List
- View: `app/views/bookmarks/index.html.erb` — `<table class="bookmarks-table">` with 4 columns: title, url, edit, delete
- No `.bookmarks-table` selector exists in any CSS file — table inherits generic `table` styles from `common.css.scss`
- Generic `table` styles: `margin: 20px`, `th/td: padding: 5px`

### Welcome Page (already handled)
- `welcome.css.scss`: `$portal-mobile-breakpoint: 768px`, `@media (max-width: $portal-mobile-breakpoint - 1px)` portal column tabs
- `themes/modern.css.scss` line 329: `@media (max-width: 767px)` portal column tab overrides
- `themes/classic.css.scss` line 127, `themes/simple.css.scss` line 131: same pattern

### Wrapper Padding (already handled)
- `common.css.scss`: `@media (max-width: 480px)` → `padding: 0 10px`
- `common.css.scss`: `@media (min-width: 481px) and (max-width: 768px)` → `padding: 0 20px`
- Covers all mobile viewports

### Existing Tests
- `test/controllers/preferences_controller_test.rb` — GET preferences, assert 200
- `test/controllers/bookmarks_controller_test.rb` — GET bookmarks index, assert 200

</code_context>

<canonical_refs>
## Canonical References

- `app/assets/stylesheets/common.css.scss` — primary target for mobile fixes (existing mobile breakpoints at 480px/768px)
- `app/assets/stylesheets/themes/modern.css.scss` — reference for existing mobile breakpoint pattern (line 329)
- `app/views/preferences/index.html.erb` — preferences page structure (`.preferences-table`)
- `app/views/bookmarks/index.html.erb` — bookmarks page structure (`.bookmarks-table`, 4 columns)
- `.planning/REQUIREMENTS.md` — MOB-01, MOB-02 requirements
- `CLAUDE.md` — tri-suite policy (lint + Minitest + Cucumber)

</canonical_refs>

<deferred>
## Deferred Ideas

- Hide/show URL column toggle — mobile-specific interaction beyond scope
- Responsive bookmarks new/edit form — out of scope for this phase
- Per-theme mobile overrides — not needed; common.css.scss applies universally

</deferred>
