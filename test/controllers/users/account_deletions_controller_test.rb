require 'test_helper'

class Users::AccountDeletionsControllerTest < ActionDispatch::IntegrationTest
  def test_new_requires_authentication
    get new_account_deletion_path
    assert_redirected_to new_user_session_path
  end

  def test_new_renders_confirmation_field
    sign_in User.find(3)
    get new_account_deletion_path
    assert_response :success
    assert_select 'input#confirmation[name="confirmation"]'
  end

  def test_destroy_requires_authentication
    delete account_deletion_path, params: { confirmation: 'DELETE' }
    assert_redirected_to new_user_session_path
  end

  def test_destroy_with_wrong_confirmation_renders_new
    sign_in User.find(3)
    delete account_deletion_path, params: { confirmation: 'NOPE' }
    assert_response :unprocessable_entity
    assert_select 'h1', text: I18n.t('account_deletions.new.title', locale: :ja)
  end

  def test_destroy_soft_deletes_user_and_signs_out
    u = User.find(3)
    bookmark_count = Bookmark.where(user_id: u.id).count

    sign_in u
    delete account_deletion_path, params: { confirmation: 'DELETE' }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    u.reload
    assert u.deleted?
    assert u.deleted_at.present?
    assert_match(/\Adeleted_\d+_[a-f0-9]+@deleted\.invalid\z/, u.email)
    assert_nil u.oauth2_token
    assert_equal bookmark_count, Bookmark.where(user_id: u.id).count

    sign_out u
    post user_session_path, params: { user: { email: 'user3@example.com', password: 'testtest' } }
    assert_redirected_to new_user_session_path
  end
end
