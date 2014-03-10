class UpdatePortalsAgain < ActiveRecord::Migration
  def up
    User.all.each do |u|
      u.save!
    end
  end

  def down
  end
end
