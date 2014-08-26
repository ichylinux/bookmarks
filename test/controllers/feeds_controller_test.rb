require 'test_helper'

class FeedsControllerTest < ActionController::TestCase

  def test_他人のフィードは参照できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    get :show, :id => feed.id

    assert_response :not_found
  end

  def test_更新
    sign_in user
    patch :update, :id => feed_of(user), :feed => feed_of(user).attributes
    assert_response :redirect
    assert @feed = assigns(:feed)
    assert_redirected_to :action => 'index'
  end

end
