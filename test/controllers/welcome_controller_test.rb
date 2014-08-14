require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "should get index" do
    sign_in user
    get :index
    assert_response :success
  end

end
