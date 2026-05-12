require 'test_helper'

class Users::EmailRegistrationsControllerTest < ActionDispatch::IntegrationTest
  def test_ダミーメールユーザーがメールアドレスを登録できる
    tw = users(:twitter_user)
    sign_in tw
    new_email = "registered_#{tw.id}@example.com"
    post users_email_registration_path, params: { email_registration: { email: new_email } }
    assert_redirected_to preferences_path
    assert_equal new_email, tw.reload.email
    assert_equal I18n.t('email_registrations.saved', locale: :ja), flash[:notice]
  end

  def test_英語ロケールで登録成功時のフラッシュが英語になる
    tw = users(:twitter_user)
    tw.preference.update!(locale: 'en')
    sign_in tw
    new_email = "registered_en_#{tw.id}@example.com"
    post users_email_registration_path, params: { email_registration: { email: new_email } }
    assert_redirected_to preferences_path
    assert_equal I18n.t('email_registrations.saved', locale: :en), flash[:notice]
  end

  def test_衝突するメールアドレスはエラーを返す
    tw = users(:twitter_user)
    sign_in tw
    post users_email_registration_path, params: { email_registration: { email: user.email } }
    assert_response :unprocessable_entity
    assert_match(I18n.t('errors.messages.taken', locale: :ja), @response.body)
  end

  def test_実メールユーザーはフォームにアクセスできない
    sign_in user
    get users_email_registration_path
    assert_redirected_to preferences_path
  end

  def test_未認証ユーザーはサインインにリダイレクトされる
    get users_email_registration_path
    assert_redirected_to new_user_session_path
  end

  def test_RecordNotUniqueはフォームを再描画する
    tw = users(:twitter_user)
    sign_in tw
    orig_save = User.instance_method(:save)
    ctrl_path = Rails.root.join('app/controllers/users/email_registrations_controller.rb').to_s
    User.define_method(:save) do |*args, **kwargs|
      if caller_locations.any? { |loc| loc.absolute_path == ctrl_path }
        raise ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint'
      end
      orig_save.bind_call(self, *args, **kwargs)
    end

    post users_email_registration_path, params: { email_registration: { email: "race_safe_#{tw.id}@example.com" } }
    assert_response :unprocessable_entity
    assert_select 'ul.email-registrations-errors li', text: /すでに存在します/
  ensure
    User.define_method(:save) do |*args, **kwargs|
      orig_save.bind_call(self, *args, **kwargs)
    end
  end

  def test_新規フォームが日本語ロケールで表示される
    tw = users(:twitter_user)
    tw.preference.update!(locale: 'ja')
    sign_in tw
    get users_email_registration_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'h1.email-registrations-title', text: I18n.t('email_registrations.new.title', locale: :ja)
  end

  def test_新規フォームが英語ロケールで表示される
    tw = users(:twitter_user)
    tw.preference.update!(locale: 'en')
    sign_in tw
    get users_email_registration_path
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'h1.email-registrations-title', text: I18n.t('email_registrations.new.title', locale: :en)
  end
end
