# Requirements: Bookmarks — v1.36.0 タスクガジェットの完了操作の改善

**Defined:** 2026-06-18
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

**Milestone goal:** タスクガジェットの「完了」操作をヘッダに集約し、複数選択での一括完了を分かりやすく効率化する。

## v1.36.0 Requirements

### Gadget Header (HDR)

- [ ] **HDR-01**: タスクガジェットのヘッダ行（既存の「新規」リンクと同じ行）に「完了」アクションを配置する
- [ ] **HDR-02**: 「完了」アクションは1件以上のタスクが選択されているときのみ表示され、未選択時はヘッダに現れない
- [ ] **HDR-03**: ヘッダに現在の選択件数（例: 「2件選択中」/ "2 selected"）を表示し、選択数の増減に追従して更新される

### Layout (LAY)

- [ ] **LAY-01**: 従来の `.todo_actions` 行（リスト内の独立した `<li>`、1行分の高さを占有）を廃止し、タスク一覧の縦スペースを回収する

### Selection (SEL)

- [ ] **SEL-01**: 既存のタップ/クリック選択挙動（行をクリックすると `span.selected` でチェックマークが表示される）を変更せず維持する
- [ ] **SEL-02**: ヘッダの「完了」実行で、選択中の全タスクが完了扱い（`done: true`）になり、ガジェット一覧から外れる（既存 `POST /todos/delete` バックエンドを流用、未選択時は無操作）

### Internationalization (I18N)

- [ ] **I18N-01**: 新規・変更したヘッダUI文言（完了ラベル・選択件数）が ja/en の両ロケールキーで提供され、ロケールキーのパリティテストが通る

### Test (TEST)

- [ ] **TEST-01**: Minitest が、ヘッダへの「完了」配置・選択件数表示・空選択ガードをカバーする（welcome/todo ガジェットの構造テスト + `TodosController#delete` の controller テスト）
- [ ] **TEST-02**: Cucumber E2E が「複数タスクを選択 → ヘッダの完了を実行 → 対象タスクが完了扱いになる」フローを検証する
- [ ] **TEST-03**: マイルストーン終了時にトライスイートがグリーン（`yarn run lint` / `bin/rails test` / `bundle exec rake dad:test`）

## v2 Requirements

Deferred to future release.

### Gadget Header (HDR)

- **HDR-FUT-01**: 行ごとの個別「完了」操作（タスク単位のワンクリック完了）をガジェットに追加する
- **HDR-FUT-02**: ヘッダに「すべて選択 / 選択解除」トグルを追加する

## Out of Scope

| Feature | Reason |
|---------|--------|
| 選択UIの全面刷新（チェックボックス化・長押し選択モード） | 既存のタップ選択（チェックマーク）仕様を維持する方針のため対象外 |
| ガジェットからの完了取り消し（done → not done） | `/todos` 一覧画面のフィルタで対応済み；本マイルストーン範囲外 |
| todo 以外のガジェットヘッダ再設計 | 本マイルストーンは todo ガジェットに限定 |
| 新規 JS ライブラリ/ビルドツールの導入 | Sprockets + jQuery 制約を踏襲（standing out of scope） |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HDR-01 | Phase 127 | Pending |
| HDR-02 | Phase 127 | Pending |
| HDR-03 | Phase 127 | Pending |
| LAY-01 | Phase 127 | Pending |
| SEL-01 | Phase 127 | Pending |
| SEL-02 | Phase 127 | Pending |
| I18N-01 | Phase 127 | Pending |
| TEST-01 | Phase 128 | Pending |
| TEST-02 | Phase 128 | Pending |
| TEST-03 | Phase 128 | Pending |
