# language: ja

機能:

  シナリオ: トップ画面を作成
    * rails g controller welcome
    * indexページを作成
    
  シナリオ: ログイン機能を設置
    * rails g devise user
    * devise用の日本語ファイルを取得
    * rake db:migrate
    * application_controllerを修正
    * レイアウトにログアウトのリンクを用意

  シナリオ: アプリを起動
    * rails s
    * http://localhost:3000 にアクセスするとログイン画面が表示される
    * Sign up をクリック
    * ユーザ登録画面に遷移
    * メールアドレスとパスワードを入力して Sign up をクリック
    * トップ画面に遷移し、ログアウトのリンクが表示される

