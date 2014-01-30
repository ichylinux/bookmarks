# language: ja

機能: スプリント１

  シナリオ: アプリの新規作成
    * rails new bookmarks -d mysql --skip-bundle
    * Gemfileを編集
    * sudo bundle install
    
  シナリオ: データベースを作成
    * rake dad:db:config
    * rake dad:db:create
    * rake db:migrate

  シナリオ: アプリを起動
    * rails s
    * http://localhost:3000 にアクセス


