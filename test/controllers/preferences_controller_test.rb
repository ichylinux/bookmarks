require 'test_helper'

class PreferencesControllerTest < ActionDispatch::IntegrationTest

  def test_更新
    assert user.preference.persisted?

    preference_param = preference_params(default_priority: Todo::PRIORITY_HIGH).merge(id: user.preference.id)
    assert_not_equal user.preference.default_priority, preference_param[:default_priority]

    sign_in user
    patch preference_path(user), params: {
      user: {
        name: 'twitter_name',
        preference_attributes: preference_param
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
  end

  def test_open_links_in_new_tabを保存する
    assert user.preference.persisted?
    assert_not user.preference.open_links_in_new_tab?

    preference_param = preference_params(open_links_in_new_tab: true).merge(id: user.preference.id)

    sign_in user
    patch preference_path(user), params: {
      user: {
        name: 'twitter_name',
        preference_attributes: preference_param
      }
    }
    assert_response :redirect
    assert user.preference.reload.open_links_in_new_tab?
  end

end
