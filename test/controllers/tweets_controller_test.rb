require 'test_helper'

class TweetsControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get tweets_path
    assert_response :success
    assert_equal '/tweets', path
  end

end
