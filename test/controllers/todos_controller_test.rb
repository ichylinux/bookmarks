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

end
