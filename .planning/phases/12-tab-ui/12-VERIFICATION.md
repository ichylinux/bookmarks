---
phase: 12-tab-ui
slug: tab-ui
verified_at: 2026-04-30
status: human_needed
status_note: >-
  TAB-02 の「ページリロードなし・アドレスバー query 不変」の要件は Rails 統合テストでは直接証明できない。
  `12-02-SUMMARY.md` にあるとおりワークフロー自動承認のみで本セッションはブラウザ実地確認を行っていない。
requirements:
  TAB-01: covered_automated
  TAB-02: human_pending
  TAB-03: covered_automated
---

# Phase 12 — Tab UI — Verification

フェーズ目標「シンプルテーマのみでホーム／ノートタブ、`?tab=notes`/保存後はノート、モダン・クラシックでは非表示」を、コード・自動テスト・コードレビューで照合した記録です。

---

## 総合ステータス

| 項目 | 判定 |
|------|------|
| **YAML status** | `human_needed`（下記 TAB-02 人手確認が未証明のため） |
| 自動化・静的整合 | TAB-01 / TAB-03 / ROADMAP SC4（モダン・クラシック非表示）は **満たす** |

---

## 自動テスト証拠

| コマンド | 結果（オーケストレーター報告） |
|----------|-------------------------------|
| `bin/rails test` | 110 例、519 アサーション、失敗・エラー・スキップ 0 |
| `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb test/controllers/welcome_controller/layout_structure_test.rb test/controllers/notes_controller_test.rb` | 22 例、110 アサーション、失敗・エラー 0 |

---

## must_have 対コードベース

| チェック | 結果 | 根拠 |
|----------|------|------|
| シンプルで日本語タブ「ホーム」「ノート」、既定はホーム | **OK** | `favorite_theme == 'simple'` 分岐内の `button` + `notes_active` により `tab=notes` 以外はホーム側が可視（`app/views/welcome/index.html.erb`） |
| `?tab=notes` / ノート保存リダイレクトでノートパネル | **OK** | SSR: `notes_active = (params[:tab].to_s == 'notes')`；`NotesController` は `redirect_to root_path(tab: 'notes')`；`notes_controller_test.rb` でリダイレクト先をアサート |
| クリントタブ操作は URL 変更なし・`button` + クラス切替 | **OK** | `type="button"`、`notes_tabs.js` は `activateTab` で `simple-tab-panel--hidden` の付替えのみ。`pushState` / `replaceState` なし |
| モダン・クラシックでタブ DOM 不在 | **OK** | `layout_structure_test.rb` で `#notes-tab-panel` / `nav.simple-tabstrip` が 0 件 |
| タブ用 CSS は `welcome.css.scss` の `.simple` のみ | **OK** | `common.css.scss` に `simple-tab` 一致なし |
| `tab` クエリの生反映なし | **OK** | ERB では `params[:tab]` を `<%= params[:tab] %>` 等で出していない（完全一致ブールのみ） |

---

## 人手検証（TAB-02）

| 要件 ID | 内容 | 本記録での状態 |
|---------|------|----------------|
| **TAB-02** | タブクリックでパネル切替、**フルページリロードなし**、クリック前後でアドレスバーの query が変わらない（D-07） | **未実施（ブラウザ未観測）** — `12-02-SUMMARY.md` のチェック表はいずれも「Not manually re-run here」と明記。実装は `button` + jQuery でリロード機構がなく、レビューでも主操作がナビゲーションでないことは整合。正式サインオフには `12-VALIDATION.md` §Manual-Only の手順での実地確認を推奨。 |

---

## コードレビュー扱い

| ID | 重大度 | 扱い |
|----|--------|------|
| **WR-01** | warning | **ブロッカーではない** — D-07（タブクリックで History API 禁止）による意図的トレードオフ。`?tab=notes` で開いた後にクライアントでホームへ切替えても URL は変わらず、再読込では SSR が `tab` を解釈してノートに戻る挙動。`12-REVIEW.md` 記載どおり文書化済みのトレードオフ。 |
| **IN-01** | info | 非ブロッキング（ARIA 改善余地） |
| **IN-02** | info | 非ブロッキング（デフォルト GET での hidden クラス明示アサーションの追加余地） |

---

## 要件カバレッジ

| ID | 要件（要約） | 検証 |
|----|--------------|------|
| **TAB-01** | シンプル welcome にホーム／ノートのタブが見える | 自動: `welcome_controller_test`（`nav.simple-tabstrip`、両 `button`、`#simple-home-panel` / `#notes-tab-panel`） |
| **TAB-02** | ノートクリックでノートパネル、ホームでポータルに戻る、**無リロード** | 実装・静的レビューは整合。**ブラウザ UAT は本フェーズ実行記録上「未人手観測」** のためフェーズ証明は `human_pending`。 |
| **TAB-03** | ノート保存後にノートタブ文脈で戻る | 自動: `root_path(tab: 'notes')` リダイレクトのテスト、`GET /?tab=notes` の SSR でノート側可視クラス |

---

## フェーズ達成への残作業（policy により任意）

TAB-02 を「証明済み」にする場合: シンプルテーマでログインし `/` で「ホーム」「ノート」を往復、ネットワークで document ナビゲーションが増えないこととアドレスバー query 不変を記録する（`12-02-PLAN.md` Task 2）。

---

*検証記録作成: 2026-04-30 — プラン `12-01` / `12-02` の成果物・`12-REVIEW.md`・コードベース grep/読取に基づく。*
