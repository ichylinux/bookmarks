class AddCascadeDeleteForeignKeysToUsers < ActiveRecord::Migration[8.1]
  TABLES_WITH_INTEGER_USER_ID = %i[
    bookmarks feeds mastodon_accounts notes portal_layouts portals
    preferences todos visited_links x_accounts x_api_calls
  ].freeze

  def up
    # visited_links has a composite index (user_id, url) at exactly the 3072-byte
    # limit with integer user_id. Widening to bigint (+4 bytes) would exceed it,
    # so we drop the index, change the column, and recreate with a smaller url prefix.
    if index_exists?(:visited_links, [:user_id, :url], name: "index_visited_links_on_user_id_and_url")
      remove_index :visited_links, name: "index_visited_links_on_user_id_and_url"
    end

    TABLES_WITH_INTEGER_USER_ID.each do |table|
      col = columns(table).find { |c| c.name == "user_id" }
      change_column table, :user_id, :bigint, null: false if col&.sql_type&.start_with?("int(")
    end

    unless index_exists?(:visited_links, [:user_id, :url], name: "index_visited_links_on_user_id_and_url")
      add_index :visited_links, %i[user_id url],
                name: "index_visited_links_on_user_id_and_url",
                unique: true, length: { url: 766 }
    end

    # Remove orphaned rows that would violate the FK constraints we're about to add
    TABLES_WITH_INTEGER_USER_ID.each do |table|
      execute "DELETE FROM #{table} WHERE user_id NOT IN (SELECT id FROM users)"
    end

    # oauth_identities already has a FK but without ON DELETE CASCADE; replace it
    remove_foreign_key :oauth_identities, :users if foreign_key_exists?(:oauth_identities, :users)
    add_foreign_key :oauth_identities, :users, on_delete: :cascade

    TABLES_WITH_INTEGER_USER_ID.each do |table|
      unless foreign_key_exists?(table, :users)
        add_foreign_key table, :users, on_delete: :cascade
      end
    end
  end

  def down
    TABLES_WITH_INTEGER_USER_ID.each do |table|
      remove_foreign_key table, :users if foreign_key_exists?(table, :users)
    end

    remove_foreign_key :oauth_identities, :users if foreign_key_exists?(:oauth_identities, :users)
    add_foreign_key :oauth_identities, :users

    if index_exists?(:visited_links, [:user_id, :url], name: "index_visited_links_on_user_id_and_url")
      remove_index :visited_links, name: "index_visited_links_on_user_id_and_url"
    end

    TABLES_WITH_INTEGER_USER_ID.each do |table|
      change_column table, :user_id, :integer, null: false
    end

    add_index :visited_links, %i[user_id url],
              name: "index_visited_links_on_user_id_and_url",
              unique: true, length: { url: 767 }
  end
end
