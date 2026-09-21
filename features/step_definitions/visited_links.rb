module VisitedLinksHelpers
  def gadget_link_targets(text, href_must_include: nil)
    link = find('a', text: text, wait: 15)
    href = link[:href]
    if href_must_include && !href.include?(href_must_include)
      raise "expected href to contain #{href_must_include.inspect}, got #{href.inspect}"
    end

    [href, text]
  end

  def gadget_nav_suppress_js(target_href_json)
    <<~JS
      var targetHref = #{target_href_json};
      document.querySelectorAll('a').forEach(function(a) {
        if (a.href === targetHref) {
          a.addEventListener('click', function(e) { e.preventDefault(); }, true);
        }
      });
    JS
  end

  def gadget_link_has_class?(target_href_json, css_class_json)
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

World(VisitedLinksHelpers)

もし /^フィードガジェットに "([^"]*)" が表示される$/ do |text|
  @stub_gadget_link_title = text
  @_visited_gadget_link_href, = gadget_link_targets(text, href_must_include: 'stub-article')
  capture
end

もし /^Xガジェットに "([^"]*)" が表示される$/ do |text|
  acc = XAccount.where(user_id: user.id).order(:id).last
  assert acc, 'Xアカウントが作成されているはずです'

  within("##{acc.gadget_id}") do
    @stub_gadget_link_title = text
    @_visited_gadget_link_href, = gadget_link_targets(text, href_must_include: 'x.com/i/status')
  end
  capture
end

もし /^Mastodonガジェットに "([^"]*)" が表示される$/ do |text|
  acc = MastodonAccount.where(user_id: user.id).order(:id).last
  assert acc, 'Mastodonアカウントが作成されているはずです'

  within("##{acc.gadget_id}") do
    @stub_gadget_link_title = text
    @_visited_gadget_link_href, = gadget_link_targets(text, href_must_include: 'ruby.social')
  end
  capture
end

もし /^ガジェットリンクのナビゲーションを抑制します。$/ do
  raise 'run gadget visibility step first' if @_visited_gadget_link_href.blank?

  page.execute_script(gadget_nav_suppress_js(@_visited_gadget_link_href.to_json))
  capture
end

もし /^フィードガジェットの最初のリンクをクリックします。$/ do
  title = @stub_gadget_link_title
  raise 'run gadget visibility step first' if title.blank?

  find('a', text: title).click
  capture
end

もし /^ガジェットの "([^"]*)" リンクをクリックします。$/ do |text|
  find('a', text: text).click
  capture
end

ならば /^そのリンクに "([^"]*)" クラスが付与されています。$/ do |css_class|
  raise 'run gadget visibility step first' if @_visited_gadget_link_href.blank?

  assert gadget_link_has_class?(@_visited_gadget_link_href.to_json, css_class.to_json),
         "expected a[href ~= #{@_visited_gadget_link_href.inspect}] to have class #{css_class.inspect}"
  capture
end

もし /^訪問済みリンクがサーバーに保存されるまで待ちます。$/ do
  raise 'run gadget visibility step first' if @_visited_gadget_link_href.blank?

  stored_url = VisitedLink.normalize_url(@_visited_gadget_link_href)
  assert wait_until { VisitedLink.exists?(user_id: user.id, url: stored_url) },
         "訪問済みリンク (#{stored_url.inspect}) がサーバーに保存されませんでした"
  capture
end

もし /^閲覧履歴ページを開きます。$/ do
  visit feed_article_histories_path
  assert page.has_css?('h1', text: I18n.t('feed_article_histories.index.heading'), wait: 15),
         "expected h1 with #{I18n.t('feed_article_histories.index.heading').inspect}"
  capture
end

ならば /^閲覧履歴に "([^"]*)" が表示される$/ do |title|
  link = find('ol li a', text: title, wait: 15)
  @_history_article_href = link[:href]
  capture
end

もし /^閲覧履歴の記事リンクのナビゲーションを抑制します。$/ do
  raise 'run history visibility step first' if @_history_article_href.blank?

  page.execute_script(gadget_nav_suppress_js(@_history_article_href.to_json))
  capture
end

もし /^閲覧履歴の "([^"]*)" をクリックします。$/ do |title|
  find('ol li a', text: title).click
  capture
end

ならば /^閲覧履歴の記事リンク先 URL に "([^"]*)" が含まれる$/ do |fragment|
  raise 'run history visibility step first' if @_history_article_href.blank?

  assert @_history_article_href.include?(fragment),
         "expected history link href to include #{fragment.inspect}, got #{@_history_article_href.inspect}"
  capture
end
