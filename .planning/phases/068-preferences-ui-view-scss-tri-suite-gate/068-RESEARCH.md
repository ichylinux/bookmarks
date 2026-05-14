# Phase 68: Preferences UI + View + SCSS + Tri-suite Gate - Research

**Researched:** 2026-05-15
**Domain:** Rails ERB view editing, SCSS, i18n locale files, Minitest controller tests, Cucumber step definitions
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Preferences UI — Select Control**
- Place the `portal_column_count` select row **after** `show_column_nav_buttons` in `app/views/preferences/index.html.erb`
- Use `f.label :portal_column_count` for the `<th>`
- Use `f.select :portal_column_count` with integer values 3 and 4, labels from `t('.portal_column_count_options.three')` / `t('.portal_column_count_options.four')`
- Locale strings: ja: `'3列'` / `'4列'`; en: `'3 columns'` / `'4 columns'`
- Locale label key: `preferences.preference_attributes.portal_column_count` (i.e., `activerecord.attributes.preference.portal_column_count`)

**4-Column CSS Approach**
- Add CSS class `portal--4col` on the `div.portal` element in `_portal_column_section.html.erb` when `portal_columns.size == 4`
- Add override in `welcome.css.scss`: `.portal--4col .gadgets { width: 25% }` (desktop-only, above `$portal-mobile-breakpoint`)
- Theme files (`modern.css.scss`, `classic.css.scss`, `simple.css.scss`) need **no changes**
- The existing `div.gadgets { width: 33.33% }` default stays unchanged

**Test Strategy**
- `test/controllers/preferences_controller_test.rb` — add PATCH test saving `portal_column_count: 4` and GET test verifying the select renders the saved value
- `test/models/portal_test.rb` — no new tests needed (Phase 67 already covers distribution)
- Cucumber — add scenario to an existing or new preferences feature verifying save+reload shows 4 selected
- `test/i18n/locales_parity_test.rb` — existing parity test will automatically catch any key mismatch; no new test file needed — just ensure both locale files have the keys

**Strong Params**
- Add `:portal_column_count` to `preference_attributes` permitted list in `PreferencesController#user_params`

### Claude's Discretion
- Exact position of the new `portal_column_count_options` block within the `preferences.index` locale section (after or before `font_size_options`)
- Whether to use `selected:` option in the `f.select` call or rely on Rails model binding (model binding preferred — matches existing `locale` select pattern)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COL-02 | Preferences page shows a select control for portal column count (3 or 4 columns); ja/en locale strings for the label and option values | View change in `index.html.erb`, locale keys in both YML files, activerecord attribute key for label |
| COL-03 | Submitting the preferences form persists the column count; the select control reflects the saved value on page reload | Strong params addition in controller, model binding in `f.select` auto-reflects saved value |
| COL-05 | Welcome page renders the correct number of column sections for the user's preference (3 or 4); existing gadget placements in columns 0–2 preserved | `_portal_column_section.html.erb` conditional class change; Phase 67 portal model already handles column distribution |
| COL-07 | Minitest covers preference validation, preferences controller (save column count), portal column distribution, locale key parity | Controller test additions; parity test is auto-passing with correct locale keys |
| COL-08 | Tri-suite gate green: `yarn run lint` + `bin/rails test` + `bundle exec rake dad:test` | CLAUDE.md test commands; all three must pass before phase closes |
</phase_requirements>

---

## Summary

Phase 68 is a pure wiring phase. Phase 67 delivered the entire data layer (migration, model constant, validation, `Portal#portal_columns` parameterization). This phase has exactly five deliverables:

1. **One new `<tr>` in the preferences form view** — `f.select :portal_column_count` after the `show_column_nav_buttons` row.
2. **One conditional class on `div.portal`** in `_portal_column_section.html.erb` — `portal--4col` when `portal_columns.size == 4`.
3. **One CSS rule in `welcome.css.scss`** — `.portal--4col .gadgets { width: 25% }` scoped inside `@media (min-width: $portal-mobile-breakpoint)`.
4. **Four new locale keys** — two in `ja.yml`, two in `en.yml` (one label key each via `activerecord.attributes.preference.portal_column_count`, two option-label keys each via `preferences.index.portal_column_count_options.three/four`).
5. **One strong-params addition** — `:portal_column_count` in `PreferencesController#user_params`.

Test coverage: two new Minitest tests in the existing controller test file; one Cucumber scenario; the existing `LocalesParityTest` exercises automatically once both locale files are updated.

**Primary recommendation:** Make all five deliverables in a single logical wave; they are small, interdependent only at save time, and the tri-suite gate is the final acceptance criterion.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Preferences form UI (select control) | Frontend Server (SSR) | — | ERB template rendered server-side; Rails form helpers write HTML |
| Persisting column count | API / Backend | Database / Storage | Controller `user_params` strong params gate; ActiveRecord saves to `preferences.portal_column_count` |
| Portal column count rendering (welcome page) | Frontend Server (SSR) | — | `_portal_column_section.html.erb` consumes `portal_columns` array already sized by Phase 67 model |
| 4-column CSS modifier | CDN / Static | — | SCSS compiled to static CSS; no dynamic logic needed at runtime |
| Locale string keys | Frontend Server (SSR) | — | Rails i18n resolves at render time; both locale files must be parity-matched |
| Test gate | — | — | All three suites run in CI/local; no architectural tier |

---

## Standard Stack

Phase 68 uses zero new dependencies. All libraries are already present in the project.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ERB | Rails 7.2 (project) | View templates | Project standard |
| Rails i18n | Rails 7.2 (project) | Locale key resolution via `t()` | Project standard |
| Sass (Dart Sass) | Project bundled | SCSS compilation | Project standard — `welcome.css.scss` is already Sass |
| Minitest | Project bundled | Unit + integration tests | CLAUDE.md mandated |
| Cucumber (daddy gem) | Project bundled | E2E scenarios | CLAUDE.md mandated |

**Installation:** None required. [VERIFIED: codebase grep — no new gems or npm packages needed]

---

## Architecture Patterns

### System Architecture Diagram

```
User browser
    │
    ▼
GET /preferences
    │
    ▼
PreferencesController#index ──► app/views/preferences/index.html.erb
                                      │
                                      └─ f.fields_for :preference_attributes
                                              │
                                              ├─ existing rows (theme, locale, font_size, ...)
                                              ├─ show_column_nav_buttons (checkbox)
                                              └─ portal_column_count (NEW select) ◄─ t('.portal_column_count_options.*')

PATCH /preferences/:id
    │
    ▼
PreferencesController#update
    │
    ├─ user_params strong-params (add :portal_column_count)
    ├─ @user.attributes = attrs
    └─ @user.save! ──► preferences.portal_column_count persisted

GET /
    │
    ▼
WelcomeController#index
    │
    └─ @portal.portal_columns  (Phase 67: already sized by preference)
         │
         ▼
    _portal_column_section.html.erb
         │
         ├─ portal_columns.size == 4 ? 'portal--4col' : ''
         └─ div.portal[class="portal ... portal--4col"]
                │
                └─ CSS: .portal--4col .gadgets { width: 25% }
                         (only active above $portal-mobile-breakpoint = 768px)
```

### Recommended File Touch List

```
app/
├── views/preferences/index.html.erb          # +1 <tr> with f.select
├── views/welcome/_portal_column_section.html.erb  # +1 conditional class
├── assets/stylesheets/welcome.css.scss        # +1 CSS rule inside @media (min-width: $portal-mobile-breakpoint)
└── controllers/preferences_controller.rb     # :portal_column_count in permitted params

config/locales/
├── ja.yml    # +3 keys: activerecord label + 2 option labels
└── en.yml    # +3 keys: same structure

test/controllers/
└── preferences_controller_test.rb   # +2 tests

features/
└── (new or existing preferences feature file)  # +1 Cucumber scenario
features/step_definitions/
└── preferences.rb                  # +steps for the new scenario
```

### Pattern 1: `f.select` with manual options array (font_size pattern)

Existing precedent in `index.html.erb` line 29:

```erb
<%= f.select :font_size,
      Preference::FONT_SIZES.map { |size| [t(".font_size_options.#{size}"), size] },
      selected: (@user.preference.font_size.presence || Preference::FONT_SIZE_MEDIUM) %>
```

For `portal_column_count`, the pattern adapts as:

```erb
<%= f.select :portal_column_count,
      Preference::PORTAL_COLUMN_COUNTS.map { |n| [t(".portal_column_count_options.#{n == 3 ? 'three' : 'four'}"), n] } %>
```

Model binding handles `selected:` automatically because `portal_column_count` always has a valid integer value (NOT NULL, default 3). No `selected:` option needed. [VERIFIED: codebase — `PORTAL_COLUMN_COUNTS = [3, 4].freeze`, `default: 3, null: false` in schema]

Alternative: explicit `selected: @user.preference.portal_column_count` is also valid but redundant — model binding already handles it.

### Pattern 2: Conditional CSS class on `div.portal`

Existing `_portal_column_section.html.erb` line 20:

```erb
<div class="portal portal--column-active-0">
```

The decision is to prepend the conditional class assignment:

```erb
<% col_class = portal_columns.size == 4 ? 'portal--4col' : '' %>
<div class="portal portal--column-active-0 <%= col_class %>".strip>
```

Note: `.strip` avoids a trailing space when `col_class` is empty. Alternatively omit `.strip` — a trailing space in a class attribute is harmless but `.strip` keeps output clean. [VERIFIED: codebase — existing pattern uses string interpolation for dynamic classes]

### Pattern 3: CSS scoped inside `@media (min-width: $portal-mobile-breakpoint)`

Current `welcome.css.scss` line 132–136:

```scss
@media (min-width: $portal-mobile-breakpoint) {
  .portal-column-tabs {
    display: none;
  }
}
```

The 4-column rule must go inside a `@media (min-width: $portal-mobile-breakpoint)` block to ensure it only applies on desktop (768px+). The mobile path already sets `.portal .gadgets.portal-column { width: 100% }` inside `max-width` so no conflict arises.

Add immediately after the existing `@media (min-width: $portal-mobile-breakpoint)` block:

```scss
@media (min-width: $portal-mobile-breakpoint) {
  .portal--4col .gadgets {
    width: 25%;
  }
}
```

[VERIFIED: codebase — `$portal-mobile-breakpoint: 768px`, line 2; desktop `div.gadgets { width: 33.33% }` line 58–60 is not inside any media query, so `.portal--4col .gadgets { width: 25% }` in desktop media query will correctly override it]

### Pattern 4: Strong params — add to existing `preference_attributes` array

Current `PreferencesController#user_params` (line 43–50):

```ruby
preference_attributes: [
  :id, :theme, :font_size, :use_todo, :default_priority,
  :use_note, :use_calendar, :open_links_in_new_tab, :show_column_nav_buttons, :locale
]
```

Add `:portal_column_count` to this list. Position at end (or grouped with column-related params) — order is not significant for `permit`. [VERIFIED: codebase]

### Pattern 5: Locale key structure

`ja.yml` currently has:

```yaml
preferences:
  index:
    font_size_options:
      large: 大
      medium: 中
      small: 小
```

Add parallel block:

```yaml
preferences:
  index:
    portal_column_count_options:
      three: '3列'
      four: '4列'
```

And the attribute label key (used by `f.label :portal_column_count`) lives under:

```yaml
activerecord:
  attributes:
    preference:
      portal_column_count: ポータル列数
```

Both keys are required for the `LocalesParityTest` to remain green. [VERIFIED: codebase — `locales_parity_test.rb` flattens all keys recursively; any key in `ja.yml` not in `en.yml` fails the test]

### Anti-Patterns to Avoid

- **Putting `.portal--4col .gadgets { width: 25% }` outside the desktop media query:** The mobile path has its own overrides; adding the rule at root level would widen gadgets on mobile when 4 columns are set, breaking the tab strip layout.
- **Using integer keys in the locale YAML** (`3:` or `4:`): YAML parses these as integers, not strings. Rails i18n `t('.portal_column_count_options.3')` would fail key lookup. Use named string keys `three:` / `four:` as decided in CONTEXT.md.
- **Hardcoding `portal_columns.size == 4` check in `welcome/index.html.erb`:** The check belongs in `_portal_column_section.html.erb` as a local (partial) concern. `index.html.erb` already passes `portal_columns:` to the partial — no additional local is needed.
- **Forgetting `show_column_nav_buttons` is not in `preference_params` test helper:** The test support helper `test/support/preferences.rb` does not include `show_column_nav_buttons` or `portal_column_count`. New controller tests that PATCH should include `id: user.preference.id` (pattern from existing tests) but do NOT need to pass all attributes — just the ones under test.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Selected option on reload | Manual `selected:` option with database read | Rails model binding — `f.select :portal_column_count, options` | Rails `fields_for` automatically selects the option matching the model attribute value; `portal_column_count` is `NOT NULL` with default 3, so binding is always valid |
| Locale key parity check | New test | Existing `LocalesParityTest#test_jaとenのキー集合が一致する` | Test recursively flattens all keys; adding new keys to both files is sufficient |
| CSS column count at runtime | JS-based column recalculation | Static CSS class `.portal--4col` | Class is set at render time from server state; no JS required for desktop layout |

---

## Common Pitfalls

### Pitfall 1: CSS specificity — `.portal--4col .gadgets` vs global `div.gadgets`

**What goes wrong:** The global desktop rule is `div.gadgets { float: left; width: 33.33% }` (no media query). The 4-column override `@media (min-width: 768px) { .portal--4col .gadgets { width: 25% } }` uses a class selector inside a media query. A class selector has higher specificity than a tag selector, so the override wins regardless of order — but only above the breakpoint.

**Why it happens:** Developers worry the global rule takes precedence.

**How to avoid:** Class selector `.portal--4col .gadgets` (specificity 0-2-0) beats tag selector `div.gadgets` (specificity 0-0-1). No `!important` needed. [VERIFIED: CSS specificity rules]

**Warning signs:** If the 4-column layout still shows `33.33%` widths, check that `portal--4col` is actually present on `div.portal` (server-side rendering path) and that the SCSS is being compiled (asset pipeline rebuild required in dev).

### Pitfall 2: `portal_column_count` submits as string, not integer

**What goes wrong:** HTML `<select>` submits value as a string (`"4"`). Rails strong params pass it as a string to the model. `Preference#portal_column_count` is an integer column — ActiveRecord automatically casts `"4"` to `4`. The validation `inclusion: { in: PORTAL_COLUMN_COUNTS }` uses `PORTAL_COLUMN_COUNTS = [3, 4].freeze` (integers). Rails type-casts before validation, so this works. However, if any test manually asserts `preference_param[:portal_column_count] == 4` (integer) against a hash built from form params (which may be `"4"`), the test may fail.

**How to avoid:** In Minitest, pass the value as an integer (`portal_column_count: 4`) in `params` — that's what `preference_params(portal_column_count: 4)` would produce. [VERIFIED: existing test pattern — e.g., `preference_params(font_size: Preference::FONT_SIZE_LARGE)` passes string constant; `preference_params(default_priority: Todo::PRIORITY_HIGH)` passes integer constant]

### Pitfall 3: `preference_params` helper does not include `portal_column_count`

**What goes wrong:** The shared test helper `test/support/preferences.rb` currently builds:
```ruby
{ use_todo: true, use_calendar: ..., open_links_in_new_tab: ..., font_size: ..., default_priority: ..., locale: ... }
```
It does NOT include `portal_column_count`. When a test PATCHes with `preference_params.merge(portal_column_count: 4, id: ...)`, Rails strong params permit `:portal_column_count` (after our addition), but the param hash only contains what was passed. If other tests rely on `preference_params` and the preference fixture has `portal_column_count: 3` (default), those tests are unaffected.

**How to avoid:** Either (a) add `portal_column_count: options.fetch(:portal_column_count, 3)` to the helper so it always includes the field, or (b) pass it explicitly only in the new tests. Option (a) is cleaner and consistent with `use_calendar` pattern. Either is acceptable.

### Pitfall 4: Cucumber — `Before` hook resets preference but does not reset `portal_column_count`

**What goes wrong:** `features/support/hooks.rb` `Before` hook calls:
```ruby
pref.update!(
  theme: "modern", use_note: false, use_todo: false, use_calendar: true,
  locale: "ja", default_priority: Todo::PRIORITY_NORMAL, open_links_in_new_tab: false
)
```
`portal_column_count` is not in this list. After a Cucumber scenario sets `portal_column_count: 4` and the next scenario runs, the value remains 4 (the DB row was not reset). This is the existing known flakiness pattern described in CLAUDE.md.

**How to avoid:** Add `portal_column_count: 3` to the `Before` hook's `update!` call. This is a direct fix to the leakage problem identified in CLAUDE.md ("Scenarios share DB state"). The new Cucumber scenario for COL-08 should also clean up after itself (or rely on the `Before` hook reset).

**Warning signs:** Subsequent scenarios that check `portal-column` count in the DOM show 4 columns when 3 are expected.

### Pitfall 5: `LocalesParityTest` fails if only one locale file is updated

**What goes wrong:** Adding keys to `ja.yml` but not `en.yml` (or vice versa) causes `LocalesParityTest#test_jaとenのキー集合が一致する` to fail with a list of unmatched keys.

**How to avoid:** Always update both files in the same task. The three new keys required in each file are:
- `activerecord.attributes.preference.portal_column_count`
- `preferences.index.portal_column_count_options.three`
- `preferences.index.portal_column_count_options.four`

[VERIFIED: codebase — `locales_parity_test.rb` flattens both locale trees and diffs the key sets]

---

## Code Examples

Verified patterns from codebase:

### Preferences form — new select row

```erb
<%# Source: app/views/preferences/index.html.erb — font_size row pattern (line 28-30) %>
<tr>
  <th><%= f.label :portal_column_count %></th>
  <td><%= f.select :portal_column_count,
        Preference::PORTAL_COLUMN_COUNTS.map { |n|
          [t(".portal_column_count_options.#{n == 3 ? 'three' : 'four'}"), n]
        } %></td>
</tr>
```

### Portal column section — conditional class

```erb
<%# Source: app/views/welcome/_portal_column_section.html.erb — existing structure (line 20) %>
<% col_class = portal_columns.size == 4 ? 'portal--4col' : '' %>
<div class="portal portal--column-active-0 <%= col_class %>".strip>
```

### SCSS — 4-column override

```scss
// Source: app/assets/stylesheets/welcome.css.scss
// Add after existing @media (min-width: $portal-mobile-breakpoint) block at line 132
@media (min-width: $portal-mobile-breakpoint) {
  .portal--4col .gadgets {
    width: 25%;
  }
}
```

### Strong params — add portal_column_count

```ruby
# Source: app/controllers/preferences_controller.rb line 43-50
preference_attributes: [
  :id, :theme, :font_size, :use_todo, :default_priority,
  :use_note, :use_calendar, :open_links_in_new_tab,
  :show_column_nav_buttons, :locale, :portal_column_count
]
```

### Controller test — save and reload

```ruby
# Source: test/controllers/preferences_controller_test.rb — open_links_in_new_tab pattern (line 23-37)
def test_portal_column_countを4に保存する
  user.preference.update!(portal_column_count: 3)
  sign_in user
  patch preference_path(user), params: {
    user: {
      preference_attributes: preference_params(portal_column_count: 4)
        .merge(id: user.preference.id)
    }
  }
  assert_response :redirect
  assert_equal 4, user.preference.reload.portal_column_count
end

def test_設定画面にportal_column_count選択肢を表示する
  user.preference.update!(portal_column_count: 4, locale: 'ja')
  sign_in user
  get preferences_path
  assert_response :success
  assert_select 'select[name=?]', 'user[preference_attributes][portal_column_count]' do
    assert_select 'option[value="3"]', text: '3列'
    assert_select 'option[value="4"][selected=?]', 'selected', text: '4列'
  end
end
```

### Cucumber scenario (new, in a preferences feature file)

```gherkin
# language: ja
シナリオ: ポータル列数を4に変更して保存できる
  * 設定画面を表示します。
  * ポータル列数を4列に変更して保存します。
  * 設定画面を再表示すると4列が選択されています。
```

Step definitions to add in `features/step_definitions/preferences.rb`:

```ruby
もし /^ポータル列数を4列に変更して保存します。$/ do
  select '4列', from: 'ポータル列数'
  click_on '保存'
end

ならば /^設定画面を再表示すると4列が選択されています。$/ do
  visit '/preferences'
  assert has_select?('ポータル列数', selected: '4列'),
    'ポータル列数が4列として選択されているはずです'
  capture
end
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 7.2 built-in) + Cucumber (daddy gem) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/preferences_controller_test.rb test/i18n/locales_parity_test.rb` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COL-02 | Preferences page renders portal_column_count select with correct labels in ja | unit/integration | `bin/rails test test/controllers/preferences_controller_test.rb` | ✅ (new test in existing file) |
| COL-03 | PATCH saves portal_column_count; GET shows saved value as selected | unit/integration | `bin/rails test test/controllers/preferences_controller_test.rb` | ✅ (new test in existing file) |
| COL-05 | Welcome page renders 4 `portal-column` divs when preference is 4 | unit/integration | `bin/rails test test/controllers/welcome_controller/layout_structure_test.rb` | ✅ (new test in existing file) |
| COL-07 | Locale key parity (ja/en both have new keys) | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ (existing test runs automatically) |
| COL-08 | Tri-suite green | E2E + full | `bundle exec rake dad:test` | ✅ (Cucumber scenario needed — Wave 0 gap) |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/preferences_controller_test.rb test/i18n/locales_parity_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` — all green before marking phase complete

### Wave 0 Gaps

- [ ] Cucumber scenario for COL-08 — needs new steps in `features/step_definitions/preferences.rb` and a new scenario in a preferences feature file (no preferences `.feature` file currently exists — create `features/07.設定.feature`)
- [ ] `Before` hook in `features/support/hooks.rb` should include `portal_column_count: 3` to prevent cross-scenario leakage (fix existing flakiness root cause for this field)

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified — all changes are code/config edits within the existing Rails app)

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Existing `before_action :authenticate_user!` in `ApplicationController`; preferences controller inherits this |
| V5 Input Validation | yes | Strong params whitelist + `inclusion: { in: PORTAL_COLUMN_COUNTS }` model validation |
| V6 Cryptography | no | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mass assignment via forged form params | Tampering | Strong params — `:portal_column_count` must be explicitly permitted |
| Out-of-range integer injection | Tampering | `validates :portal_column_count, inclusion: { in: [3, 4] }` rejects invalid values at model layer |

---

## Open Questions

None — CONTEXT.md decisions cover every implementation choice. The only judgment call left to the planner is:

1. **`preference_params` helper update:** Add `portal_column_count: options.fetch(:portal_column_count, 3)` to `test/support/preferences.rb` or pass explicitly in new tests only. Either is correct; updating the helper is cleaner for future tests.

2. **New Cucumber feature file vs. extending existing:** No `preferences` feature file exists. Create `features/07.設定.feature` or add to `features/02.タスク.feature`. A new file is cleaner — `07.設定.feature` follows the numeric naming convention.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.portal--4col .gadgets` class selector has higher specificity than `div.gadgets` tag selector and will correctly override width | Common Pitfalls #1 | If wrong, need `!important` or restructure selector — low risk, CSS specificity is deterministic |
| A2 | Cucumber `select` helper matches by label (the `<th>` text rendered via `f.label :portal_column_count` → `activerecord.attributes.preference.portal_column_count`) | Code Examples (Cucumber) | If label text differs, Cucumber step fails with "Unable to find select 'ポータル列数'" — verify in Wave 0 run |

**All other claims verified against codebase source files in this session.**

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase] `app/views/preferences/index.html.erb` — existing `f.select` patterns (locale, font_size), field placement, `fields_for` block structure
- [VERIFIED: codebase] `app/views/welcome/_portal_column_section.html.erb` — `div.portal` structure, `portal_columns.each_with_index`
- [VERIFIED: codebase] `app/assets/stylesheets/welcome.css.scss` — `$portal-mobile-breakpoint`, desktop `div.gadgets { width: 33.33% }`, `@media (min-width: $portal-mobile-breakpoint)` block
- [VERIFIED: codebase] `app/controllers/preferences_controller.rb` — `user_params` strong params list
- [VERIFIED: codebase] `config/locales/ja.yml` + `config/locales/en.yml` — `preferences.index` structure, `activerecord.attributes.preference` structure
- [VERIFIED: codebase] `app/models/preference.rb` — `PORTAL_COLUMN_COUNTS = [3, 4].freeze`, `validates :portal_column_count`
- [VERIFIED: codebase] `test/controllers/preferences_controller_test.rb` — existing test patterns (assert_select, preference_params, PATCH params shape)
- [VERIFIED: codebase] `test/i18n/locales_parity_test.rb` — automatic parity enforcement
- [VERIFIED: codebase] `features/support/hooks.rb` — `Before` hook preference reset (missing `portal_column_count`)
- [VERIFIED: codebase] `features/step_definitions/todos.rb` + `modern_theme.rb` — Cucumber step style, Capybara `select` + `has_select?` usage

### Tertiary (LOW confidence)
- A2 above: Capybara `select` / `has_select?` matching by label text — consistent with all observed step definitions but not directly tested against the new label key in this session.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all files inspected directly
- Architecture: HIGH — all touch points identified from source
- Pitfalls: HIGH — derived from direct code inspection + known flakiness in CLAUDE.md
- Test patterns: HIGH — directly extracted from existing test files

**Research date:** 2026-05-15
**Valid until:** 2026-06-15 (stable codebase; no fast-moving dependencies)
