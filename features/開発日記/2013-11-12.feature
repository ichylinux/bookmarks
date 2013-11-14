# language: ja

機能:

  シナリオ: カレンダーの作成
    * モデルを作成
      """
      <b>
      $ rails g model Calendar
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
      $ rake dad:generate:controller calendars
      </b>
      """
    * ビューを作成
      """
      <b>
      $ rake dad:generate:view calendars
      </b>
      """
    * ルーティングを追加
    * メニューを追加
    