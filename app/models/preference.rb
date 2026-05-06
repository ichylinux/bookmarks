class Preference < ApplicationRecord
  FONT_SIZE_LARGE = 'large'.freeze
  FONT_SIZE_MEDIUM = 'medium'.freeze
  FONT_SIZE_SMALL = 'small'.freeze
  FONT_SIZES = [
    FONT_SIZE_LARGE,
    FONT_SIZE_MEDIUM,
    FONT_SIZE_SMALL
  ].freeze

  SUPPORTED_LOCALES = %w[ja en].freeze
  LOCALE_OPTIONS = {
    '自動' => nil,
    '日本語' => 'ja',
    'English' => 'en'
  }.freeze

  belongs_to :user, inverse_of: 'preference'

  validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true
  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true

  scope :font_size_notice_pending, -> { where(font_size_notice_pending: true) }

  def self.default_preference(user)
    ret = self.new(user: user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.theme = "modern"
    ret.use_todo = true
    ret.use_calendar = true
    ret
  end

  def self.normalize_font_size(font_size)
    return FONT_SIZE_MEDIUM unless FONT_SIZES.include?(font_size)

    font_size
  end

  def self.migrate_legacy_font_sizes!
    where(font_size: [nil, FONT_SIZE_MEDIUM]).update_all(
      font_size: FONT_SIZE_SMALL,
      font_size_notice_pending: true,
      updated_at: Time.current
    )
  end

  def normalized_font_size
    self.class.normalize_font_size(font_size)
  end

end
