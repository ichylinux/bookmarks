もし /^設定画面で タスクウィジェットを表示する にチェックを入れます。$/ do
  sign_in user
  click_on current_user.email
  click_on '設定'
  check 'タスクウィジェットを表示する'
  capture
  click_on '保存'
end

もし /^設定画面で タスク追加時の初期優先度 を選択します。$/ do
  sign_in user
  click_on current_user.email
  click_on '設定'
  check 'タスクウィジェットを表示する'
  select Todo::PRIORITIES[Todo::PRIORITY_HIGH], :from => 'タスク追加時の初期優先度'
  capture
  click_on '保存'
end

もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  click_on 'Home'
  assert page.has_selector?('#todo .title', :text => name)
  capture
end

もし /^(.*?) をクリックしてタスクを追加します。$/ do |action|
  assert page.has_selector?('.todo_actions')

  @todo_count = page.find('#todo').all('li').size

  click_on action
  assert page.has_selector?('#new_todo')
  capture
  
  within '#new_todo' do
    fill_in 'todo_title', :with => '新しいタスクの内容'
    capture
    click_on '登録'
  end

  assert wait_until { page.find('#todo').all('li').size == @todo_count + 1 }
  capture
end

もし /^新しいタスクの追加時に、選択した優先度が選択された状態で表示されます。$/ do
  visit '/'
  assert has_selector?('.todo_actions')
  capture

  click_on '新しいタスク'
  begin
    within '#new_todo' do
      selector = 'select[name*="\[priority\]"]'
      assert has_selector?(selector)
      assert Todo::PRIORITY_HIGH == first(selector).value.to_i, "優先度が #{Todo::PRIORITY_HIGH} であること"
    end
  ensure
    capture
  end
end

もし /^空白のまま (.*) をクリックするとタスクの入力が終了します。$/ do |action|
  click_on '新しいタスク'
  assert page.has_selector?('#new_todo')
  capture

  within '#new_todo' do
    click_on action
  end
  
  assert page.has_selector?('.todo_actions')
  capture
end
