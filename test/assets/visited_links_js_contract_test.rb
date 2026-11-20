require 'test_helper'

class VisitedLinksJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/visited_links.js').read
  end

  test 'uses iife wrapper not document ready' do
    assert_includes @source, '(function () {'
    assert_includes @source, '})();'
    refute_match(/\$\(document\)\.ready|\$\(function/, @source)
  end

  test 'registers namespaced delegated handler on gadget links' do
    assert_includes @source, "$(document).on('click.visitedLinks', '.gadget:not(#bookmark_gadget):not(#todo) ol li a[href]'"
  end

  test 'excludes bookmark and todo gadget links' do
    assert_includes @source, ':not(#bookmark_gadget)'
    assert_includes @source, ':not(#todo)'
  end

  test 'adds visited class before posting' do
    assert_includes @source, "addClass('link--visited')"
    assert_includes @source, 'postVisitedLink('
    click_handler = @source.split("click.visitedLinks'")[1] || ''
    assert click_handler.index("addClass('link--visited')") < click_handler.index('postVisitedLink('),
           "addClass('link--visited') must appear before postVisitedLink( in click handler"
  end

  test 'non-feed branch posts url only' do
    assert_includes @source, 'return { url: url }'
    refute_includes @source, 'authenticity_token'
  end

  test 'feed branch posts url title source feed and gadget_id' do
    assert_includes @source, "source: 'feed'"
    assert_includes @source, 'title: title'
    assert_includes @source, 'gadget_id: gadgetId'
    assert_includes @source, 'const title = $(this).text().trim()'
  end

  test 'x branch posts url title source x and gadget_id' do
    assert_includes @source, "source: 'x'"
    assert_includes @source, 'gadget_id: gadgetId'
    assert_includes @source, "indexOf('x_account_') === 0"
  end

  test 'mastodon branch posts url title source mastodon and gadget_id' do
    assert_includes @source, "source: 'mastodon'"
    assert_includes @source, 'gadget_id: gadgetId'
    assert_includes @source, "indexOf('mastodon_account_') === 0"
  end

  test 'feed detection uses feed_ id prefix' do
    assert_includes @source, "indexOf('feed_') === 0"
    assert_includes @source, "closest('.gadget')"
  end

  test 'strips fragment from href before posting' do
    assert_includes @source, "this.href.replace(/#.*$/, '')"
  end

  test 'does not prevent default — link navigates normally' do
    refute_includes @source, 'preventDefault'
  end

  test 'queues on ajax failure and clears session meta' do
    assert_includes @source, '.fail(function'
    assert_includes @source, 'markSessionExpired()'
    assert_includes @source, 'enqueue(payload)'
    refute_includes @source, 'isSessionFailure'
  end

  test 'skips ajax when session meta was removed until page reload' do
    assert_includes @source, 'if (!sessionActiveOnPage())'
    assert_includes @source, 'meta.remove()'
  end

  test 'persists pending visits in localStorage' do
    assert_includes @source, ApplicationHelper::PENDING_VISITED_LINKS_STORAGE_KEY
    assert_includes @source, 'localStorage.getItem(STORAGE_KEY)'
    assert_includes @source, 'localStorage.setItem(STORAGE_KEY'
  end

  test 'flushes pending queue when session meta is present' do
    assert_includes @source, 'meta[name="bookmarks-session-active"]'
    assert_includes @source, 'SESSION_META_SELECTOR'
    assert_includes @source, 'flushPending()'
  end

  test 'no window namespace export' do
    refute_match(/window\.\w+\s*=/, @source)
  end
end