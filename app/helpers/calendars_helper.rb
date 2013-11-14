# coding: UTF-8

module CalendarsHelper

  def date_classes(calendar, date)
    ret = []
    ret << 'sunday' if date.sunday?
    ret << 'saturday' if date.saturday?
    ret << 'holiday' if calendar.holiday?(date)
    ret.join(' ')
  end
  
end