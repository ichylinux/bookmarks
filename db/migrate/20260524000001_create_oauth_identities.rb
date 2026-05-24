class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_identities, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps
    end
  end
end
