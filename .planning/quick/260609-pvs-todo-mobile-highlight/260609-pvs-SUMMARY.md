---
quick_id: 260609-pvs
status: complete
---

# Quick Task 260609-pvs: モバイルでのTODO強調表示 — Summary

## 結論

モバイル（画面幅 ≤767px）では「強調表示」ボタンを**常時表示**する。タップで既存の PATCH トグル API をそのまま利用。

デスクトップは従来どおりホバー時のみ表示。

## 変更

- `app/assets/stylesheets/todos.css.scss` — 767px 以下で `.todo-highlight-btn { display: inline-block }`
