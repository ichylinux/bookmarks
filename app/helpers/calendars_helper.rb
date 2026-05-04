module CalendarsHelper
  def date_classes(calendar_gadget, date)
    ret = []
    ret << 'today' if date.today?
    ret << 'sunday' if date.sunday?
    ret << 'saturday' if date.saturday?
    ret << 'holiday' if calendar_gadget.holiday?(date)
    ret.join(' ')
  end
end
