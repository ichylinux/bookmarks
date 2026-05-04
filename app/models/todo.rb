module TodoConst
  PRIORITY_HIGH = 1
  PRIORITY_NORMAL = 2
  PRIORITY_LOW = 3

  PRIORITY_KEYS = {
    PRIORITY_HIGH => :high,
    PRIORITY_NORMAL => :normal,
    PRIORITY_LOW => :low,
  }.freeze

  class PriorityLabels
    include Enumerable

    def initialize(keys)
      @keys = keys
    end

    def [](priority)
      Todo.priority_label(priority)
    end

    def invert
      Todo.priority_options.to_h
    end

    def each(&block)
      @keys.each_key { |priority| block.call(priority, self[priority]) }
    end
  end

  PRIORITIES = PriorityLabels.new(PRIORITY_KEYS).freeze
end

class Todo < ApplicationRecord
  include TodoConst
  include Crud::ByUser

  belongs_to :user

  def self.priority_options
    PRIORITY_KEYS.map { |priority, _key| [priority_label(priority), priority] }
  end

  def self.priority_key(priority)
    PRIORITY_KEYS.fetch(priority)
  end

  def self.priority_label(priority)
    I18n.t("todos.priorities.#{priority_key(priority)}")
  end

  def priority_name
    self.class.priority_label(priority)
  end

end
