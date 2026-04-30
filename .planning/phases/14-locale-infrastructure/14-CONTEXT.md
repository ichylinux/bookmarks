---
phase: 14
phase_name: Locale Infrastructure
phase_slug: locale-infrastructure
milestone: v1.4
created: 2026-05-01
status: ready-to-plan
---

# Phase 14: Locale Infrastructure - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

このフェーズは v1.4 (Internationalization) の **基盤レイヤ** を整える。実 UI 文字列の翻訳キー追加 (Phase 16〜17) や `/preferences` 言語スイッチャ UI (Phase 15)、Devise/2FA 翻訳 (Phase 18) は **対象外**。

このフェーズで届けるのは:

1. **永続化:** `Preference` モデルに `locale` 列を追加し、`Preference::SUPPORTED_LOCALES = %w[ja en].freeze` で値域を制約する。
2. **解決:** すべてのコントローラ応答が「**保存済み Preference#locale → Accept-Language の許可リスト一致 → 日本語フォールバック**」の順で `I18n.locale` を確定する。
3. **多重防御:** どの段階でもホワイトリスト外の入力 (リクエストヘッダ・stale な DB 値・将来の許可リスト縮小) は黙ってフォールスルーし、I18n が `enforce_available_locales` 例外を投げないことを保証する。
4. **アクセシビリティ:** レンダリングされたページの `<html lang>` が実際に使われた locale と一致する。
5. **テスト:** VERI18N-01 (ユーザ向けテスト 4 経路: 保存済み・Accept-Language・無効値フォールバック・デフォルト :ja) を満たす Minitest 統合テストを追加する。

このフェーズではまだ「UI 文字列を `t('...')` 化する作業」は行わない。`<html lang>` 切替と locale 解決の経路が動くことが完了条件であり、ユーザに見える文言の変化は Phase 16 以降。

</domain>

<decisions>
## Implementation Decisions

### Locale Persistence

- **D-01:** `locale` 列は **`preferences` テーブル** に追加する (`users` テーブルではなく)。既存の per-user UI 嗜好 (`theme` / `font_size` / `use_note` / `open_links_in_new_tab` / `default_priority`) はすべて `Preference` モデルに集約されており、その不変則を `locale` でも保つ。Phase 15 の `/preferences` 切替 UI は `PreferencesController#preference_params` に `:locale` を追加するだけで成立し、既存パターン (`open_links_in_new_tab` 追加時と同形) と直交する。**PROJECT.md の言い回し ("`users` テーブルに `locale` カラムを追加") は Phase 14 のコミットで `preferences` テーブル表現に更新する。**

- **D-02:** マイグレーションは `add_column :preferences, :locale, :string, null: true` (DB デフォルトなし)。`nil` = 「ユーザは locale を未指定」のサイン状態として一級扱いし、解決パイプラインで Accept-Language 段にフォールスルーさせる。既存 Preference 行のバックフィルは行わない (NULL のまま) — 既存ユーザは次回アクセス時にブラウザ言語が尊重される。`Preference.default_preference` も `locale = nil` のまま追加変更しない (新規ユーザも未指定で作成され Accept-Language 検出が効く)。

- **D-03:** `Preference::SUPPORTED_LOCALES = %w[ja en].freeze` を **真実の源** として定義し、モデルに `validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true` を追加する (既存の `validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true` と同形)。`config/application.rb` の I18n 設定はこの定数から派生させる:
  ```ruby
  config.i18n.available_locales = Preference::SUPPORTED_LOCALES.map(&:to_sym)
  config.i18n.default_locale = :ja  # 既存のまま
  ```
  値域を 1 箇所変更すればモデル検証・I18n 構成・解決ロジックすべてに反映される。

### Locale Resolution

- **D-04:** 解決ロジックは **同形パイプライン** で実装する: `[saved_locale, accept_language_match].each do |candidate| return candidate.to_sym if candidate && Preference::SUPPORTED_LOCALES.include?(candidate.to_s) end; I18n.default_locale`。各段で「候補を出す → ホワイトリスト検査 → 通れば採用、通らなければ次段」を一律に適用する。これにより I18N-03 (「保存データから不正値を強制できないこと」) が **書き込み時のモデル検証** に加えて **読み出し時の解決パイプライン** でも防御され、stale な DB 値・手動 SQL・将来の SUPPORTED_LOCALES 縮小に対して resilient になる。`enforce_available_locales = true` のもとで I18n が例外を投げる経路を実質ゼロにする。Rails.logger は出さず黙ってフォールスルー (個人 Web アプリスケールでは過剰)。

### Claude's Discretion

ユーザは領域 1 のみを明示議論し、残り 3 領域は Claude 裁量に委ねた。プランナはこのセクションの推奨を**強い既定**として扱い、必然的に逸脱する場合のみ PLAN.md で根拠を述べること。

#### Resolution Code Structure (領域 2 — 推奨)

`set_locale` ロジックは **専用 concern (`app/controllers/concerns/localization.rb`) に切り出し**、`ApplicationController` で `include Localization` + `before_action :set_locale` する形を推奨。

理由:
- 既存プロジェクトに `app/models/concerns/crud/by_user.rb` の前例があり、薄い横断的関心事を concern にまとめるパターンが確立している。
- Phase 18 で `Devise::SessionsController` などを (必要なら) サブクラス化して同じロジックを再利用する際、concern なら 1 行 include で済む。
- テスト時に concern 単体を ActionController::Base のミニテスト用クラスに include して挙動を切り出して検証できる。
- 解決パイプラインのプライベートヘルパ (`saved_locale`, `accept_language_match`) も concern 内に同居させ、`ApplicationController` を肥大させない。
- `<html lang>` レンダリング用のヘルパ (例: `current_locale_lang_attr`) もこの concern またはその helper 対 (`ApplicationHelper` など) で提供する。

却下理由:
- ApplicationController 直書きは将来の Devise/2FA 拡張時に重複を招く。
- 専用モジュール+ヘルパの組み合わせは現プロジェクトに前例なし。

#### Accept-Language Parsing (領域 3 — 推奨)

`Rails::Request#accept_language` などの組み込みは Rails 8.1 では信頼できる単一 API として提供されていないため、**自前で q-value 順を尊重した最小パーサ** を `Localization` concern 内に private method として実装することを推奨。`accept-language` gem は導入しない (REQUIREMENTS Out of Scope: I18NTOOL-02 に deferred)。

実装の輪郭:
- `request.env['HTTP_ACCEPT_LANGUAGE']` を読み、`,` で分割。
- 各エントリを `tag;q=value` の形でパースし、欠落時は `q=1.0` とみなす。
- q 値で降順ソート、各タグから先頭の 2 文字 (`ja-JP` → `ja`) を取り出して順に `SUPPORTED_LOCALES.include?` で検査。
- 最初にマッチしたものを返す。マッチなしなら `nil` を返して上位パイプラインに次段委譲。
- 失敗時 (header 欠落・パース不可) は例外を上げず `nil`。

理由:
- 完全な RFC 4647 互換は不要 (実ブラウザは `ja-JP;q=0.9, en-US;q=0.8, en;q=0.7` 程度のシンプルな形式が大半)。
- gem を 1 つ増やすコストよりも、20〜30 行の concern 内 private メソッドで足りる。
- ホワイトリストとの照合が常に最終ゲートなので、パーサが多少緩くても安全側に倒れる (一致しなければデフォルト :ja)。
- Phase 18 での「Accept-Language 経路の検証」テストで挙動が固定される。

却下理由:
- 単純な「先頭 2 文字だけ拾う」案 (Q3 提示の選択肢 a) は、`zh-CN;q=1.0, ja;q=0.9` の場合に zh を先に拾って fall through が遅れる、または不正動作の余地。q-value を尊重する方が VERI18N-01 のテスト想定 (有効 Accept-Language マッチ) と素直に対応する。

#### `?locale=` パラメータポリシー (領域 4 — 推奨)

**Phase 14 では `?locale=` を一切認識しない**。以下を採用する:
- ルーティング/コントローラに `params[:locale]` を読む処理を入れない。
- 結果として、解決パイプラインの段は `[saved_locale, accept_language_match]` の 2 段のみ → デフォルト `:ja` フォールバック。

理由:
- I18N-02 の解決順序仕様には `?locale=` が**登場しない** → 仕様に沿わない経路を増やすのは over-spec。
- I18N-03 の「パラメータから不正値を強制できないこと」は **そもそも `params[:locale]` を読まない** ことで自動的に達成される (受理経路がなければ強制経路も存在しない)。
- ユーザの言語切替は Phase 15 の `/preferences` フォーム経由 (DB 永続) で完結するため、URL レベルの一時切替の必要性なし。
- 将来 `?locale=` 一時切替が真に必要になった場合、既に確立された解決パイプラインに 1 段 (許可リスト検査込み) を追加するだけで導入できる — 後方互換性の負債を作らず deferred 可能。
- スコープ最小化により Phase 14 のテスト総数も最小に保てる (param 経路のテストを書かなくて済む)。

却下理由:
- 「認識するが許可リスト外は無視」案も I18N-03 を満たすが、テスト観点では「読まない」方が経路が完全に消える分シンプル。

#### Test Coverage Strategy (テスト方針)

VERI18N-01 を満たす方法として、以下を推奨:
- **Minitest 統合テスト** (`test/controllers/application_controller_test.rb` を新規作成、または既存の代表コントローラテストに追加) を主役とする。`@request.headers['Accept-Language'] = '...'` で Accept-Language を、ユーザ fixtures の Preference#locale で保存値を切り替える。
- 既存テスト規約に従い、テストメソッド名は日本語 (`def test_保存済みlocale_の場合_その言語で描画される` など)。
- `assert_select 'html[lang=?]', 'en'` で `<html lang>` 属性を直接検証する (I18N-04)。
- Cucumber には Phase 14 段階では追加しない (UI 文字列がまだ翻訳されていないため、ブラウザ視点で見える差分が `<html lang>` 属性のみで E2E 価値が薄い)。Phase 18 で代表的な ja/en 経路を Cucumber で覆う。
- `Preference` モデルテスト (`test/models/preference_test.rb` を新規作成、または既存) に `validates :locale, inclusion:` の境界テスト ('ja' OK / 'en' OK / 'fr' NG / nil OK) を 1 ブロック追加。

却下理由:
- 純粋な request spec パターン (`test/integration/`) は既存プロジェクトで未使用 (`.keep` のみ) — 既存パターン (controller test) に合わせる。

#### `<html lang>` 配置とレイアウトの影響

- `app/views/layouts/application.html.erb` 16 行目の `<html>` を `<html lang="<%= I18n.locale %>">` に変更する (シンボル → 文字列キャスト不要、ERB 出力で安全)。
- 他レイアウトファイルが存在しないため (Devise の views も Devise 標準のレイアウト継承で `application.html.erb` を経由する)、変更箇所は基本的に 1 箇所。Devise が独自レイアウトを宣言している場合 (`config/initializers/devise.rb` 参照) は plan 時に確認。
- ヘルパ (例: `def current_locale_lang_attr; I18n.locale.to_s; end`) を作るかは PR サイズと比較して plan 判断 — 直接埋め込みでも可。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements

- `.planning/ROADMAP.md` — Phase 14 ゴール、成功基準 5 項目、依存関係
- `.planning/REQUIREMENTS.md` — I18N-01〜I18N-04、VERI18N-01 の文面、Out of Scope (URL ベースルート、`accept-language` gem、`i18n-js` 配線、ユーザ生成コンテンツ翻訳)
- `.planning/PROJECT.md` — v1.4 ゴール、過去マイルストーン (v1.1〜v1.3) の決定、制約 (Sprockets 維持、新 JS 依存追加なし)。**locale 永続化先の記述 (L19) は本フェーズ実装で `preferences` 表現に更新する**
- `.planning/STATE.md` — v1.4 計画状況、過去フェーズの累積コンテキスト

### Prior Phase Alignment

- `.planning/phases/13-note-gadget-integration-tests/13-CONTEXT.md` — 直前完了フェーズ、テスト戦略 (controller test + Cucumber 役割分担) の前例
- `.planning/phases/12-tab-ui/12-CONTEXT.md` — Theme 隔離パターン (ERB 内 `if` ガード + SCSS `.simple { }`) — locale には適用されないが、レイアウト編集時の参照
- `.planning/milestones/v1.3-ROADMAP.md` — 前マイルストーンの落とし所、累積決定の参照

### Existing I18n / Locale Configuration

- `config/application.rb` (L29-30) — 既存設定 `I18n.config.enforce_available_locales = true` / `config.i18n.default_locale = :ja`。本フェーズでは `config.i18n.available_locales = Preference::SUPPORTED_LOCALES.map(&:to_sym)` を追加
- `config/locales/ja.yml` (44 行) — 既存属性翻訳 (`activerecord.attributes.bookmark.title` 等) — Phase 14 では追加翻訳キーは入れない
- `config/locales/en.yml` (33 行) — Rails 標準スタブ (実キー無し) — Phase 14 では空のまま、Phase 16〜18 で本格的にキーを追加

### Code and Assets to Modify or Reference

- `app/models/preference.rb` — `SUPPORTED_LOCALES` 定数追加、`validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true` 追加。既存の `FONT_SIZES` 定数定義パターンに揃える
- `app/controllers/application_controller.rb` — `include Localization` + `before_action :set_locale` を追加 (現在は `protect_from_forgery`, `authenticate_user!`, `configure_permitted_parameters` のみ)
- `app/controllers/concerns/localization.rb` — **新規** — `set_locale` メソッド + `saved_locale` / `accept_language_match` private helpers + Accept-Language q-value パーサ
- `app/views/layouts/application.html.erb` — L2 `<html>` を `<html lang="<%= I18n.locale %>">` に変更
- `db/schema.rb` — マイグレーション後に `preferences` テーブルに `t.string "locale"` が追加される
- `db/migrate/<TS>_add_locale_to_preferences.rb` — **新規** — `add_column :preferences, :locale, :string, null: true`
- `test/fixtures/users.yml` / `test/fixtures/preferences.yml` (存在すれば) — 必要なら locale を持つ Preference fixture を 1〜2 件追加 (テストの「保存済み locale」経路用)
- `test/test_helper.rb` — Devise integration helpers が既に組まれている前提
- `test/controllers/application_controller_test.rb` — **新規** — VERI18N-01 の 4 経路を覆う統合テスト
- `test/models/preference_test.rb` — **新規 (もしくは追加)** — `validates :locale, inclusion:` の境界テスト

### Coding Conventions and Patterns

- `.planning/codebase/CONVENTIONS.md` — 2 スペースインデント、シングルクォート、`private` キーワード分離、コメント日本語、テストメソッド名日本語、定数 SCREAMING_SNAKE_CASE、`Crud::ByUser` concern 前例
- `.planning/codebase/TESTING.md` — Minitest + 日本語メソッド名、`assert_select` で HTML 構造、Devise test helpers (`sign_in user`)、support helpers (`test/support/users.rb` 等)、Cucumber は features/ 配下で日本語 Gherkin
- `.planning/codebase/STACK.md` — Rails 8.1 / Ruby 3.4 / Sprockets / jQuery 4.6 / `rails-i18n 8.1.0` / `devise-i18n 1.16.0` / `i18n-js 4.2.4` (Phase 14 では未配線)

### External Specs

外部仕様文書なし。要件は `.planning/REQUIREMENTS.md` で完結。RFC 4647 (Language Tag Matching) は Accept-Language パーサの参考だが完全準拠は不要 (上記 D-04 推奨参照)。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Preference` モデルの定数+検証パターン:** `FONT_SIZE_LARGE` / `FONT_SIZE_MEDIUM` / `FONT_SIZE_SMALL` を `FONT_SIZES = [...].freeze` でまとめ `validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true` で値域を制約する形が既存。`SUPPORTED_LOCALES` も同形で書ける。
- **`Crud::ByUser` concern の前例:** モデル横断的関心事を concern に切り出すパターンが確立しており、コントローラ側にも同じスタイル (`Localization` concern) を適用しやすい。
- **`Preference.default_preference(user)` ファクトリ:** 新規ユーザの Preference 初期値生成パターンが確立。本フェーズでは `locale` は `nil` のまま (明示設定なし) でよい。
- **`User.after_save :create_default_portal`:** 新規ユーザ作成時に依存レコードを自動生成する callback パターン。Preference の自動生成も同様の callback がある可能性 — plan 時に確認 (`current_user.preference` が常に存在する保証があるか)。
- **Devise Test Helpers:** `test/test_helper.rb` で `Devise::Test::IntegrationHelpers` が `ActionDispatch::IntegrationTest` に include 済み — テストの認証は `sign_in user` 一行で済む。
- **Test support helpers:** `test/support/users.rb` の `def user; @_user ||= User.first; end` 等のメモ化パターン — 必要なら `def user_with_locale(loc); ...; end` を追加してテストを簡潔化できる。

### Established Patterns

- **薄いコントローラ + モデル中心:** ロジックはモデル (Preference 検証) と concern (Localization 解決) に集約。サービスオブジェクトは未使用 — 本フェーズでも導入しない。
- **before_action での前処理:** `ApplicationController` では `authenticate_user!` を before_action で適用。`set_locale` も同パターンで追加する。`set_locale` は `authenticate_user!` よりも前に走らせる必要があるか後でよいかは plan 判断 (Devise が認証失敗時に flash メッセージを出す場合、その flash も翻訳されてほしい → `set_locale` を **先に** 走らせる方が安全)。
- **`<html>` タグ:** 現状 `lang` 属性なし、修正は 1 箇所 (`app/views/layouts/application.html.erb` のみ)。Devise が独自レイアウトを宣言していなければ全画面に波及。
- **テストの日本語メソッド名:** `def test_保存済みlocale_の場合_その言語で描画される` などの命名で既存 controller test と整合させる。
- **Fixture-driven テストデータ:** `users.yml` 等 YAML fixture が既存 — 必要なら `preferences.yml` (もし無ければ) もしくは fixture の追加で「locale 保存済みユーザ」を表現。
- **`devise-i18n` の挙動:** Devise の組み込み flash/error 翻訳は gem 経由で `I18n.locale` に従う。本フェーズで `I18n.locale` が正しく切り替わっていれば、Devise メッセージの ja/en 振り分けは自動で動く (Phase 18 で改めて検証)。

### Integration Points

- **Migration:** `add_column :preferences, :locale, :string, null: true` 1 本 + `bin/rails db:migrate` で `db/schema.rb` 更新。
- **Model:** `app/models/preference.rb` に定数 + 検証追加。
- **Application config:** `config/application.rb` に `config.i18n.available_locales = ...` 1 行追加。
- **Concern:** `app/controllers/concerns/localization.rb` (新規) + `ApplicationController` に `include` + `before_action`。
- **Layout:** `<html>` → `<html lang="<%= I18n.locale %>">` (1 行)。
- **Tests:** `application_controller_test.rb` (新規)、`preference_test.rb` (新規 or 追加)。

</code_context>

<specifics>
## Specific Ideas

ユーザは領域 1「locale 永続化先と形」のみを掘り下げ、以下の 4 点を明示的に選択した:

- **D-01 で「`users` ではなく `preferences`」を選択** — PROJECT.md の文言よりも既存パターン (per-user UI 嗜好の `Preference` 集約) との整合性を優先。
- **D-02 で「`null: true`、DB デフォルトなし」を選択** — 既存ユーザのバックフィルを避け、Accept-Language が次回アクセス時に自然に効くことを優先。
- **D-03 で「`Preference::SUPPORTED_LOCALES` 定数を真実の源」を選択** — 既存の `FONT_SIZES` パターン踏襲、I18n 設定はそこから派生。
- **D-04 で「解決パイプラインに二重防御を組み込む」を選択** — モデル検証 + 読み出し時 whitelist の両層で I18N-03 を担保。

残り 3 領域 (解決ロジック構造 / Accept-Language パース / `?locale=` ポリシー) はユーザが Claude 裁量に委ねた。各領域の推奨は上記 `<decisions>` 内 "Claude's Discretion" サブセクションに詳述。

</specifics>

<deferred>
## Deferred Ideas

- **`?locale=` 一時切替経路:** 現フェーズでは導入しない (D の Claude's Discretion 領域 4 参照)。将来 URL から locale を一時切替する真の要求が出たら、既に確立された解決パイプラインに「params 段 → 許可リスト検査 → 通れば採用」を 1 段追加するだけで導入可能。
- **`Rails.logger.warn` による不正 locale 検出ログ:** 個人 Web アプリスケールでは過剰のため Phase 14 では入れない。Phase 18 で「翻訳漏れ検出」の運用観測性が必要になった段階で再検討候補。
- **`accept-language` gem 導入 (I18NTOOL-02):** 自前パーサで実装し、もし将来 Accept-Language ヘッダの複雑形式 (RFC 4647 拡張、wildcard `*` 等) が問題になったら gem 移行を検討。
- **`i18n-js` の配線 (Phase 17 で別途検討):** Phase 14 のスコープ外。Phase 17 で JS 可視文字列の翻訳を `data-*` 属性経由で行う方針 (TRN-05) と整合。
- **Devise 独自レイアウト確認:** Devise が `app/views/layouts/devise.html.erb` 等を定義していないかは plan 時に確認。定義していれば `<html lang>` の修正は両方に必要。

### Reviewed Todos (not folded)

- `2026-04-30-extract-drawer-ui-helper.md` — Phase 13 で fold 済 (D-09)。pending リストに残置している場合は Phase 14 のスコープ外なので追加 fold せず、別途 todos クリーンアップとして扱う。
- `2026-04-30-gate-drawer-blocks-on-theme.md` — Phase 13 で fold 済 (D-10)。同上。

### PROJECT.md Update (本フェーズ実装に同梱)

PROJECT.md L19 の「Add `locale` column to users table; persist selected language per account」を「Add `locale` column to `preferences` table; persist selected language per account」に更新する。Phase 14 のドキュメントコミットに同梱 (D-01 の決定に整合)。

</deferred>

---

*Phase: 14-locale-infrastructure*
*Context gathered: 2026-05-01*
