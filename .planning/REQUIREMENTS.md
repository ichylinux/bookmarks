# Requirements: Bookmarks v1.37.0 — モバイルでのタスク追加機能

**Defined:** 2026-06-26
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.37.0 Requirements

### モバイル UI (MOB)

- [ ] **MOB-01**: タッチデバイス（`@media (hover: none)`）でも「追加」リンクが表示され、タップできる
- [ ] **MOB-02**: インライン追加フォームが ≤767px で縦積みレイアウトになる（`flex-wrap` 対応）
- [ ] **MOB-03**: `/todos/new` および `/todos/edit` 単独ページにも `.todo` ラッパーを追加し、同じ CSS スコープを共有する
- [ ] **MOB-04**: フォーム入力に `font-size: 1rem` を設定し、iOS Safari の自動ズームを防止する

### テスト (TEST)

- [ ] **TEST-01**: Minitest — `.todo-gadget-new-link` がモバイル CSS で `opacity: 1` / `pointer-events: auto` になることを検証する構造テスト
- [ ] **TEST-02**: Cucumber — 390px ビューポートで「追加」リンクをタップ → インラインフォーム表示 → タスク追加の E2E シナリオ
- [ ] **TEST-03**: トライスイートグリーン（`yarn run lint` + `bin/rails test` + `bundle exec rake dad:test`）

## Future Requirements

| Item | Description |
|------|-------------|
| LOC-FUT-01 | 英語ロケールキー `welcome.todo_gadget.new_link` を "Add" に変更（現在 "new"、ユーザ要望により本マイルストーンでは維持） |
| MOB-FUT-01 | auto-focus — iOS Safari の AJAX callback 制限により延期（pre-rendered hidden form が必要） |
| MOB-FUT-02 | キャンセルボタン — 空タイトル dismiss が既存パターンのため延期 |

## Out of Scope

| Feature | Reason |
|---------|--------|
| 英語ロケールラベル変更 | ユーザの明示的判断で "new" のまま維持 |
| モーダル / ボトムシート / FAB | インラインフォームに統一、オーバーレイは採用しない |
| auto-focus (JS) | iOS Safari は AJAX callback 内で `.focus()` を無視する |
| デスクトップ動作変更 | モバイルの改善が目的；デスクトップは現状を維持 |

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| MOB-01 | Phase 129 | Pending |
| MOB-02 | Phase 129 | Pending |
| MOB-03 | Phase 129 | Pending |
| MOB-04 | Phase 129 | Pending |
| TEST-01 | Phase 130 | Pending |
| TEST-02 | Phase 130 | Pending |
| TEST-03 | Phase 130 | Pending |
