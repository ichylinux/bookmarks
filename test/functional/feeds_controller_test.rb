require 'test_helper'

class FeedsControllerTest < ActionController::TestCase

  def test_他人のフィードは参照できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    get :show, :id => feed.id

    assert_response :not_found    
  end

end
