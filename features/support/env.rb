require 'daddy/cucumber/rails'

Before do
  Capybara.reset_sessions!
  @_current_user = nil

  fixture_user = User.find_by(id: 1)
  next unless fixture_user

  preference = fixture_user.preference || fixture_user.build_preference
  preference.assign_attributes(
    theme: 'modern',
    use_todo: true,
    use_note: false,
    default_priority: Todo::PRIORITY_NORMAL,
    locale: nil
  )
  preference.save!
end
