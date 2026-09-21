---
slug: suppress-email-autofocus-on-signup
date: "2026-06-02"
status: complete
---

# Quick Task: アカウント登録画面のメールアドレス自動フォーカス抑制

## Goal

アカウント登録画面にアクセスしたとき、メールアドレス入力欄へ自動フォーカスされないようにする。

## Tasks

1. `app/views/devise/registrations/new.html.erb` の email フィールドから `autofocus` を除去
2. `test/controllers/registrations_controller_test.rb` に autofocus 非付与のアサーションを追加
3. lint / test / dad:test を実行して回帰がないことを確認
