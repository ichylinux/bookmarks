module FeedVisitedLinksHelpers
  def feed_stub_click_targets(stub_title)
    link = find('a', text: stub_title, wait: 15)
    href = link[:href]
    unless href.include?('stub-article')
      raise "expected stub article href to contain 'stub-article', got #{href.inspect}"
    end

    [href, stub_title]
  end

  def feed_stub_nav_suppress_js(target_href_json)
    <<~JS
      var targetHref = #{target_href_json};
      document.querySelectorAll('a').forEach(function(a) {
        if (a.href === targetHref) {
          a.addEventListener('click', function(e) { e.preventDefault(); }, true);
        }
      });
    JS
  end

  def feed_stub_link_has_class?(target_href_json, css_class_json)
    page.evaluate_script(<<~JS)
      (function() {
        var href = #{target_href_json};
        var cls = #{css_class_json};
        var links = document.querySelectorAll('a');
        for (var i = 0; i < links.length; i++) {
          if (links[i].href === href && links[i].classList.contains(cls)) { return true; }
        }
        return false;
      })()
    JS
  end
end

World(FeedVisitedLinksHelpers)

もし /^フィードガジェットに "([^"]*)" が表示される$/ do |text|
  @stub_feed_article_title = text
  @_visited_feed_link_href, = feed_stub_click_targets(text)
  capture
end

もし /^ガジェットリンクのナビゲーションを抑制します。$/ do
  raise 'run feed gadget visibility step first' if @_visited_feed_link_href.blank?

  page.execute_script(feed_stub_nav_suppress_js(@_visited_feed_link_href.to_json))
  capture
end

もし /^フィードガジェットの最初のリンクをクリックします。$/ do
  title = @stub_feed_article_title
  raise 'run feed gadget visibility step first' if title.blank?

  find('a', text: title).click
  capture
end

ならば /^そのリンクに "([^"]*)" クラスが付与されています。$/ do |css_class|
  raise 'run feed gadget visibility step first' if @_visited_feed_link_href.blank?

  assert feed_stub_link_has_class?(@_visited_feed_link_href.to_json, css_class.to_json),
         "expected a[href ~= #{@_visited_feed_link_href.inspect}] to have class #{css_class.inspect}"
  capture
end

もし /^訪問済みリンクがサーバーに保存されるまで待ちます。$/ do
  raise 'run feed gadget visibility step first' if @_visited_feed_link_href.blank?

  stored_url = VisitedLink.normalize_url(@_visited_feed_link_href)
  assert wait_until { VisitedLink.exists?(user_id: user.id, url: stored_url) },
         "訪問済みリンク (#{stored_url.inspect}) がサーバーに保存されませんでした"
  capture
end
