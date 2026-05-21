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
      assert_select 'h1', text: 'Users'
    end

    def test_テーブルに7カラムのヘッダーが表示される
      sign_in users(:one)
      get admin_users_path
      assert_response :success
      assert_select 'table.admin-users__table thead th', count: 7
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
