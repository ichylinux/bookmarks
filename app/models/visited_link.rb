class VisitedLink < ApplicationRecord
  belongs_to :user
  validates :url, presence: true

  HISTORY_SOURCES = %w[feed x mastodon].freeze
  X_STATUS_URL = %r{\Ahttps://x\.com/i/status/\d+\z}
  MASTODON_STATUS_URL = %r{\Ahttps://[^/]+/@[^/]+/\d+\z}
  GADGET_ID_PATTERNS = {
    'feed' => /\Afeed_(\d+)\z/,
    'x' => /\Ax_account_(\d+)\z/,
    'mastodon' => /\Amastodon_account_(\d+)\z/
  }.freeze

  scope :feed_history_for, ->(user) { where(user_id: user.id, source: HISTORY_SOURCES).order(visited_at: :desc) }
  scope :liked_only, -> { where.not(liked_at: nil) }

  MAX_TITLE_LENGTH = 2083

  def liked?
    liked_at.present?
  end

  def self.record!(user, url, title: nil, source: nil, gadget_id: nil)
    normalized = normalize_url(url)
    return if normalized.blank?

    existing = find_by(user_id: user.id, url: normalized)
    attrs = { user_id: user.id, url: normalized, visited_at: Time.current }
    attrs[:liked_at] = existing.liked_at if existing&.liked_at.present?
    if HISTORY_SOURCES.include?(source)
      attrs[:source] = source
      stripped_title = title.to_s.strip
      if stripped_title.present?
        attrs[:title] = stripped_title.byteslice(0, MAX_TITLE_LENGTH)
      end
      resolved_gadget_id = resolve_gadget_id(user, gadget_id, source)
      attrs[:gadget_id] = resolved_gadget_id if resolved_gadget_id.present?
    end

    upsert(attrs)
  end

  def self.toggle_like!(user, url, title: nil, source: nil, gadget_id: nil)
    normalized = normalize_url(url)
    return nil if normalized.blank?
    return nil unless HISTORY_SOURCES.include?(source)

    row = find_by(user_id: user.id, url: normalized)
    if row&.liked_at.present?
      row.update!(liked_at: nil)
      return false
    end

    now = Time.current
    attrs = {
      visited_at: row&.visited_at || now,
      liked_at: now,
      source: source
    }
    stripped_title = title.to_s.strip
    attrs[:title] = stripped_title.byteslice(0, MAX_TITLE_LENGTH) if stripped_title.present?
    resolved_gadget_id = resolve_gadget_id(user, gadget_id, source)
    attrs[:gadget_id] = resolved_gadget_id if resolved_gadget_id.present?

    if row
      row.update!(attrs)
    else
      create!(attrs.merge(user_id: user.id, url: normalized))
    end
    true
  end

  def self.link_state_for(user, urls)
    normalized = Array(urls).map { |u| normalize_url(u) }.reject(&:blank?)
    empty = Set.new
    return { visited: empty, liked: empty } if normalized.empty?

    rows = where(user_id: user.id, url: normalized).pluck(:url, :liked_at)
    visited = rows.map(&:first).to_set
    liked = rows.select { |_, liked_at| liked_at.present? }.map(&:first).to_set
    { visited: visited, liked: liked }
  end

  def self.gadget_titles_for(user, gadget_ids)
    ids = Array(gadget_ids).compact.uniq
    return {} if ids.empty?

    titles = {}
    feed_ids = ids.filter_map { |g| g[/\Afeed_(\d+)\z/, 1]&.to_i }
    x_ids = ids.filter_map { |g| g[/\Ax_account_(\d+)\z/, 1]&.to_i }
    mastodon_ids = ids.filter_map { |g| g[/\Amastodon_account_(\d+)\z/, 1]&.to_i }

    Feed.where(user_id: user.id, id: feed_ids).find_each { |f| titles[f.gadget_id] = f.title }
    XAccount.where(user_id: user.id, id: x_ids).find_each { |x| titles[x.gadget_id] = x.title }
    MastodonAccount.where(user_id: user.id, id: mastodon_ids).find_each { |m| titles[m.gadget_id] = m.title }

    titles
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

  def self.resolve_gadget_id(user, gadget_id, source)
    return nil unless HISTORY_SOURCES.include?(source)

    raw = gadget_id.to_s.strip
    return nil if raw.blank?

    pattern = GADGET_ID_PATTERNS[source]
    return nil unless pattern

    match = raw.match(pattern)
    return nil unless match

    record_id = match[1].to_i
    case source
    when 'feed'
      return raw if Feed.where(user_id: user.id, id: record_id).exists?
    when 'x'
      return raw if XAccount.where(user_id: user.id, id: record_id).exists?
    when 'mastodon'
      return raw if MastodonAccount.where(user_id: user.id, id: record_id).exists?
    end

    nil
  end
  private_class_method :inferred_history_source, :resolve_gadget_id
end
