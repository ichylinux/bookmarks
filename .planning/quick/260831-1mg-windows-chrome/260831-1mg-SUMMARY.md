---
id: 260831-1mg
status: incomplete
date: 2026-08-31
commit: 71b8c47
---

# Quick Task 260831-1mg — SUMMARY

**Description:** Windows+Chromeの場合、タスクガジェットのヘッダにマウスオーバーしても追加ボタンが表示されない

## 状態

**未完了(ユーザー指示によりエグゼキュータを中断)**

コード修正とテスト追加はコミット済み(`71b8c47`)だが、**検証(green-bar ゲート)は未実施**。

## 根本原因

`app/assets/stylesheets/welcome.css.scss` のホバー表示ルールが primary-only な
media feature (`hover` / `pointer`) で囲まれていた。

- L375 付近 — `@media (hover: hover) and (pointer: fine)` が
  `div.title:hover .todo-gadget-new-link { opacity: 1; pointer-events: auto; }` を包む
- L321 付近 — `@media (hover: none)` が同じ共有クラスに `pointer-events: none` を適用

`hover` / `pointer` は**主要な入力機構のみ**を表す。タッチスクリーン搭載の Windows
ノート / 2-in-1 では Chrome がタッチを primary と判定するため、マウス利用者でも
`hover: none` / `pointer: coarse` 側にマッチし、表示ルールが効かず
`pointer-events: none` が適用される。macOS/Linux の非タッチ機ではマウスが primary
のため再現しない。

## 実施した変更(コミット 71b8c47)

| ファイル | 内容 |
|---|---|
| `app/assets/stylesheets/welcome.css.scss` | media condition を `any-hover` / `any-pointer` に変更(セレクタは不変) |
| `features/02.タスク.feature` | デスクトップのホバー表示シナリオを追加 |
| `features/step_definitions/todos.rb` | ホバー表示ステップ + served CSS の CSSOM アサーションを追加 |
| `features/support/windows_hybrid_input.rb` | Windows タッチ+マウスのハイブリッド入力をエミュレートする専用 Capybara セッション(新規) |

モバイルの非表示ルール `.gadget.todo .title--gadget-with-icon .todo-gadget-new-link`
(`@media (max-width: 767px)` 内、詳細度 0,4,0)は変更しておらず、表示ルール(0,3,1)
に対して依然として優先される。よって 260710-p6v / 260712-j75 の回帰防止は構造的に維持。

## 未消化項目(要対応)

1. **`bundle exec rake dad:test` — 未実行**(ユーザー指示により中断。後日手動実行予定)
2. **`yarn run lint` / `bin/rails test` — 実行有無を確認できていない**(エグゼキュータ中断のため)
3. **新規テストコードは一度も実行されていない。** 参照している
   `Closer::Drivers::Chrome.options(headless: true)` / `current_user` /
   `resize_browser_window` / `two_factor_enabled?` の存在は静的に確認済みだが、
   `blink-settings=primaryPointerType=...` による入力デバイスのエミュレーションが
   実際に効くかは未検証。dad:test で最初に確認すべき箇所。
4. **Windows+Chrome 実機での動作確認**(プランの checkpoint:human-verify)。
   まだ再現する場合は DevTools コンソールで以下を実行し、根本原因モデルを反証する:
   ```js
   ['(hover:hover)','(pointer:fine)','(any-hover:hover)','(any-pointer:fine)']
     .forEach(q => console.log(q, matchMedia(q).matches));
   ```

## スコープ外(意図的)

`welcome.css.scss:213` と `preferences.css.scss:45` も同じ primary-only feature を
使っているが、装飾的なハイライト抑制のみで機能欠落はないため、タスクを atomic に
保つ目的で今回は変更していない。
