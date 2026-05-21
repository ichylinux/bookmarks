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
  end
end
