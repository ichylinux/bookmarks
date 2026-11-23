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
    assert_redirected_to notes_path

    note = Note.order(id: :desc).first
    assert_equal '新しいメモ', note.body
    assert_equal @user.id, note.user_id
  end

  def test_blank_body_does_not_create
    sign_in @user

    assert_no_difference('Note.count') do
      post notes_path, params: { note: { body: '   ' } }
    end

    assert_redirected_to notes_path
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

    assert_redirected_to notes_path
    follow_redirect!
    assert_predicate flash[:alert], :present?
  end

  def test_successful_create_xhr_renders_note_item_partial
    sign_in @user

    assert_difference('Note.count', 1) do
      post notes_path, params: { note: { body: 'AJAX新規' } }, xhr: true
    end

    assert_response :success
    assert_select '.note-item'
    assert_match(/AJAX新規/, response.body)
    assert_equal 'AJAX新規', Note.order(id: :desc).first.body
  end

  def test_blank_body_create_xhr_returns_error_text
    sign_in @user

    assert_no_difference('Note.count') do
      post notes_path, params: { note: { body: '   ' } }, xhr: true
    end

    assert_response :unprocessable_entity
    assert_not_empty response.body
  end

  def test_routing_post_notes_to_create
    assert_routing({ path: '/notes', method: :post }, { controller: 'notes', action: 'create' })
  end

  def test_successful_update
    sign_in @user
    note = notes(:one)

    patch note_path(note), params: { note: { body: '更新後メモ' } }

    assert_redirected_to notes_path
    assert_equal '更新後メモ', note.reload.body
  end

  def test_blank_body_update_fails
    sign_in @user
    note = notes(:one)
    old_body = note.body

    patch note_path(note), params: { note: { body: '   ' } }

    assert_redirected_to notes_path
    assert_equal old_body, note.reload.body
  end

  def test_successful_update_xhr_renders_note_item_partial
    sign_in @user
    note = notes(:one)

    patch note_path(note), params: { note: { body: 'AJAX更新' } }, xhr: true

    assert_response :success
    assert_equal 'AJAX更新', note.reload.body
    assert_select '.note-item'
    assert_match(/AJAX更新/, response.body)
  end

  def test_blank_body_update_xhr_returns_error_text
    sign_in @user
    note = notes(:one)

    patch note_path(note), params: { note: { body: '   ' } }, xhr: true

    assert_response :unprocessable_entity
    assert_not_empty response.body
  end

  def test_destroy_is_logical_delete
    sign_in @user
    note = notes(:one)

    assert_no_difference('Note.count') do
      delete note_path(note)
    end

    assert_redirected_to notes_path
    assert note.reload.deleted
  end

  def test_destroy_xhr_returns_no_content
    sign_in @user
    note = notes(:one)

    assert_no_difference('Note.count') do
      delete note_path(note), xhr: true
    end

    assert_response :no_content
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

  def test_index_success
    @user.preference.update!(use_note: true)
    sign_in @user
    get notes_path
    assert_response :success
    assert_select '#notes-page .note-gadget', count: 1
    assert_select 'form.note-gadget-form[action=?][method=?]', notes_path, 'post', count: 1
  end

  def test_index_returns_not_found_when_use_note_off
    @user.preference.update!(use_note: false)
    sign_in @user
    get notes_path
    assert_response :not_found
  end

  def test_index_unauthenticated_redirects
    get notes_path
    assert_redirected_to new_user_session_path
  end

  def test_index_assigns_active_notes
    @user.preference.update!(use_note: true)
    Note.where(user_id: @user.id).delete_all
    own_note = @user.notes.create!(body: 'active note for assigns test')
    sign_in @user
    get notes_path
    assert_response :success
    assert_includes response.body, own_note.body
  end

  def test_index_empty_notes_state_ja
    @user.preference.update!(use_note: true)
    Note.where(user_id: @user.id).delete_all
    sign_in @user
    I18n.with_locale(:ja) do
      get notes_path
    end
    assert_response :success
    assert_select '.note-empty', text: 'メモはまだありません', count: 1
  end

  def test_index_empty_notes_state_en
    @user.preference.update!(use_note: true, locale: 'en')
    Note.where(user_id: @user.id).delete_all
    sign_in @user
    I18n.with_locale(:en) do
      get notes_path
    end
    assert_response :success
    assert_select '.note-empty', text: 'No notes yet', count: 1
  end

  def test_index_locale_ja_labels
    @user.preference.update!(use_note: true)
    sign_in @user
    I18n.with_locale(:ja) do
      get notes_path
    end
    assert_response :success
    assert_select 'form.note-gadget-form textarea[aria-label=?]', 'メモ'
  end

  def test_index_locale_en_labels
    @user.preference.update!(use_note: true, locale: 'en')
    sign_in @user
    I18n.with_locale(:en) do
      get notes_path
    end
    assert_response :success
    assert_select 'form.note-gadget-form textarea[aria-label=?]', 'Note'
  end

  def test_index_does_not_include_other_users_notes
    @user.preference.update!(use_note: true)
    Note.where(user_id: @user.id).delete_all
    own_note = @user.notes.create!(body: '自分のメモ index-test')
    other_note = @other_user.notes.create!(body: '他ユーザーの秘密メモ index-test')
    sign_in @user
    get notes_path
    assert_response :success
    assert_includes response.body, own_note.body
    assert_not_includes response.body, other_note.body
  end

  def test_routing_get_notes_to_index
    assert_routing({ path: '/notes', method: :get }, { controller: 'notes', action: 'index' })
  end
end
