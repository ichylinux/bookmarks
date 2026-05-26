class BackfillUseBookmarkOnPreferences < ActiveRecord::Migration[8.1]
  def up
    # Users with no non-deleted bookmarks inherit the old implicit behaviour
    # (gadget was hidden). Set use_bookmark false so they see no change.
    execute <<~SQL
      UPDATE preferences
      SET use_bookmark = FALSE
      WHERE user_id NOT IN (
        SELECT DISTINCT user_id FROM bookmarks WHERE deleted = FALSE
      )
    SQL
  end

  def down
    execute "UPDATE preferences SET use_bookmark = TRUE"
  end
end
