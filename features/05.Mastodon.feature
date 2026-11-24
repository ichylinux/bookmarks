# language: ja
@mastodon_gadget
機能: Mastodonガジェット

  シナリオ: ウェルカムページのガジェットにトゥートプレビューが表示される
    * モダンテーマでサインインします。
    * ルートページを開きます。
    * 最初のMastodonガジェットに "Cucumber stub toot preview" が表示される

  @mobile_portal
  シナリオ: モバイルでヘッダをタップしてMastodon設定ダイアログを開ける
    * モダンテーマでサインインします。
    * Mastodonガジェットが表示されたモバイル版ルートページを開きます。
    * Mastodonガジェットのヘッダをタップして操作を表示します。
    * Mastodon設定リンクをタップしてダイアログを開きます。
    * Mastodonガジェット設定で表示件数を 2 に変更して保存し、ガジェットが再読込されます。
