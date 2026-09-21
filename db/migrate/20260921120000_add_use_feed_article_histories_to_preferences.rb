class AddUseFeedArticleHistoriesToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :use_feed_article_histories, :boolean, null: false, default: false
  end
end
