# frozen_string_literal: true

require 'test_helper'

class XClientTest < ActiveSupport::TestCase
  def setup
    XClient.stub_fetch_following_result = nil
    XClient.stub_fetch_tweets_result = nil
  end

  def teardown
    XClient.stub_fetch_following_result = nil
    XClient.stub_fetch_tweets_result = nil
  end

  def test_fetch_following_stub_short_circuits
    XClient.stub_fetch_following_result = {
      success: true,
      items: [
        { id: '1', username: 'a', name: 'A', protected: false }
      ]
    }
    u = users(:twitter_user)
    r = XClient.new.fetch_following(user: u)
    assert r[:success]
    assert_equal 'a', r[:items].first[:username]
  end

  def test_fetch_following_malformed_stub_returns_api_error
    XClient.stub_fetch_following_result = 'nope'
    r = XClient.new.fetch_following(user: users(:twitter_user))
    assert_not r[:success]
    assert_equal :api_error, r[:error]
  end

  def test_fetch_tweets_expands_tco_and_truncates
    XClient.stub_fetch_tweets_result = {
      success: true,
      items: [{ text: 'a' * 200, url: 'https://x.com/i/status/9' }]
    }
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
end
