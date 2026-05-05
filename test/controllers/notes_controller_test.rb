require 'test_helper'

class NotesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.find(1)
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

  def test_successful_update
    sign_in @user
    note = notes(:one)

    patch note_path(note), params: { note: { body: '更新後メモ' } }

    assert_redirected_to root_path(tab: 'notes')
    assert_equal '更新後メモ', note.reload.body
  end

  def test_blank_body_update_fails
    sign_in @user
    note = notes(:one)
    old_body = note.body

    patch note_path(note), params: { note: { body: '   ' } }

    assert_redirected_to root_path(tab: 'notes')
    assert_equal old_body, note.reload.body
  end

  def test_destroy_is_logical_delete
    sign_in @user
    note = notes(:one)

    assert_no_difference('Note.count') do
      delete note_path(note)
    end

    assert_redirected_to root_path(tab: 'notes')
    assert note.reload.deleted
  end

  def test_other_users_note_cannot_be_updated
    sign_in @user
    note = notes(:two)

    patch note_path(note), params: { note: { body: '不正更新' } }

    assert_response :not_found
  end

  def test_routing_patch_notes_member_to_update
    assert_routing({ path: '/notes/1', method: :patch }, { controller: 'notes', action: 'update', id: '1' })
  end

  def test_routing_delete_notes_member_to_destroy
    assert_routing({ path: '/notes/1', method: :delete }, { controller: 'notes', action: 'destroy', id: '1' })
  end
end
