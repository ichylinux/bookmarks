---
status: clean
phase: 16-core-shell-and-shared-messages-translation
files_reviewed: 9
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
---

# Phase 16 Code Review

## Findings

問題は見つかりませんでした。

## レビュー対象

Standard depth で以下の Phase 16 変更ファイルをレビューしました。

- `app/controllers/notes_controller.rb`
- `app/views/common/_menu.html.erb`
- `app/views/layouts/application.html.erb`
- `config/locales/en.yml`
- `config/locales/ja.yml`
- `test/controllers/application_controller_test.rb`
- `test/controllers/notes_controller_test.rb`
- `test/i18n/locales_parity_test.rb`
- `test/i18n/rails_i18n_smoke_test.rb`

確認内容:

- `nav.*` と `flash.errors.generic` は `ja.yml` / `en.yml` でキー集合が揃っており、`Note` の native-brand 扱いも計画どおり維持されています。
- Layout と simple-theme menu は共有の absolute key `t('nav.*')` を使っており、lazy lookup や未定義キー参照は見当たりません。
- `notes_controller.rb` の fallback alert は action 内で `t('flash.errors.generic')` を呼び出しており、起動時 locale で固定される constant extraction リスクはありません。
- 追加テストは Phase 16 の主目的である chrome 表示と共有 flash キー、locale parity、rails-i18n smoke をカバーしています。

## 検証

- `bin/rails test test/i18n test/controllers/application_controller_test.rb test/controllers/notes_controller_test.rb` — PASS (`18 runs, 75 assertions, 0 failures, 0 errors, 0 skips`)

## 残留リスク

- Full gate (`yarn run lint && bin/rails test && bundle exec rake dad:test`) はこのレビューでは再実行していません。Phase summary 上は Plan 16-03 で green と記録されていますが、Cucumber には既知の scenario-order flake があります。
- `notes_controller.rb` の generic fallback 分岐自体は通常の validation error では到達しにくいため、テストは catalog lookup と controller source の `t('flash.errors.generic')` 利用確認に依存しています。現状実装では問題ありません。
