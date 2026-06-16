---
quick_id: 260617-2nf
status: complete
---

# Quick Task 260617-2nf: ToDoガジェット チェック即完了+Undo（提案B）

## Summary

各行に常時表示されていた「完了」リンク行（`.todo_actions`）を削除し、優先度列（チェック相当）のクリックで即完了する UX に変更した。完了時は 300ms のフェードアウト後に DOM から除去し、ガジェット下部に 3 秒間 Undo トーストを表示する。

## Changes

- `POST /todos/undo_complete` — `done: false` に戻し partial を返却
- `_todo_gadget.html.erb` — `<ol>` に API URL・CSRF・トースト文言を data 属性で埋め込み
- `todos.js` — `complete_todo` / `undo_complete` / トースト管理
- `todos.css.scss` — フェードアウト・トーストスタイル
- i18n — `todos.toast.completed` / `todos.toast.undo`
- テスト・Cucumber ステップ更新

## Verification

```bash
bundle exec rails test test/controllers/todos_controller_test.rb test/controllers/welcome_controller/dashboard_test.rb
# 40 runs, 238 assertions, 0 failures
```

## Commit

04e1460 — feat(todo): complete on priority click with undo toast
