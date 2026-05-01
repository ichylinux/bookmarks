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

end
