class Preference < ActiveRecord::Base
  FONT_SIZE_LARGE = 'large'.freeze
  FONT_SIZE_MEDIUM = 'medium'.freeze
  FONT_SIZE_SMALL = 'small'.freeze
  FONT_SIZES = [
    FONT_SIZE_LARGE,
    FONT_SIZE_MEDIUM,
    FONT_SIZE_SMALL
  ].freeze
  FONT_SIZE_OPTIONS = {
    '大' => FONT_SIZE_LARGE,
    '中' => FONT_SIZE_MEDIUM,
    '小' => FONT_SIZE_SMALL
  }.freeze

  belongs_to :user, inverse_of: 'preference'

  validates :font_size, inclusion: { in: FONT_SIZES }

  def self.default_preference(user)
    ret = self.new(user: user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.theme = "modern"
    ret.use_todo = true
    ret.font_size = FONT_SIZE_MEDIUM
    ret
  end

end
