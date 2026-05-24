class AddProviderUidIndexToOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    add_index :oauth_identities, [:provider, :uid],
              unique: true,
              name: 'index_oauth_identities_on_provider_and_uid'
  end
end
