require 'test_helper'

class TodosControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get todos_path
    assert_response :success
    assert_equal '/todos', path
  end

  def test_他人のタスクは編集できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    get edit_todo_path(todo), xhr: true
    assert_response :not_found
  end

  def test_他人のタスクは更新できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    patch todo_path(todo), xhr: true
    assert_response :not_found
  end

  def test_他人のタスクは削除できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    assert_no_difference 'Todo.not_deleted.count' do
      delete todos_path(todo)
    end
    assert_response :not_found
  end

  def test_他人のタスクはバッチ削除できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    assert_no_difference 'Todo.not_deleted.count' do
      post delete_todos_path, params: { todo_id: [todo.id] }
    end
    assert_response :not_found
    assert_not todo.reload.done?
  end

  def test_完了でdoneが立つ
    todo = Todo.where(user_id: user.id).first
    sign_in user

    assert_not todo.done?

    post delete_todos_path, params: { todo_id: [todo.id] }

    assert_response :success
    assert todo.reload.done?
    assert_not todo.deleted?
  end

  def test_完了の取り消しでdoneが戻る
    todo = Todo.where(user_id: user.id).first
    todo.update!(done: true)
    sign_in user

    assert todo.done?

    post undo_complete_todos_path, params: { todo_id: [todo.id] }, xhr: true

    assert_response :success
    assert_not todo.reload.done?
    assert_select 'li[data-id=?]', todo.id.to_s, count: 1
  end

  def test_他人のタスクは完了の取り消しできない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first
    todo.update!(done: true)

    post undo_complete_todos_path, params: { todo_id: [todo.id] }

    assert_response :not_found
    assert todo.reload.done?
  end

  def test_削除でdeletedが立つ
    todo = Todo.where(user_id: user.id).first
    sign_in user

    assert_no_difference 'Todo.count' do
      delete todo_path(todo)
    end

    assert_response :redirect
    assert todo.reload.deleted?
    assert_not todo.done?
  end

  def test_新規フォームが日本語ロケールで優先度と登録ボタンを表示する
    user.preference.update!(locale: 'ja', default_priority: Todo::PRIORITY_HIGH)
    sign_in user
    get new_todo_path, xhr: true

    assert_response :success
    assert_select 'select[name=?]', 'todo[priority]' do
      assert_select 'option[value=?][selected=?]', Todo::PRIORITY_HIGH.to_s, 'selected', text: '高', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_NORMAL.to_s, text: '中', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_LOW.to_s, text: '低', count: 1
    end
    assert_select 'input[type=submit][value=?]', '登録', count: 1
  end

  def test_新規フォームが英語ロケールで優先度と作成ボタンを表示する
    user.preference.update!(locale: 'en', default_priority: Todo::PRIORITY_LOW)
    sign_in user
    get new_todo_path, xhr: true

    assert_response :success
    assert_select 'select[name=?]', 'todo[priority]' do
      assert_select 'option[value=?]', Todo::PRIORITY_HIGH.to_s, text: 'High', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_NORMAL.to_s, text: 'Normal', count: 1
      assert_select 'option[value=?][selected=?]', Todo::PRIORITY_LOW.to_s, 'selected', text: 'Low', count: 1
    end
    assert_select 'input[type=submit][value=?]', 'Create', count: 1
  end

  def test_編集フォームが英語ロケールで更新ボタンを表示しタイトルは変わらない
    todo = Todo.where(user_id: user.id).first
    todo.update!(title: '編集対象タスク 17-03', priority: Todo::PRIORITY_NORMAL)
    user.preference.update!(locale: 'en')
    sign_in user
    get edit_todo_path(todo), xhr: true

    assert_response :success
    assert_select 'option[value=?][selected=?]', Todo::PRIORITY_NORMAL.to_s, 'selected', text: 'Normal', count: 1
    assert_select 'input[name=?][value=?]', 'todo[title]', todo.title, count: 1
    assert_select 'input[type=submit][value=?]', 'Update', count: 1
    assert_select 'button.todo-highlight-btn', count: 0
  end

  def test_編集フォームに強調表示ボタンはない
    todo = Todo.where(user_id: user.id).first
    todo.update!(highlighted: true)
    sign_in user
    get edit_todo_path(todo), xhr: true

    assert_response :success
    assert_select 'input[type=submit][value=?]', '更新', count: 1
    assert_select 'button.todo-highlight-btn', count: 0
  end

  def test_新規フォームに強調表示ボタンはない
    sign_in user
    get new_todo_path, xhr: true

    assert_response :success
    assert_select 'button.todo-highlight-btn', count: 0
  end

  def test_英語ロケールで優先度表示は翻訳されタイトルと数値は変わらない
    user.preference.update!(locale: 'en')
    sign_in user
    title = '日本語タスクタイトル 17-03'

    assert_difference 'Todo.count', 1 do
      post todos_path, params: { todo: { title: title, priority: Todo::PRIORITY_HIGH } }, xhr: true
    end

    assert_response :success
    todo = Todo.order(:id).last
    assert_equal title, todo.title
    assert_equal Todo::PRIORITY_HIGH, todo.priority
    assert_select 'span.priority_1', text: 'High', count: 1
    assert_includes response.body, title
  end

  def test_強調表示をトグルできる
    todo = Todo.where(user_id: user.id).first
    sign_in user

    assert_not todo.highlighted?

    patch toggle_highlight_todo_path(todo), xhr: true
    assert_response :success
    assert todo.reload.highlighted?
    assert_select 'li.highlighted', count: 1
    assert_select 'button.todo-highlight-btn[aria-pressed=?]', 'true', text: '強調解除', count: 1

    patch toggle_highlight_todo_path(todo), xhr: true
    assert_response :success
    assert_not todo.reload.highlighted?
    assert_select 'li.highlighted', count: 0
    assert_select 'button.todo-highlight-btn[aria-pressed=?]', 'false', text: '強調表示', count: 1
  end

  def test_他人のタスクは強調表示をトグルできない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    patch toggle_highlight_todo_path(todo), xhr: true
    assert_response :not_found
  end

end
