class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  MAX_TITLE_LENGTH = 2083

  def self.record!(user, url, title: nil, source: nil)
    normalized = normalize_url(url)
    return if normalized.blank?

    attrs = { user_id: user.id, url: normalized, visited_at: Time.current }
    if source == 'feed'
      attrs[:source] = 'feed'
      stripped_title = title.to_s.strip
      if stripped_title.present?
        attrs[:title] = stripped_title.byteslice(0, MAX_TITLE_LENGTH)
      end
    end

    upsert(attrs)
  end

  def self.urls_for(user)
    where(user_id: user.id).pluck(:url).to_set
  end

  def self.normalize_url(url)
    url.to_s.split('#', 2).first.to_s
  end
end
