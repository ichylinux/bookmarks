もし /^設定画面で タスクウィジェットを表示する にチェックを入れます。$/ do
  sign_in user
  click_on current_user.email
  assert find('.navigation .menu')
  click_on '設定'
  check 'タスクウィジェットを表示する'
  capture
  click_on '保存'
  assert has_no_button?('保存')
end

もし /^設定画面で タスク追加時の初期優先度 を選択します。$/ do
  sign_in user
  click_on current_user.email
  click_on '設定'
  check 'タスクウィジェットを表示する'
  select Todo::PRIORITIES[Todo::PRIORITY_HIGH], from: 'タスク追加時の初期優先度'
  capture
  click_on '保存'
end

もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  click_on 'Home'
  assert has_selector?('#todo .title', text: name)
  capture
end

もし /^(.*?) をクリックしてタスクを追加します。$/ do |action|
  with_capture do
    assert has_selector?('.todo_actions')

    @todo_count = find('#todo').all('li').size
  
    click_on action
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

もし /^新しいタスクの追加時に、選択した優先度が選択された状態で表示されます。$/ do
  visit '/'
  assert has_selector?('.todo_actions')
  capture

  click_on '新しいタスク'
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
  click_on '新しいタスク'
  assert has_selector?('form.todo')
  capture

  within 'form.todo' do
    click_on action
  end
  
  assert has_selector?('.todo_actions')
  capture
end
