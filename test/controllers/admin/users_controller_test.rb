# frozen_string_literal: true

require 'test_helper'

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    def test_未ログインはサインインページへリダイレクトされる
      get admin_users_path
      assert_redirected_to new_user_session_path
    end

    def test_非管理者は404を返す
      sign_in users(:two)
      get admin_users_path
      assert_response :not_found
    end

    def test_管理者は200を返す
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert_select 'h1', text: I18n.t('admin.users.index.title', locale: :ja)
    end

    def test_テーブルに8カラムのヘッダーが表示される
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert_select 'table.admin-users__table thead th', count: 8
    end

    def test_purgeable_user_shows_purge_link
      sign_in users(:one)
      u = purgeable_user!
      begin
        get admin_users_path
        assert_response :success
        assert_select "a[href=?]", confirm_purge_admin_user_path(u), text: I18n.t('admin.users.index.purge_button', locale: :ja)
      ensure
        u.delete if User.exists?(u.id)
      end
    end

    def test_non_purgeable_user_has_no_purge_link
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert_select "a[href=?]", confirm_purge_admin_user_path(users(:two)), count: 0
    end

    def test_confirm_purge_renders_for_purgeable_user
      sign_in users(:one)
      u = purgeable_user!
      begin
        get confirm_purge_admin_user_path(u)
        assert_response :success
        assert_select 'form[action=?][method=post]', admin_user_path(u)
        assert_select 'input[name=_method][value=delete]'
      ensure
        u.delete if User.exists?(u.id)
      end
    end

    def test_confirm_purge_redirects_when_not_purgeable
      sign_in users(:one)
      get confirm_purge_admin_user_path(users(:two))
      assert_redirected_to admin_users_path
      assert_equal I18n.t('admin.users.purge.not_purgeable', locale: :ja), flash[:alert]
    end

    def test_destroy_purges_purgeable_user
      sign_in users(:one)
      u = purgeable_user!
      email = u.email
      delete admin_user_path(u)
      assert_redirected_to admin_users_path
      assert_equal I18n.t('admin.users.purge.success', locale: :ja), flash[:notice]
      assert_not User.exists?(u.id)
      follow_redirect!
      assert_not response.body.include?(email)
    end

    def test_destroy_rejects_non_purgeable_user
      sign_in users(:one)
      u = users(:two)
      delete admin_user_path(u)
      assert_redirected_to admin_users_path
      assert_equal I18n.t('admin.users.purge.not_purgeable', locale: :ja), flash[:alert]
      assert User.exists?(u.id)
    end

    def test_destroy_requires_admin
      u = purgeable_user!
      begin
        sign_in users(:two)
        delete admin_user_path(u)
        assert_response :not_found
        assert User.exists?(u.id)
      ensure
        u.delete if User.exists?(u.id)
      end
    end

    def test_destroy_redirects_guest
      u = purgeable_user!
      begin
        delete admin_user_path(u)
        assert_redirected_to new_user_session_path
        assert User.exists?(u.id)
      ensure
        u.delete if User.exists?(u.id)
      end
    end

    private

    def purgeable_user!
      User.create!(
        email: "admin-purge-#{SecureRandom.hex(4)}@example.com",
        password: Devise.friendly_token[0, 20]
      ).tap { |user| user.update_columns(deleted: true, deleted_at: 91.days.ago) }
    end

    def test_削除済みユーザーも一覧に表示される
      sign_in users(:one)
      u = User.create!(email: 'deleted_test@example.com', password: 'passwordpass',
                       otp_secret: User.generate_otp_secret)
      begin
        u.update_columns(deleted: true, deleted_at: Time.current)
        get admin_users_path
        assert_response :success
        assert response.body.include?(u.email)
      ensure
        u.destroy
      end
    end

    def test_Xアカウントなしのユーザーはx_user_nameが空
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert response.body.include?(users(:three).email)
    end

    def test_管理者フラグが正しく表示される
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert response.body.include?('✓')
      assert response.body.include?('—')
    end
  end
end
