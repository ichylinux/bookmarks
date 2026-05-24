class BackfillOauthIdentitiesFromUsers < ActiveRecord::Migration[8.1]
  # Inline models — immune to future changes in the live model classes
  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class OauthIdentity < ActiveRecord::Base
    self.table_name = 'oauth_identities'
  end

  def up
    rows = User.where.not(provider: nil).where.not(uid: nil).pluck(:id, :provider, :uid, :created_at)
    rows.each do |user_id, provider, uid, created_at|
      OauthIdentity.find_or_create_by!(user_id: user_id, provider: provider) do |i|
        i.uid        = uid
        i.created_at = created_at
        i.updated_at = created_at
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Backfill cannot be automatically reversed; remove rows manually if needed."
  end
end
