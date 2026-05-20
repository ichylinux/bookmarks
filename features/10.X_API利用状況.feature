# language: ja

@admin_x_api_report
機能: 管理者 X API 利用状況

  シナリオ: 管理者が利用状況レポートを閲覧できる
    * 管理者としてサインインします。
    * X API 利用状況ページを開きます。
    * 利用状況テーブルに user2@example.com の行が表示される

  @admin_x_api_report_rack
  シナリオ: 非管理者は利用状況ページにアクセスできない
    * 一般ユーザーとしてサインインします。
    * X API 利用状況ページにアクセスすると 404 になる
