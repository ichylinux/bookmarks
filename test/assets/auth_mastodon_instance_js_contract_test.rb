require 'test_helper'

class AuthMastodonInstanceJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/auth_mastodon_instance.js').read
    @oauth_buttons = Rails.root.join('app/views/devise/shared/_oauth_buttons.html.erb').read
  end

  test 'script reads and writes mastodon instance via localStorage' do
    assert_includes @source, 'window.localStorage.getItem(storageKey)'
    assert_includes @source, 'window.localStorage.setItem(storageKey, value)'
  end

  test 'script reads storage key from form data attribute' do
    assert_includes @source, 'form?.dataset.mastodonInstanceStorageKey'
  end

  test 'script guards localStorage access with try catch' do
    assert_match(/try \{[\s\S]*localStorage\.getItem[\s\S]*\} catch \{/m, @source)
    assert_match(/form\.addEventListener\('submit'[\s\S]*try \{[\s\S]*localStorage\.setItem[\s\S]*\} catch \{/m, @source)
  end

  test 'oauth buttons partial exposes storage key on mastodon form' do
    assert_includes @oauth_buttons, 'ApplicationHelper::MASTODON_INSTANCE_STORAGE_KEY'
    assert_includes @oauth_buttons, 'mastodon_instance_storage_key'
  end
end
