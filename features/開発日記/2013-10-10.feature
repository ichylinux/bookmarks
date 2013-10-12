# language: ja

機能:

  シナリオ: RSSフィードの表示
    * RSSフィード用のモデルを作成
      """
      <b>
      $ rails g model feed
      </b>
      """
    * マイグレーションファイルを編集
    * マイグレーション実行
      """
      <b>
      $ rake db:migrate
      </b>
      """
    * RSSのURLを登録するマスタ画面を作成
      """
      <b>
      $ rails g controller feeds
      </b>
      """
    * ルーティングを追加
    * トップページにRSSを表示
