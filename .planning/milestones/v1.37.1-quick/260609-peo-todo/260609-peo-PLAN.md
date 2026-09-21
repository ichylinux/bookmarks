---
quick_id: 260609-peo
status: planned
---

# Quick Task 260609-peo: TODO強調表示

特定のタスクを目立つように表示できるようにしたい。該当タスクをホバーすると「強調表示」のボタンが出て、クリックするとそのTODOの見た目が目立つデザインになる。

## Tasks

### Task 1: Backend — highlighted カラムとトグル API

- Migration: `todos.highlighted` boolean (default false)
- Route: `PATCH /todos/:id/toggle_highlight`
- Controller: `toggle_highlight` action（認可チェック付き、partial 返却）

### Task 2: Frontend — ホバーボタンと強調スタイル

- `_todo.html.erb`: ホバー時表示ボタン、highlighted クラス
- `todos.js`: PATCH でトグル、partial 差し替え
- `todos.css.scss` + modern theme: 強調表示の視覚デザイン
- i18n: 強調表示 / 強調解除

### Task 3: Tests

- Controller test: トグル成功、他人のタスクは 404
