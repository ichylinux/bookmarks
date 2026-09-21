---
status: complete
date: "2026-06-02"
commit: uncommitted
---

# Quick Task Summary: アカウント登録画面のメールアドレス自動フォーカス抑制

## Done

- 新規登録フォームの `user[email]` から `autofocus: true` を削除
- 登録画面テストに `input[type=email][autofocus]` が 0 件であることを追加

## Verification

- `yarn run lint` ✓
- `bin/rails test` ✓
- `bundle exec rake dad:test` ✓
