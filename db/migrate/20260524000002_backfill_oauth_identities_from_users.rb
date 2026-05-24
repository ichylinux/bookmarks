class BackfillOauthIdentitiesFromUsers < ActiveRecord::Migration[8.1]
  def up
    rows = User.where.not(provider: nil).where.not(uid: nil).pluck(:id, :provider, :uid, :created_at)
    records = rows.map do |user_id, provider, uid, created_at|
      { user_id: user_id, provider: provider, uid: uid, created_at: created_at, updated_at: created_at }
    end
    return if records.empty?

    records.each do |record|
      OauthIdentity.find_or_create_by!(user_id: record[:user_id], provider: record[:provider]) do |identity|
        identity.uid = record[:uid]
        identity.created_at = record[:created_at]
        identity.updated_at = record[:updated_at]
      end
    end
  end

  def down; end
end
