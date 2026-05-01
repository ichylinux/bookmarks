# Phase 17: Feature Surface Translation - Research

**Date:** 2026-05-01  
**Status:** Ready for planning  
**Scope:** TRN-02, TRN-03, TRN-05

## Research Question

このフェーズを良く計画するために知るべきことは、「どの文字列がアプリ定義 UI chrome で、どの文字列がユーザー作成または外部コンテンツか」と、「Rails server-rendered + Sprockets/jQuery のまま JavaScript-visible copy をどう供給するか」である。

結論として、Phase 17 は新しい i18n 基盤を作るフェーズではない。既存の `I18n.locale` 解決、`config/locales/{ja,en}.yml`、ERB の `t(...)` / `human_attribute_name`、Sprockets + jQuery を使い、feature surface の固定 UI 文言を抽出するフェーズとして計画するのがよい。

## Standard Stack

- Rails I18n を唯一の翻訳 runtime とする。`config/locales/ja.yml` と `config/locales/en.yml` に同じキー集合を追加する。
- View は ERB 側で `t(...)`、`Model.human_attribute_name(...)`、`l(date, format: ...)` を使う。
- JavaScript-visible messages は server-rendered `data-*` attributes または ERB で JSON escape された値を使う。新しい JS i18n pipeline は作らない。
- 既存の `i18n-js` gem は Gemfile 上に存在するが、Phase 17 では設定・利用しない。Requirement の out-of-scope と Phase context が明示的に禁止している。
- `rails-i18n` の `date.abbr_day_names` と `date.formats` を利用できる。Calendar の weekday/month 表示は hand-rolled 配列より Rails I18n に寄せる。

## Architecture Patterns

- Locale key は以下の分け方が最も安全。
  - `gadgets.bookmark.title`, `gadgets.todo.title`: model/gadget から参照する固定 gadget title。
  - `todos.priorities.high|normal|low`: Todo priority の表示ラベル。stored numeric values はそのまま。
  - `date.formats.calendar_month`: Calendar caption 用。`ja` は `%Y年%-m月`、`en` は `%B %Y` 相当。
  - `actions.*`: 複数 resource で繰り返す `edit`, `delete`, `list`, `back_to_list`, `add`, `show`, `create`, `update`, `save` など。
  - View 固有 copy は lazy lookup の path と一致する namespace に置く。例: `bookmarks.index.*`, `bookmarks.form.*`, `bookmarks.show.*`, `welcome.note_gadget.*`, `welcome.feed.*`, `welcome.calendar.*`, `feeds.form.*`, `calendars.get_gadget.*`。
- Lazy lookup を使う場合は template path と YAML 階層を完全一致させる。Phase 15 の失敗例として、`t('.foo')` は partial/action path に解決されるため `bookmarks.form.foo` と `bookmarks.foo` を混同しない。
- Plain Ruby gadget object は view context を持たないため、`BookmarkGadget#title` / `TodoGadget#title` は `I18n.t('gadgets.bookmark.title')` のような absolute key を使う。
- Todo priority は class-load 時に翻訳値を constant に入れない。`Todo::PRIORITY_HIGH = 1` 等の numeric constants を残し、`PRIORITY_KEYS = { 1 => :high, 2 => :normal, 3 => :low }` か同等の mapping から `priority_name` / `priority_options` を runtime locale で解決する。
- Calendar は `Calendar#day_of_week(index)` を残すなら `I18n.t('date.abbr_day_names')[index]` を返す。月表示は view 側で `l(@calendar.display_date, format: :calendar_month)` に寄せる。

## Current Implementation Map

### Locale Catalog

- `config/locales/ja.yml` / `config/locales/en.yml`
  - 既存: `activerecord.attributes.bookmark|feed|calendar|todo|preference`, `messages.confirm_delete`, `nav.*`, `flash.errors.generic`, `preferences.*`, `two_factor.*`。
  - 不足: feature views 用の action labels、breadcrumb labels、form helper text、note gadget copy、Todo priority labels、fixed gadget titles、feed/calendar loading/error copy、calendar month format。
  - `test/i18n/locales_parity_test.rb` が ja/en の key parity を既に検証しているため、追加キーの片側漏れは Minitest で拾える。

### Bookmark Surface

- `app/models/bookmark_gadget.rb`
  - `title` が `'Bookmark'` 固定。D-01 により翻訳対象。
  - `entries` 内コメントの日本語は user-visible ではないため対象外。
- `app/views/bookmarks/index.html.erb`
  - 翻訳対象: `aria-label="パンくずリスト"`, `ルート`, `フォルダを作成`, `フォルダ`, `ブックマークを追加`, `ブックマーク`, `操作`, `編集`, `削除`。
  - 既に翻訳済み/再利用可: `Bookmark.human_attribute_name :title`, `messages.confirm_delete`。
  - 非翻訳: `@parent.title`, `b.title`, `b.url` は user-created content。
- `app/views/bookmarks/_form.html.erb`
  - 翻訳対象: `URL（フォルダの場合は空欄）`, folder creation help text, title auto-fill help text, `親フォルダ`, `なし（ルート）`, submit label。
  - 既に翻訳済み/再利用可: `f.label :url`, `f.label :title` は AR attribute keys 経由。
  - 非翻訳: folder option labels `f.title` は user-created folder names。
- `app/views/bookmarks/show.html.erb`, `app/views/bookmarks/edit.html.erb`
  - 翻訳対象: `一覧`, `編集`, `親フォルダ`。
  - 非翻訳: bookmark title/url and parent folder title。
- `app/views/bookmarks/new.html.erb`
  - 固定文言なし。`_form` に従属。

### Note Surface

- `app/views/welcome/_note_gadget.html.erb`
  - 翻訳対象: `ノート`, `メモ`, `保存`, `メモはまだありません`。
  - 非翻訳: `note.body` は user-created content。timestamp format は今回の明示 scope では固定 UI copy ではないが、英語 UI で日付形式も揃えるなら別途確認対象。
- `app/controllers/notes_controller.rb`
  - Phase 16 で `flash.errors.generic` 済み。Phase 17 で追加の controller flash は見当たらない。

### Todo Surface

- `app/models/todo_gadget.rb`
  - `title` が `'Todo'` 固定。D-01 により翻訳対象。
- `app/models/todo.rb`
  - `PRIORITIES = { 1 => '高', 2 => '中', 3 => '低' }` が locale 固定。D-02 により表示時翻訳対象。
  - Stored values は numeric priority のまま変えない。
- `app/views/todos/_actions.html.erb`
  - 翻訳対象: `完了`, `新しいタスク`。
  - `data-authenticity_token` は UI copy ではない。
- `app/views/todos/_form.html.erb`
  - 翻訳対象: priority select labels, `登録`, `更新`。
  - `f.text_field :title` は placeholder なし。
- `app/views/todos/_todo.html.erb`
  - 翻訳対象: `todo.priority_name` の表示結果。
  - 非翻訳: `todo.title` は user-created content。
- `app/views/todos/index.html.erb`
  - 翻訳対象: `削除`。
  - 注意: table header は `Todo.human_attribute_name` 済みだが、row は priority ではなく `t.title` を priority column 下に出している既存挙動がある。Phase 17 の主目的ではないため、修正するなら別 bug として切り分ける。
- `app/views/preferences/index.html.erb`
  - Phase 17 の主対象ファイルではないが、`default_priority` select が `Todo::PRIORITIES.invert` を使う。D-02 を満たすには、ここも `Todo.priority_options` のような runtime-localized options に差し替える必要がある。

### Feed Surface

- `app/views/feeds/index.html.erb`
  - 翻訳対象: `追加`, `1件も登録されていません。`, `サイト名`, `表示件数`, `フィードURL`, `編集`, `削除`。
  - 既存 AR keys `Feed.human_attribute_name(:title|:display_count|:feed_url)` を使える。
  - 非翻訳: `feed.title`, `feed.feed_url`, `feed.display_count` は record data。
  - 注意: delete link は `confirm: t(...)` 形式。既存挙動を保つなら i18n 目的だけで `data:` への広範な refactor は不要。
- `app/views/feeds/_form.html.erb`
  - 翻訳対象: `フィードから取得`, submit label。
  - JS 用に button/form へ translated `data-*` messages を供給する場所として適している。
  - 既存 AR labels は利用可能。
- `app/assets/javascripts/feeds.js`
  - 翻訳対象: `フィードURLを先に入力してください。`, `フィードを取得できませんでした。`。
  - 推奨: `$(button).data('feedUrlRequiredMessage')`, `$(button).data('feedFetchFailedMessage')` のように button の `data-*` から読む。
- `app/views/welcome/_feed.html.erb`
  - 翻訳対象: Ajax fail の `フィードを取得できませんでした。(%{status})`, loading の `フィードを取得中・・・`。
  - 推奨: gadget wrapper に `data-fetch-failed-message="<%= t(..., status: '__STATUS__') %>"` のような置換前提より、`data-fetch-failed-prefix` と status append、または inline ERB script で escaped string を渡す。計画時には escaping と jQuery `.data()` 変換を明記する。
  - 非翻訳: `gadget.title` は Feed record title で user-created/external boundary。
- `app/views/feeds/show.html.erb`
  - 固定 UI copy なし。`@feed.title`, feed entry titles/URLs は external/user content なので非翻訳。

### Calendar Surface

- `app/models/calendar.rb`
  - `day_of_week` の `%w{ 日 月 火 水 木 金 土 }` は翻訳対象。
  - `holiday(date)` は `holiday_jp` の `holiday.name` を返す。D-03/D-04 により Japanese holiday names は外部地域データとして非翻訳。
  - `display_year` / `display_month` は numeric accessors。month/year の UI formatting は view or helper で翻訳対象。
- `app/views/calendars/get_gadget.html.erb`
  - 翻訳対象: `<%= year %>年<%= month %>月`, weekday labels。
  - 非翻訳: `@calendar.holiday(date)` の holiday names。
  - `<<` / `>>` は icon-like navigation controls。翻訳不要だがアクセシビリティ label を追加するなら `previous_month` / `next_month` を locale key 化する。
- `app/views/welcome/_calendar.html.erb`
  - 翻訳対象: loading text `%{title}を取得中・・・`。
  - 非翻訳: `gadget.title` は Calendar record title。translated sentence に user-created title を interpolate するだけにする。
- `app/views/calendars/_form.html.erb`
  - 翻訳対象: submit label。`f.label :title` は AR label 済み。
- `app/views/calendars/show.html.erb`, `app/views/calendars/edit.html.erb`
  - 翻訳対象: `編集`, `削除`, `参照`。
  - 非翻訳: `@calendar.title`。

### JavaScript and Inline Script Surface

- `app/assets/javascripts/feeds.js` は alert 文言を持つ唯一の first-party JS file。
- `app/views/welcome/_feed.html.erb` は inline Ajax fail で user-visible `.text(...)` を持つ。
- `app/views/welcome/_calendar.html.erb` は inline Ajax loading text を server-rendered HTML として持つ。
- `app/assets/javascripts/todos.js`, `calendars.js`, `bookmark_gadget.js`, `notes_tabs.js` には翻訳対象の prose UI copy はない。`▶` / `▼` は icon state、JS comments は非対象。

### Existing Test Surface

- `test/controllers/bookmarks_controller_test.rb`
  - Breadcrumb の Japanese fixed text を直接 assert している。Phase 17 では ja/en 両方の expectation に更新が必要。
- `test/controllers/welcome_controller/welcome_controller_test.rb`
  - Note gadget の `ノート`, `保存`, empty state を直接 assert している。ja/en representative tests に拡張する。
- `test/controllers/todos_controller_test.rb`, `feeds_controller_test.rb`, `calendars_controller_test.rb`
  - 現状は routing/authorization 中心。Phase 17 の feature surface i18n assertions を追加する余地がある。
- `features/02.タスク.feature` / `features/step_definitions/todos.rb`
  - `Todo`, `新しいタスク`, `登録`, priority labels を前提にしている。Todo gadget title を Japanese locale で `タスク` にする場合は feature text/step expectations を更新する。
- `features/01.ブックマーク.feature` / `features/step_definitions/bookmarks.rb`
  - Rails default submit `登録する` に依存している。Bookmark form submit を explicit key にすると Cucumber step の button label も更新対象。
- `features/04.ノート.feature` / `features/step_definitions/notes.rb`
  - `保存` button に依存。Japanese locale のままなら維持可能だが、key 化後も test は通るよう確認する。

## Translation Boundary

### Translate

- Fixed gadget titles: `BookmarkGadget#title`, `TodoGadget#title` (D-01)。
- Bookmark UI labels/actions/help text/breadcrumbs: root, folder/bookmark add controls, action headers, edit/delete/list/back labels, parent folder label, folder placeholder/help text。
- Note gadget UI: heading, body label, save button, empty state。
- Todo UI: gadget title, complete/new task actions, create/update buttons, priority display/select labels (D-02)。
- Feed UI: index/form labels/actions/empty states, fetch-title button, loading/error messages。
- Calendar UI: month/year formatting, weekday labels, loading sentence, show/edit/delete/view labels (D-03)。
- JavaScript-visible messages in `feeds.js` and `_feed.html.erb`, supplied by server-rendered translated values (TRN-05)。

### Do Not Translate

- Bookmark titles, URLs, folder names, and parent folder names (D-04)。
- Note bodies (D-04)。
- Todo titles (D-04)。
- Feed site names, feed URLs, feed titles, feed entry titles and URLs (D-01, D-04)。
- Calendar record titles (D-01, D-04)。
- `holiday_jp` holiday names returned from `Calendar#holiday` (D-03, D-04)。
- Language selector native labels `自動 / 日本語 / English` from Phase 15 precedent。
- Code comments, CSS classes, DOM ids, route/action names, icon glyphs like `▶` / `▼`, and `<<` / `>>` unless an accessibility label is intentionally added。

### Boundary-Sensitive Interpolation

- `messages.confirm_delete` correctly translates the sentence while interpolating user content `%{name}` unchanged. Preserve this pattern.
- Calendar loading can translate the sentence while interpolating `%{title}` unchanged.
- Feed Ajax error can translate the fixed error copy while appending HTTP status unchanged.
- Never build translation keys from user content. User content may be an interpolation value only.

## Recommended Implementation Strategy

### 1. Seed Locale Keys First

Plan the first implementation unit around adding the full key skeleton to both locale files and extending tests if needed. This reduces merge conflicts in later view-only tasks and lets `LocalesParityTest` catch omissions early.

Recommended namespaces:

- `actions.add`, `actions.edit`, `actions.delete`, `actions.list`, `actions.back_to_list`, `actions.show`, `actions.create`, `actions.update`, `actions.save`
- `gadgets.bookmark.title`, `gadgets.todo.title`
- `todos.priorities.high`, `todos.priorities.normal`, `todos.priorities.low`
- `bookmarks.index.*`, `bookmarks.form.*`, `bookmarks.show.*`
- `feeds.index.*`, `feeds.form.*`
- `welcome.note_gadget.*`, `welcome.feed.*`, `welcome.calendar.*`
- `calendars.get_gadget.previous_month`, `calendars.get_gadget.next_month` if ARIA/title labels are added
- `date.formats.calendar_month`

Use absolute keys for shared/model code. Use lazy keys only in templates where path is obvious and tests will catch missing translations.

### 2. Add Model-Level Translation Helpers

- `BookmarkGadget#title` returns `I18n.t('gadgets.bookmark.title')`.
- `TodoGadget#title` returns `I18n.t('gadgets.todo.title')`.
- `Todo` keeps numeric constants and adds runtime methods:
  - `Todo.priority_options` for select helpers.
  - `Todo.priority_key(priority)` or equivalent mapping.
  - `#priority_name` uses active `I18n.locale`.
- Replace `Todo::PRIORITIES.invert` usages in `todos/_form` and `preferences/index` with runtime-localized options.
- `Calendar#day_of_week(index)` should use `I18n.t('date.abbr_day_names')[index]` or the view should directly use `I18n.t`. Keep holiday lookup unchanged.

### 3. Substitute Views by Feature Surface

- Bookmark views: replace fixed strings with `t(...)`, keep `Bookmark.human_attribute_name` for model fields, add explicit `f.submit t(...)` for deterministic labels.
- Note/Todo welcome partials: translate labels/buttons/empty states/gadget titles, preserve note/todo content.
- Feed views: translate fixed UI labels and add `data-*` messages to the fetch-title button/form.
- Calendar views: translate actions/loading/month/weekday display, preserve record title and holiday names.

### 4. Feed JavaScript from Server-Rendered Values

For `feeds.js`, avoid global translation objects. Prefer:

```javascript
const message = $(button).data('feedUrlRequiredMessage');
alert(message);
```

with ERB:

```erb
<%= f.button t('.fetch_from_feed'),
      onclick: 'feeds.get_feed_title(this); return false;',
      'data-url': url_for(action: 'get_feed_title'),
      'data-feed-url-required-message': t('.feed_url_required'),
      'data-feed-fetch-failed-message': t('.feed_fetch_failed') %>
```

For `_feed.html.erb`, either put translated messages on `#feed_<id>` as `data-*` and read them from inline JS, or use `to_json` for JS string literals. `data-*` better matches the Phase 17 decision and is easier to assert in Minitest.

### 5. Keep Existing Architecture

- Do not introduce `i18n-js`, import maps, bundlers, Stimulus, or global `window.I18n`.
- Do not migrate Todo data.
- Do not refactor CRUD/controller structure except as required for translation helper access.
- Do not try to translate external feed or holiday data.

## Testing Strategy

### Minitest

- Keep `test/i18n/locales_parity_test.rb` as the key parity gate. New keys in one locale only should fail.
- Add/update controller integration tests with saved `user.preference.locale = 'ja'` and `'en'`:
  - Bookmark index/form/show: assert translated breadcrumb/action/help text and assert user-created bookmark/folder titles remain unchanged.
  - Welcome root: assert fixed gadget titles localize, note gadget labels/buttons/empty state localize, bookmark/todo user content remains unchanged.
  - Todo new/edit partial or Ajax endpoints: assert priority select and `priority_name` render active locale while numeric selected value stays unchanged.
  - Preferences page: assert default priority select options localize because it uses Todo priority labels.
  - Feed index/form: assert translated labels/buttons, empty state, and `data-*` JS messages.
  - Calendar `get_gadget`: assert English month/year and weekday labels, Japanese month/year and weekday labels, and a known `holiday_jp` holiday name remains Japanese.
- Avoid overfitting tests to every string. Use representative path coverage plus locale key parity.

### Cucumber

- Use `bundle exec rake dad:test`, not `bundle exec cucumber`.
- Existing Japanese scenarios should continue to exercise default Japanese locale. Update steps if Japanese labels intentionally change from legacy English (`Todo`) to localized Japanese (`タスク`).
- Cucumber is best used as smoke coverage for real browser interactions: bookmark creation, todo widget add flow, note save flow. Do not duplicate every Minitest assertion.

### Lint and Full Gate

Per `CLAUDE.md`, phase completion requires all three suites:

1. `yarn run lint`
2. `bin/rails test`
3. `bundle exec rake dad:test`

If `dad:test` fails, rerun once because current suite has known scenario-order flakiness around preferences/theme/note state. A failure that reproduces twice is a real regression.

## Risks and Pitfalls

- **Lazy lookup path:** `_form.html.erb` resolves to `resource.form.*`, not `resource.*`. Misplaced keys will produce `translation missing` or fallback behavior.
- **Runtime locale in constants:** Do not put translated strings in constants at class load. Todo priority labels must resolve per request locale.
- **User content interpolation:** Bookmark titles, note bodies, todo titles, feed titles, and calendar titles must not be translated or used as translation keys.
- **Holiday names:** `holiday_jp` names are Japanese external regional data. Tests/static audit may see Japanese text in calendar output; document it as intentional.
- **Gadget title boundary:** `BookmarkGadget#title` and `TodoGadget#title` are fixed UI labels and should localize. Feed and Calendar gadget titles are records and should not.
- **Sprockets data attribute approach:** jQuery `.data('feedUrlRequiredMessage')` maps from `data-feed-url-required-message`. Plan exact names to avoid mismatches.
- **Escaping JS-visible copy:** If using inline JS literals, use `to_json`; if using `data-*`, let Rails escape attribute values.
- **Existing Cucumber flakiness:** Preference state leaks can create unrelated failures. Follow the rerun policy.
- **Cucumber label dependencies:** Existing steps click Japanese labels like `保存`, `登録`, `新しいタスク`, and one scenario expects `Todo`. Translation changes may require step/scenario updates.
- **Rails default submit labels:** Existing `f.submit` may rely on Rails default Japanese labels. For deterministic bilingual UI, prefer explicit translated submit labels.
- **Scope creep:** Devise/auth pages and milestone-wide translation audit are Phase 18. Do not pull them into Phase 17.

## Don't Hand-Roll

- Do not hand-roll a JavaScript translation registry.
- Do not hand-roll Accept-Language or locale resolution; Phase 14 already shipped it.
- Do not hand-roll weekday/month names when Rails I18n date data can supply them.
- Do not hand-roll static key parity checking; reuse/extend `LocalesParityTest`.
- Do not add `i18n-js` configuration or a JS build pipeline.
- Do not migrate or reinterpret Todo priority stored values.

## Code Examples

Recommended model pattern:

```ruby
class Todo < ActiveRecord::Base
  PRIORITY_HIGH = 1
  PRIORITY_NORMAL = 2
  PRIORITY_LOW = 3

  PRIORITY_KEYS = {
    PRIORITY_HIGH => :high,
    PRIORITY_NORMAL => :normal,
    PRIORITY_LOW => :low
  }.freeze

  def self.priority_options
    PRIORITY_KEYS.map { |value, key| [I18n.t("todos.priorities.#{key}"), value] }
  end

  def priority_name
    I18n.t("todos.priorities.#{PRIORITY_KEYS.fetch(priority)}")
  end
end
```

Recommended calendar pattern:

```erb
<span><%= l(@calendar.display_date, format: :calendar_month) %></span>
```

Recommended JS-fed pattern:

```javascript
if (url === '') {
  alert($(button).data('feedUrlRequiredMessage'));
  return;
}
```

## Planning Recommendations

Recommend **5 plans across 4 waves**:

### Wave 1

1. **17-01 Locale catalog + translation primitives**
   - Add locale key skeleton to `ja.yml` and `en.yml`.
   - Add gadget title methods, Todo priority runtime helpers, Calendar weekday/month strategy.
   - Add/adjust focused model/i18n tests.

### Wave 2

2. **17-02 Bookmark feature surface**
   - Translate bookmark index/form/show/edit surfaces and bookmark gadget title.
   - Update bookmark controller/Cucumber assertions for ja/en representative paths.

3. **17-03 Note and Todo feature surfaces**
   - Translate note gadget, todo gadget/actions/form/priority display, and preference default priority select.
   - Update welcome/todo tests and Japanese Cucumber expectations.

These two can run in parallel only if 17-01 has already seeded all needed locale keys. Otherwise, keep them serial to avoid `ja.yml` / `en.yml` conflicts.

### Wave 3

4. **17-04 Feed, Calendar, and JS-visible strings**
   - Translate feed CRUD/form/loading/error copy and `feeds.js` alerts via `data-*`.
   - Translate calendar month/weekdays/loading/actions while preserving holiday names and record titles.
   - Run `yarn run lint` for JS changes.

### Wave 4

5. **17-05 Representative validation and full gate**
   - Ensure ja/en representative Minitest coverage across bookmarks, gadgets, feeds, calendar, JS-fed messages.
   - Run `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`; rerun `dad:test` once if it hits known flakiness.
   - Do not mark Phase 17 complete unless all three suites are green.

## Validation Architecture

### Representative Samples

- Bookmark index in `ja` and `en`: breadcrumb/action labels translated; folder/bookmark titles unchanged.
- Bookmark form in `ja` and `en`: placeholder/help text/submit translated; folder select user-created names unchanged.
- Root dashboard in `ja` and `en`: Bookmark/Todo gadget titles localized; Feed/Calendar record titles unchanged.
- Simple theme note panel in `ja` and `en`: heading/body label/save/empty state translated; note bodies unchanged.
- Todo form/display in `ja` and `en`: priority options/display localized; stored numeric priority values unchanged.
- Feed form in `ja` and `en`: fetch button translated and `data-*` messages present in active locale.
- Feed gadget loading/failure copy in `ja` and `en`: fixed message translated; HTTP status appended unchanged.
- Calendar gadget for a stable date such as 2026-01-01: month/year and weekdays localized; `holiday_jp` holiday name remains Japanese.

### Invariants

- Active `I18n.locale` controls all fixed feature UI copy.
- `ja.yml` and `en.yml` key sets remain equal.
- User-created and external content renders byte-for-byte as stored/fetched.
- Todo priority database values remain numeric and unchanged.
- No `i18n-js` config, no new JS bundling, no global JS translation registry.
- JavaScript-visible prose comes from server-rendered translated values.
- Phase 18 surfaces (Devise/auth/2FA verification sweep) remain out of scope.

### Failure Modes

- `translation missing` output due to lazy lookup namespace mismatch.
- English locale still showing Japanese fixed UI copy from view literals or `Todo::PRIORITIES`.
- Japanese locale losing expected legacy labels and breaking Cucumber steps without intentional test updates.
- Feed JS alerts falling back to hardcoded Japanese because data attribute names do not match jQuery `.data()` reads.
- Calendar tests falsely failing on Japanese holiday names that are intentionally external data.
- Over-translation of bookmark/folder/note/todo/feed/calendar record content.
- `dad:test` failing intermittently from known preference-state leakage rather than Phase 17 behavior.

## Confidence

High for implementation map and architectural direction: all target files listed in Phase context were read, plus related views, JS, tests, Cucumber steps, and codebase convention docs. Medium for exact English wording: final product copy should be chosen during implementation, but namespace and boundary decisions are clear.

