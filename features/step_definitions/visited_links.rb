もし /^フィードガジェットに "([^"]*)" が表示される$/ do |text|
  assert_selector('.gadget ol li a', text: text, wait: 15)
  capture
end

もし /^ガジェットリンクのナビゲーションを抑制します。$/ do
  page.execute_script(<<~JS)
    document.querySelectorAll('.gadget ol li a').forEach(function(a) {
      a.addEventListener('click', function(e) { e.preventDefault(); }, true);
    });
  JS
  capture
end

もし /^フィードガジェットの最初のリンクをクリックします。$/ do
  find('.gadget ol li a', match: :first).click
  capture
end

ならば /^そのリンクに "([^"]*)" クラスが付与されています。$/ do |css_class|
  assert has_css?(".gadget ol li a.#{css_class}")
  capture
end

もし /^訪問済みリンクがサーバーに保存されるまで待ちます。$/ do
  assert wait_until { VisitedLink.exists?(user_id: user.id) },
         '訪問済みリンクがサーバーに保存されませんでした'
  capture
end
