require 'test_helper'

class TodosControllerTest < ActionController::TestCase

  def test_一覧
    sign_in user
    get :index
    assert_response :success
    assert_template :index
  end

  def test_他人のタスクは編集できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    get :edit, :params => {:id => todo.id}, :xhr => true

    assert_response :not_found
  end

  def test_他人のタスクは更新できない
    sign_in user
    assert todo = Todo.where('user_id <> ?', user).first

    patch :update, :params => {:id => todo.id}, :xhr => true

    assert_response :not_found 
  end

end
