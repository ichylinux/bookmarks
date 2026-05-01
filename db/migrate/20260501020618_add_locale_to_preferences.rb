class AddLocaleToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :locale, :string, null: true
  end
end
