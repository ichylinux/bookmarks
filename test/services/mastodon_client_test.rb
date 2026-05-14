require 'test_helper'

class MastodonClientTest < ActiveSupport::TestCase
  def test_fetch_previews_returns_truncated_plain_text_and_url
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(%r{/api/v1/accounts/lookup}) do
      [200, { 'Content-Type' => 'application/json' }, '{"id":99,"username":"FastRuby"}']
    end
    long_text = 'a' * 120
    body = [{ 'content' => "<p>#{long_text}</p>", 'url' => 'https://ruby.social/@FastRuby/1' }].to_json
    stubs.get(%r{/api/v1/accounts/99/statuses}) do
      [200, { 'Content-Type' => 'application/json' }, body]
    end

    conn = Faraday.new do |f|
      f.adapter :test, stubs
      f.options.timeout = 5
      f.options.open_timeout = 3
    end

    client = MastodonClient.new(instance_host: 'ruby.social', connection: conn)
    result = client.fetch_recent_status_previews(username: 'FastRuby', limit: 5)

    assert result[:success], result.inspect
    item = result[:items].first
    assert_equal 'https://ruby.social/@FastRuby/1', item[:url]
    assert_operator item[:text].length, :<=, 100
  end

  def test_lookup_404_returns_not_found
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(%r{/api/v1/accounts/lookup}) { [404, {}, ''] }

    conn = Faraday.new do |f|
      f.adapter :test, stubs
      f.options.timeout = 5
      f.options.open_timeout = 3
    end

    client = MastodonClient.new(instance_host: 'ruby.social', connection: conn)
    result = client.fetch_recent_status_previews(username: 'Nobody', limit: 5)

    assert_not result[:success]
    assert_equal :not_found, result[:error]
  end

end
