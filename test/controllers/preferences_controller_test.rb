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

  def test_文字サイズを保存する
    assert user.preference.persisted?
    assert_not_equal Preference::FONT_SIZE_LARGE, user.preference.font_size

    preference_param = preference_params(font_size: Preference::FONT_SIZE_LARGE).merge(id: user.preference.id)

    sign_in user
    patch preference_path(user), params: {
      user: {
        name: 'twitter_name',
        preference_attributes: preference_param
      }
    }
    assert_response :redirect
    assert_equal Preference::FONT_SIZE_LARGE, user.preference.reload.font_size
  end

  def test_設定画面に文字サイズ選択肢を表示する
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'label[for=?]', 'user_preference_attributes_font_size', text: '文字サイズ'
    assert_select 'select[name=?]', 'user[preference_attributes][font_size]' do
      assert_select 'option[value=?]', Preference::FONT_SIZE_LARGE, text: '大'
      assert_select 'option[value=?]', Preference::FONT_SIZE_MEDIUM, text: '中'
      assert_select 'option[value=?]', Preference::FONT_SIZE_SMALL, text: '小'
    end
  end

  def test_文字サイズのbodyクラスを描画する
    user.preference.update!(font_size: Preference::FONT_SIZE_SMALL)

    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'body.font-size-small'
  end

end
