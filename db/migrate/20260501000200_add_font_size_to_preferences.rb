class AddFontSizeToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_column :preferences, :font_size, :string, default: nil, null: true
  end
end
