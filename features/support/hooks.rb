# frozen_string_literal: true

Before do
  # Ensure browser/session artifacts never leak across scenarios.
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)

  pref = user.preference
  pref.update!(
    theme: "modern",
    use_note: false,
    use_todo: false,
    use_calendar: true,
    locale: "ja",
    default_priority: Todo::PRIORITY_NORMAL,
    open_links_in_new_tab: false
  )
end
