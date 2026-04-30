# Phase 14: Locale Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `14-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 14-locale-infrastructure
**Areas discussed:** locale-persistence-and-shape (only)

---

## Locale Persistence and Shape

ユーザはこの領域のみを 4 質問に渡って明示的に議論し、領域 2〜4 は Claude 裁量に委ねた。

### Q1: locale カラムをどこに置くか

| Option | Description | Selected |
|--------|-------------|----------|
| A. `users.locale` | PROJECT.md の明示通り。Devise の `current_user.locale` で 1 ホップ取得、未ログイン時の判定が単純。ただし既存 UI 嗜好集約パターン (Preference) と分裂 | |
| B. `preferences.locale` | 既存パターン (theme/font_size/use_note/open_links_in_new_tab はすべて Preference) との整合性を保つ。Phase 15 のフォーム実装が直交。PROJECT.md 文言修正が必要 | ✓ |
| C. それ以外 | 自由記述 | |

**User's choice:** B
**Notes:** 既存パターンとの整合性を仕様文書の明示よりも優先。PROJECT.md の言い回し更新は本フェーズ実装に同梱する方針 (deferred として記録)。

---

### Q2: カラムの NULL 許容とデフォルト値

| Option | Description | Selected |
|--------|-------------|----------|
| A. `null: true`、DB デフォルトなし | `nil` = 未指定の一級状態。バックフィル不要、既存ユーザは次回アクセス時に Accept-Language が尊重される。fixture 更新不要、4 経路テストが書きやすい | ✓ |
| B. `null: false`、DB デフォルト `'ja'` | NULL を扱わない単純さ。既存ユーザが `'ja'` でロックされ I18N-02 #2 が機能しない | |
| C. `null: true` + モデル側で新規作成時に `'ja'` を入れる | 中庸案。既存はバックフィルしないが新規ユーザは `'ja'` で固定 → Accept-Language 検出効かず | |
| D. それ以外 | 自由記述 | |

**User's choice:** A
**Notes:** 「未指定」を一級状態として扱うことで I18N-02 の解決順序と最も素直に対応。

---

### Q3: モデル側の値制約と単一の真実の源

| Option | Description | Selected |
|--------|-------------|----------|
| A. `Preference::SUPPORTED_LOCALES` 定数を真実の源 | 既存の `FONT_SIZES` パターン踏襲。`config/application.rb` でその定数から `config.i18n.available_locales` を派生させる | ✓ |
| B. `I18n.available_locales` を真実の源 | Rails 標準概念に揃う。ただし初期化順序や `enforce_available_locales` 挙動でテストが脆くなりがち | |
| C. モデル検証なし、コントローラ coerce のみ | 不正値の DB 書き込みを防げず I18N-03 防御層が薄い | |
| D. それ以外 | 自由記述 | |

**User's choice:** A
**Notes:** `FONT_SIZES` 定数定義との完全な書き味の一致。モデル定数 → I18n 設定の単方向依存。

---

### Q4: コントローラ側の二重防御 coerce

| Option | Description | Selected |
|--------|-------------|----------|
| A. モデル検証のみに任せる | 単純・DRY。ただし stale data や `enforce_available_locales` 例外が 500 を起こす余地 | |
| B. 解決パイプラインの各段で whitelist 検査 → 通れば採用、通らなければ次段 | I18N-03 を書き込み時 + 読み出し時の二重防御に昇格。stale data・手動 SQL・将来の許可リスト縮小に resilient。VERI18N-01 の 4 経路テストが同じパイプラインで素直に書ける | ✓ |
| C. B + `Rails.logger.warn` | 観測性向上。個人 Web アプリスケールでは過剰、ログノイズ | |
| D. それ以外 | 自由記述 | |

**User's choice:** B
**Notes:** Rails.logger は出さず黙ってフォールスルー。`?locale=` 対応を将来追加する場合も同じパターンで 1 段追加可能なので、今フェーズで構造を固める価値が高い。

---

## Claude's Discretion

ユーザは領域 1 (Q1〜Q4) の議論を完了した時点で「ここで一旦止めて CONTEXT.md を書く (残り 3 領域は Claude 裁量に委ねる)」を選択した。リスクを認識した上での裁量委譲。

委譲された領域の Claude 推奨 (詳細は `14-CONTEXT.md` の `<decisions>` 内 "Claude's Discretion" サブセクション):

- **領域 2: 解決ロジック構造** — `app/controllers/concerns/localization.rb` 新規 concern として切り出し、`ApplicationController` で `include` + `before_action :set_locale`。既存の `Crud::ByUser` concern パターン踏襲。
- **領域 3: Accept-Language パース** — concern 内に q-value 順を尊重した自前最小パーサを実装。`accept-language` gem は導入しない。失敗時は `nil` を返してパイプライン上位へ次段委譲。
- **領域 4: `?locale=` パラメータポリシー** — Phase 14 では一切認識しない (params[:locale] を読まない経路を作らない)。I18N-03 を構造的に保証。将来必要なら確立されたパイプラインに 1 段追加で対応。
- **テスト方針** — Minitest 統合テスト主役 (`test/controllers/application_controller_test.rb` 新規)、Cucumber は本フェーズでは追加せず Phase 18 に委ねる。`Preference` モデルテストに `validates :locale, inclusion:` の境界テストを 1 ブロック追加。
- **`<html lang>` 配置** — `app/views/layouts/application.html.erb` L2 を `<html lang="<%= I18n.locale %>">` に変更。Devise 独自レイアウト存在チェックは plan 時。

## Deferred Ideas

- `?locale=` 一時切替経路 (将来追加可能、確立された解決パイプラインに 1 段差し込み)
- `Rails.logger.warn` による不正 locale 検出ログ (個人 Web アプリスケールでは過剰)
- `accept-language` gem 導入 (I18NTOOL-02、自前パーサで困難になった段階で再検討)
- `i18n-js` 配線 (Phase 17 で別途、本フェーズ out of scope)
- Devise 独自レイアウト確認 (plan 時に `app/views/layouts/devise.html.erb` 等の有無を検査)

## Reviewed Todos (not folded)

- `2026-04-30-extract-drawer-ui-helper.md` — Phase 13 で fold 済、本フェーズスコープ外
- `2026-04-30-gate-drawer-blocks-on-theme.md` — Phase 13 で fold 済、本フェーズスコープ外

## PROJECT.md Update Pending

PROJECT.md L19 の「`users` テーブルに `locale` カラム」記述を D-01 決定に整合させて `preferences` テーブル表現に更新する作業を、Phase 14 のドキュメントコミットに同梱する。
