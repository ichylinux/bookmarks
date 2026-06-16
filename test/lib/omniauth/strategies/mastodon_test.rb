# frozen_string_literal: true

require 'test_helper'

class OmniAuth::Strategies::MastodonTest < ActiveSupport::TestCase
  INSTANCE = 'mastodon.social'
  SITE = "https://#{INSTANCE}".freeze

  setup do
    @app = ->(env) { [200, env, ['OK']] }
    @strategy = OmniAuth::Strategies::Mastodon.new(
      @app,
      'placeholder_client_id',
      'placeholder_client_secret',
      scope: 'read'
    )
  end

  def test_request_phase_registers_app_and_redirects_to_instance_authorize
    WebMock.stub_request(:post, "#{SITE}/api/v1/apps")
           .to_return(
             status: 200,
             body: { client_id: 'test-client-id', client_secret: 'test-client-secret' }.to_json,
             headers: { 'Content-Type' => 'application/json' }
           )

    env = build_env(session: { mastodon_instance: INSTANCE })
    @strategy.instance_variable_set(:@env, env)

    status, headers, = catch(:warden) { @strategy.request_phase }

    assert_equal 302, status
    location = headers['Location']
    assert_includes location, 'mastodon.social'
    assert_includes location, '/oauth/authorize'
    assert_includes location, 'client_id=test-client-id'
    assert_equal 'test-client-id', env['rack.session'][:mastodon_oauth_client_id]
    assert_equal 'test-client-secret', env['rack.session'][:mastodon_oauth_client_secret]
    assert_equal INSTANCE, env['rack.session'][:mastodon_oauth_instance]
  end

  def test_callback_phase_exchanges_token_and_sets_uid_and_info
    WebMock.stub_request(:post, "#{SITE}/oauth/token")
           .to_return(
             status: 200,
             body: { access_token: 'test-token', token_type: 'Bearer' }.to_json,
             headers: { 'Content-Type' => 'application/json' }
           )

    WebMock.stub_request(:get, "#{SITE}/api/v1/accounts/verify_credentials")
           .with(headers: { 'Authorization' => 'Bearer test-token' })
           .to_return(
             status: 200,
             body: { id: '12345', username: 'alice', display_name: 'Alice' }.to_json,
             headers: { 'Content-Type' => 'application/json' }
           )

    env = build_env(
      path: '/users/auth/mastodon/callback',
      params: { code: 'auth-code' },
      session: {
        mastodon_instance: INSTANCE,
        mastodon_oauth_client_id: 'test-client-id',
        mastodon_oauth_client_secret: 'test-client-secret'
      }
    )
    @strategy.instance_variable_set(:@env, env)
    @strategy.options[:provider_ignores_state] = true

    @strategy.callback_phase

    auth = @strategy.auth_hash
    assert_equal '12345', auth.uid
    assert_equal 'Alice', auth.info['name']
    assert_equal 'alice', auth.info['nickname']
    assert_equal INSTANCE, auth.info['instance']
    assert_equal INSTANCE, auth.extra['instance']
  end

  def test_request_phase_skips_registration_when_credentials_cached_for_same_instance
    env = build_env(
      session: {
        mastodon_instance: INSTANCE,
        mastodon_oauth_client_id: 'cached-client-id',
        mastodon_oauth_client_secret: 'cached-client-secret',
        mastodon_oauth_instance: INSTANCE
      }
    )
    @strategy.instance_variable_set(:@env, env)

    status, headers, = catch(:warden) { @strategy.request_phase }

    assert_equal 302, status
    assert_includes headers['Location'], 'client_id=cached-client-id'
    assert_not_requested :post, %r{/api/v1/apps}
  end

  def test_request_phase_reregisters_when_instance_changes
    WebMock.stub_request(:post, "#{SITE}/api/v1/apps")
           .to_return(
             status: 200,
             body: { client_id: 'new-client-id', client_secret: 'new-client-secret' }.to_json,
             headers: { 'Content-Type' => 'application/json' }
           )

    env = build_env(
      session: {
        mastodon_instance: INSTANCE,
        mastodon_oauth_client_id: 'old-client-id',
        mastodon_oauth_client_secret: 'old-client-secret',
        mastodon_oauth_instance: 'other.instance'
      }
    )
    @strategy.instance_variable_set(:@env, env)

    catch(:warden) { @strategy.request_phase }

    assert_requested :post, "#{SITE}/api/v1/apps", times: 1
    assert_equal 'new-client-id', env['rack.session'][:mastodon_oauth_client_id]
    assert_equal INSTANCE, env['rack.session'][:mastodon_oauth_instance]
  end

  def test_request_phase_fails_without_mastodon_instance_in_session
    env = build_env(session: {})
    @strategy.instance_variable_set(:@env, env)

    assert_raises(Devise::MissingWarden) do
      @strategy.request_phase
    end

    assert_equal :invalid_credentials, env['omniauth.error.type']
    assert_match(/mastodon_instance is required/, env['omniauth.error'].message)
    assert_not_requested :post, %r{/api/v1/apps}
  end

  private

  def build_env(path: '/users/auth/mastodon', params: {}, session: {})
    query = Rack::Utils.build_query(params)
    url = "https://example.com#{path}"
    url = "#{url}?#{query}" if query.present?

    Rack::MockRequest.env_for(
      url,
      'rack.session' => session
    )
  end
end
