class AddColumnDisplayCountOnFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :display_count, :integer, null: false
    Feed.all.each do |f|
      f.save!
    end
  end

  def down
    remove_column :feeds, :display_count
  end
end
