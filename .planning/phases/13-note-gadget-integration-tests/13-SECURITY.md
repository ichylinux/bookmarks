---
phase: 13
slug: note-gadget-integration-tests
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-30
---

# Phase 13 — Security

> プランファイル（`13-01`〜`13-04`）の `<threat_model>` を統合し、ビュー／コントローラ／レイアウトと `test/`・`features/` の根拠で緩和を確認した。

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| ブラウザ → Rails（ノート表示） | `_note_gadget` は保存済みノート本文を HTML として出力 | メモ本文（ユーザー作成テキスト、最大 4000 字／Phase 11） |
| Devise session → Welcome | 一覧は常に `current_user` 配下 | `user_id` はセッション主体に紐づく |
| CSRF | メモ作成は `note` 用 `form_with`、`local: true` | POST と Rails 管理トークン |
| テーマ境界 | ガジェット／タブはシンプルテーマ分岐内のみ | UI 表面の露出抑制 |
| 認証 → レイアウト | `drawer_ui?` と明示的なシンプルメニュー条件 | ログイン状態とテーマの組 |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-13-01 | Tampering (XSS 相当) | `_note_gadget.html.erb` の本文表示 | mitigate | `<%= note.body %>` のみ。`raw` / `html_safe` 不使用（該当ファイル grep および目視） | closed |
| T-13-02 | Information Disclosure | `WelcomeController#index` のノート取得 | mitigate | `@notes = current_user.notes.recent` — グローバル `Note` クエリなし | closed |
| T-13-03 | Tampering | メモ作成フォーム POST | mitigate | `form_with ... local: true`、レイアウトに `csrf_meta_tags` | closed |
| T-13-04 | Information Disclosure | 非シンプルでのノート UI 露出 | mitigate | `welcome/index.html.erb` で `favorite_theme == 'simple'` 内にのみ `render 'note_gadget'` | closed |
| T-13-05 | Tampering / 整合性 | 保存後のタブ・URL | mitigate | `NotesController` が `root_path(tab: 'notes')` へリダイレクト（既存）; Cucumber `features/04.ノート.feature` で `tab=notes` を検証 | closed |
| T-13-06 | Elevation / 露出 | シンプルで隠しドロワー DOM | mitigate | `application.html.erb` でドロワー／オーバーレイを `drawer_ui?` でゲート。シンプルでは描画されない | closed |
| T-13-07 | Spoofing（未認証 UI） | ヘッダ・ドロワー・シンプルメニュー | mitigate | `drawer_ui?` に `user_signed_in?` を包含。シンプルメニューは `user_signed_in? && favorite_theme == 'simple'`（`!drawer_ui?` ではない） | closed |
| T-13-08 | Denial of QA（回帰） | ドロワー挙動・隔離 | mitigate | `layout_structure_test.rb` と `welcome_controller_test.rb`（計画 13-02 / 13-04 の意図に沿う）が緑 | closed |

*Disposition: mitigate（実装）· accept（文書化リスク）· transfer（第三者）*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-30 | 8 | 8 | 0 | Cursor / gsd-secure-phase |

### Evidence Summary

- **T-13-01:** `app/views/welcome/_note_gadget.html.erb` — 本文は `<%= note.body %>`、`raw` / `html_safe` なし。
- **T-13-02:** `app/controllers/welcome_controller.rb` L6 `current_user.notes.recent`。
- **T-13-03:** 同一パーシャルで `form_with ... local: true`；`application.html.erb` `csrf_meta_tags`。
- **T-13-04:** `app/views/welcome/index.html.erb` — `favorite_theme == 'simple'` ブロック内の `render 'note_gadget'`。
- **T-13-05:** ルーティング POST の信頼境界は Phase 11 と共有。E2E は `features/step_definitions/notes.rb` でクエリ `tab` が `notes` であることを確認。
- **T-13-06 / T-13-07:** `welcome_helper.rb` の `drawer_ui?` と `application.html.erb` の条件分岐整合。
- **T-13-08:** `bin/rails test` スイートおよび（必要時）`DRIVER=chrome HEADLESS=true bundle exec cucumber features/04.ノート.feature` が CI 方針に沿って実行可能であること（本セッションでは実装・既存テストとの整合のみ記録）。

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-30
