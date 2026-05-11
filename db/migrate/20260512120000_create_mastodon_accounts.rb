class CreateMastodonAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :mastodon_accounts do |t|
      t.integer :user_id, null: false
      t.string :profile_url, null: false
      t.string :instance, null: false
      t.string :username, null: false
      t.integer :display_count, null: false, default: 5
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end

    add_index :mastodon_accounts, :user_id
  end
end
