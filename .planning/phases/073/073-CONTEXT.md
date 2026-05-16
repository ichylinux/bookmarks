# Phase 73: Data + Model Layer - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add a persisted, validated `show_icons` boolean preference that defaults to `true` for all users.
Covers: migration, model constant, `default_preference` update, validation.
No user-facing changes in this phase.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase.

Key constraints from ROADMAP success criteria:
- `show_icons` boolean, NOT NULL, DB-level default `true`
- New users get `show_icons: true` via `default_preference` (explicit assignment)
- `Preference` model validates `show_icons` presence (rejects nil)
- Migration is idempotent for existing users (DB default handles them)

Pattern reference: `show_column_nav_buttons` used a single `add_column` with `default: false, null: false` + a backfill migration. For `show_icons` (default: true), existing rows get `true` from DB default — no separate backfill needed.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Preference` model in `app/models/preference.rb` — boolean constants pattern (see `PORTAL_COLUMN_COUNTS`, `FONT_SIZES`)
- `default_preference` class method sets defaults for new users
- Migration pattern: `add_column :preferences, :field, :boolean, default: X, null: false`

### Established Patterns
- Model constants: `SHOW_COLUMN_NAV_BUTTONS_DEFAULT` not used; booleans set inline in `default_preference`
- Validation for booleans: none currently for boolean fields; v1.23 adds presence validation for `show_icons`
- `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` — reference for inclusion validation

### Integration Points
- `preferences` table (MySQL, charset utf8mb4)
- `Preference#default_preference(user)` — must set `show_icons: true`
- `PreferencesController` strong params — Phase 75 will add `show_icons` there

</code_context>

<specifics>
## Specific Ideas

- Migration timestamp: use `20260517000000` (next available in sequence)
- Constant name: `SHOW_ICONS_DEFAULT = true` (consistent naming pattern)
- Validation: `validates :show_icons, inclusion: { in: [true, false] }` — rejects nil, allows true/false

</specifics>

<deferred>
## Deferred Ideas

None — infrastructure phase stays within scope.

</deferred>
