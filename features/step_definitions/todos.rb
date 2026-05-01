TODO_ACTIONS_SELECTOR = '#todo .todo_actions'.freeze
NEW_TODO_LINK_SELECTOR = '#todo .todo_actions a[href="/todos/new"]'.freeze
PREFERENCE_USE_TODO_SELECTOR = '#user_preference_attributes_use_todo'.freeze
PREFERENCE_DEFAULT_PRIORITY_SELECTOR = '#user_preference_attributes_default_priority'.freeze

def open_preferences_and_find_todo_checkbox
  retries = 0
  begin
    sign_in user
    visit '/preferences'

    checkbox = first(PREFERENCE_USE_TODO_SELECTOR, visible: :all, wait: 3)
    return checkbox if checkbox

    raise Capybara::ElementNotFound, "Unable to find #{PREFERENCE_USE_TODO_SELECTOR}"
  rescue Capybara::ElementNotFound
    retries += 1
    raise if retries > 1

    Capybara.reset_sessions!
    @_current_user = nil
    retry
  end
end

もし /^設定画面で タスクウィジェットを表示する にチェックを入れます。$/ do
  checkbox = open_preferences_and_find_todo_checkbox
  checkbox.set(true)
  find('input[type="submit"], button[type="submit"]', match: :first).click
  capture
end

もし /^設定画面で タスク追加時の初期優先度 を選択します。$/ do
  checkbox = open_preferences_and_find_todo_checkbox
  checkbox.set(true)
  priority_select = find(PREFERENCE_DEFAULT_PRIORITY_SELECTOR)
  priority_select.find("option[value='#{Todo::PRIORITY_HIGH}']").select_option
  find('input[type="submit"], button[type="submit"]', match: :first).click
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
