class CalendarGadget
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def gadget_id
    'calendar'
  end

  def title
    I18n.t('gadgets.calendar.title')
  end

  def entries
    (1..31)
  end

  def day_of_week(index)
    I18n.t('date.abbr_day_names')[index]
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
    return false unless I18n.locale.to_sym == :ja

    HolidayJp.holiday?(date)
  end

  def holiday(date)
    return nil unless holiday?(date)

    from = display_date.prev_month.beginning_of_month
    to = display_date.next_month.end_of_month
    @holidays_of_month ||= HolidayJp.between(from, to)
    @holidays_of_month.each do |h|
      return h.name if h.date == date
    end

    nil
  end
end
