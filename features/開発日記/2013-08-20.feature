# language: ja

機能:

  シナリオ: トップ画面を作成
    * rails g controller welcome
    * indexページを作成
    
  シナリオ: ログイン機能を設置
    * rails g devise user
    * devise用の日本語ファイルを取得
    * rake db:migrate
