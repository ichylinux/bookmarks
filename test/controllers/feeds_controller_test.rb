require 'test_helper'

class FeedsControllerTest < ActionController::TestCase

  def test_一覧
    sign_in user
    get :index
    assert_response :success
    assert_template :index
  end

  def test_他人のフィードは参照できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    get :show, :params => {:id => feed.id}

    assert_response :not_found
  end

  def test_追加
    sign_in user
    get :new
    assert_response :success
    assert_template :new
  end

  def test_登録
    sign_in user
    post :create, :params => {:feed => feed_params}
    assert_response :redirect
    assert @feed = assigns(:feed)
    assert_redirected_to :action => 'index'
  end

  def test_編集
    sign_in user
    get :edit, :params => {:id => feed_of(user)}
    assert_response :success
    assert_template :edit
  end

  def test_更新
    sign_in user
    patch :update, :params => {:id => feed_of(user), :feed => feed_params}
    assert_response :redirect
    assert @feed = assigns(:feed)
    assert_redirected_to :action => 'index'
  end

end
