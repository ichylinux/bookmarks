class UpdatePortals < ActiveRecord::Migration
  def up
    User.all.each do |u|
      p = Portal.new(:user_id => u.id, :name => 'Home')
      p.save!
    end
  end

  def down
  end
end
