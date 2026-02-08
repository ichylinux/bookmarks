class ChangeColumnDisplayCountOnFeeds < ActiveRecord::Migration
  def change
    change_column :feeds, :display_count, :integer, null: false, default: Feed::DEFAULT_DISPLAY_COUNT
  end
end
