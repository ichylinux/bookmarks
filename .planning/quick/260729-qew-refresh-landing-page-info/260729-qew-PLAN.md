---
phase: quick-260729-qew
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - config/locales/en.yml
  - config/locales/ja.yml
  - test/controllers/welcome_controller/root_path_test.rb
autonomous: true
requirements: [LANDING-CHANGELOG-REFRESH]

must_haves:
  truths:
    - "Guest landing changelog announces the feed gadget settings dialog (2026-07-29)"
    - "Guest landing changelog announces the sticky Simple-theme header (2026-07-18)"
    - "Guest landing changelog announces mobile bookmark add via header tap (2026-07-16)"
    - "Guest landing changelog announces mobile task add via header tap (2026-06-27)"
    - "Guest landing changelog records the gadget-header tap/drag fix and the mobile add-button-after-complete fix"
    - "en.yml and ja.yml landing.changelog.entries stay key-for-key and date/tag-for-date/tag in sync"
    - "root_path_test asserts a headline that is still inside the helper's 10-entry cap"
    - "bin/rails test is green"
  artifacts:
    - path: "config/locales/en.yml"
      provides: "English landing changelog with 6 new entries"
      contains: "2026-07-29"
    - path: "config/locales/ja.yml"
      provides: "Japanese landing changelog with 6 new entries"
      contains: "2026-07-29"
    - path: "test/controllers/welcome_controller/root_path_test.rb"
      provides: "Newest-headline assertion pointing at the current top entry"
      contains: "フィードガジェットの設定をダッシュボードから変更できるようになりました"
  key_links:
    - from: "config/locales/en.yml landing.changelog.entries"
      to: "config/locales/ja.yml landing.changelog.entries"
      via: "identical date/tag pair per entry in identical order, translated headline/description"
      pattern: "2026-07-29|2026-07-27|2026-07-18|2026-07-16|2026-07-10|2026-06-27"
    - from: "app/helpers/application_helper.rb changelog_entries (.first(10) cap)"
      to: "test/controllers/welcome_controller/root_path_test.rb newest-headline assertion"
      via: "adding 6 entries pushes the 2026-06-09 entry out of the rendered top 10"
      pattern: "強調表示"
---

<objective>
Refresh the guest landing page changelog so it reflects everything user-facing that shipped since the last refresh (newest entry is currently 2026-06-25). CONTENT-ONLY for the locales: edit only `landing.changelog.entries` in `config/locales/en.yml` and `config/locales/ja.yml`. Do NOT touch `_landing.html.erb` markup, `landing.css.scss`, or any `landing-*` class.

One test change is REQUIRED, not optional: `changelog_entries` caps output at 10 (`app/helpers/application_helper.rb`), and `root_path_test` currently asserts the 2026-06-09 headline, which sits at position 8 today. Adding 6 entries pushes it to position 14, out of the rendered set — so `test_日本語ロケールで最新changelog見出しが表示される` must be re-pointed at the new top entry.

Purpose: five weeks of shipped work (feed gadget settings dialog, sticky Simple-theme header, mobile bookmark/task header-tap add, two gadget-header interaction fixes) is invisible to guests.
Output: 6 new entries mirrored across both locales + one updated assertion.

Tracer-first is not applicable here: this is a single-layer content change (locale YAML consumed by an existing, unmodified helper and view). There is no cross-layer path to prove.
</objective>

<execution_context>
@$HOME/.cursor/gsd-core/workflows/execute-plan.md
@$HOME/.cursor/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

# Helper that sorts and caps the entries at 10 (DO NOT MODIFY — reference only)
@app/helpers/application_helper.rb

# View that renders the entries (DO NOT MODIFY — reference only)
@app/views/welcome/_landing.html.erb

# Locale files to edit — `landing:` starts at line 362, `entries:` at line 412 in BOTH files
@config/locales/en.yml
@config/locales/ja.yml

# Test to re-point
@test/controllers/welcome_controller/root_path_test.rb
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add 6 changelog entries to en.yml</name>
  <files>config/locales/en.yml</files>
  <action>
In `config/locales/en.yml`, locate `landing.changelog.entries` (the `entries:` key is at line 412; the first list item is the `2026-06-25` entry at line 413). Insert the following SIX entries as the first items in the sequence, immediately before the existing `2026-06-25` entry, newest-first in the order given below.

Preserve the exact surrounding indentation: list items are indented 8 spaces (`        - date:`), child keys 10 spaces. Each entry has exactly these four keys in this order: `date`, `headline`, `tag`, `description`. Each `date` value MUST be a double-quoted string in "YYYY-MM-DD" form, matching existing entries. Use only the existing tag vocabulary (`ux`, `fix`, `performance`, `new`). Match the marketing tone of the existing entries. Do not modify any other `landing.*` key in this task — hero/values/integrations copy stays as-is.

Entry 1 (date "2026-07-29", tag new):
  headline: Edit feed gadget settings from your dashboard
  description: The feed gadget header now has a settings button. Open the dialog to update the feed URL, site name, and how many items to show — all without leaving the dashboard.

Entry 2 (date "2026-07-27", tag fix):
  headline: Fixed gadget header links being swallowed by drag and swipe
  description: Site name links and header action buttons sometimes failed to respond because a reorder drag or column swipe consumed the tap. Gadget header links now react reliably on both desktop and mobile.

Entry 3 (date "2026-07-18", tag ux):
  headline: The navigation header now stays put while you scroll
  description: On the Simple theme, the navigation header sticks to the top of the screen, so Home and Notes stay one click away no matter how far down the page you are.

Entry 4 (date "2026-07-16", tag ux):
  headline: Add bookmarks from the gadget header on mobile
  description: Tap a bookmark gadget header on your smartphone to reveal the add button — the same gesture already available in the task gadget.

Entry 5 (date "2026-07-10", tag fix):
  headline: Fixed the add button lingering after completing tasks on mobile
  description: After marking tasks complete on a smartphone, a leftover touch state could keep the add button visible in the task gadget header. It now hides as expected.

Entry 6 (date "2026-06-27", tag ux):
  headline: Add tasks from the gadget header on mobile
  description: Tap a task gadget header on your smartphone to reveal the add button and create a task without leaving the dashboard.
  </action>
  <verify>
    <automated>bin/rails runner "e=I18n.t('landing.changelog.entries', locale: :en); d=e.map{|x| x[:date]}; miss=%w[2026-07-29 2026-07-27 2026-07-18 2026-07-16 2026-07-10 2026-06-27]-d; raise miss.inspect if miss.any?; e.each{|x| raise x.inspect unless x.keys.sort==[:date,:description,:headline,:tag]}; raise 'top' unless d.max=='2026-07-29'; puts 'EN OK'"</automated>
  </verify>
  <done>en.yml parses; all six new dates are present under landing.changelog.entries with the four required keys; 2026-07-29 is the newest date.</done>
</task>

<task type="auto">
  <name>Task 2: Mirror the 6 entries into ja.yml (default locale)</name>
  <files>config/locales/ja.yml</files>
  <action>
In `config/locales/ja.yml`, locate `landing.changelog.entries` (`entries:` at line 412; first list item is the `2026-06-25` entry at line 413). Insert the SAME SIX entries in the SAME order and the SAME position (immediately before the `2026-06-25` entry), with IDENTICAL `date` and `tag` values as en.yml, but Japanese `headline` and `description`. Preserve the 8-space/10-space indentation of surrounding items. `ja` is the default, user-visible locale — the copy must read naturally and match the tone of the existing Japanese entries.

Entry 1 (date "2026-07-29", tag new):
  headline: フィードガジェットの設定をダッシュボードから変更できるようになりました
  description: フィードガジェットのヘッダーに設定ボタンが加わりました。ダイアログからフィードURL・サイト名・表示件数を、ダッシュボードを離れずに変更できます。

Entry 2 (date "2026-07-27", tag fix):
  headline: ガジェットヘッダのリンクがドラッグやスワイプに吸われる不具合を修正しました
  description: ガジェットのサイト名リンクやヘッダーの操作ボタンが、並べ替えドラッグや列スワイプに吸われて反応しない場合がある不具合を修正しました。パソコンでもスマートフォンでも確実に反応します。

Entry 3 (date "2026-07-18", tag ux):
  headline: シンプルテーマのヘッダーがスクロール中も表示されたままになりました
  description: シンプルテーマで、ナビゲーションヘッダーが画面上部に固定表示されるようになりました。どこまでスクロールしても「ホーム」や「ノート」にすぐ移動できます。

Entry 4 (date "2026-07-16", tag ux):
  headline: スマートフォンでブックマークガジェットのヘッダーをタップして追加できるようになりました
  description: スマートフォンでブックマークガジェットのヘッダーをタップすると追加ボタンが表示されるようになりました。タスクガジェットと同じ操作でブックマークを追加できます。

Entry 5 (date "2026-07-10", tag fix):
  headline: モバイルでタスクを完了した直後に追加ボタンが表示される不具合を修正しました
  description: スマートフォンでタスクを完了した後、タッチ操作の残留によって追加ボタンがヘッダーに表示されたままになる不具合を修正しました。

Entry 6 (date "2026-06-27", tag ux):
  headline: スマートフォンでタスクガジェットのヘッダーをタップして追加できるようになりました
  description: スマートフォンでタスクガジェットのヘッダーをタップすると追加ボタンが表示され、ダッシュボードを離れずにタスクを追加できるようになりました。

Confirm each entry's key set (date, headline, tag, description) matches en.yml key-for-key, and that the (date, tag) sequence is positionally identical between the two files. Do not modify any other `landing.*` key.
  </action>
  <verify>
    <automated>bin/rails runner "ja=I18n.t('landing.changelog.entries', locale: :ja); en=I18n.t('landing.changelog.entries', locale: :en); raise 'count' unless ja.size==en.size; raise 'pairs' unless ja.map{|x| [x[:date],x[:tag].to_s]}==en.map{|x| [x[:date],x[:tag].to_s]}; ja.each{|x| raise x.inspect unless x.keys.sort==[:date,:description,:headline,:tag]}; raise 'top' unless ja.map{|x| x[:date]}.max=='2026-07-29'; puts 'JA OK'"</automated>
  </verify>
  <done>ja.yml parses; entry count equals en.yml; the positional (date, tag) sequence is identical across locales; every entry has the four required keys; 2026-07-29 is the newest date.</done>
</task>

<task type="auto">
  <name>Task 3: Re-point the newest-headline assertion and run the gates</name>
  <files>test/controllers/welcome_controller/root_path_test.rb</files>
  <action>
In `test/controllers/welcome_controller/root_path_test.rb`, the test `test_日本語ロケールで最新changelog見出しが表示される` (around line 73) asserts the 2026-06-09 headline about highlighting tasks. Because `changelog_entries` renders only the newest 10 entries, that headline is no longer rendered after Task 1 and Task 2. Replace the asserted string with the new top entry's Japanese headline from Task 2 Entry 1 — the feed gadget settings headline — keeping the surrounding `get root_path` / `assert_response :success` / `assert_includes response.body, ...` structure and the existing method name unchanged. Change nothing else in this file.

Then run the gates. This change is YAML + Ruby test only, so `bin/rails test` is the meaningful suite; `yarn run lint` (ESLint) is cheap and should stay green. `bundle exec rake dad:test` is not required for this task — no Cucumber feature references landing changelog copy (verified: no matches for the changelog heading or entry text under `features/`). If the sort/cap assumption turns out wrong and the 2026-06-09 headline is still rendered, revert this assertion change rather than adding entries to compensate.
  </action>
  <verify>
    <automated>bin/rails test test/controllers/welcome_controller/root_path_test.rb test/helpers/application_helper_test.rb test/i18n/changelog_i18n_test.rb && yarn run lint && bin/rails test 2>&1 | tail -5</automated>
  </verify>
  <done>The landing/changelog focused tests pass, `yarn run lint` is green, and the full `bin/rails test` run reports 0 failures and 0 errors.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| server→guest browser | Locale copy is rendered into the unauthenticated landing page |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260729-qew-01 | Information Disclosure | `landing.changelog.entries` rendered to guests | low | mitigate | Entry copy describes shipped user-facing behavior only — no internal paths, commit SHAs, infrastructure details, or unreleased work |
| T-260729-qew-02 | Tampering | `_landing.html.erb` escaping of entry text | low | accept | Entries render through ERB `<%= %>` auto-escaping; the plan adds plain text with no HTML markup and does not touch the view |
</threat_model>

<verification>
- Both locale files parse with no YAML syntax or indentation errors.
- `landing.changelog.entries` has equal length in en.yml and ja.yml, with a positionally identical (date, tag) sequence.
- All six new dates appear in both locales: 2026-07-29 (new), 2026-07-27 (fix), 2026-07-18 (ux), 2026-07-16 (ux), 2026-07-10 (fix), 2026-06-27 (ux).
- `changelog_entries` returns the 2026-07-29 entry first and at most 10 entries.
- `root_path_test` asserts a headline that is actually rendered.
- `yarn run lint` green; `bin/rails test` green (0 failures, 0 errors).
</verification>

<success_criteria>
- The guest landing changelog announces the feed gadget settings dialog, the sticky Simple-theme header, mobile bookmark and task header-tap add, and the two gadget-header interaction fixes.
- en.yml and ja.yml stay key-for-key in sync with natural translated copy.
- No markup, CSS, or `landing-*` class changes; locale edits confined to `landing.changelog.entries`.
- Minitest and ESLint are green.
</success_criteria>

<output>
Create `.planning/quick/260729-qew-refresh-landing-page-info/260729-qew-SUMMARY.md` when done.
</output>
