require 'test_helper'

class PreferencesControllerTest < ActionController::TestCase

  def test_更新
    assert user.preference.persisted?

    preference_param = valid_preference_params.merge(:default_priority => Todo::PRIORITY_HIGH)
    assert_not_equal user.preference.default_priority, preference_param[:default_priority]

    sign_in user
    patch :update, :id => user.preference.id, :preference => preference_param
    assert_equal Todo::PRIORITY_HIGH, assigns(:preference).default_priority
    assert_response :redirect
    assert_redirected_to :action => 'index'
  end

end
