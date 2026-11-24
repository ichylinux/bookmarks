もし /^Mastodonガジェットが表示されたモバイル版ルートページを開きます。$/ do
  sign_in user
  ensure_mobile_viewport!
  visit root_path
  navigate_to_gadget_column!(mastodon_gadget_id_prefix)
  assert has_selector?(".gadget[id^=\"#{mastodon_gadget_id_prefix}\"]", visible: true)
  find(".gadget[id^=\"#{mastodon_gadget_id_prefix}\"] .gadget-title-text", wait: 15)
  capture
end

もし /^Mastodonガジェットのヘッダをタップして操作を表示します。$/ do
  ensure_gadget_header_actions_visible!(gadget_id_prefix: mastodon_gadget_id_prefix, gadget_icon: 'mastodon')
  capture
end

もし /^Mastodon設定リンクをタップしてダイアログを開きます。$/ do
  open_gadget_settings_dialog!(
    gadget_id_prefix: mastodon_gadget_id_prefix,
    settings_link_class: 'mastodon-gadget-settings-link',
    gadget_icon: 'mastodon'
  )
  capture
end

もし /^Mastodonガジェット設定で表示件数を (\d+) に変更して保存し、ガジェットが再読込されます。$/ do |count|
  acc = MastodonAccount.where(user_id: user.id).order(:id).last
  gadget_sel = "##{acc.gadget_id}"
  mark_gadget_list_stale!(gadget_sel)
  save_gadget_settings_display_count!(count: count)
  assert_equal count.to_i, acc.reload.display_count
  assert_gadget_list_reloaded!(gadget_sel)
  assert_selector(gadget_sel, text: 'Cucumber stub toot preview', wait: 15)
  capture
end

もし /^Xガジェットが表示されたモバイル版ルートページを開きます。$/ do
  sign_in user
  ensure_mobile_viewport!
  visit root_path
  navigate_to_gadget_column!(x_gadget_id_prefix)
  assert has_selector?(".gadget[id^=\"#{x_gadget_id_prefix}\"]", visible: true)
  find(".gadget[id^=\"#{x_gadget_id_prefix}\"] .gadget-title-text", wait: 15)
  capture
end

もし /^Xガジェットのヘッダをタップして操作を表示します。$/ do
  ensure_gadget_header_actions_visible!(gadget_id_prefix: x_gadget_id_prefix, gadget_icon: 'x')
  capture
end

もし /^X設定リンクをタップしてダイアログを開きます。$/ do
  open_gadget_settings_dialog!(
    gadget_id_prefix: x_gadget_id_prefix,
    settings_link_class: 'x-gadget-settings-link',
    gadget_icon: 'x'
  )
  capture
end

もし /^Xガジェット設定で表示件数を (\d+) に変更して保存し、ガジェットが再読込されます。$/ do |count|
  acc = XAccount.where(user_id: user.id).order(:id).last
  gadget_sel = "##{acc.gadget_id}"
  mark_gadget_list_stale!(gadget_sel)
  save_gadget_settings_display_count!(count: count)
  assert_equal count.to_i, acc.reload.display_count
  assert_gadget_list_reloaded!(gadget_sel)
  assert_selector(gadget_sel, text: 'Cucumber stub X preview', wait: 15)
  capture
end