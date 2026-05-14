class UpdateShowColumnNavButtonsOnPreferences < ActiveRecord::Migration[8.1]
  def change
    Preference.update_all(['show_column_nav_buttons = ?', true])
  end
end
