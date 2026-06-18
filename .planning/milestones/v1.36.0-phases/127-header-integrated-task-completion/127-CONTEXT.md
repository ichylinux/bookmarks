# Phase 127: Header-Integrated Task Completion - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

タスクガジェット（welcome の todo ガジェット）の「完了」操作を、リスト内の独立した `.todo_actions` 行からガジェットヘッダ（既存の「新規／追加」リンクと同じ `.title--gadget-with-icon` 行）へ移す。1件以上選択時のみヘッダに「完了」アクションと現在の選択件数を表示し、選択の増減に追従させる。既存のタップ選択挙動（`span.selected` チェックマーク）と一括完了バックエンド（`POST /todos/delete`）は変更せず流用する。新規 JS ライブラリは導入しない（Sprockets + jQuery 制約）。本フェーズはテストを含まない（Phase 128 が担当）。

</domain>

<decisions>
## Implementation Decisions

### Header Action — Placement & Appearance
- 「完了」アクションは既存の `.title--gadget-with-icon` ヘッダ行内に配置し、「新規／追加」リンクの後ろに右寄せで並べる
- 「完了」は `todo-gadget-new-link` と同様のリンク（`<a>`）として描画し、`onclick: 'todos.delete_todos(this); return false;'` で既存ハンドラを流用（新規 JS ライブラリなし）
- 0件選択時は DOM 上に残したまま `display:none`（JS 管理クラス）で隠し、1件以上選択時に表示する
- 選択件数テキスト（例「2件選択中」）を「完了」リンクのすぐ左に置き、両者をヘッダ右側のコンテナにまとめる

### Selection Count & Backend Wiring
- 選択件数の更新は既存の `click 'li span:first-child'` ハンドラ内で `li.selected` 件数を再計算し、ヘッダの表示／非表示と件数テキストを更新する
- CSRF トークンは `.todo_actions` 撤廃に伴い、既存の `meta[name="csrf-token"]`（`toggle_highlight` で既に使用）から取得する
- `new_todo` の挿入位置は `.todo_actions` 撤廃に伴い `<ol>` の先頭へ prepend する
- 空選択ガード: 0件のときアクションは非表示（クリック不可）にし、加えて JS 側でも件数0なら no-op にする

### i18n & Wording
- 「完了」ラベルは既存の `t('todos.actions.complete')`（= 完了）を再利用する
- 選択件数文言は ja「%{count}件選択中」 / en "%{count} selected"
- 新規キーは `welcome.todo_gadget.selected_count` に置き ja/en パリティを保つ
- 英語の複数形は単純補間（`%{count} selected`）で扱い、one/other の分岐はしない

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/welcome/_todo_gadget.html.erb` — ガジェット本体。`common/gadget_title_with_icon` を `header_link:` 付きで描画し、`<ol>` 内で `todos/actions` と各 `todo` をレンダリング
- `app/views/common/_gadget_title_with_icon.html.erb` — ヘッダ partial。`header_link` local をタイトル横に出力（ここに「完了」用のスロットを足す余地がある）
- `app/views/todos/_actions.html.erb` — 撤廃対象の `.todo_actions` `<li>`（完了リンク + `data-authenticity_token`）
- `app/assets/javascripts/todos.js` — `todos.init`（選択トグル `click 'li span:first-child'`、`li:not(.todo_actions)` ガード多数）、`todos.delete_todos`（`.todo_actions` から CSRF 取得、`li.selected` を hide）、`todos.new_todo`（`.todo_actions` の後ろに挿入）
- `app/assets/stylesheets/todos.css.scss` — `.todo_actions`、`span.selected`、`li:not(.todo_actions)` 系ルール多数

### Established Patterns
- ガジェットは ERB partial + Sprockets/jQuery。`todos.js` は `window.todos` 名前空間に関数をぶら下げる（新規グローバル禁止）
- ヘッダリンクは `link_to ... onclick: 'todos.xxx(this); return false;'` で JS ハンドラへ委譲
- AJAX の CSRF は `meta[name="csrf-token"]` から取得する前例あり（`todos.toggle_highlight`）
- ロケールは ja/en 両方にキーを置き、パリティテストで保証

### Integration Points
- `_todo_gadget.html.erb` のヘッダ描画箇所（`header_link:` まわり）に「完了」＋件数を追加
- `todos.js` の選択トグルハンドラ・`delete_todos`・`new_todo` を `.todo_actions` 撤廃に合わせて改修
- `config/locales/ja.yml` / `en.yml` の `welcome.todo_gadget` に `selected_count` を追加
- `.todo_actions` 参照を持つ CSS の `li:not(.todo_actions)` セレクタ群の整理

</code_context>

<specifics>
## Specific Ideas

- 選択挙動（`span.selected` チェックマーク表示）は完全に不変であること（SEL-01）
- 完了実行は既存 `POST /todos/delete` を流用し、選択中 `todo_id` を送る（SEL-02）。未選択クリックは無操作
- `.todo_actions` 行の撤廃により縦スペースを実際に回収する（LAY-01）

</specifics>

<deferred>
## Deferred Ideas

- HDR-FUT-01 行ごとの個別「完了」操作（タスク単位ワンクリック完了） — v2
- HDR-FUT-02 ヘッダに「すべて選択／選択解除」トグル — v2

</deferred>
