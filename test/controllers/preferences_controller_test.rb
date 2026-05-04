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
    assert_equal '/preferences', path
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

  def test_文字サイズ未設定ならbodyクラスはmediumにフォールバックする
    user.preference.update!(font_size: nil)

    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'body.font-size-medium'
  end

  def test_言語セレクタを表示する
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'label[for=?]', 'user_preference_attributes_locale'
    assert_select 'select[name=?]', 'user[preference_attributes][locale]' do
      assert_select 'option[value=?]', '', text: '自動'
      assert_select 'option[value=?]', 'ja', text: '日本語'
      assert_select 'option[value=?]', 'en', text: 'English'
    end
  end

  def test_localeをjaに更新できる
    user.preference.update!(locale: nil)
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: 'ja').merge(id: user.preference.id)
      }
    }

    assert_response :redirect
    assert_equal 'ja', user.preference.reload.locale
  end

  def test_localeをenに更新できる
    user.preference.update!(locale: nil)
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: 'en').merge(id: user.preference.id)
      }
    }

    assert_response :redirect
    assert_equal 'en', user.preference.reload.locale
  end

  def test_localeをnilに戻せる
    user.preference.update!(locale: 'ja')
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: '').merge(id: user.preference.id)
      }
    }

    assert_response :redirect
    assert_nil user.preference.reload.locale
  end

  def test_保存後preferences_pathにリダイレクトされる
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params.merge(id: user.preference.id)
      }
    }

    assert_redirected_to preferences_path
  end

  def test_設定画面が日本語ロケールで日本語表示される
    user.preference.update!(locale: 'ja')
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'th', text: 'テーマ'
    assert_select 'th', text: '言語'
    assert_select 'th', text: '文字サイズ'
    assert_select 'option', text: 'モダン'
    assert_select 'option', text: '大'
    assert_select 'input[type=submit][value=?]', '保存'
  end

  def test_設定画面が英語ロケールで英語表示される
    user.preference.update!(locale: 'en')
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'th', text: 'Theme'
    assert_select 'th', text: 'Language'
    assert_select 'th', text: 'Font size'
    assert_select 'option', text: 'Modern'
    assert_select 'option', text: 'Large'
    assert_select 'input[type=submit][value=?]', 'Save'
    assert_select 'option', text: '自動'
    assert_select 'option', text: '日本語'
    assert_select 'option', text: 'English'
  end

  def test_設定画面のdefault_priority_selectが日本語ロケールで数値値を保つ
    user.preference.update!(locale: 'ja', default_priority: Todo::PRIORITY_HIGH)
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'select[name=?]', 'user[preference_attributes][default_priority]' do
      assert_select 'option[value=?][selected=?]', Todo::PRIORITY_HIGH.to_s, 'selected', text: '高', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_NORMAL.to_s, text: '中', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_LOW.to_s, text: '低', count: 1
    end
  end

  def test_設定画面のdefault_priority_selectが英語ロケールで数値値を保つ
    user.preference.update!(locale: 'en', default_priority: Todo::PRIORITY_LOW)
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'select[name=?]', 'user[preference_attributes][default_priority]' do
      assert_select 'option[value=?]', Todo::PRIORITY_HIGH.to_s, text: 'High', count: 1
      assert_select 'option[value=?]', Todo::PRIORITY_NORMAL.to_s, text: 'Normal', count: 1
      assert_select 'option[value=?][selected=?]', Todo::PRIORITY_LOW.to_s, 'selected', text: 'Low', count: 1
    end
  end

  def test_localeをjaからenに変更すると保存通知が英語で表示される
    user.preference.update!(locale: 'ja')
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: 'en').merge(id: user.preference.id)
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_equal '/preferences', path
    assert_select 'html[lang=?]', 'en'
    assert_select '.flash-notice', text: I18n.t('preferences.saved', locale: :en)
  end

  def test_localeをenからjaに変更すると保存通知が日本語で表示される
    user.preference.update!(locale: 'en')
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: 'ja').merge(id: user.preference.id)
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_equal '/preferences', path
    assert_select 'html[lang=?]', 'ja'
    assert_select '.flash-notice', text: I18n.t('preferences.saved', locale: :ja)
  end

  def test_localeはサインアウト後も保持される
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(locale: 'en').merge(id: user.preference.id)
      }
    }
    assert_redirected_to preferences_path
    assert_equal 'en', user.preference.reload.locale

    sign_out user
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'select[name=?]', 'user[preference_attributes][locale]' do
      assert_select 'option[value=?][selected=?]', 'en', 'selected', text: 'English'
    end
  end

  def test_use_calendarをオフに保存する
    assert user.preference.persisted?
    user.preference.update!(use_calendar: true)
    preference_param = preference_params(use_calendar: false).merge(id: user.preference.id)
    sign_in user
    patch preference_path(user), params: {
      user: { preference_attributes: preference_param }
    }
    assert_response :redirect
    assert_not user.preference.reload.use_calendar?
  end

  def test_設定画面にuse_calendarチェックボックスを表示する
    user.preference.update!(locale: 'ja')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'label[for=?]', 'user_preference_attributes_use_calendar', text: 'カレンダーウィジェットを表示する'
    assert_select 'input[type=checkbox][name=?]', 'user[preference_attributes][use_calendar]'
  end

end
