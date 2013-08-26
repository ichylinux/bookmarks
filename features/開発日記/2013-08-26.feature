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
      $ rake dad:unicorn:install RAILS_ENV=production RAILS_ROOT=/home/${USER}/apps/bookmarks/current
      $ rake dad:nginx:app:config RAILS_ENV=production RAILS_ROOT=/home/${USER}/apps/bookmarks/current
      $ cap deploy:setup
      $ cap deploy:cold
      $ sudo /etc/init.d/nginx restart
      """
