class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  def self.record!(user, url)
    normalized = normalize_url(url)
    return if normalized.blank?

    upsert({ user_id: user.id, url: normalized, visited_at: Time.current })
  end

  def self.urls_for(user)
    where(user_id: user.id).pluck(:url).to_set
  end

  def self.normalize_url(url)
    url.to_s.sub(/#.*$/, '')
  end
end
