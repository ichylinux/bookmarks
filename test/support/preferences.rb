def preference_params(options = {})
  {
    use_todo: true,
    use_calendar: options.fetch(:use_calendar, true),
    open_links_in_new_tab: options.fetch(:open_links_in_new_tab, false),
    font_size: options.fetch(:font_size, nil),
    default_priority: options.fetch(:default_priority, Todo::PRIORITY_NORMAL),
    locale: options.fetch(:locale, nil)
  }
end
