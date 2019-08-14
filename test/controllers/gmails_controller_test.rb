require 'test_helper'

class GmailsControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get gmails_path
    assert_response :success
    assert_equal '/gmails', path
  end

  def test_新規
    sign_in user
    get new_gmail_path
    assert_response :success
    assert_equal '/gmails/new', path
  end

  def test_登録
    sign_in user
    post gmails_path, params: {gmail: gmail_params}
    assert_response :redirect
    follow_redirect!
    assert_equal '/gmails', path
  end

  def test_編集
    sign_in gmail.user

    get edit_gmail_path(gmail)
    assert_response :success
    assert_equal "/gmails/#{gmail.id}/edit", path
  end

  def test_更新
    sign_in gmail.user

    patch gmail_path(gmail), params: {gmail: gmail_params}
    assert_response :redirect
    assert_equal "/gmails/#{gmail.id}", path
  end

  def test_削除
    sign_in gmail.user

    assert_difference 'Gmail.where(deleted: false).count', -1 do
      delete gmail_path(gmail)
    end
    assert_response :redirect
    follow_redirect!
    assert_equal '/gmails', path
  end

end
