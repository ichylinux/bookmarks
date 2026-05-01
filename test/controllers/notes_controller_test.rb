require 'test_helper'

class NotesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = user
    @other_user = User.find(2)
  end

  def test_successful_create
    sign_in @user

    assert_difference('Note.count', 1) do
      post notes_path, params: { note: { body: '新しいメモ' } }
    end

    assert_response :redirect
    assert_redirected_to root_path(tab: 'notes')

    note = Note.order(id: :desc).first
    assert_equal '新しいメモ', note.body
    assert_equal @user.id, note.user_id
  end

  def test_blank_body_does_not_create
    sign_in @user

    assert_no_difference('Note.count') do
      post notes_path, params: { note: { body: '   ' } }
    end

    assert_redirected_to root_path(tab: 'notes')
    follow_redirect!
    assert_predicate flash[:alert], :present?
  end

  def test_flash_errors_genericはjaで日本語になる
    ja = I18n.with_locale(:ja) { I18n.t('flash.errors.generic') }
    assert_equal 'エラーが発生しました', ja
  end

  def test_flash_errors_genericはenで英語になる
    en = I18n.with_locale(:en) { I18n.t('flash.errors.generic') }
    assert_equal 'Something went wrong.', en
  end

  def test_unauthenticated_redirects_to_sign_in
    assert_no_difference('Note.count') do
      post notes_path, params: { note: { body: 'hack' } }
    end

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  def test_user_id_param_cannot_override_current_user
    sign_in @user

    assert_difference('Note.count', 1) do
      post notes_path, params: { note: { body: 'owned', user_id: @other_user.id } }
    end

    note = Note.order(id: :desc).first
    assert_equal @user.id, note.user_id
    assert_not_equal @other_user.id, note.user_id
  end

  def test_body_over_max_length_does_not_create
    sign_in @user
    long_body = 'a' * 4001

    assert_no_difference('Note.count') do
      post notes_path, params: { note: { body: long_body } }
    end

    assert_redirected_to root_path(tab: 'notes')
    follow_redirect!
    assert_predicate flash[:alert], :present?
  end

  def test_routing_post_notes_to_create
    assert_routing({ path: '/notes', method: :post }, { controller: 'notes', action: 'create' })
  end

  def test_delete_notes_member_not_routed
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path('/notes/1', method: :delete)
    end
  end
end
