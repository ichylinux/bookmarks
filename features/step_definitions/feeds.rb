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

もし /^ガジェット並べ替えの監視を開始します。$/ do
  page.execute_script(feed_header_link_probe_js)
  capture
end

# ハンドル全体の中心はタイトルテキスト（サイト名リンク）に重なるため、
# リンクではないアイコン側を掴む。アイコン上での押下は sortable に届く
# 必要がある（gadget_header_settings.js のヘッダガードが握り潰していないことの検証）。
もし /^フィードガジェットのドラッグハンドルのアイコンを数ピクセルドラッグします。$/ do
  icon = find('.gadget[id^="feed_"] .gadget-title-drag-handle .gadget-title-icon')

  Capybara.current_session.driver.browser.action
          .move_to(icon.native)
          .click_and_hold
          .move_by(3, 2)
          .release
          .perform
  capture
end

ならば /^ガジェットの並べ替えドラッグが開始されています。$/ do
  assert wait_until { page.evaluate_script('window.__gadgetSortStarted === true') },
         'ドラッグハンドルのアイコンを押してもガジェットの並べ替えドラッグが始まりません'
  capture
end

もし /^フィードガジェットが表示されたモバイル版ルートページを開きます。$/ do
  sign_in user
  ensure_mobile_viewport!
  visit root_path
  navigate_to_gadget_column!(feed_gadget_id_prefix)
  assert has_selector?('.gadget[id^="feed_"]', visible: true)
  find(feed_header_link_selector, wait: 15)
  capture
end

もし /^フィードガジェットのヘッダをタップして操作を表示します。$/ do
  ensure_gadget_header_actions_visible!(gadget_id_prefix: feed_gadget_id_prefix, gadget_icon: 'feed')
  capture
end

もし /^フィード設定リンクをタップしてダイアログを開きます。$/ do
  open_gadget_settings_dialog!(
    gadget_id_prefix: feed_gadget_id_prefix,
    settings_link_class: 'feed-gadget-settings-link',
    gadget_icon: 'feed'
  )
  capture
end
