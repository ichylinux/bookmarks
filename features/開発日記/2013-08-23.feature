# language: ja

機能:

  シナリオ: ブックマークの管理機能を作成
    * モデルを作成
      """
      <b>
      $ rails g model bookmark
      </b>
      """
    * マイグレーション
      """
      <b>
      $ rake db:migrate
      </b>
      """
    * コントローラを作成
      """
      <b>
      $ rake dad:generate:controller bookmarks
      </b>
      """
    * ルーティングを追加
    * モデルの属性を一括代入できるように設定を変更
    * ビューを作成
    * ラベルを日本語化
    * 管理機能へのリンクを作成

  シナリオ: トップページにブックマークの一覧を表示
    * indexアクションを追加