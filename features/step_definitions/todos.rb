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
  end
  capture
end
