# Phase 67: Data + Model Layer - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add `preferences.portal_column_count` integer column (default 3, NOT NULL) via migration; validate allowed values [3, 4] in Preference model; update `Portal#portal_columns` and `Portal#portal_column_count` to use the stored preference instead of the hardcoded 3; ensure downgrade safety (column_no >= column_count records skipped and redistributed); Minitest coverage for model validation and portal distribution.

No user-facing UI in this phase. Preferences form and welcome page rendering are Phase 68.

</domain>

<decisions>
## Implementation Decisions

### Migration
- Add `portal_column_count` integer column to `preferences` with `default: 3, null: false` — matches pattern of `show_column_nav_buttons` (recent migration)
- No data migration needed: all existing rows will get default 3 via `null: false, default: 3`
- Timestamp: next after `20260514200001`

### Preference Model
- Add `PORTAL_COLUMN_COUNTS = [3, 4].freeze` constant (mirrors `FONT_SIZES` pattern)
- Add `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` (not allow_nil — column has a DB default and is not null)

### Portal Model
- `Portal#portal_column_count` should return `user.preference.portal_column_count` (the `Portal` already has `belongs_to :user`); rename/replace the current method which just calls `portal_columns.size`
- `Portal#portal_columns`: replace `@portal_columns = [[], [], []]` with `count = portal_column_count; @portal_columns = Array.new(count) { [] }`
- Replace `i % 3` fallback with `i % count` (using the same `count` local)
- Downgrade safety: skip `PortalLayout` records where `pl.column_no >= count` — those gadgets fall into the unplaced `gadgets` hash and get redistributed via the fallback

### Claude's Discretion
- Test file placement and naming (follow existing `test/models/` and `test/models/portal_test.rb` conventions)
- Whether to add a helper on Preference for the count (e.g. `portal_column_count` with a nil-safe fallback) or handle nil in Portal — Preference column has a DB default so nil is not expected, but a nil guard is acceptable

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Preference::FONT_SIZES` and `validates :font_size, inclusion:` — exact pattern for `PORTAL_COLUMN_COUNTS` and its validation
- `Portal#portal_columns` current implementation (hardcoded 3, PortalLayout query, fallback with `i % 3`)
- Migration pattern: `add_column :preferences, :column_name, :type, default: X, null: false`

### Established Patterns
- Preference constants are SCREAMING_SNAKE_CASE arrays (FONT_SIZES, SUPPORTED_LOCALES)
- Portal already has `belongs_to :user` and calls `user.preference.*` (e.g. `user.preference.use_todo?`)
- Tests in `test/models/preference_test.rb` and `test/models/portal_test.rb`

### Integration Points
- `Portal#portal_columns` is called in `welcome_controller.rb` and rendered in `_portal_column_section.html.erb`
- `Portal#portal_column_count` is used in `welcome/index.html.erb` for the layout JS loop

</code_context>

<specifics>
## Specific Ideas

- PORTAL_COLUMN_COUNTS = [3, 4] (integers, not strings — unlike FONT_SIZES which are strings)
- The `portal_column_count` method on Portal should delegate to `user.preference.portal_column_count`, not compute from `portal_columns.size`
- When preference is 4 and a PortalLayout has column_no=3, switching back to 3: those gadgets redistribute via fallback; saved column_no=3 positions are preserved in DB and restore when switching back to 4

</specifics>

<deferred>
## Deferred Ideas

- CSS for 4-column layout — Phase 68
- Preferences UI select control — Phase 68
- Cucumber E2E for column count — Phase 68
- Column counts other than 3/4 — explicitly out of scope

</deferred>
