class Preference < ApplicationRecord
  FONT_SIZE_LARGE = 'large'.freeze
  FONT_SIZE_MEDIUM = 'medium'.freeze
  FONT_SIZE_SMALL = 'small'.freeze
  FONT_SIZES = [
    FONT_SIZE_LARGE,
    FONT_SIZE_MEDIUM,
    FONT_SIZE_SMALL
  ].freeze

  PORTAL_COLUMN_COUNTS = [3, 4].freeze
  SHOW_ICONS_DEFAULT = true

  SUPPORTED_LOCALES = %w[ja en].freeze
  LOCALE_OPTIONS = {
    '自動' => nil,
    '日本語' => 'ja',
    'English' => 'en'
  }.freeze

  belongs_to :user, inverse_of: 'preference'

  validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true
  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
  validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }
  validates :show_icons, inclusion: { in: [true, false] }
  validate :validate_portal_column_widths

  before_validation :cast_portal_column_widths
  before_validation :normalize_portal_column_widths_length

  scope :font_size_notice_pending, -> { where(font_size_notice_pending: true) }

  def self.equal_portal_column_widths(count)
    case count
    when 3 then [34, 33, 33]
    when 4 then [25, 25, 25, 25]
    else
      raise ArgumentError, "unsupported portal_column_count: #{count}"
    end
  end

  def self.default_preference(user)
    ret = self.new(user: user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.theme = "modern"
    ret.use_bookmark = true
    ret.use_todo = true
    ret.use_calendar = true
    ret.portal_column_count = PORTAL_COLUMN_COUNTS.first
    ret.show_icons = SHOW_ICONS_DEFAULT
    ret
  end

  def self.normalize_font_size(font_size)
    return FONT_SIZE_MEDIUM unless FONT_SIZES.include?(font_size)

    font_size
  end

  def normalized_font_size
    self.class.normalize_font_size(font_size)
  end

  def effective_portal_column_widths
    widths = normalized_portal_column_widths_array
    return widths if widths_valid_for_count?(widths, portal_column_count)

    self.class.equal_portal_column_widths(portal_column_count)
  end

  private

  def cast_portal_column_widths
    return if portal_column_widths.nil?

    self.portal_column_widths = Array(portal_column_widths).map(&:to_i)
  end

  def normalize_portal_column_widths_length
    return unless PORTAL_COLUMN_COUNTS.include?(portal_column_count)

    widths = normalized_portal_column_widths_array
    return if widths.nil?
    return if widths.length == portal_column_count

    self.portal_column_widths = self.class.equal_portal_column_widths(portal_column_count)
  end

  def validate_portal_column_widths
    return if portal_column_widths.nil?

    widths = normalized_portal_column_widths_array
    unless widths_valid_for_count?(widths, portal_column_count)
      errors.add(:portal_column_widths, :invalid)
    end
  end

  def normalized_portal_column_widths_array
    raw = portal_column_widths
    return nil if raw.nil?

    Array(raw).map { |value| value.to_i }
  end

  def widths_valid_for_count?(widths, count)
    return false unless widths.is_a?(Array)
    return false unless widths.length == count
    return false unless widths.all? { |width| width.is_a?(Integer) && width.positive? }
    return false unless widths.sum == 100

    true
  end

end
