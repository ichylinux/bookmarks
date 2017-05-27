class AddColumnContentOnTweets < ActiveRecord::Migration[5.0]
  def change
    add_column :tweets, :content, :text
  end
end
