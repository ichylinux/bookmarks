class OauthIdentity < ApplicationRecord
  class UidOwnedByAnotherUserError < StandardError; end

  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true
  validates :provider, uniqueness: { scope: :user_id }

  def self.upsert_for!(user:, provider:, uid:)
    provider = provider.to_s
    uid = uid.to_s
    retried = false

    owned_by_other = find_by(provider: provider, uid: uid)
    if owned_by_other && owned_by_other.user_id != user.id
      raise UidOwnedByAnotherUserError
    end

    identity = find_or_initialize_by(user_id: user.id, provider: provider)
    identity.uid = uid
    identity.save!
    identity
  rescue ActiveRecord::RecordNotUnique
    existing = find_by(provider: provider, uid: uid)
    raise UidOwnedByAnotherUserError if existing && existing.user_id != user.id
    raise if retried

    retried = true
    retry
  end
end
