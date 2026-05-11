# frozen_string_literal: true

Before do
  # Ensure browser/session artifacts never leak across scenarios.
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)

  MastodonAccount.delete_all

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

Before('@mastodon_gadget') do
  MastodonAccount.create!(
    user_id: user.id,
    profile_url: 'https://ruby.social/@FastRuby',
    display_count: 3
  )

  MastodonClient.stub_fetch_result = {
    success: true,
    items: [{ text: 'Cucumber stub toot preview', url: 'https://ruby.social/@FastRuby/999' }]
  }
end

After('@mastodon_gadget') do
  MastodonClient.stub_fetch_result = nil
end
