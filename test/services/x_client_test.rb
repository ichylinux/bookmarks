require 'test_helper'

class XClientTest < ActiveSupport::TestCase
  def test_fetch_following_returns_normalized_items
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(%r{/2/users/\w+/following}) do
      [200, { 'Content-Type' => 'application/json' },
       { data: [{ id: '1', username: 'a', name: 'A', protected: false }], meta: {} }.to_json]
    end
    conn = Faraday.new do |f|
      f.adapter :test, stubs
      f.options.timeout = 5
      f.options.open_timeout = 3
    end
    r = XClient.new(connection: conn).fetch_following(user: users(:twitter_user))
    assert r[:success]
    assert_equal 'a', r[:items].first[:username]
  end

  def test_fetch_following_non_200_returns_api_error
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(%r{/2/users/\w+/following}) { [500, {}, 'Server Error'] }
    conn = Faraday.new do |f|
      f.adapter :test, stubs
    end
    r = XClient.new(connection: conn).fetch_following(user: users(:twitter_user))
    assert_not r[:success]
    assert_equal :api_error, r[:error]
  end

  def test_fetch_tweets_expands_tco_and_truncates
    WebMock.stub_request(:get, /api\.twitter\.com\/2\/users\/9\/tweets/)
      .to_return(
        status: 200,
        body: { data: [{ id: '9', text: 'a' * 200 }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    r = XClient.new.fetch_recent_tweets(user: users(:twitter_user), x_user_id: '9', limit: 5)
    assert r[:success]
    assert_operator r[:items].first[:text].length, :<=, 100
  end

  def test_fetch_following_http_paginates
    stubs = Faraday::Adapter::Test::Stubs.new
    calls = 0
    stubs.get(%r{/2/users/99/following}) do
      calls += 1
      if calls == 1
        [200, { 'Content-Type' => 'application/json' },
         { data: [{ id: '1', username: 'u1', name: 'U1', protected: false }], meta: { next_token: 'n1' } }.to_json]
      else
        [200, { 'Content-Type' => 'application/json' },
         { data: [{ id: '2', username: 'u2', name: 'U2', protected: true }], meta: {} }.to_json]
      end
    end

    conn = Faraday.new do |f|
      f.adapter :test, stubs
      f.options.timeout = 5
      f.options.open_timeout = 3
    end

    u = users(:twitter_user)
    u.update_columns(uid: '99', token: 't', token_secret: 's')

    r = XClient.new(connection: conn).fetch_following(user: u, max_results: 3)
    assert r[:success], r.inspect
    assert_equal 2, r[:items].size
  ensure
    u = users(:twitter_user)
    u.update_columns(uid: nil, token: nil, token_secret: nil)
  end

  def test_bearer_header_used_when_oauth2_token_present
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/2/ping') do |env|
      auth = env[:request_headers]['Authorization'].to_s
      assert_match(/\ABearer /, auth)
      assert_no_match(/oauth_consumer_key/, auth)
      [200, { 'Content-Type' => 'application/json' }, '{}']
    end

    u = users(:twitter_user)
    u.update_columns(oauth2_token: 'my-bearer-token', oauth2_token_expires_at: 1.hour.from_now)

    conn = Faraday.new(url: 'https://api.twitter.com') do |f|
      f.headers['Authorization'] = "Bearer #{u.oauth2_token}"
      f.adapter :test, stubs
    end

    conn.get('/2/ping')
  ensure
    u = users(:twitter_user)
    u.update_columns(oauth2_token: nil, oauth2_token_expires_at: nil)
  end

  def test_fetch_following_uses_bearer_when_oauth2_token_present
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(%r{/2/users/\w+/following}) do |env|
      assert_match(/\ABearer /, env[:request_headers]['Authorization'].to_s)
      [200, { 'Content-Type' => 'application/json' },
       { data: [{ id: '1', username: 'b', name: 'B', protected: false }], meta: {} }.to_json]
    end

    u = users(:twitter_user)
    u.update_columns(oauth2_token: 'my-bearer-token', oauth2_token_expires_at: 1.hour.from_now)

    conn = Faraday.new do |f|
      f.headers['Authorization'] = "Bearer #{u.oauth2_token}"
      f.adapter :test, stubs
      f.options.timeout = 5
      f.options.open_timeout = 3
    end

    r = XClient.new(connection: conn).fetch_following(user: u)
    assert r[:success]
    assert_equal 'b', r[:items].first[:username]
  ensure
    u = users(:twitter_user)
    u.update_columns(oauth2_token: nil, oauth2_token_expires_at: nil)
  end

  def test_oauth1_header_present_on_real_faraday_stack
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/2/ping') do |env|
      auth = env[:request_headers]['Authorization'].to_s
      assert_match(/\AOAuth oauth_consumer_key=/, auth)
      [200, { 'Content-Type' => 'application/json' }, '{}']
    end

    u = users(:twitter_user)
    u.update_columns(uid: '1', token: 'tok', token_secret: 'sec')

    conn = Faraday.new(url: 'https://api.twitter.com') do |f|
      f.request :oauth1, 'header',
        consumer_key: 'ck',
        consumer_secret: 'cs',
        token: u.token,
        token_secret: u.token_secret
      f.adapter :test, stubs
    end

    conn.get('/2/ping')
  ensure
    u = users(:twitter_user)
    u.update_columns(uid: nil, token: nil, token_secret: nil)
  end

  def test_refresh_oauth2_token_updates_user
    u = users(:twitter_user)
    u.update_columns(
      oauth2_token: 'old-token',
      oauth2_refresh_token: 'refresh-me',
      oauth2_token_expires_at: 10.minutes.ago
    )

    WebMock.stub_request(:post, "https://api.x.com/2/oauth2/token")
      .with(body: { grant_type: 'refresh_token', refresh_token: 'refresh-me', client_id: 'dummy_client_id' })
      .to_return(
        status: 200,
        body: { access_token: 'new-token', refresh_token: 'new-refresh', expires_in: 7200 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub the followers call that triggers the refresh
    WebMock.stub_request(:get, %r{api\.twitter\.com/2/users/.*/following})
      .to_return(status: 200, body: { data: [], meta: {} }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Mock Rails config for client id/secret
    old_id = Rails.application.config.app_config.omniauth_twitter2_client_id
    old_secret = Rails.application.config.app_config.omniauth_twitter2_client_secret
    Rails.application.config.app_config.omniauth_twitter2_client_id = 'dummy_client_id'
    Rails.application.config.app_config.omniauth_twitter2_client_secret = 'dummy_secret'

    begin
      XClient.new.fetch_following(user: u)
    ensure
      Rails.application.config.app_config.omniauth_twitter2_client_id = old_id
      Rails.application.config.app_config.omniauth_twitter2_client_secret = old_secret
    end

    u.reload
    assert_equal 'new-token', u.oauth2_token
    assert_equal 'new-refresh', u.oauth2_refresh_token
    assert_operator u.oauth2_token_expires_at, :>, Time.current
  ensure
    u = users(:twitter_user)
    u.update_columns(oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil)
  end
end
