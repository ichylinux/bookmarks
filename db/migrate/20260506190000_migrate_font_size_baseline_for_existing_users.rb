class MigrateFontSizeBaselineForExistingUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :preferences, :font_size_notice_pending, :boolean, default: false, null: false

    Preference.reset_column_information
    Preference.migrate_legacy_font_sizes!
  end

  def down
    execute <<~SQL
      UPDATE preferences
      SET font_size = 'medium'
      WHERE font_size = 'small' AND font_size_notice_pending = TRUE
    SQL

    remove_column :preferences, :font_size_notice_pending
  end
end
