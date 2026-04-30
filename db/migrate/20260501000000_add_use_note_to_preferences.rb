class AddUseNoteToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_column :preferences, :use_note, :boolean, default: true, null: false
  end
end
