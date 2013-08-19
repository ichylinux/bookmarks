# language: ja

機能:

  シナリオ: アプリの新規作成
    * rails new bookmarks -d mysql --skip-bundle
    * Gemfileを編集
    * sudo bundle install
    
  シナリオ: データベースを作成
    * rake dad:db:config
    * rake dad:db:create
    * rake db:migrate


