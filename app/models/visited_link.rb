class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  HISTORY_SOURCES = %w[feed x mastodon].freeze
  X_STATUS_URL = %r{\Ahttps://x\.com/i/status/\d+\z}
  MASTODON_STATUS_URL = %r{\Ahttps://[^/]+/@[^/]+/\d+\z}

  scope :feed_history_for, ->(user) { where(user_id: user.id, source: HISTORY_SOURCES).order(visited_at: :desc) }

  MAX_TITLE_LENGTH = 2083

  def self.record!(user, url, title: nil, source: nil)
    normalized = normalize_url(url)
    return if normalized.blank?

    attrs = { user_id: user.id, url: normalized, visited_at: Time.current }
    if HISTORY_SOURCES.include?(source)
      attrs[:source] = source
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

  def self.backfill_history_sources!
    ids_by_source = Hash.new { |h, k| h[k] = [] }
    where(source: nil).find_each do |row|
      inferred = inferred_history_source(row.url)
      ids_by_source[inferred] << row.id if inferred
    end
    ids_by_source.each do |source, ids|
      where(id: ids, source: nil).update_all(source: source)
    end
  end

  def self.inferred_history_source(url)
    case url
    when X_STATUS_URL then 'x'
    when MASTODON_STATUS_URL then 'mastodon'
    end
  end
  private_class_method :inferred_history_source
end
