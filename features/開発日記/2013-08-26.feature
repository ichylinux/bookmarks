# language: ja

機能:

  シナリオ: デプロイ
    * Unicornの設定ファイルを用意
      """
      $ rake dad:unicorn:install
      """
    * Capistranoの設定ファイルを用意
      """
      $ capify .
      """
    * サーバにログインし、以下のコマンドを実行
      """
      $ ssh ホスト名
      $ rake dad:unicorn:install
      $ rake dad:nginx:app:config
      $ cap deploy:setup
      $ cap deploy:cold
      """
