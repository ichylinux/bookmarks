---
id: 260831-1mg
status: fixed-pending-device-verification
date: 2026-08-31
commit: 71b8c47 (第1次・誤診), 未コミット (第2次・本修正)
---

# Quick Task 260831-1mg — SUMMARY

**Description:** Windows+Chromeの場合、タスクガジェットのヘッダにマウスオーバーしても追加ボタンが表示されない

## 経緯

第1次修正 (`71b8c47`) は**未検証の根本原因仮説**に基づいてコミット・デプロイされ、
**実機で効果がなかった**。第2次で実機診断を取り、仮説を反証してから修正し直した。

## 実機診断結果 (Chrome 151 / Windows 10 / 2026-08-31)

```
(hover:hover)        false    (hover:none)         true
(pointer:fine)       false    (pointer:coarse)     true
(any-hover:hover)    false    (any-hover:none)     true
(any-pointer:fine)   false    (any-pointer:coarse) true
(max-width:767px)    false
innerWidth 1289 / dpr 1.1 / maxTouchPoints 10
mediaConditionsInServedCss: [..., "(any-hover: hover) and (any-pointer: fine)"]
linkIdle: { opacity: "0", pointerEvents: "none" }
```

判明した事実:

1. **デプロイは正常に届いていた** — 配信CSSに第1次修正の `any-hover` 条件が存在する。
2. **この端末では Chrome がマウスを一切認識していない** — primary-only 系
   (`hover`/`pointer`) だけでなく any-input 系 (`any-hover`/`any-pointer`) も
   すべて none/coarse を返す。ユーザーは実際にマウスを操作している。
3. よって第1次修正 (`hover`→`any-hover` の置換) は**この端末では no-op** だった。

## 根本原因 (訂正後)

「追加」の表示ルールを**入力デバイスのメディア特性でゲートしていたこと自体**が原因。

- `@media (any-hover: hover) and (any-pointer: fine)` がマッチせず `opacity: 0` のまま
- `@media (any-hover: none) { pointer-events: none }` が逆にマッチして `pointer-events: none`

第1次修正の根本原因モデル（「Windowsタッチ機ではタッチが primary と判定されるが
マウスは any-* に現れる」）は**誤り**。この端末ではマウスがどの媒体特性にも現れない。

## 修正内容

| ファイル | 内容 |
|---|---|
| `app/assets/stylesheets/welcome.css.scss` | 表示ルールのゲートを `@media (min-width: $portal-mobile-breakpoint)` に変更。ベースの `pointer-events: none` は無条件化（メディアクエリ依存を撤廃） |
| `features/support/windows_hybrid_input.rb` → `windows_touch_only_input.rb` | 再現条件を実機の申告値 (`availablePointerTypes=2, availableHoverTypes=1` = タッチのみ) に修正。旧版は反証済みの「マウスも申告される」前提を再現しており、バグを検出できなかった |
| `features/step_definitions/todos.rb` / `02.タスク.feature` | アサーションを反転 — 表示条件に `hover`/`pointer` が**含まれず** `width` ベースであることを検証。あわせてセッションのビューポート幅を明示検証 (下記 flakiness 対策) |
| `welcome.css.scss:213` | `#bookmark_gadget .folder-header` のホバー背景を `@media (min-width: $portal-mobile-breakpoint)` に変更 |
| `preferences.css.scss:45` | 設定行のホバー背景から `@media (hover: hover)` ゲートを撤廃 |

モバイル (`max-width: 767px`) の詳細度 (0,4,0) 非表示ルールは不変。表示ルール
(0,3,1) より優先されるため、260710-p6v / 260712-j75 の回帰防止は構造的に維持。

## 検証

| ゲート | 結果 |
|---|---|
| `yarn run lint` | green |
| `bundle exec rake dad:test features/02.タスク.feature` | **6 scenarios / 28 steps 全 passed** |
| red-before 確認 (旧CSSを一時復元して `02.タスク.feature:23`) | **1 failed** — `todos.rb:137` のホバー表示アサーションで落ちる |

`bin/rails test` は CSS / feature のみの変更のため対象なしと判断。

red-before / green-after が両方取れているため、このシナリオは今回のバグを実際に
検出できる。第1次修正時に欠けていたのがこの確認。

## 残 (要ユーザー対応)

- **Windows+Chrome 実機での再確認** — デプロイ後にホバーで「追加」が出ることの確認。

## 派生修正 (同一原因の残り2箇所)

ユーザー指示により、装飾のみだが同じ理由で無効化されていた2箇所も修正した。方針が異なるのは意図的:

- `welcome.css.scss:213` — **幅ゲートに置換**。このファイルには既に同じ変数を使う
  ブレークポイントが2箇所あり (171, 384行)、元のゲートの目的 (タップ後の sticky hover が
  フォルダヘッダに残るのを防ぐ) を幅ゲートでそのまま保てる。
- `preferences.css.scss:45` — **ゲート撤廃**。設定画面にはレスポンシブなブレークポイントが
  一切存在せず (このファイルの `@media` はこれ1つだった)、768px を持ち込むとポータルの
  ブレークポイント概念を無関係なページに複製することになる。sticky hover が残っても
  設定行1つが次のタップまで色付くだけなので代替ゲートは不要と判断。

これでスタイルシートからデバイス依存のゲートは全て消えた。

## 変更しなかったもの

`note_gadget.js:172` の `matchMedia('(hover: none)')` 分岐は、この端末で誤判定されるが
**タップ用ツールチップのハンドラを追加する**方向の分岐であり、機能が消えるのではなく増える。
失敗の向きが逆なので変更していない。

## テストの flakiness (発見と対処)

4 feature をまとめて実行した際、追加したホバーシナリオが1度失敗した。再実行で green
(同じ4 feature が 6分12秒 → 1分11秒)。マシン負荷によるタイムアウトであり regression では
ないが、原因として以下を特定し対処した:

- 表示条件が幅ベースになったことで、このシナリオは初めて**セッションのビューポート幅**に
  依存するようになった。headless Chrome は `--ozone-override-screen-size=800,600` で起動する
  ため `resize_browser_window(1280, 800)` がクランプされ得る。
- ステップ冒頭で `window.innerWidth >= 768` を明示検証するようにした。クランプされた場合は
  「追加が見えない」ではなく幅が原因だと分かる形で落ちる。

なお `dad:test` の chromedriver は**固定ポート 9515** を使うため、2つ同時に走らせると衝突する
(今回の失敗の原因ではないが運用上の注意点)。
