require 'test_helper'

class PreferencesControllerTest < ActionController::TestCase

  def test_更新
    assert user.preference.persisted?

    preference_param = preference_params(default_priority: Todo::PRIORITY_HIGH).merge(id: user.preference.id)
    assert_not_equal user.preference.default_priority, preference_param[:default_priority]

    sign_in user
    patch :update, :params => {id: user.id,
      user: {
        name: 'twitter_name',
        preference_attributes: preference_param
      }
    }
    assert_equal Todo::PRIORITY_HIGH, assigns(:user).preference.default_priority
    assert_response :redirect
    assert_redirected_to root_path
  end

end
