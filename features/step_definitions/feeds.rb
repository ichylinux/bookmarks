def navigate_to_feed_gadget_column!
  return if has_selector?('.gadget[id^="feed_"]', visible: true, wait: 1)

  all('button.portal-column-tab').each do |tab|
    tab.click
    return if has_selector?('.gadget[id^="feed_"]', visible: true, wait: 1)
  end
end

def click_feed_gadget_settings_link
  within first('.gadget[id^="feed_"]') do
    header = find('.title--gadget-with-icon[data-gadget-icon="feed"]')
    unless header[:class].to_s.include?('title--gadget-actions-visible')
      find('.gadget-title-text').click
    end
  end
  el = find('.gadget[id^="feed_"] .feed-gadget-settings-link', visible: :all)
  page.execute_script('arguments[0].click()', el)
end

module FeedGadgetHeaderHelpers
  # feeds/show.html.erb がヘッダに描画するサイト名リンク。
  # common/_gadget_title_with_icon.html.erb 経由で .gadget-title-drag-handle の
  # 内側に入るため、並べ替えドラッグとクリックが競合しやすい箇所。
  # 定数ではなくメソッドで公開する（ステップ定義ブロックからの定数参照は
  # レキシカルスコープの都合で解決できないため）。
  def feed_header_link_selector
    '.gadget[id^="feed_"] .gadget-title-text a'
  end

  def feed_header_link_probe_js
    <<~JS
      window.__feedHeaderLinkClicked = false;
      window.__gadgetSortStarted = false;
      jQuery('.gadgets').on('sortstart', function() { window.__gadgetSortStarted = true; });
      document.querySelector(#{feed_header_link_selector.to_json})
        .addEventListener('click', function(e) {
          window.__feedHeaderLinkClicked = true;
          // 外部サイトへ実際に遷移させない（WebMock はブラウザの遷移を止められない）
          e.preventDefault();
        }, true);
    JS
  end
end

World(FeedGadgetHeaderHelpers)

もし /^フィードガジェットのヘッダにサイト名 "([^"]*)" が表示される$/ do |name|
  link = find(feed_header_link_selector, text: name, wait: 15)
  assert link[:href].present?, "ヘッダのサイト名 #{name.inspect} が href を持っていません"
  capture
end

もし /^フィードガジェットのヘッダのサイト名のナビゲーションを抑制します。$/ do
  page.execute_script(feed_header_link_probe_js)
  capture
end

# 押してから離すまでにポインタが数 px 動く「普通のクリック」を再現する。
# ぴたりと止まったクリックでは sortable のドラッグ（distance 既定値 1px）が
# 始まらないため、この不具合は再現できない。
# 移動量は 5px 未満にすること: 5px 以上動かすと Chrome がリンクのネイティブ
# ドラッグを開始し、ガジェット外の普通のリンクでも click が出なくなるため、
# 本件とは無関係の理由で失敗してしまう。
もし /^フィードガジェットのヘッダのサイト名を、ポインタを数ピクセル動かしながらクリックします。$/ do
  link = find(feed_header_link_selector)

  Capybara.current_session.driver.browser.action
          .move_to(link.native)
          .click_and_hold
          .move_by(3, 2)
          .release
          .perform
  capture
end

ならば /^そのサイト名リンクのクリックが発火しています。$/ do
  assert wait_until { page.evaluate_script('window.__feedHeaderLinkClicked === true') },
         'ヘッダのサイト名のクリックがガジェット並べ替えドラッグに吸われています'
  capture
end

ならば /^ガジェットの並べ替えドラッグは開始されていません。$/ do
  assert !page.evaluate_script('window.__gadgetSortStarted === true'),
         'ヘッダのサイト名を押しただけでガジェットの並べ替えドラッグが始まっています'
  capture
end

もし /^フィードガジェットが表示されたモバイル版ルートページを開きます。$/ do
  sign_in user
  ensure_mobile_viewport!
  visit root_path
  navigate_to_feed_gadget_column!
  assert has_selector?('.gadget[id^="feed_"]', visible: true)
  find(feed_header_link_selector, wait: 15)
  capture
end

もし /^フィードガジェットのヘッダをタップして操作を表示します。$/ do
  within first('.gadget[id^="feed_"]') do
    find('.gadget-title-text').click
    assert has_selector?('.title--gadget-actions-visible')
  end
  capture
end

もし /^フィード設定リンクをタップしてダイアログを開きます。$/ do
  click_feed_gadget_settings_link
  assert has_selector?('dialog.feed-settings-dialog[open]', visible: :all, wait: 5)
  capture
end
