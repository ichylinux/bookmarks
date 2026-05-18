Before do |scenario|
  # Ensure browser/session artifacts never leak across scenarios.
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)

  MastodonAccount.delete_all
  XAccount.delete_all
  VisitedLink.delete_all

  pref = user.preference
  pref.update!(
    theme: "modern",
    use_note: false,
    use_todo: false,
    use_calendar: true,
    locale: "ja",
    default_priority: Todo::PRIORITY_NORMAL,
    open_links_in_new_tab: false,
    portal_column_count: 3,
    portal_column_widths: Preference.equal_portal_column_widths(3)
  )

  unless scenario.source_tag_names.include?('@mobile_portal')
    resize_browser_window(1280, 800)
  end
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
  user.update_columns(provider: nil, uid: nil, token: nil, token_secret: nil)
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
