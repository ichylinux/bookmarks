---
quick_id: 260609-peo
status: complete
---

# Quick Task 260609-peo: TODO強調表示 — Summary

## Completed

- `todos.highlighted` カラムを追加し、サーバー側で永続化
- タスク行ホバー時に「強調表示」/「強調解除」ボタンを表示
- クリックで PATCH トグル → partial 差し替え
- 強調中は左ボーダー + 背景色 + 太字で視覚的に目立つ
- modern テーマ向けスタイルも追加
- コントローラテスト 3 件追加（lint + test green）

## Files changed

- `db/migrate/20260609000001_add_highlighted_to_todos.rb`
- `config/routes.rb`
- `app/controllers/todos_controller.rb`
- `app/views/todos/_todo.html.erb`
- `app/assets/javascripts/todos.js`
- `app/assets/stylesheets/todos.css.scss`
- `app/assets/stylesheets/themes/modern.css.scss`
- `config/locales/ja.yml`, `config/locales/en.yml`
- `test/controllers/todos_controller_test.rb`
