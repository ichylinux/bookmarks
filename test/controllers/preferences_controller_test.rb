require 'test_helper'

class PreferencesControllerTest < ActionDispatch::IntegrationTest

  def test_更新
    assert user.preference.persisted?

    preference_param = preference_params(default_priority: Todo::PRIORITY_HIGH).merge(id: user.preference.id)
    assert_not_equal user.preference.default_priority, preference_param[:default_priority]

    sign_in user
    patch preference_path(user), params: {
      user: {
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

  def test_文字サイズが不正値ならbodyクラスはmediumにフォールバックする
    user.preference.update_column(:font_size, 'extra-large')

    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'body.font-size-medium'
  end

  def test_既存ユーザーfont_size_nilはsmallへ移行して1回だけ通知する
    user.preference.update_columns(font_size: Preference::FONT_SIZE_SMALL, font_size_notice_pending: true)

    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'body.font-size-small'
    assert_select '.flash-notice', text: I18n.t('preferences.font_size_migration_notice')
    assert_not user.preference.reload.font_size_notice_pending?

    get preferences_path
    assert_response :success
    assert_select '.flash-notice', text: I18n.t('preferences.font_size_migration_notice'), count: 0
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
    assert_select '.flash-notice button.flash-dismiss[data-dismiss-flash][aria-label=?]',
      I18n.t('flash.dismiss', locale: :en), count: 1
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
    assert_select '.flash-notice button.flash-dismiss[data-dismiss-flash][aria-label=?]',
      I18n.t('flash.dismiss', locale: :ja), count: 1
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
    assert_select 'label[for=?]', 'user_preference_attributes_use_calendar', text: 'カレンダーを表示する'
    assert_select 'input[type=checkbox][name=?]', 'user[preference_attributes][use_calendar]'
  end

  def test_モダンテーマで設定フォームが描画される
    user.preference.update!(theme: 'modern')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'form.preferences-form'
    assert_select 'table.preferences-table'
    assert_select 'input[type="submit"]'
  end

  def test_クラシックテーマで設定フォームが描画される
    user.preference.update!(theme: 'classic')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'form.preferences-form'
    assert_select 'table.preferences-table'
    assert_select 'input[type="submit"]'
  end

  def test_シンプルテーマで設定フォームが描画される
    user.preference.update!(theme: 'simple')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'form.preferences-form'
    assert_select 'table.preferences-table'
    assert_select 'input[type="submit"]'
  end

  def test_MOB01_設定ページにpreferences_tableが描画される
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'table.preferences-table', minimum: 1
  end

  def test_ダミーメールユーザにはメール登録リンクが表示される
    tw = users(:twitter_user)
    tw.preference.update!(locale: 'ja')
    sign_in tw
    get preferences_path
    assert_response :success
    assert_select 'a[href=?]', users_email_registration_path,
                  text: I18n.t('preferences.index.email_registration_link', locale: :ja)
  end

  def test_実メールユーザにはメール登録リンクが表示されない
    user.preference.update!(locale: 'ja')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'a[href=?]', users_email_registration_path, count: 0
  end

  def test_connected_accounts_section_renders_four_auth_rows
    user.preference.update!(locale: 'ja')
    sign_in user
    get preferences_path

    assert_response :success
    assert_select 'section.connected-accounts h2',
                  text: I18n.t('preferences.index.connected_accounts_section_title', locale: :ja)
    assert_select 'section.connected-accounts .connected-accounts__row', count: 4
    %w[google twitter facebook email_password].each do |key|
      assert_select 'section.connected-accounts .connected-accounts__provider',
                    text: I18n.t("preferences.index.connected_accounts.#{key}", locale: :ja)
    end
  end

  def test_portal_column_countを4に保存する
    user.preference.update!(portal_column_count: 3)
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(portal_column_count: 4).merge(id: user.preference.id)
      }
    }
    assert_response :redirect
    assert_equal 4, user.preference.reload.portal_column_count
  end

  def test_portal_column_widthsを保存する
    sign_in user
    user.preference.update!(portal_column_count: 3, portal_column_widths: [34, 33, 33])

    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(
          portal_column_widths: %w[50 30 20]
        ).merge(id: user.preference.id)
      }
    }

    assert_redirected_to preferences_path
    assert_equal [50, 30, 20], user.preference.reload.portal_column_widths.map(&:to_i)
  end

  def test_設定画面にportal_column_widthスライダーを表示する
    user.preference.update!(portal_column_count: 3, portal_column_widths: [40, 35, 25])
    sign_in user
    get preferences_path
    assert_response :success
    assert_select '[data-portal-width-list] [data-portal-width-slider]', count: 3
    assert_select 'input[name="user[preference_attributes][portal_column_widths][]"][value="40"]'
  end

  def test_設定画面にportal_column_count選択肢を表示する
    user.preference.update!(portal_column_count: 4, locale: 'ja')
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'select[name=?]', 'user[preference_attributes][portal_column_count]' do
      assert_select 'option[value="3"]', text: '3列'
      assert_select 'option[value="4"][selected=?]', 'selected', text: '4列'
    end
  end
  def test_show_iconsをfalseに保存する
    user.preference.update!(show_icons: true)
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(show_icons: false).merge(id: user.preference.id)
      }
    }
    assert_response :redirect
    assert_equal false, user.preference.reload.show_icons
  end

  def test_show_iconsをtrueに保存する
    user.preference.update!(show_icons: false)
    sign_in user
    patch preference_path(user), params: {
      user: {
        preference_attributes: preference_params(show_icons: true).merge(id: user.preference.id)
      }
    }
    assert_response :redirect
    assert_equal true, user.preference.reload.show_icons
  end

  def test_設定画面にshow_iconsチェックボックスを表示する
    sign_in user
    get preferences_path
    assert_response :success
    assert_select 'input[type=checkbox][name=?]', 'user[preference_attributes][show_icons]'
  end


end
