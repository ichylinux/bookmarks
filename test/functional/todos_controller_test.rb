require 'test_helper'

class TodosControllerTest < ActionController::TestCase

  def test_他人のタスクは編集できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    xhr :get, :edit, :id => todo.id

    assert_response :not_found
  end

  def test_他人のタスクは更新できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    xhr :put, :update, :id => todo.id

    assert_response :not_found 
  end

end
