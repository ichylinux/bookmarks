もし /^設定画面で (.*?) にチェックを入れます。$/ do |name|
  sign_in user
  click_on current_user.email
  click_on '設定'
  check name
  capture
  click_on '登録する'
end

もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  click_on 'Home'
  assert page.has_selector?('#todo .title', :text => name)
  capture
end

もし /^(.*?) をクリックしてタスクを追加します。$/ do |action|
  assert page.has_selector?('.todo_actions', :visible => true)
  capture

  @todo_count = page.find('#todo').all('li').size

  click_on action
  assert page.has_no_selector?('.todo_actions', :visible => true)
  assert page.has_selector?('#new_todo')
  capture
  
  within '#new_todo' do
    fill_in 'todo_title', :with => '新しいタスクの内容'
    capture
    click_on '登録'
  end

  wait_until { page.find('#todo').all('li').size == @todo_count + 1 }
  capture
end

もし /^空白のまま (.*) をクリックするとタスクの入力が終了します。$/ do |action|
  assert page.has_no_selector?('.todo_actions', :visible => true)
  assert page.has_selector?('#new_todo')
  capture

  within '#new_todo' do
    click_on action
  end
  
  assert page.has_selector?('.todo_actions', :visible => true)
  capture
end
