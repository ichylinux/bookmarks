class AddUniqueIndexOnUsersMastodonHandle < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :mastodon_handle, unique: true
  end
end
