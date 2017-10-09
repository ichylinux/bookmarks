require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  def test_トップページ
    sign_in user
    get root_path
    assert_response :success
    assert_equal '/', path
  end

end
