# frozen_string_literal: true

もし /^最初のMastodonガジェットに "([^"]*)" が表示される$/ do |text|
  acc = MastodonAccount.where(user_id: user.id).order(:id).last
  assert acc, 'Mastodonアカウントが作成されているはずです'
  assert_selector("##{acc.gadget_id}", text: text, wait: 15)
end
