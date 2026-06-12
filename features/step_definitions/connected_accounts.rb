もし /^設定画面の連携アカウントセクションを開きます。$/ do
  sign_in user
  visit '/preferences'
  assert_selector '.connected-accounts'
  capture
end

ならば /^Google・X・Facebook・Mastodon・メールアドレスの5行が表示されています。$/ do
  within '.connected-accounts' do
    assert_text I18n.t('preferences.index.connected_accounts.google', locale: :ja)
    assert_text I18n.t('preferences.index.connected_accounts.twitter', locale: :ja)
    assert_text I18n.t('preferences.index.connected_accounts.facebook', locale: :ja)
    assert_text I18n.t('preferences.index.connected_accounts.mastodon', locale: :ja)
    assert_text I18n.t('preferences.index.connected_accounts.email_password', locale: :ja)
  end
  capture
end

もし /^Googleの連携解除ボタンをクリックします。$/ do
  disconnect_label = I18n.t('preferences.index.connected_accounts.disconnect', locale: :ja)
  google_label     = I18n.t('preferences.index.connected_accounts.google', locale: :ja)

  within('.connected-accounts__row', text: google_label) do
    click_button disconnect_label
  end
  capture
end

ならば /^Googleの行が「未連携」になっています。$/ do
  google_label        = I18n.t('preferences.index.connected_accounts.google', locale: :ja)
  not_connected_label = I18n.t('preferences.index.connected_accounts.not_connected', locale: :ja)

  within('.connected-accounts__row', text: google_label) do
    assert_selector '.connected-accounts__badge--unlinked', text: not_connected_label
  end
  capture
end

もし /^Xの連携解除ボタンをクリックすると解除エラーが表示されます。$/ do
  disconnect_label = I18n.t('preferences.index.connected_accounts.disconnect', locale: :ja)
  twitter_label    = I18n.t('preferences.index.connected_accounts.twitter', locale: :ja)

  within('.connected-accounts__row', text: twitter_label) do
    click_button disconnect_label
  end

  assert_text I18n.t('oauth_identities.destroy.last_auth_method', locale: :ja)

  within('.connected-accounts__row', text: twitter_label) do
    assert_selector '.connected-accounts__badge--connected'
  end
  capture
end
