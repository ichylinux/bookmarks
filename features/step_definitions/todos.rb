TODO_ACTIONS_SELECTOR = '#todo .todo_actions'.freeze
NEW_TODO_LINK_SELECTOR = '#todo .todo_actions a[href="/todos/new"]'.freeze

もし /^設定画面で タスクウィジェットを表示する にチェックを入れます。$/ do
  sign_in user
  preference = user.preference || user.build_preference
  preference.use_todo = true
  preference.save!
  capture
end

もし /^設定画面で タスク追加時の初期優先度 を選択します。$/ do
  sign_in user
  preference = user.preference || user.build_preference
  preference.use_todo = true
  preference.default_priority = Todo::PRIORITY_HIGH
  preference.save!
  capture
end

もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  visit root_path
  assert has_selector?('#todo .title', text: name)
  capture
end

もし /^(.*?) をクリックしてタスクを追加します。$/ do |_action|
  with_capture do
    assert has_selector?(TODO_ACTIONS_SELECTOR)

    @todo_count = find('#todo').all('li').size
  
    find(NEW_TODO_LINK_SELECTOR).click
    assert has_selector?('form.todo')
    capture

    within 'form.todo' do
      fill_in 'todo[title]', with: '新しいタスクの内容'
      capture
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    assert find('#todo').all('li', count: @todo_count + 1)
  end
end

もし /^新しいタスクの追加時に、選択した優先度が選択された状態で表示されます。$/ do
  visit '/'
  assert has_selector?(TODO_ACTIONS_SELECTOR)
  capture

  find(NEW_TODO_LINK_SELECTOR).click
  assert has_selector?('form.todo')
  with_capture do
    within 'form.todo' do
      selector = 'select[name*="\[priority\]"]'
      assert has_selector?(selector)
      assert_equal Todo::PRIORITY_HIGH, evaluate_script("$('#{selector}').val()").to_i, "優先度が #{Todo::PRIORITY_HIGH} であること"
    end
  end
end

もし /^空白のまま (.*) をクリックするとタスクの入力が終了します。$/ do |_action|
  find(NEW_TODO_LINK_SELECTOR).click
  assert has_selector?('form.todo')
  capture

  within 'form.todo' do
    find('input[type="submit"], button[type="submit"]', match: :first).click
  end
  
  assert has_selector?(TODO_ACTIONS_SELECTOR)
  capture
end
