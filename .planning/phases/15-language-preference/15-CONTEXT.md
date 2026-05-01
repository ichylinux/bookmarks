---
phase: 15
phase_name: Language Preference
phase_slug: language-preference
milestone: v1.4
created: 2026-05-01
status: ready-to-plan
---

# Phase 15: Language Preference - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

このフェーズは v1.4 Internationalization の **ユーザ操作レイヤ** を完成させる。Phase 14 が用意した locale 解決パイプライン（saved → Accept-Language → :ja デフォルト、whitelist 二重防御、`<html lang>` 配線）の **書き込み口**（ユーザによる locale 選択 UI）と **読み出し口の対象ページ翻訳**（`/preferences` ページの全面翻訳）を構築する。

このフェーズで届けるのは:

1. **言語セレクタ:** 既存 `/preferences` フォームに「言語」セクションを追加し、3 値（自動 / 日本語 / English）の `<select>` で `Preference#locale` に永続化する。
2. **永続化と再現:** ユーザの選択が DB（`preferences.locale`）に保存され、サインアウト/再ログイン/ブラウザ更新/別セッションでも一貫して再現される（Phase 14 の解決パイプラインを通過する）。
3. **`/preferences` ページの全面翻訳:** PREF-03 を strict 解釈で満たすため、`/preferences` ページが en 表示時に **全面英語化** されるよう、必要な i18n キーを ja.yml / en.yml に追加し、view の hardcode 3 箇所を `t('.xxx')` 化する。
4. **保存後 UX:** `PreferencesController#update` の redirect 先を `root_path` から `preferences_path` に変更し、保存直後に新 locale で同じページが再描画されることを保証する。

このフェーズで **触らない** もの: layout (`app/views/layouts/application.html.erb`)、menu (`app/views/common/_menu.html.erb`)、各 gadget surface（bookmarks/notes/todos/feeds/calendars）、Devise auth pages、flash messages。これらは Phase 16 (Core Shell) / Phase 17 (Feature Surface) / Phase 18 (Auth) の領分。

</domain>

<decisions>
## Implementation Decisions

### Locale Selector Design

- **D-01:** `Preference::LOCALE_OPTIONS` 定数を `app/models/preference.rb` に追加する。値は `{ '自動' => nil, '日本語' => 'ja', 'English' => 'en' }.freeze`。既存 `FONT_SIZE_OPTIONS` 定数パターン（`{ '大' => 'large', ... }`）と完全同形。view では `f.select :locale, Preference::LOCALE_OPTIONS, ...` で参照。

- **D-02:** ラベル文字列はすべて **native 表記固定**（I18n を経由しない）:
  - `'自動'` — 単独の日本語語。en 表示時もそのまま `自動` として残す（混在を許容）。
  - `'日本語'` / `'English'` — 各言語の native 表記。これにより en 表示時もユーザが「日本語」を読めれば ja に戻れるロックアウト耐性を持つ。
  - 領域 1 / 2 で議論し、native 原則を貫く方が「言語セレクタは常に native」という UI 慣習に沿う。`t('.locale_options.ja')` 経由は採用しない。

- **D-03:** select の widget は `<select>`（`f.select`）、`include_blank: false`、`selected: @user.preference.locale`。ラジオボタンは既存 form に前例がない（`f.check_box`/`f.select` の二系統のみ）ため採用しない。`include_blank: false` は明示し、Rails が prompt option を勝手に追加しないようにする。

### nil State Handling

- **D-04:** `nil` は first-class state として **意図的に保持される**。フォームを保存しただけで `nil → 'ja'` への暗黙 upgrade は発生させない。これにより「設定変更に関心がないユーザ（モダンテーマで日本語のままで満足）」は Accept-Language 自動判定の体験を継続できる。

- **D-05:** select で `'自動'` を選んで保存すると、HTTP には `locale=""` が submit される。Controller の strong params 通過後、`presence` で空文字を nil に正規化してから ActiveRecord に渡す:
  ```ruby
  preference_attrs = params[:user][:preference_attributes]
  preference_attrs[:locale] = preference_attrs[:locale].presence if preference_attrs.key?(:locale)
  ```
  `validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true`（Phase 14 で確立）はそのまま機能する — 空文字は inclusion で弾かれない、nil は allow_nil で許容される。

- **D-06:** locale=nil ユーザがフォームを開いたとき、select は `自動` が選択された状態で表示される（`selected: @user.preference.locale` が nil → 値 nil の option が選択状態 = `自動`）。保存ボタンを押しても `locale=""` → nil 正規化で nil のまま、何も変化しない。font_size など別フィールドだけ変更して保存する場合も locale は nil のまま不変。

### Translation Scope

- **D-07:** Phase 15 のスコープは `/preferences` ページ単体の全面翻訳。具体的に:
  - **新規 i18n キー追加先**: `config/locales/ja.yml` および `config/locales/en.yml`
  - **view 修正対象**: `app/views/preferences/index.html.erb` のみ
  - **Phase 16 (Core Shell) のスコープ**: `app/views/layouts/application.html.erb`, `app/views/common/_menu.html.erb`, drawer nav, breadcrumbs, ARIA labels, flash messages — Phase 15 では touch しない
  - **Phase 17 (Feature Surface) のスコープ**: bookmarks/notes/todos/feeds/calendars の各 view と controller — Phase 15 では touch しない
  - **Phase 18 (Auth) のスコープ**: Devise pages, two_factor_authentication / two_factor_setup の翻訳済みキー（既存 ja.yml）の en 対応 — Phase 15 では `two_factor.*` を en.yml にも追加するが、この preferences ページから link されている範囲のみ。Devise pages 本体は Phase 18 が責任を持つ

- **D-08:** 翻訳キー namespace 設計（Rails 標準慣習に整合）:
  - **モデル属性ラベル**（`f.label`）: `activerecord.attributes.preference.{theme,font_size,use_todo,use_note,open_links_in_new_tab,default_priority,locale}`、`activerecord.attributes.user.name`。Phase 15 で **新規追加** = `preference.locale`（ja: `'言語'`、en: `'Language'`）+ `user.name` の en 訳 + 既存 `preference.*` 全 6 キーの en 訳。
  - **ページ固有 hardcode の置き換え** — Phase 15 で導入する新 namespace `preferences`（`/preferences` index ページ用、lazy lookup `t('.xxx')` 対応）:
    - `preferences.theme_options.modern` / `.classic` / `.simple` — theme select の Hash labels（現状 hardcode `'モダン' / 'クラシック' / 'シンプル'`）
    - `preferences.font_size_options.large` / `.medium` / `.small` — font_size select の Hash labels（現状 `Preference::FONT_SIZE_OPTIONS = { '大' => ..., '中' => ..., '小' => ... }` の key 部分。**ただし定数の Hash key を I18n 経由に切り替えると `font_size_class` helper や他参照箇所への影響が出る可能性があるので、Plan 段階で「定数を残しつつ view 側で `Preference::FONT_SIZE_OPTIONS.transform_keys { ... }` 的に翻訳対応するか、それとも view 側で素直に `t` を使った Hash を組み立てるか」を決定する**）
    - `preferences.submit` — `f.submit` のラベル（現状 hardcode `'保存'`）
  - **既存 `two_factor.*` namespace**: Phase 15 で en 訳を追加（既存 ja キーの英訳を ja.yml と同じ構造で en.yml にミラー追加）

- **D-09:** Phase 15 で翻訳しない `font_size` 表示部の取扱いは Plan で詰める。現状 `Preference::FONT_SIZE_OPTIONS = { '大' => 'large', '中' => 'medium', '小' => 'small' }` は **データモデル定数** であり、`app/views/preferences/index.html.erb` の select 表示にも使われている。Phase 15 の選択肢:
  - (a) 定数の hash key を `Preference::FONT_SIZE_OPTIONS = ['large','medium','small']` に変更し、view 側で `{ t('preferences.font_size_options.large') => 'large', ... }` を組み立てる
  - (b) 定数はそのまま、view 側で `Preference::FONT_SIZE_OPTIONS.transform_keys { |k| ... }` でビュー時翻訳
  - (c) 定数を `{ large: 'large', ... }` の inverted form に変更して view で `t` キーに変換
  - 推奨は (a) — 定数の責務を「サポート値の列挙」に絞り、表示文言は完全に view/i18n 層に分離する。Plan 段階で決定。

### Persistence Verification (PREF-02)

- **D-10:** PREF-02（"persists across sign-out, sign-in, browser refresh, and future sessions"）は Phase 14 の DB 永続化機構と Localization concern によって **基盤側で既に達成済み**。Phase 15 の責務は:
  - フォームから保存される値が確実に DB に書かれる（Minitest 統合テストで sign_in → patch → reload で値確認）
  - sign_out → sign_in しても再現する（Minitest 統合テストで sign_in → patch → sign_out → sign_in → get で値確認）
  - 保存後リロード（GET `/preferences`）でセレクタが新しい値で表示される

  追加の永続化機構（Cookie / セッション / Redis 等）は **不要**。既存 Devise 認証セッションと `current_user.preference.locale` の DB 値だけで完結する。

### Post-Save Redirect

- **D-11:** `PreferencesController#update` の最後の `redirect_to root_path` を `redirect_to preferences_path` に変更する。**locale 変更時に限らず一律変更**。理由:
  - PREF-03（"User sees the preferences page itself translated after changing language"）の strict 解釈を満たす — 保存 → redirect → GET `/preferences` で `around_action :set_locale` が新 locale で走る → 同じページが新 locale でレンダリング
  - locale だけ条件分岐すると controller のロジックが太る + テスト組み合わせが増える。一律変更が最小複雑度
  - Form 慣習として「保存後はリソースの自身に戻る」は Rails の標準（Gmail / GitHub / Twitter 等の設定保存後 UX とも一致）
  - 既存ユーザ体験への破壊性は小（drawer/menu の Home リンクで一手間で home に戻れる）

- **D-12:** 既存テスト 3 件（`test_更新`, `test_open_links_in_new_tabを保存する`, `test_文字サイズを保存する`）の `assert_equal '/', path` を `assert_equal '/preferences', path` に書き換える。動作仕様は変わらず、redirect 先 URL の expected のみ更新。

### Test Coverage (Claude's Discretion)

- **D-13:** テスト方針（既存 Phase 14 の規約と Phase 13 の Note Gadget 経験を踏襲）:
  - 主役: Minitest 統合テスト `test/controllers/preferences_controller_test.rb` の拡張（既存ファイルに test メソッドを追加、新規ファイルは作らない）
  - 新規テスト想定（Plan で詰める。**既存テストの redirect 先 URL の更新は D-12 の通り別件**）:
    1. `test_言語セレクタを表示する` — locale select が DOM に存在し、3 option (自動 / 日本語 / English) を含む
    2. `test_localeをjaに更新できる` — patch with locale=ja → reload で 'ja'
    3. `test_localeをenに更新できる` — patch with locale=en → reload で 'en'
    4. `test_localeをnilに戻せる` — locale='ja' から patch with locale='' → reload で nil
    5. `test_保存後preferences_pathにリダイレクトされる` — patch any → assert_redirected_to preferences_path（新仕様の証明）
    6. `test_設定画面が日本語ロケールで日本語表示される` — locale=ja, get → `<html lang='ja'>` + 「テーマ」「保存」など日本語ラベル assertion（PREF-03 evidence）
    7. `test_設定画面が英語ロケールで英語表示される` — locale=en, get → `<html lang='en'>` + Theme / Save など英語ラベル assertion（PREF-03 evidence）
    8. `test_localeはサインアウト後も保持される` — sign_in → patch locale=en → sign_out → sign_in → get `/preferences` → select で en が selected（PREF-02 evidence）
  - Cucumber は追加しない — Phase 14 で deferred to Phase 18 とした方針を継続。`/preferences` の動作は Minitest 統合テストで完全に検証可能（jQuery などクライアント側挙動なし、純粋な server-rendered form）

- **D-14:** 既存 PreferencesControllerTest にある 6 つの test（test_更新 / test_open_links_in_new_tabを保存する / test_文字サイズを保存する / test_設定画面に文字サイズ選択肢を表示する / test_文字サイズのbodyクラスを描画する / test_文字サイズ未設定ならbodyクラスはmediumにフォールバックする）は既存挙動の検証として残す。D-12 で redirect 先 URL の更新だけ行う。

### Schema (No Migration Needed)

- **D-15:** Phase 15 で **DB マイグレーションは不要**。`preferences.locale` 列は Phase 14 の migration `20260501020618_add_locale_to_preferences.rb` で既に追加済み。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements

- `.planning/REQUIREMENTS.md` — PREF-01, PREF-02, PREF-03 の文面、v1.4 全体スコープ、Out of Scope (URL ベースルート、`accept-language` gem 等)
- `.planning/ROADMAP.md` — Phase 15 ゴール、成功基準 4 項目、Phase 16/17/18 の境界
- `.planning/PROJECT.md` — v1.4 ゴール、Active Requirements、Key Decisions（Phase 14 累積 4 件含む）
- `.planning/STATE.md` — v1.4 進捗、Phase 14 完了アーティファクト、累積 Critical Pitfalls

### Prior Phase Alignment（Phase 15 が直接依存）

- `.planning/phases/14-locale-infrastructure/14-CONTEXT.md` — D-01..D-04（locale 永続化先 / nil first-class / SUPPORTED_LOCALES 定数 / 解決パイプライン二重防御）
- `.planning/phases/14-locale-infrastructure/14-01-SUMMARY.md` — Plan 14-01 で確定した永続化レイヤ（migration / SUPPORTED_LOCALES / inclusion validation / available_locales）
- `.planning/phases/14-locale-infrastructure/14-02-SUMMARY.md` — Localization concern の private method 名・public 挙動（around_action / resolved_locale / saved_locale / accept_language_match / parse_accept_language）
- `.planning/phases/14-locale-infrastructure/14-VERIFICATION.md` — Phase 14 で証明された I18N-01..04, VERI18N-01 の must-haves と検証経路

### Code and Assets to Modify or Reference

- `app/models/preference.rb` — `LOCALE_OPTIONS` 定数追加、既存 `FONT_SIZE_OPTIONS` パターン参照。`SUPPORTED_LOCALES` は Phase 14 で確立済み（再定義しない）
- `app/controllers/preferences_controller.rb` — `user_params` の `preference_attributes` に `:locale` を追加、空文字 → nil 正規化処理を追加、`redirect_to root_path` を `redirect_to preferences_path` に変更
- `app/views/preferences/index.html.erb` — locale select セクション追加、theme select Hash の `t` 化、font_size select の D-09 案 (a) 適用、`f.submit '保存'` の `t` 化、`f.label :font_size, '文字サイズ'` の override 削除（モデル属性翻訳に依存）
- `config/locales/ja.yml` — `activerecord.attributes.preference.locale: '言語'` 追加、`preferences.theme_options.{modern,classic,simple}`、`preferences.font_size_options.{large,medium,small}`、`preferences.submit: '保存'` 追加
- `config/locales/en.yml` — `activerecord.attributes.preference.{theme,font_size,use_todo,use_note,open_links_in_new_tab,default_priority,locale}`、`activerecord.attributes.user.name`、`two_factor.*`（既存 ja.yml と対応）、`preferences.theme_options.{modern,classic,simple}: 'Modern' / 'Classic' / 'Simple'`、`preferences.font_size_options.{large,medium,small}: 'Large' / 'Medium' / 'Small'`、`preferences.submit: 'Save'`
- `test/controllers/preferences_controller_test.rb` — 既存 6 test の redirect 先 URL 更新 (D-12) + 新規 8 test 追加 (D-13)

### Coding Conventions and Patterns

- `.planning/codebase/CONVENTIONS.md` — 2 スペースインデント、シングルクォート、`private` キーワード分離、コメント・テストメソッド名は日本語、定数 SCREAMING_SNAKE_CASE
- `.planning/codebase/TESTING.md` — Minitest + 日本語メソッド名、`assert_select` で HTML 構造、Devise test helpers (`sign_in user`)、support helpers
- `.planning/codebase/STACK.md` — Rails 8.1 / Ruby 3.4 / Sprockets / `rails-i18n 8.1.0` / `devise-i18n 1.16.0`（`devise-i18n` は Phase 18 まで実質未使用）

### External Specs

外部仕様文書なし。Rails 公式 i18n ガイド（lazy lookup と `activerecord.attributes.*` 慣習）が参考だが特に逸脱なし。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Preference::FONT_SIZE_OPTIONS` 定数パターン**: `{ '大' => 'large', '中' => 'medium', '小' => 'small' }.freeze` 形式の Hash 定数を view の `f.select` に直接渡す。`LOCALE_OPTIONS` も同形でゼロ反復で書ける。
- **`PreferencesController#user_params` の strong params 構造**: `preference_attributes: [:id, :theme, :font_size, ...]` の配列に `:locale` を 1 行追加するだけで permission 拡張完了。既存パターン（`open_links_in_new_tab` 追加時と同形）。
- **既存 form の `f.select` パターン**: `f.select :font_size, Preference::FONT_SIZE_OPTIONS, selected: ...` の hash 直渡し + `selected:` オプション。locale も完全同形で書ける。
- **`f.fields_for :preference_attributes` の入れ子フォーム**: `accepts_nested_attributes_for` 関連の wiring が既に動作しており、locale を入れ子で送信する経路が確立。
- **Minitest 統合テスト規約**: `test/controllers/preferences_controller_test.rb` に 6 test の前例。`test/support/users.rb` の `def user; @_user ||= User.first; end` ヘルパで Devise test helpers と組み合わせて使う。`assert_select 'html[lang=?]', 'ja'` は Phase 14 で確立済み。
- **Devise integration helpers**: `test/test_helper.rb` で `Devise::Test::IntegrationHelpers` が `ActionDispatch::IntegrationTest` に include 済み — `sign_in user` / `sign_out` 両方使える。

### Established Patterns

- **薄いコントローラ + 入れ子 form**: `PreferencesController` は `User.find` → `attributes=` → `transaction { save! }` → `redirect_to` の極薄 5 行パターン。Phase 15 もこの厚さを維持する（特殊ロジック追加せず、strong params 拡張と redirect 先のみ変更）。
- **Hash select でラベルと値を同居**: `{ '日本語' => 'ja' }` のような「label => value」Hash を view 直書きで select に渡す前例あり（`theme`）。
- **設定画面の i18n 部分採用**: `app/views/preferences/index.html.erb` は既に `t('two_factor.section_title')` 等で `t` 呼び出しが入っている — Phase 15 で他の hardcode を `t` 化する際の一貫性が保てる。
- **テストメソッド名は日本語**: `def test_更新`, `def test_文字サイズを保存する` 等。Phase 15 でも同規約。

### Integration Points

- **Phase 14 の Localization concern**: `around_action :set_locale` が既に全リクエストに適用されている。Phase 15 で `redirect_to preferences_path` した後の GET でも当然動作 → 新 locale で render される。追加配線は不要。
- **`<html lang>` 配線**: `app/views/layouts/application.html.erb` line 2 が既に `<html lang="<%= I18n.locale %>">` で、`I18n.locale` は around_action が解決した値を持つ。Phase 15 のテストでも `assert_select 'html[lang=?]', 'en'` が Phase 14 と同じ経路で動く。
- **Whitelist 二重防御**: `Preference#locale = 'fr'` は Phase 14 の `validates :locale, inclusion: ..., allow_nil: true` で reject される。フォームから submit される値は `''` / `'ja'` / `'en'` のみなので、悪意ある入力でも model 検証を通過しない。

### Caveats and Gotchas

- **Rails の `f.select` で `nil` 値を持つ option**: Rails view helper は `nil` 値の option を `<option value="">...</option>` でレンダリングする。HTTP 経由では空文字 `""` で来るので、controller 側で `presence` で nil 化する必要がある（D-05）。これを忘れると `'' is not included in the list ['ja', 'en']` の inclusion validation エラーが出る。
- **`include_blank: false` を明示**: Rails の `f.select` はデフォルトで `include_blank: false` だが、明示しておくことで Rails が prompt option を勝手に追加する挙動（一部バージョンや helper combination で発生）を防ぐ。
- **`assert_select 'option', text: 'モダン'` の HTML エンティティ**: 全角 / 半角 / Unicode 文字の比較は通常通りだが、ja.yml の値に `&` 等が含まれる場合は注意。今回は対象外。
- **`f.label :font_size, '文字サイズ'` の override 問題**: 現状 view では override が入っているため、`activerecord.attributes.preference.font_size: '文字サイズ'` を ja.yml に追加しても効かない（override が優先）。Phase 15 で override を削除して、ja.yml / en.yml の翻訳に統一する。

### What Phase 14 Already Took Care Of

Phase 15 plan 設計時に **再考しなくていい** こと（Phase 14 で確定済み）:

- `preferences.locale` 列の存在・型・null 許容性
- `Preference::SUPPORTED_LOCALES` の値域 (`%w[ja en]`)
- `validates :locale, inclusion:, allow_nil: true` の検証
- `I18n.available_locales = %i[ja en]` の boot config
- `Localization` concern の解決パイプライン
- `ApplicationController` への `include Localization` 配線
- `<html lang>` の I18n.locale 派生
- VERI18N-01 の 4 経路自動テスト

</code_context>

<specifics>
## Specific Decisions Captured From This Session

ユーザは 4 つの gray area すべてを掘り下げ、各領域で次の選択をした:

- **領域 1（セレクタの形）**: `Preference::LOCALE_OPTIONS` 定数として model に置く `<select>` + native ラベル（D-01, D-02, D-03）
- **領域 2（nil 取扱い）**: 領域 2 の最初の選択（"nil を隠す"）から議論を経て、**3 値 select で `自動` ラベルを露出する方針に修正**。動機は「設定変更に関心がないユーザにアプリの提案するデフォルト体験を提供し続けたい」（D-04..D-06）。`自動` の単独表記は en 表示時もそのまま、`日本語` / `English` の native 表記でロックアウト耐性は確保
- **領域 3（翻訳範囲）**: `/preferences` ページ単体の全面翻訳。Phase 16/17/18 の境界を厳守（D-07, D-08, D-09）
- **領域 4（保存後 redirect）**: `redirect_to preferences_path` に一律変更、locale だけ条件分岐はしない（D-11, D-12）

ユーザが Claude 裁量に委ねた領域:
- テスト層（Cucumber 不採用、Minitest 統合テストのみ）— D-13
- i18n キー namespace 設計（Rails 標準 lazy lookup 踏襲）— D-08
- DB マイグレーション要否（不要、Phase 14 で完了済み）— D-15

</specifics>

<deferred>
## Deferred Ideas

- **Locale 切替時の確認モーダル**: 「英語に切り替えますか？」のような確認 UI は Phase 15 では入れない。フォーム save 即適用のシンプルさを維持。Phase 15 完了後の retrospective でユーザ体験を見て判断。
- **Locale 別の Cucumber feature**: Phase 14 と同様、Phase 18 にまとめて配置（VERI18N-02 で代表 ja/en 経路を覆う）。Phase 15 では Minitest 統合テストで完結。
- **`?locale=` URL パラメータ経路**: Phase 14 D-04 で deferred とした方針を継続。Phase 15 でも追加しない。
- **`accept-language` gem 導入 (I18NTOOL-02)**: 自前パーサで Phase 14 から動作中。継続。
- **`i18n-tasks` gem 導入 (I18NTOOL-01)**: 翻訳キーの自動監査ツール。Phase 15 のキー追加量（~30 keys 程度）では手動監査で十分。Phase 16/17 で大量にキーが増えた段階で再検討。
- **Locale 切替時の flash メッセージ**: 「言語を変更しました」のようなフィードバック。Phase 15 では追加しない（redirect 先で同じページが新 locale で見えるのが最良の feedback）。Phase 16 で flash messages 全体翻訳の一部として扱う方が自然。

### Reviewed Todos (not folded)

Phase 13 で fold 済の 2 件（`2026-04-30-extract-drawer-ui-helper.md`, `2026-04-30-gate-drawer-blocks-on-theme.md`）は drawer 関連で Phase 15 とスコープ外。todos クリーンアップとして別途扱う。

`2026-05-01-model-class-inherit-applicationrecord.md`（notes ディレクトリ）は v1.4 全体のリファクタリング ToDo で Phase 15 とは独立。Phase 15 では fold しない。

</deferred>

---

*Phase: 15-language-preference*
*Context gathered: 2026-05-01*
