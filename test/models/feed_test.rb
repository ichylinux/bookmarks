require 'test_helper'

class FeedTest < ActiveSupport::TestCase

  def test_他人のフィードは参照できない
    assert user = User.find(2)
    assert feed = Feed.where('user_id <> ?', user).first
    assert ! feed.readable_by?(user)
    assert ! feed.creatable_by?(user)
    assert ! feed.updatable_by?(user)
    assert ! feed.deletable_by?(user)
  end

  def test_gadget_title_icon_image_url_returns_atom_icon
    feed = Feed.new(feed_url: 'http://example.com/feed.xml', title: 't', user_id: 1, display_count: 5)
    atom = Feedjira::Parser::Atom.new
    atom.icon = 'https://cdn.example.com/icon.png'
    atom.define_singleton_method(:entries) { [] }

    feed.define_singleton_method(:feed?) { true }
    feed.define_singleton_method(:feed) { atom }
    feed.define_singleton_method(:url) { 'https://blog.example.com/' }

    assert_equal 'https://cdn.example.com/icon.png', feed.gadget_title_icon_image_url
  end

  def test_gadget_title_icon_image_url_resolves_relative_atom_icon
    feed = Feed.new(feed_url: 'http://example.com/feed.xml', title: 't', user_id: 1, display_count: 5)
    atom = Feedjira::Parser::Atom.new
    atom.icon = '/static/logo.png'
    atom.define_singleton_method(:entries) { [] }

    feed.define_singleton_method(:feed?) { true }
    feed.define_singleton_method(:feed) { atom }
    feed.define_singleton_method(:url) { 'https://blog.example.com/home' }

    assert_equal 'https://blog.example.com/static/logo.png', feed.gadget_title_icon_image_url
  end

  def test_gadget_title_icon_image_url_returns_rss_image_regardless_of_feed_url_host
    f = Feed.new(feed_url: 'https://x.com/foo.rss', title: 'x', user_id: 1, display_count: 5)
    rss = Feedjira::Parser::RSS.new
    img = Feedjira::Parser::RSSImage.new
    img.url = 'https://cdn.example.com/channel.png'
    rss.image = img
    rss.define_singleton_method(:entries) { [] }

    f.define_singleton_method(:feed?) { true }
    f.define_singleton_method(:feed) { rss }

    assert_equal 'https://cdn.example.com/channel.png', f.gadget_title_icon_image_url
  end

end
