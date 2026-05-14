# frozen_string_literal: true

require 'webmock/minitest'

# Block all external HTTP in tests.
# allow_localhost: true permits Capybara's embedded Puma server and Selenium
# ChromeDriver (both on 127.0.0.1) so the Cucumber/browser suite is unaffected.
# This covers localhost, 127.0.0.1, and ::1.
WebMock.disable_net_connect!(allow_localhost: true)

# Stub fixture feed URLs so Feed#retrieve_feed does not make real network calls.
# The fixture feeds (id: 1, 2) reference slashdot.jp and rss.slashdot.org; both
# must be stubbed or Cucumber scenarios that render the home page (which loads
# feeds/1 via FeedsController#show) raise WebMock::NetConnectNotAllowedError —
# an Exception subclass that bypasses rescue => e in Feed#feed.
STUB_RSS_BODY = <<~XML.freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Stub Feed</title>
      <link>http://example.com</link>
      <description>WebMock stub feed for tests</description>
    </channel>
  </rss>
XML

WebMock.stub_request(:get, /slashdot/).to_return(status: 200, body: STUB_RSS_BODY, headers: { 'Content-Type' => 'application/rss+xml' })
