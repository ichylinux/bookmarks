Before do |scenario|
  # Ensure browser/session artifacts never leak across scenarios.
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)
  instance_variable_set(:@_preferences_reset_for, nil)

  MastodonAccount.delete_all
  XAccount.delete_all
  XApiCall.delete_all
  VisitedLink.delete_all

  resize_browser_window(1280, 800)
end

Before('@mastodon_gadget') do
  MastodonAccount.create!(
    user_id: user.id,
    profile_url: 'https://ruby.social/@FastRuby',
    display_count: 3
  )

  @_mastodon_stub_lookup = WebMock.stub_request(:get, /ruby\.social\/api\/v1\/accounts\/lookup/)
    .to_return(
      status: 200,
      body: { id: 9876, username: 'FastRuby' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  @_mastodon_stub_statuses = WebMock.stub_request(:get, /ruby\.social\/api\/v1\/accounts\/9876\/statuses/)
    .to_return(
      status: 200,
      body: [{ content: '<p>Cucumber stub toot preview</p>', url: 'https://ruby.social/@FastRuby/999' }].to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

After('@mastodon_gadget') do
  WebMock.remove_request_stub(@_mastodon_stub_lookup) if @_mastodon_stub_lookup
  WebMock.remove_request_stub(@_mastodon_stub_statuses) if @_mastodon_stub_statuses
end

Before('@x_gadget') do
  u = user
  u.update_columns(oauth2_token: 'cucumber_oauth2_token')
  OauthIdentity.where(user_id: u.id, provider: 'twitter2').delete_all
  OauthIdentity.create!(user_id: u.id, provider: 'twitter2', uid: '9988776655')

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

  @_x_stub_tweets = WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/551199\/tweets/)
    .to_return(
      status: 200,
      body: { data: [{ id: '1234567890123456789', text: 'Cucumber stub X preview' }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

After('@x_gadget') do
  WebMock.remove_request_stub(@_x_stub_tweets) if @_x_stub_tweets
  XAccount.where(user_id: user.id).delete_all
  OauthIdentity.where(user_id: user.id, provider: 'twitter2').delete_all
  user.update_columns(oauth2_token: nil)
end

Before('@x_manual_add') do
  u = user
  u.update_columns(oauth2_token: 'manual_add_token')
  OauthIdentity.where(user_id: u.id, provider: 'twitter2').delete_all
  OauthIdentity.create!(user_id: u.id, provider: 'twitter2', uid: 'x_manual_uid_host')

  @_x_manual_stub_lookup_ok = WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/by\/username\/testhandle/)
    .to_return(
      status: 200,
      body: { 'data' => { 'id' => 'x_manual_uid', 'username' => 'testhandle', 'name' => 'Test Handle' } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  @_x_manual_stub_lookup_404 = WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/by\/username\/ghost_user/)
    .to_return(
      status: 404,
      body: { 'errors' => [{ 'detail' => 'Could not find user with username: ghost_user' }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  @_x_manual_stub_following = WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/x_manual_uid_host\/following/)
    .to_return(
      status: 200,
      body: { 'data' => [] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

After('@x_manual_add') do
  WebMock.remove_request_stub(@_x_manual_stub_lookup_ok) if @_x_manual_stub_lookup_ok
  WebMock.remove_request_stub(@_x_manual_stub_lookup_404) if @_x_manual_stub_lookup_404
  WebMock.remove_request_stub(@_x_manual_stub_following) if @_x_manual_stub_following
  XAccount.where(user_id: user.id).delete_all
  OauthIdentity.where(user_id: user.id, provider: 'twitter2').delete_all
  user.update_columns(oauth2_token: nil)
end

Before('@feed_visited_links') do
  @_feed_article_url = 'https://example.com/stub-article'

  feed_xml = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>Stub Feed</title>
        <link>http://slashdot.jp</link>
        <description>Stub feed for visited links test</description>
        <item>
          <title>Stub Article</title>
          <link>https://example.com/stub-article</link>
        </item>
      </channel>
    </rss>
  XML

  @_feed_visited_stub = WebMock.stub_request(:get, 'http://slashdot.jp/slashdotjp.rss')
    .to_return(status: 200, body: feed_xml, headers: { 'Content-Type' => 'application/rss+xml' })
end

After('@feed_visited_links') do
  WebMock.remove_request_stub(@_feed_visited_stub) if @_feed_visited_stub
end

Before('@admin_x_api_report_rack') do
  @admin_report_prev_driver = Capybara.current_driver
  Capybara.current_driver = :rack_test
end

After('@admin_x_api_report_rack') do
  Capybara.current_driver = @admin_report_prev_driver if @admin_report_prev_driver
end

Before('@admin_purge') do
  User.where(email: 'purge_e2e_test@example.com').delete_all

  u = User.create!(
    email: 'purge_e2e_test@example.com',
    password: Devise.friendly_token[0, 20]
  )
  u.update_columns(deleted: true, deleted_at: 91.days.ago)
end

After('@admin_purge') do
  User.where(email: 'purge_e2e_test@example.com').delete_all
end

Before('@connected_accounts') do
  u = user
  u.update_column(:password_auth_enabled, false)
  OauthIdentity.where(user_id: u.id).delete_all
  # Two providers linked: google and twitter2 (twitter alone will be the "last" in scenario 3)
  OauthIdentity.create!(user_id: u.id, provider: 'google_oauth2', uid: 'ca_google_uid')
  OauthIdentity.create!(user_id: u.id, provider: 'twitter2', uid: 'ca_twitter_uid')
end

After('@connected_accounts') do
  OauthIdentity.where(user_id: user.id).delete_all
  user.update_column(:password_auth_enabled, false)
end

Before('@account_deletion') do
  @account_deletion_previous_driver = Capybara.current_driver
  Capybara.current_driver = :rack_test

  u = User.find(3)
  u.update_columns(
    deleted: false,
    deleted_at: nil,
    email: 'user3@example.com',
    x_user_name: nil,
    oauth2_token: nil,
    oauth2_refresh_token: nil,
    oauth2_token_expires_at: nil
  )
end

After('@account_deletion') do
  Capybara.current_driver = @account_deletion_previous_driver if @account_deletion_previous_driver
end
