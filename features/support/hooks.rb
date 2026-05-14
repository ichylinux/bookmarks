# frozen_string_literal: true

Before do
  # Ensure browser/session artifacts never leak across scenarios.
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)

  MastodonAccount.delete_all
  XAccount.delete_all

  XClient.stub_fetch_following_result = nil
  XClient.stub_fetch_tweets_result = nil

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

Before('@x_gadget') do
  u = user
  u.update_columns(
    provider: 'twitter',
    uid: '9988776655',
    token: 'cucumber_oauth_token',
    token_secret: 'cucumber_oauth_secret'
  )

  XAccount.create!(
    user_id: u.id,
    x_user_id: '551199',
    username: 'cucumber_x',
    display_name: 'Cucumber X User',
    selected: true,
    deleted: false,
    protected: false,
    display_count: 5
  )

  XClient.stub_fetch_tweets_result = {
    success: true,
    items: [{ text: 'Cucumber stub X preview', url: 'https://x.com/i/status/1234567890123456789' }]
  }
end

After('@x_gadget') do
  XClient.stub_fetch_tweets_result = nil
  XClient.stub_fetch_following_result = nil
  XAccount.where(user_id: user.id).delete_all
  user.update_columns(provider: nil, uid: nil, token: nil, token_secret: nil)
end
