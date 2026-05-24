class AddCascadeDeleteForeignKeysToUsers < ActiveRecord::Migration[8.1]
  def change
    # oauth_identities already has a FK but without ON DELETE CASCADE; replace it
    remove_foreign_key :oauth_identities, :users
    add_foreign_key :oauth_identities, :users, on_delete: :cascade

    add_foreign_key :bookmarks, :users, on_delete: :cascade
    add_foreign_key :feeds, :users, on_delete: :cascade
    add_foreign_key :mastodon_accounts, :users, on_delete: :cascade
    add_foreign_key :notes, :users, on_delete: :cascade
    add_foreign_key :portal_layouts, :users, on_delete: :cascade
    add_foreign_key :portals, :users, on_delete: :cascade
    add_foreign_key :preferences, :users, on_delete: :cascade
    add_foreign_key :todos, :users, on_delete: :cascade
    add_foreign_key :visited_links, :users, on_delete: :cascade
    add_foreign_key :x_accounts, :users, on_delete: :cascade
    add_foreign_key :x_api_calls, :users, on_delete: :cascade
  end
end
