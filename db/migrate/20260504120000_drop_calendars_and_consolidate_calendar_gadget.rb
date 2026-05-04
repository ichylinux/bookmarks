class DropCalendarsAndConsolidateCalendarGadget < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:portal_layouts)
      execute <<-SQL.squish
        UPDATE portal_layouts
        SET gadget_id = 'calendar'
        WHERE gadget_id REGEXP '^calendar_[0-9]+$'
      SQL

      seen = {}
      PortalLayout.where(gadget_id: 'calendar').order(:user_id, :column_no, :display_order).each do |row|
        if seen[row.user_id]
          row.destroy!
        else
          seen[row.user_id] = true
        end
      end
    end

    drop_table :calendars if table_exists?(:calendars)
  end

  def down
    create_table :calendars, charset: 'utf8mb4', collation: 'utf8mb4_general_ci', force: :cascade do |t|
      t.integer :user_id, null: false
      t.string :title
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end
  end
end
