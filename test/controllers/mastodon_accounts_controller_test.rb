require 'test_helper'

class MastodonAccountsControllerTest < ActionDispatch::IntegrationTest
  def test_一覧
    sign_in user
    get mastodon_accounts_path
    assert_response :success
    assert_equal '/mastodon_accounts', path
  end

  def test_一覧が日本語ロケールでUIを表示する
    account = mastodon_account_of(user.id)
    user.preference.update!(locale: 'ja')
    sign_in user
    get mastodon_accounts_path

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '.actions a', text: '追加', count: 1
    assert_select 'th', text: 'プロフィールURL'
    assert_select 'th', text: '表示件数'
    assert_select 'th', text: '操作'
    assert_select 'div.profile_url', text: account.profile_url
    assert_select 'a', text: '編集'
    assert_select 'a', text: '削除'
  end

  def test_一覧が英語ロケールでUIを表示する
    account = mastodon_account_of(user.id)
    user.preference.update!(locale: 'en')
    sign_in user
    get mastodon_accounts_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.actions a', text: 'Add', count: 1
    assert_select 'th', text: 'Profile URL'
    assert_select 'th', text: 'Display count'
    assert_select 'th', text: 'Actions'
    assert_select 'div.profile_url', text: account.profile_url
    assert_select 'a', text: 'Edit'
    assert_select 'a', text: 'Delete'
  end

  def test_空の一覧が英語ロケールで翻訳される
    MastodonAccount.where(user_id: user.id).delete_all
    user.preference.update!(locale: 'en')
    sign_in user
    get mastodon_accounts_path

    assert_response :success
    assert_select 'div', text: 'No Mastodon accounts have been added.'
  end

  def test_他人のアカウントは編集できない
    sign_in user
    other = mastodon_accounts(:two)

    get edit_mastodon_account_path(other)
    assert_response :not_found
  end

  def test_追加して一覧に表示される
    MastodonAccount.where(user_id: user.id).delete_all
    sign_in user
    assert_difference -> { MastodonAccount.where(user_id: user.id).not_deleted.count }, 1 do
      post mastodon_accounts_path, params: { mastodon_account: mastodon_account_params }
    end
    assert_redirected_to mastodon_accounts_path
    follow_redirect!
    assert_response :success
    assert_select 'div.profile_url', text: 'https://ruby.social/@TestUser'
  end

  def test_編集で表示件数を更新できる
    account = mastodon_account_of(user.id)
    sign_in user
    patch mastodon_account_path(account), params: {
      mastodon_account: { profile_url: account.profile_url, display_count: 10 }
    }
    assert_redirected_to mastodon_accounts_path
    assert_equal 10, account.reload.display_count
  end

  def test_削除でソフトデリートされる
    account = mastodon_account_of(user.id)
    sign_in user
    assert_difference -> { MastodonAccount.where(user_id: user.id).not_deleted.count }, -1 do
      delete mastodon_account_path(account)
    end
    assert_redirected_to mastodon_accounts_path
    assert account.reload.deleted
  end

  def test_show_renders_preview_links
    account = mastodon_account_of(user.id)
    stub_mastodon_success('ruby.social', 'FastRuby', [{ content: '<p>Preview line</p>', url: 'https://ruby.social/@x/1' }])
    sign_in user
    get mastodon_account_path(account, format: :html)

    assert_response :success
    assert_select 'a[href=?]', 'https://ruby.social/@x/1', text: 'Preview line'
  end

  def test_show_renders_error_message_on_timeout
    account = mastodon_account_of(user.id)
    WebMock.stub_request(:get, /ruby\.social\/api\/v1\/accounts\/lookup/).to_timeout
    user.preference.update!(locale: 'en')
    sign_in user
    get mastodon_account_path(account, format: :html)

    assert_response :success
    assert_select 'span', text: 'The Mastodon server took too long to respond.'
  end

  def test_show_xhr_returns_fragment_without_html_wrapper
    account = mastodon_account_of(user.id)
    stub_mastodon_success('ruby.social', 'FastRuby', [{ content: '<p>XHR line</p>', url: 'https://ruby.social/@x/2' }])
    sign_in user
    get mastodon_account_path(account, format: :html), xhr: true

    assert_response :success
    refute_match(%r{<html}i, @response.body)
    assert_select 'a', text: 'XHR line'
  end

  def test_show_他人のアカウントは参照できない
    sign_in user
    other = mastodon_accounts(:two)

    get mastodon_account_path(other, format: :html)
    assert_response :not_found
  end

  private

  def stub_mastodon_success(instance, username, statuses)
    WebMock.stub_request(:get, /#{Regexp.escape(instance)}\/api\/v1\/accounts\/lookup/)
      .to_return(
        status: 200,
        body: { id: 99, username: username }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    WebMock.stub_request(:get, /#{Regexp.escape(instance)}\/api\/v1\/accounts\/99\/statuses/)
      .to_return(
        status: 200,
        body: statuses.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
