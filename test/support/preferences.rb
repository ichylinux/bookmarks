def preference_params(options = {})
  {
    use_todo: true,
    open_links_in_new_tab: options.fetch(:open_links_in_new_tab, false),
    font_size: options.fetch(:font_size, Preference::FONT_SIZE_MEDIUM),
    default_priority: options.fetch(:default_priority, Todo::PRIORITY_NORMAL)
  }
end
