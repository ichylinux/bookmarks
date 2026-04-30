class AddUseNoteToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_column :preferences, :use_note, :boolean, default: false, null: false
  end
end
