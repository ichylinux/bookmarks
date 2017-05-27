class AddColumnTwtterUserIdOnTweets < ActiveRecord::Migration[5.0]
  def change
    add_column :tweets, :twitter_user_id, :string
  end
end
