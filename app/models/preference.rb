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

  def self.default_preference(user)
    ret = self.new(user: user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.theme = "modern"
    ret.use_todo = true
    ret.use_calendar = true
    ret
  end

end
