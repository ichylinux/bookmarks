module MastodonConst
  DEFAULT_DISPLAY_COUNT = 5
  PROFILE_URL_PATTERN = %r{\A(?:https?://)?([^/]+)/(?:@|users/)([^/?#]+)\z}
end

class MastodonAccount < ApplicationRecord
  include MastodonConst
  include Crud::ByUser

  belongs_to :user

  before_validation :parse_profile_url
  before_save :set_display_count

  validates :profile_url, presence: true
  validates :instance, presence: true
  validates :username, presence: true
  validates :display_count, numericality: { only_integer: true, greater_than: 0 }

  def gadget_id
    "mastodon_account_#{id}"
  end

  def title
    "@#{username}@#{instance}"
  end

  private

  def parse_profile_url
    self.instance = nil
    self.username = nil
    return if profile_url.blank?

    normalized = profile_url.strip.chomp('/')
    m = PROFILE_URL_PATTERN.match(normalized)
    return unless m

    self.instance = m[1].downcase
    self.username = m[2]
  end

  def set_display_count
    self.display_count = DEFAULT_DISPLAY_COUNT if display_count.to_i == 0
  end
end
