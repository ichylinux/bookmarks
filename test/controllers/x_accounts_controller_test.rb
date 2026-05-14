# frozen_string_literal: true

require 'test_helper'

class XAccountsControllerTest < ActionDispatch::IntegrationTest
  def setup
    XClient.stub_fetch_following_result = nil
    XClient.stub_fetch_tweets_result = nil
    XAccount.where(user_id: twitter_user.id).delete_all
  end

  def teardown
    XClient.stub_fetch_following_result = nil
    XClient.stub_fetch_tweets_result = nil
    XAccount.where(user_id: twitter_user.id).delete_all
  end

  # --- gate: require_twitter_linked ---

  def test_未ログインはリダイレクトされる
    get x_accounts_path
    assert_redirected_to new_user_session_path
  end

  def test_TwitterリンクなしユーザーはPreferencesにリダイレクトされる
    sign_in user
    get x_accounts_path
    assert_redirected_to preferences_path
  end

  # --- index ---

  def test_一覧
    sign_in twitter_user
    get x_accounts_path
    assert_response :success
  end

  def test_一覧に選択件数の警告が表示される
    sign_in twitter_user
    build_selected_accounts(XAccount::SOFT_WARNING_AT)

    get x_accounts_path
    assert_response :success
    assert_select 'span', text: I18n.t('x_accounts.index.selection_soft_warning')
  end

  # --- refresh ---

  def test_再取得が成功するとリダイレクトされる
    XClient.stub_fetch_following_result = {
      success: true,
      items: [{ id: '1', username: 'alice', name: 'Alice', protected: false }]
    }
    sign_in twitter_user
    post refresh_x_accounts_path
    assert_redirected_to x_accounts_path
    assert_equal 1, XAccount.where(user_id: twitter_user.id).count
  end

  def test_再取得が失敗するとアラートでリダイレクトされる
    XClient.stub_fetch_following_result = { success: false, error: :timeout }
    sign_in twitter_user
    post refresh_x_accounts_path
    assert_redirected_to x_accounts_path
    follow_redirect!
    assert_select 'span.flash-message__body'
  end

  # --- update: selection ---

  def test_選択を有効にできる
    acc = create_account(username: 'bob', selected: false)
    sign_in twitter_user
    patch x_account_path(acc), params: { x_account: { selected: '1' } }
    assert_redirected_to x_accounts_path
    assert acc.reload.selected?
  end

  def test_選択上限を超えるとエラーになる
    build_selected_accounts(XAccount::MAX_SELECTION)
    extra = create_account(username: 'over_cap', selected: false)

    sign_in twitter_user
    patch x_account_path(extra), params: { x_account: { selected: '1' } }
    assert_redirected_to x_accounts_path
    assert_not extra.reload.selected?
  end

  def test_protectedアカウントは確認なしに選択できない
    acc = create_account(username: 'private_acct', protected: true, selected: false, protected_acknowledged: false)
    sign_in twitter_user
    patch x_account_path(acc), params: { x_account: { selected: '1' } }
    assert_redirected_to x_accounts_path
    assert_not acc.reload.selected?
  end

  def test_protectedアカウントは確認ありで選択できる
    acc = create_account(username: 'private_acct', protected: true, selected: false, protected_acknowledged: false)
    sign_in twitter_user
    patch x_account_path(acc), params: { x_account: { selected: '1', protected_acknowledged: '1' } }
    assert_redirected_to x_accounts_path
    assert acc.reload.selected?
  end

  def test_他人のアカウントは更新できない
    other_acc = XAccount.create!(
      user: user,
      x_user_id: '99999',
      username: 'other',
      display_name: 'Other'
    )
    sign_in twitter_user
    patch x_account_path(other_acc), params: { x_account: { selected: '1' } }
    assert_response :not_found
  ensure
    other_acc&.delete
  end

  # --- show ---

  def test_showがXHRでフラグメントを返す
    acc = create_account(username: 'charlie', selected: true)
    XClient.stub_fetch_tweets_result = {
      success: true,
      items: [{ text: 'Hello world', url: 'https://x.com/i/status/1' }]
    }
    sign_in twitter_user
    get x_account_path(acc, format: :html), xhr: true
    assert_response :success
    refute_match(%r{<html}i, @response.body)
    assert_select 'a[href=?]', 'https://x.com/i/status/1', text: 'Hello world'
  end

  def test_showがエラー時にローカライズされたメッセージを返す
    acc = create_account(username: 'charlie', selected: true)
    XClient.stub_fetch_tweets_result = { success: false, error: :timeout }
    twitter_user.preference.update!(locale: 'en')
    sign_in twitter_user
    get x_account_path(acc, format: :html), xhr: true
    assert_response :success
    assert_select 'span', text: I18n.t('errors.x_client.timeout', locale: :en)
  end

  def test_show_他人のアカウントは参照できない
    other_acc = XAccount.create!(
      user: user,
      x_user_id: '88888',
      username: 'other2',
      display_name: 'Other2'
    )
    sign_in twitter_user
    get x_account_path(other_acc, format: :html)
    assert_response :not_found
  ensure
    other_acc&.delete
  end

  private

  def twitter_user
    @twitter_user ||= users(:twitter_user)
  end

  def create_account(username:, selected: false, protected: false, protected_acknowledged: false)
    XAccount.create!(
      user: twitter_user,
      x_user_id: username,
      username: username,
      display_name: username.capitalize,
      selected: selected,
      protected: protected,
      protected_acknowledged: protected_acknowledged
    )
  end

  def build_selected_accounts(count)
    count.times do |i|
      XAccount.create!(
        user: twitter_user,
        x_user_id: "cap_acct_#{i}",
        username: "cap_acct_#{i}",
        display_name: "Cap #{i}",
        selected: true
      )
    end
  end
end
