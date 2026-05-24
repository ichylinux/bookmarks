class OauthIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true
  validates :provider, uniqueness: { scope: :user_id }

  def self.upsert_for!(user:, provider:, uid:)
    identity = find_or_initialize_by(user_id: user.id, provider: provider.to_s)
    identity.uid = uid.to_s
    identity.save!
    identity
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
