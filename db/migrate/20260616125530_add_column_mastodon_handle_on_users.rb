class AddColumnMastodonHandleOnUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :mastodon_handle, :string
  end
end
