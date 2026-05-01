Before do
  Capybara.reset_sessions!
  @_current_user = nil
  @_user = nil

  User.find_each do |u|
    u.update!(
      consumed_timestep: nil,
      otp_required_for_login: false
    )

    preference = u.preference || Preference.default_preference(u)
    preference.assign_attributes(
      theme: 'modern',
      use_todo: true,
      use_note: false,
      default_priority: Todo::PRIORITY_NORMAL,
      font_size: nil,
      open_links_in_new_tab: false,
      locale: nil
    )
    preference.save!
  end
end
