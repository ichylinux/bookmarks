require 'holiday_jp'
require 'singleton'

module HolidayJp

  class Holidays
    include Singleton
  end

  def self.between(start, last)
    Holidays.instance.holidays.find_all do |date, _holiday|
      start <= date && date <= last
    end.map(&:last)
  end

  def self.holiday?(date)
    Holidays.instance.holidays[date]
  end
end