class CalendarsController < ApplicationController
  def get_gadget
    head :not_found and return unless current_user.preference.use_calendar?

    @calendar_gadget = CalendarGadget.new(current_user)
    @calendar_gadget.display_date = Date.parse(params[:display_date])
    render layout: false
  end
end
