class RemoveUidAndProviderFromUsers < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = 'users'
  end

  class MigrationOauthIdentity < ApplicationRecord
    self.table_name = 'oauth_identities'
  end

  def up
    MigrationUser.where.not(provider: nil).where.not(uid: nil).find_each do |user|
      MigrationOauthIdentity.find_or_create_by!(user_id: user.id, provider: user.provider) do |identity|
        identity.uid = user.uid
      end
    end

    remove_index :users, :uid, if_exists: true
    remove_column :users, :uid
    remove_column :users, :provider
  end

  def down
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_index :users, :uid, unique: true

    MigrationOauthIdentity.find_each do |identity|
      MigrationUser.where(id: identity.user_id).update_all(
        provider: identity.provider,
        uid: identity.uid
      )
    end
  end
end
