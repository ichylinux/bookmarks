def click_todo_gadget_new_link
  within '#todo' do
    if @mobile_portal_scenario
      header = find('.title--gadget-with-icon')
      unless header[:class].to_s.include?('title--gadget-actions-visible')
        find('.gadget-title-text').click
      end
    end
  end
  el = find('#todo .todo-gadget-new-link', visible: :all)
  page.execute_script('arguments[0].click()', el)
end

もし /^設定画面で タスクを表示する にチェックを入れます。$/ do
  sign_in user
  visit '/preferences'
  check 'タスクを表示する'
  capture
  click_on '保存'
  assert has_text?('設定を保存しました。')
end

もし /^設定画面で タスク追加時の初期優先度 を選択します。$/ do
  sign_in user
  visit '/preferences'
  assert has_selector?('form.preferences-form')
  check 'タスクを表示する'
  select Todo::PRIORITIES[Todo::PRIORITY_HIGH], from: 'タスク追加時の初期優先度'
  capture
  click_on '保存'
  assert has_text?('設定を保存しました。')
end

もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  find('a.head-title', text: 'Bookmarks').click
  assert has_selector?('#todo .gadget-title-text', text: name)
  capture
end

もし /^(.*?) をクリックしてタスクを追加します。$/ do |action|
  with_capture do
    assert has_selector?('#todo .todo-gadget-new-link', visible: :all)

    @todo_count = find('#todo').all('li').size

    click_todo_gadget_new_link
    assert has_selector?('form.todo')
    capture

    within 'form.todo' do
      fill_in 'todo[title]', with: '新しいタスクの内容'
      capture
      click_on '登録'
    end

    assert find('#todo').all('li', count: @todo_count + 1)
  end
end

ならば /^新しいタスクの追加時に、選択した優先度が選択された状態で表示されます。$/ do
  visit '/'
  assert has_selector?('#todo .todo-gadget-new-link', visible: :all)
  capture

  click_todo_gadget_new_link
  assert has_selector?('form.todo')
  with_capture do
    within 'form.todo' do
      selector = 'select[name*="\[priority\]"]'
      assert has_selector?(selector)
      assert_equal Todo::PRIORITY_HIGH, evaluate_script("$('#{selector}').val()").to_i, "優先度が #{Todo::PRIORITY_HIGH} であること"
    end
  end
end

もし /^空白のまま (.*) をクリックするとタスクの入力が終了します。$/ do |action|
  click_todo_gadget_new_link
  assert has_selector?('form.todo')
  capture

  within 'form.todo' do
    click_on action
  end
  
  assert has_selector?('#todo .todo-gadget-new-link', visible: :all)
  capture
end

もし /^タスクガジェットで (\d+) 件のタスクを選択します。$/ do |count|
  find('a.head-title', text: 'Bookmarks').click if has_selector?('a.head-title', text: 'Bookmarks', wait: 1)
  assert has_selector?('#todo ol li', minimum: count.to_i)

  @selected_todo_ids = []
  within '#todo ol' do
    all('li').first(count.to_i).each do |li|
      li.find('span:first-child').click
      @selected_todo_ids << li['data-id'].to_i
    end
  end
  capture
end

ならば /^ヘッダに「(\d+)件選択中」が表示されます。$/ do |count|
  within '#todo' do
    assert has_selector?('.todo-gadget-complete-group', visible: :all)
    assert has_selector?('.todo-gadget-selected-count', text: "#{count}件選択中", visible: :all)
  end
  capture
end

もし /^ヘッダの完了をクリックします。$/ do
  within '#todo' do
    find('.todo-gadget-complete-link', visible: :all).click
  end
  capture
end

ならば /^選択したタスクがガジェット一覧から消える$/ do
  @selected_todo_ids.each do |id|
    within '#todo' do
      assert has_no_selector?("li[data-id='#{id}']", visible: true, wait: 5)
    end
    assert Todo.find(id).reload.done?, "Todo #{id} should be done"
  end
  capture
end

もし /^デスクトップ幅でタスクガジェットのヘッダにマウスオーバーすると「追加」が表示されます。$/ do
  # WINCHR-01: reproduce the affected Windows machine, where Chrome reports no
  # hovering pointer at all (hover/pointer AND any-hover/any-pointer all come back
  # none/coarse) while the user drives a real mouse. Standard headless Chrome
  # cannot express this, so a dedicated session is required — see
  # features/support/windows_touch_only_input.rb.
  with_windows_touch_only_session do
    # The reveal is now gated on viewport width, so this scenario depends on the
    # session actually being at desktop width. Headless Chrome starts with
    # --ozone-override-screen-size=800,600 and can clamp resize_browser_window,
    # so assert the width explicitly — otherwise a clamped window fails below as
    # an unexplained "追加 not visible" instead of naming the real cause.
    inner_width = evaluate_script('window.innerWidth')
    assert inner_width >= 768,
           "デスクトップ幅になっていません (innerWidth=#{inner_width})。ウィンドウサイズがクランプされた可能性があります"

    within '#todo' do
      find('.title--gadget-with-icon').hover
      assert has_selector?('.todo-gadget-new-link', visible: true)
      capture

      find('.todo-gadget-new-link', visible: true).click
      assert has_selector?('form.todo')
    end
    capture
  end
end

ならば /^「追加」の表示条件が入力デバイスに依存していません。$/ do
  # The reveal rule must be gated on viewport width only. Any hover/pointer media
  # feature — primary-only or any-input — is a false negative on the WINCHR-01
  # hardware and makes the button unreachable for real mouse users.
  condition_texts = evaluate_script(<<~JS)
    (function() {
      var results = [];
      Array.from(document.styleSheets).forEach(function(sheet) {
        var rules;
        try {
          rules = sheet.cssRules;
        } catch (e) {
          return;
        }
        if (!rules) return;
        Array.from(rules).forEach(function(rule) {
          if (rule.type !== CSSRule.MEDIA_RULE) return;
          var matches = Array.from(rule.cssRules).some(function(inner) {
            return inner.selectorText &&
              inner.selectorText.indexOf('.todo-gadget-new-link') !== -1 &&
              inner.selectorText.indexOf(':hover') !== -1;
          });
          if (matches) {
            results.push(String(rule.conditionText));
          }
        });
      });
      return results;
    })()
  JS

  assert condition_texts.present?, '.todo-gadget-new-link を含む :hover 系メディアクエリが見つかりません'
  condition_texts.each do |condition_text|
    assert_no_match(/hover|pointer/, condition_text,
                    "表示条件が入力デバイスに依存しています: #{condition_text}")
    assert_match(/width/, condition_text,
                 "表示条件が幅ベースではありません: #{condition_text}")
  end
  capture
end

もし /^ガジェットヘッダをタップして操作を表示します。$/ do
  within '#todo' do
    find('.gadget-title-text').click
    assert has_selector?('.title--gadget-actions-visible')
  end
  capture
end

ならば /^ヘッダの操作表示が解除されている$/ do
  within '#todo' do
    assert has_no_selector?('.title--gadget-actions-visible')
    # opacity:0 / sticky :hover でも「追加」が画面上に見えていないこと
    assert has_no_selector?('.todo-gadget-new-link', visible: true)
  end
  capture
end
