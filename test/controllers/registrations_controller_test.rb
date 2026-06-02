require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def test_新規登録ページが日本語で補助文言を表示する
    get new_user_registration_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'body.auth-flow'
    assert_select '.auth-intro', text: I18n.t('landing.auth.sign_up_intro', locale: :ja)
    assert_select 'input[type=submit][value=?]', I18n.t('devise.registrations.new.sign_up', locale: :ja)
    assert_select 'input[type=email][autofocus]', count: 0
  end

  def test_新規登録ページが英語で補助文言を表示する
    get new_user_registration_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.auth-intro', text: I18n.t('landing.auth.sign_up_intro', locale: :en)
    assert_select 'input[type=submit][value=?]', I18n.t('devise.registrations.new.sign_up', locale: :en)
    assert_select 'input[type=email][autofocus]', count: 0
  end

  def test_新規登録完了フラッシュが日本語トーンで表示される
    post user_registration_path, params: {
      user: {
        email: "new-ja-#{SecureRandom.hex(4)}@example.com",
        password: 'password123',
        password_confirmation: 'password123'
      }
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select '.flash-notice', text: I18n.t('devise.registrations.signed_up', locale: :ja)
  end

  def test_新規登録完了フラッシュが英語トーンで表示される
    post user_registration_path,
         params: {
           user: {
             email: "new-en-#{SecureRandom.hex(4)}@example.com",
             password: 'password123',
             password_confirmation: 'password123'
           }
         },
         headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_redirected_to root_path
    follow_redirect!
    assert_select '.flash-notice', text: I18n.t('devise.registrations.signed_up', locale: :en)
  end
end
