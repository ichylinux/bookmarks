# Phase 68: Preferences UI + View + SCSS + Tri-suite Gate - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a `portal_column_count` select control to the preferences form (ja/en locale strings); parameterize the welcome page portal rendering so it outputs 3 or 4 `portal-column` sections matching the user's stored preference; add a `.portal--4col` CSS modifier in `welcome.css.scss` that overrides column width to 25% on desktop (above 768px breakpoint); confirm theme files (modern/classic/simple) need no changes. Run the full tri-suite gate (yarn run lint + bin/rails test + bundle exec rake dad:test) to close the milestone.

No new routes, no new controllers, no new models. Phase 67 delivered the data layer — Phase 68 wires it to the UI.

</domain>

<decisions>
## Implementation Decisions

### Preferences UI — Select Control
- Place the `portal_column_count` select row **after** `show_column_nav_buttons` in `app/views/preferences/index.html.erb` (logical grouping at the bottom of the preference section, consistent with column-related controls)
- Use `f.label :portal_column_count` for the `<th>` (matches attribute name convention: `font_size`, `locale`, `theme`)
- Use `f.select :portal_column_count` with integer values `3` and `4`, labels from `t('.portal_column_count_options.three')` / `t('.portal_column_count_options.four')`
- Locale strings: ja: `'3列'` / `'4列'`; en: `'3 columns'` / `'4 columns'`
- Locale label key: `preferences.preference_attributes.portal_column_count` (consistent with `font_size`, `locale`, etc.)

### 4-Column CSS Approach
- Add CSS class `portal--4col` on the `div.portal` element in `_portal_column_section.html.erb` when `portal_columns.size == 4` (using `<% col_class = portal_columns.size == 4 ? 'portal--4col' : '' %>`)
- Add override in `welcome.css.scss` (desktop-only, above `$portal-mobile-breakpoint`): `.portal--4col .gadgets { width: 25% }`
- Theme files (`modern.css.scss`, `classic.css.scss`, `simple.css.scss`) need **no changes** — `portal-column-tab` styles are index-based and already dynamic; the tab strip adapts automatically
- The existing `div.gadgets { width: 33.33% }` default stays unchanged — the `.portal--4col` class only overrides when 4 columns are active

### Test Strategy
- `test/controllers/preferences_controller_test.rb` — add test that PATCH preferences with `portal_column_count: 4` persists the value and redirects; also verify the preferences page renders the saved value as selected
- `test/models/portal_test.rb` already covers distribution (3/4 columns, downgrade) — no new portal model tests needed
- Cucumber — add a scenario to the existing preferences feature (`features/04.Preferences.feature` or equivalent) verifying that saving portal_column_count=4 and reloading preferences shows 4 selected
- `test/i18n_test.rb` (or locale parity test file) — add parity check for `portal_column_count` label and option keys in both `ja.yml` and `en.yml`

### Claude's Discretion
- Exact position of the new `portal_column_count_options` block within the `preferences.index` locale section (after or before `font_size_options`)
- Whether to use `selected:` option in the `f.select` call or rely on Rails model binding (model binding preferred — matches existing `locale` select pattern)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/preferences/index.html.erb` — existing select pattern: `f.select :locale, Preference::LOCALE_OPTIONS, { include_blank: false, selected: ... }` and `f.select :font_size, Preference::FONT_SIZES.map { ... }` — portal_column_count follows the same pattern
- `app/views/welcome/_portal_column_section.html.erb` — existing `portal_columns.each_with_index` loop; adding a class to `div.portal` is the only change needed
- `app/assets/stylesheets/welcome.css.scss` — desktop column width defined at line 59: `div.gadgets { float: left; width: 33.33% }` — add `.portal--4col .gadgets { width: 25% }` below the `@media (min-width: $portal-mobile-breakpoint)` block
- `Preference::PORTAL_COLUMN_COUNTS = [3, 4]` (Phase 67) — use this to drive the select options array

### Established Patterns
- Preferences form uses `f.fields_for :preference_attributes` — new select must go inside this block
- Locale label keys for preference attributes: `ja.yml activerecord.attributes.preference.{attr}` — add `portal_column_count: ポータル列数`
- View-level locale keys under `ja.yml preferences.index.portal_column_count_options` matching `font_size_options` pattern
- `PreferencesController#update` uses `user_params` with `preference_attributes:` nested — just add `:portal_column_count` to the permitted params list

### Integration Points
- `app/controllers/preferences_controller.rb` — `user_params` strong params — add `:portal_column_count` to `preference_attributes` permitted list
- `config/locales/ja.yml` + `config/locales/en.yml` — two new keys each: label + two option values
- `app/assets/stylesheets/welcome.css.scss` — single CSS rule addition
- `app/views/welcome/_portal_column_section.html.erb` — conditional class on `div.portal`

</code_context>

<specifics>
## Specific Ideas

- The select row should match exactly what exists for `show_column_nav_buttons` in placement: after it, inside the `f.fields_for :preference_attributes` block
- CSS class approach (`.portal--4col`) is preferred over inline style / CSS custom property — simpler, easier to test in Cucumber, matches existing `.portal--column-active-N` class pattern

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
