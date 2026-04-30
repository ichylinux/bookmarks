---
phase: 12-tab-ui
reviewed: 2026-04-30T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - app/views/welcome/index.html.erb
  - app/assets/stylesheets/welcome.css.scss
  - app/assets/javascripts/notes_tabs.js
  - test/controllers/welcome_controller/welcome_controller_test.rb
  - test/controllers/welcome_controller/layout_structure_test.rb
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-04-30T00:00:00Z  
**Depth:** standard  
**Files Reviewed:** 5  
**Status:** issues_found

## Summary

シンプルテーマ専用のタブマークアップ・`.simple` 配下の SCSS・`body.simple` ガード付きの `notes_tabs.js`、およびテーマ分岐の結合テストを確認した。`params[:tab]` は `to_s == 'notes'` の真偽にのみ使われ HTML/JS へ未エスケープ反映されないため、本スコープでは **XSS やクエリの不安全な反射は見当たらない**。不正な `tab` 値はサーバー・クライアント双方でホーム扱いにフォールバックし整合している。  
ただし **History API を使わない設計**のため、クエリ付き URL で開いたあとクライアントだけ別タブに切り替えると **再読込時にクエリ優先で表示が戻る** という利用者視点の不整合が残る（下記 WR-01）。あわせてタブの WAI-ARIA 属性と、デフォルト GET のパネル表示の明示的アサーションに改善余地がある。

## Warnings

### WR-01: クエリ文字列とクライアント表示の再読込時の不一致

**File:** `app/assets/javascripts/notes_tabs.js:22-38`（関連: `app/views/welcome/index.html.erb:37`)  
**Issue:** `?tab=notes` で初期表示後、クリックでホームに切り替えても URL は変わらない。再読込するとサーバーが再度 `params[:tab]` を解釈するため **ノートタブに戻る**。共有 URL・ブックマークとの意味は一致するが、同一セッション内の「最後に選んだタブ」とは一致しない。仕様で `pushState` / `replaceState` を禁止している場合はトレードオフとして文書化するか、クリック時に `replaceState` でクエリを同期するかのいずれかが望ましい。  
**Fix:** 例: タブクリック後に `history.replaceState` で `?tab=` を `home` 相当（クエリ削除）または `notes` に揃える。禁止ルールを維持するなら UI-SPEC / UAT に「再読込は常に URL の tab を信頼する」と明記する。

```javascript
// 例（方針が許可される場合）: activateTab 内で URL を同期
// var u = new URL(window.location.href);
// if (isNotes) { u.searchParams.set('tab', 'notes'); } else { u.searchParams.delete('tab'); }
// history.replaceState(null, '', u.pathname + u.search);
```

## Info

### IN-01: タブリストの ARIA パターンが不完全

**File:** `app/views/welcome/index.html.erb:38-40`  
**Issue:** `nav` に `role="tablist"` がある一方、子の `button` に `role="tab"`、`aria-selected`、`aria-controls`（各パネルの `id` 参照）、パネル側の `aria-labelledby` がない。キーボードの左右矢印でタブ移動などは未要件でも、スクリーンリーダーでは「タブ」として認識されにくい。  
**Fix:** `button` に `role="tab"`、`aria-selected="<%= notes_active ?>"` をタブごとに出し分け、`id` を付けて `aria-controls="simple-home-panel"` / `notes-tab-panel` を対応させる。

### IN-02: デフォルト GET でのホームパネル表示のアサーション不足

**File:** `test/controllers/welcome_controller/welcome_controller_test.rb:29-38`  
**Issue:** `test_シンプルテーマでウェルカムにホームとノートのタブボタンが表示される` はマークアップの存在のみで、`/?`（クエリなし）のとき **`#simple-home-panel` が非 hidden、`#notes-tab-panel` が hidden** であることは明示していない。`tab=notes` と `tab=evil` は別テストでカバーされている。  
**Fix:** 同テスト、または別テスト 1 本で  
`assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 0` および  
`assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 1` を追加する。

---

### テスト文脈メモ（偽陽性なし）

- `layout_structure_test` のモダン／クラシックで `#notes-tab-panel` / `nav.simple-tabstrip` が 0 件になることと、`welcome_controller_test` のシンプル＋クエリ検証は、ERB の `favorite_theme == 'simple'` 分岐と整合している。
- `params[:tab]` のテストでは `evil` のみ検証済み。サーバー側は `'notes'` 以外すべてホーム扱いであり、過剰な厳しさによる偽陽性は読み取れなかった。

---

_Reviewed: 2026-04-30T00:00:00Z_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_
