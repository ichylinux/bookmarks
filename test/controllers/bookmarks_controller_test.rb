require 'test_helper'

class BookmarksControllerTest < ActionController::TestCase

  def test_一覧
    sign_in user
    get :index
    assert_response :success
    assert_template :index
  end

  def test_参照
    sign_in user
    get :show, :id => bookmark(user)
    assert_response :success
    assert_template :show
  end

  def test_新規
    sign_in user
    get :new
    assert_response :success
    assert_template :new
  end

  def test_登録
    sign_in user
    post :create, :bookmark => valid_bookmark_params(user)
    assert_response :redirect
    assert_redirected_to :action => 'index'
  end

  def test_編集
    sign_in user
    get :edit, :id => bookmark(user)
    assert_response :success
    assert_template :edit
  end

  def test_更新
    sign_in user
    patch :update, :id => bookmark(user), :bookmark => valid_bookmark_params(user)
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => bookmark(user)
  end

  def test_削除
    sign_in user
    assert_difference 'Bookmark.not_deleted.count', -1 do
      delete :destroy, :id => bookmark(user)
    end
    assert_response :redirect
    assert_redirected_to :action => 'index'
  end
end
