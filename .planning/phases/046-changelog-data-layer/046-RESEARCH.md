# Phase 46: Changelog Data Layer - Research

**Researched:** 2026-05-10
**Domain:** Rails i18n / YAML locale arrays / ApplicationHelper
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Entries live under `landing.changelog.entries` as a YAML array in both `ja.yml` and `en.yml`
- Each entry has four fields: `date` (YYYY-MM-DD string), `headline`, `tag` (key string), `description`
- Supported tags: `ux`, `fix`, `performance`, `new`
- Tag display via `t("landing.changelog.tags.#{entry[:tag]}")`
- Section heading key: `landing.changelog.heading` (ja: `新着情報`, en: `What's New`)
- Helper method `changelog_entries` added to `ApplicationHelper` (no dedicated LandingHelper)
- Sort descending by date string, cap at 10 via `.first(10)`
- Canonical implementation:
  ```ruby
  def changelog_entries
    entries = I18n.t('landing.changelog.entries', default: [])
    entries.sort_by { |e| e[:date] }.reverse.first(10)
  end
  ```

### Claude's Discretion

None specified — all implementation decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

None identified.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLOG-01 | Changelog entries are defined in locale YAML (ja/en) — each entry has a date, headline, tag, and description | YAML array-of-hashes syntax verified; I18n.t returns Array<Hash> with symbol keys [VERIFIED] |
| CLOG-02 | Up to 10 most recent entries are shown on `/landing` | `.first(10)` after `.sort_by { |e| e[:date] }.reverse` works correctly with ISO date strings [VERIFIED] |
| CLOG-03 | Tags categorize entries and are rendered as a visible label on each card | Tag key approach via `t("landing.changelog.tags.#{entry[:tag]}")` is standard Rails i18n pattern [VERIFIED] |
| CLOG-04 | The changelog section has a localized section heading ("What's New" / 「新着情報」) | Simple scalar key under `landing.changelog.heading` — standard pattern [VERIFIED] |
</phase_requirements>

---

## Summary

Phase 46 is a pure data-layer and helper phase: no new controllers, no view rendering, no CSS. The work is confined to three files — `ja.yml`, `en.yml`, and `app/helpers/application_helper.rb`.

Rails i18n natively supports YAML arrays of hashes. `I18n.t('landing.changelog.entries')` returns `Array<Hash>` with **symbolized keys** (confirmed via live Rails runner in this project). The `date` field comes back as a `String`, which means ISO 8601 strings (`"2026-05-10"`) sort correctly with plain lexicographic comparison — no `Date.parse` required.

`ApplicationHelper` is currently empty (`module ApplicationHelper; end`). There are no existing helpers to conflict with. The other helpers in the project (`CalendarsHelper`, `WelcomeHelper`) follow a simple `def method_name ... end` style inside the module — `changelog_entries` should match this pattern.

The `LocalesParityTest` at `test/i18n/locales_parity_test.rb` has a `flatten_keys` method that treats any non-Hash value (including arrays) as a leaf. This means an array under `landing.changelog.entries` is treated as a single leaf key. The parity test will pass as long as both `ja.yml` and `en.yml` have the `landing.changelog.entries` key — the array contents are not individually checked by this test.

**Primary recommendation:** Implement exactly as described in CONTEXT.md. No surprises in the i18n layer, no changes needed to the controller, no new test infrastructure required for the data layer itself.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Locale data storage | Config (YAML) | — | Standard Rails i18n; data lives in `config/locales/` |
| Entry loading and sorting | Helper (ApplicationHelper) | — | View helper is appropriate for presentation data prep; no DB involved |
| Tag label rendering | View (ERB) | — | `t()` call at render time resolves to active locale |
| Section heading | View (ERB) | — | Simple scalar key resolved at render time |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails i18n (built-in) | via Rails 7.2 / i18n 1.14.8 | YAML locale loading and `I18n.t` lookup | Bundled with Rails; already used throughout the app |

No additional gems required. This phase uses only the existing i18n infrastructure. [VERIFIED: `bundle exec rails runner "puts I18n::VERSION"` → `1.14.8`]

### Supporting

None. This is a locale data + helper method phase only.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| YAML array in locale files | Database model or YAML file outside i18n | Locale files give free bilingual support and `I18n.t` ergonomics; overkill to add a model for curated static entries |
| String date sort | `Date.parse` sort | String sort is sufficient and simpler for ISO 8601 — `"2026-05-10" > "2026-01-01"` is lexicographically correct |
| `ApplicationHelper` | New `LandingHelper` | CONTEXT.md locks this; one method does not warrant a dedicated file |

---

## Architecture Patterns

### System Architecture Diagram

```
config/locales/ja.yml          config/locales/en.yml
  landing.changelog.entries      landing.changelog.entries
  landing.changelog.heading      landing.changelog.heading
  landing.changelog.tags.*       landing.changelog.tags.*
          |                               |
          +----------+  +----------------+
                     |  |
               I18n.t() (active locale resolved at request time)
                     |
              ApplicationHelper#changelog_entries
                - I18n.t('landing.changelog.entries', default: [])
                - .sort_by { |e| e[:date] }.reverse.first(10)
                     |
              View (Phase 47) calls changelog_entries
```

### Recommended File Changes

```
config/locales/
├── ja.yml      # add landing.changelog.* keys
└── en.yml      # add landing.changelog.* keys (parallel structure)

app/helpers/
└── application_helper.rb   # add changelog_entries method
```

No new files. No controller changes. No migration.

### Pattern 1: YAML Array of Hashes in Rails i18n

**What:** A YAML sequence (array) where each element is a YAML mapping (hash). Rails i18n deserializes this to `Array<Hash>` with symbolized keys.

**When to use:** When you have a variable-length list of structured data that varies by locale — changelog entries, FAQ items, testimonials.

**Example (ja.yml):**
```yaml
ja:
  landing:
    changelog:
      heading: 新着情報
      tags:
        ux: 使いやすさ
        fix: 修正
        performance: パフォーマンス
        new: 新機能
      entries:
        - date: "2026-05-10"
          headline: チェンジログセクションを追加
          tag: new
          description: ランディングページに新着情報セクションを追加しました。
        - date: "2026-04-01"
          headline: パフォーマンス改善
          tag: performance
          description: ページ読み込み速度を改善しました。
        - date: "2026-03-15"
          headline: UIの調整
          tag: ux
          description: ナビゲーションの操作感を改善しました。
```

**Verified return type:** `I18n.t('landing.changelog.entries')` returns `Array<Hash>` where each hash has symbol keys `[:date, :headline, :tag, :description]`. [VERIFIED: live Rails runner]

### Pattern 2: ApplicationHelper Method

**What:** A plain Ruby method in `ApplicationHelper` that calls `I18n.t` and applies Ruby transforms.

**When to use:** When a view needs processed data derived purely from i18n lookups (no DB, no controller instance variables needed).

**Example:**
```ruby
# Source: CONTEXT.md (locked decision) + WelcomeHelper pattern
module ApplicationHelper
  def changelog_entries
    entries = I18n.t('landing.changelog.entries', default: [])
    entries.sort_by { |e| e[:date] }.reverse.first(10)
  end
end
```

The `default: []` guard prevents `I18n::MissingTranslationData` errors if the key is missing (e.g., in tests before YAML is loaded). [ASSUMED — standard Rails i18n `default:` parameter behavior; consistent with existing Rails docs knowledge]

### Anti-Patterns to Avoid

- **Parsing dates:** Do not call `Date.parse(e[:date])` before sorting. ISO 8601 strings sort lexicographically correctly. Adding `Date.parse` introduces an unnecessary dependency and will raise if a date string is malformed.
- **Controller instance variable:** Do not add `@changelog_entries = changelog_entries` in `LandingController#show`. The helper is callable directly from the view. The controller is intentionally minimal (`def show; end`).
- **Separate YAML file:** Do not put changelog data in `config/changelog.yml` or `config/data/`. The locale files are the canonical location per the locked decision.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bilingual content storage | Custom DB table or separate YAML | Rails i18n YAML arrays | Free locale switching, `I18n.t` integration, no migration |
| Date sorting | Custom date comparison logic | `sort_by { |e| e[:date] }.reverse` | ISO 8601 strings sort lexicographically; built-in Ruby is sufficient |
| Missing key safety | `begin/rescue I18n::MissingTranslationData` | `I18n.t('...', default: [])` | Rails i18n has a first-class `default:` option |

---

## Common Pitfalls

### Pitfall 1: String vs Symbol Keys

**What goes wrong:** Developer writes `entry['headline']` in ERB or helper and gets `nil`.
**Why it happens:** `I18n.t` with the Simple backend returns hashes with **symbol keys**, not string keys. This is confirmed for this project's i18n 1.14.8. [VERIFIED]
**How to avoid:** Always use `entry[:date]`, `entry[:headline]`, `entry[:tag]`, `entry[:description]`.
**Warning signs:** `nil` values when iterating entries in the view.

### Pitfall 2: LocalesParityTest Failure

**What goes wrong:** Adding `landing.changelog.*` keys to `ja.yml` but forgetting to add matching keys to `en.yml` causes `LocalesParityTest#test_jaとenのキー集合が一致する` to fail.
**Why it happens:** The parity test flattens both locale files and asserts the key sets are equal. `entries` is treated as a leaf key — so `landing.changelog.entries` must exist in both files. Similarly `landing.changelog.heading`, `landing.changelog.tags.ux`, etc.
**How to avoid:** Add all keys to both files in the same commit. Run `bin/rails test test/i18n/locales_parity_test.rb` after changes.
**Warning signs:** `only_in_ja` or `only_in_en` arrays are non-empty.

### Pitfall 3: YAML Indentation for Arrays

**What goes wrong:** Incorrect indentation causes the YAML to parse as a nested hash or raises a parse error.
**Why it happens:** YAML sequences (`- `) must be indented one level deeper than the parent key, and each field of the hash must be indented one further level.
**How to avoid:** Use the exact structure shown in Pattern 1. Each `- date:` starts at the same column; `headline:`, `tag:`, `description:` are indented further.
**Warning signs:** `I18n.t('landing.changelog.entries')` returns a `Hash` instead of `Array`, or a YAML parse error at app boot.

### Pitfall 4: date Field Type

**What goes wrong:** Assuming `entry[:date]` is a `Date` object and calling `.strftime` on it.
**Why it happens:** YAML `"2026-05-10"` with quotes is loaded as a `String` by Rails i18n. [VERIFIED]
**How to avoid:** Treat `entry[:date]` as a `String`. For display formatting in Phase 47, use `Date.parse(entry[:date]).strftime(...)` or `l(Date.parse(entry[:date]))` at render time (not in the helper).
**Warning signs:** `NoMethodError: undefined method 'strftime' for "2026-05-10":String`

---

## Code Examples

### Helper Implementation

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def changelog_entries
    entries = I18n.t('landing.changelog.entries', default: [])
    entries.sort_by { |e| e[:date] }.reverse.first(10)
  end
end
```

### YAML Structure (ja.yml addition)

```yaml
# Under existing `landing:` key (around line 179 after current auth: block)
    changelog:
      heading: 新着情報
      tags:
        ux: 使いやすさ
        fix: 修正
        performance: パフォーマンス
        new: 新機能
      entries:
        - date: "2026-05-10"
          headline: チェンジログセクションを追加
          tag: new
          description: ランディングページに新着情報セクションを追加しました。
        - date: "2026-04-01"
          headline: パフォーマンス改善
          tag: performance
          description: ページ読み込み速度を改善しました。
        - date: "2026-03-15"
          headline: UIの調整
          tag: ux
          description: ナビゲーションの操作感を改善しました。
```

### YAML Structure (en.yml addition)

```yaml
# Under existing `landing:` key (around line 179 after current auth: block)
    changelog:
      heading: What's New
      tags:
        ux: UX
        fix: Fix
        performance: Performance
        new: New
      entries:
        - date: "2026-05-10"
          headline: Changelog section added
          tag: new
          description: Added a What's New section to the landing page.
        - date: "2026-04-01"
          headline: Performance improvement
          tag: performance
          description: Improved page load speed.
        - date: "2026-03-15"
          headline: UI refinements
          tag: ux
          description: Improved navigation feel and responsiveness.
```

### Test: Locale Key Presence (extends existing pattern)

```ruby
# test/i18n/locales_parity_test.rb — parity test already covers this automatically
# Dedicated smoke test for changelog keys follows rails_i18n_smoke_test.rb pattern:
class ChangelogI18nTest < ActiveSupport::TestCase
  def test_changelog_headingがja_enで解決される
    ja = I18n.with_locale(:ja) { I18n.t('landing.changelog.heading') }
    en = I18n.with_locale(:en) { I18n.t('landing.changelog.heading') }
    assert_equal '新着情報', ja
    assert_equal "What's New", en
  end

  def test_changelog_entriesがArrayを返す
    entries = I18n.with_locale(:ja) { I18n.t('landing.changelog.entries') }
    assert_kind_of Array, entries
    assert entries.length >= 1
    assert_includes entries.first.keys, :date
    assert_includes entries.first.keys, :headline
    assert_includes entries.first.keys, :tag
    assert_includes entries.first.keys, :description
  end
end
```

### Test: Helper Method (unit test for ApplicationHelper)

```ruby
# test/helpers/application_helper_test.rb (new file — no helper tests exist yet)
require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  def test_changelog_entriesが日付降順で返る
    entries = changelog_entries
    dates = entries.map { |e| e[:date] }
    assert_equal dates.sort.reverse, dates
  end

  def test_changelog_entriesが最大10件を返す
    # With 3 seed entries this just confirms <= 10
    assert changelog_entries.length <= 10
  end
end
```

---

## Codebase Findings

### ApplicationHelper (current state)

`app/helpers/application_helper.rb` is empty:
```ruby
module ApplicationHelper
end
```
No existing methods to conflict with. [VERIFIED: file read]

### LandingController (current state)

```ruby
class LandingController < ApplicationController
  skip_before_action :authenticate_user!

  def show; end
end
```
No controller changes required. Helper is available in views automatically — Rails includes all helpers in all views by default. [VERIFIED: file read]

### Existing Landing Tests

`test/controllers/landing_controller_test.rb` has 5 tests covering:
- Unauthenticated access returns `:success`
- CTA links present
- English locale rendering
- Root redirects to landing

None of these tests assert changelog content — they will not be broken by Phase 46. Phase 48 is designated for adding changelog-specific controller/view tests. [VERIFIED: file read]

### LocalesParityTest Behavior with Arrays

The `flatten_keys` method in `locales_parity_test.rb` treats any non-Hash value as a leaf. An array is not a Hash, so `landing.changelog.entries` is a single leaf key in the flattened output. The test does NOT recursively check array element keys. [VERIFIED: ruby simulation]

---

## Validation Architecture

`nyquist_validation` is enabled (per `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (via Rails) |
| Config file | none (standard Rails test/ layout) |
| Quick run command | `bin/rails test test/i18n/ test/helpers/` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLOG-01 | entries YAML has required keys | unit | `bin/rails test test/i18n/changelog_i18n_test.rb` | Wave 0 |
| CLOG-02 | helper returns <= 10 entries sorted desc | unit | `bin/rails test test/helpers/application_helper_test.rb` | Wave 0 |
| CLOG-03 | tags keys resolve in both locales | unit | `bin/rails test test/i18n/changelog_i18n_test.rb` | Wave 0 |
| CLOG-04 | heading key resolves in ja and en | unit | `bin/rails test test/i18n/changelog_i18n_test.rb` | Wave 0 |

### Parity Coverage (existing test)

`bin/rails test test/i18n/locales_parity_test.rb` will automatically verify `landing.changelog.*` key parity once YAML is added to both files. No modification to this test is required. [VERIFIED]

### Sampling Rate

- Per task commit: `bin/rails test test/i18n/ test/helpers/`
- Per wave merge: `bin/rails test`
- Phase gate: `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

- [ ] `test/i18n/changelog_i18n_test.rb` — covers CLOG-01, CLOG-03, CLOG-04
- [ ] `test/helpers/application_helper_test.rb` — covers CLOG-02
- [ ] `test/helpers/` directory does not exist — must be created

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `I18n.t('...', default: [])` prevents MissingTranslationData when key absent | Don't Hand-Roll | Low risk — standard Rails behavior, and entries will be present in YAML anyway |

---

## Open Questions

None. All implementation questions are answered by the CONTEXT.md locked decisions and verified codebase inspection.

---

## Environment Availability

Step 2.6: SKIPPED — this phase has no external dependencies beyond the existing Rails/Ruby stack. All tools (Rails i18n, Minitest) are already in use.

---

## Security Domain

No security-sensitive surface area in this phase. No user input, no authentication, no data persistence. The only data source is locale YAML files committed to the repository.

ASVS V5 (Input Validation): Not applicable — no user-supplied input.

---

## Sources

### Primary (HIGH confidence)

- Live Rails runner in `/home/ichy/workspace/bookmarks/` — verified `I18n.t` returns `Array<Hash>` with symbol keys for YAML array-of-hashes
- Live Ruby simulation — verified `sort_by { |e| e[:date] }.reverse` produces correct descending order for ISO 8601 strings
- Direct file reads — `application_helper.rb`, `landing_controller.rb`, `show.html.erb`, `ja.yml`, `en.yml`, all test files

### Secondary (MEDIUM confidence)

- None required — all critical claims verified directly against the codebase

### Tertiary (LOW confidence)

- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed via live Rails environment
- Architecture: HIGH — confirmed via direct file inspection
- Pitfalls: HIGH — verified via Ruby/Rails simulation

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (stable Rails i18n behavior)
