# coding: UTF-8

class Calendar < ActiveRecord::Base
  belongs_to :user

  def gadget_id
    "calendar_#{self.id}"
  end

  def entries
    (1..31)
  end

  def day_of_week(index)
    @names ||= %w{ 日 月 火 水 木 金 土 }
    @names[index]
  end
  
  def display_date
    @display_date ||= Date.today.beginning_of_month
  end

  def display_date=(date)
    @display_date = date
  end

  def display_year
    display_date.year
  end

  def display_month
    display_date.month
  end

  def holiday?(date)
    HolidayJp.holiday?(date)
  end
  
  def holiday(date)
    from = display_date.prev_month.beginning_of_month
    to = display_date.next_month.end_of_month
    @holidays_of_month ||= HolidayJp.between(from, to)
    @holidays_of_month.each do |holiday|
      return holiday.name if holiday.date == date
    end
    
    nil
  end

end
