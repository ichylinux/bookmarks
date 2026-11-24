# フィード / X / Mastodon ガジェットのモバイル設定ダイアログ用ヘルパ。
module GadgetSettingsHelpers
  def feed_gadget_id_prefix
    'feed_'
  end

  def mastodon_gadget_id_prefix
    'mastodon_account_'
  end

  def x_gadget_id_prefix
    'x_account_'
  end

  def navigate_to_gadget_column!(gadget_id_prefix)
    return if has_selector?(".gadget[id^=\"#{gadget_id_prefix}\"]", visible: true, wait: 1)

    all('button.portal-column-tab').each do |tab|
      tab.click
      return if has_selector?(".gadget[id^=\"#{gadget_id_prefix}\"]", visible: true, wait: 1)
    end
  end

  def ensure_gadget_header_actions_visible!(gadget_id_prefix:, gadget_icon:)
    within first(".gadget[id^=\"#{gadget_id_prefix}\"]") do
      header = find(".title--gadget-with-icon[data-gadget-icon=\"#{gadget_icon}\"]", visible: :all)
      unless header[:class].to_s.include?('title--gadget-actions-visible')
        find('.gadget-title-text').click
      end
      assert has_selector?('.title--gadget-actions-visible')
    end
  end

  def click_gadget_settings_link(gadget_id_prefix:, settings_link_class:, gadget_icon:)
    ensure_gadget_header_actions_visible!(gadget_id_prefix: gadget_id_prefix, gadget_icon: gadget_icon)
    el = find(".gadget[id^=\"#{gadget_id_prefix}\"] .#{settings_link_class}", visible: :all)
    page.execute_script('arguments[0].click()', el)
  end

  def open_gadget_settings_dialog!(gadget_id_prefix:, settings_link_class:, gadget_icon:)
    click_gadget_settings_link(
      gadget_id_prefix: gadget_id_prefix,
      settings_link_class: settings_link_class,
      gadget_icon: gadget_icon
    )
    assert has_selector?('dialog.feed-settings-dialog[open]', visible: :all, wait: 5)
  end

  def mark_gadget_list_stale!(gadget_sel)
    page.execute_script <<~JS
      const list = document.querySelector(#{gadget_sel.to_json} + ' ol');
      if (list) list.dataset.gadgetReloadStale = '1';
    JS
    assert has_selector?("#{gadget_sel} ol[data-gadget-reload-stale='1']"),
           'ガジェットの一覧 ol が見つからず、再読込の目印を付けられません'
  end

  def assert_gadget_list_reloaded!(gadget_sel)
    assert has_no_selector?("#{gadget_sel} ol[data-gadget-reload-stale='1']", wait: 15),
           'ガジェットの一覧 DOM が再描画されていません'
  end

  def save_gadget_settings_display_count!(count:)
    within 'dialog.feed-settings-dialog[open]' do
      find('input.display_count').set(count)
      find('.feed-settings-dialog__submit').click
    end
    assert wait_until { !has_selector?('dialog.feed-settings-dialog[open]', visible: :all, wait: 0.5) },
           '設定ダイアログが閉じません'
  end
end

World(GadgetSettingsHelpers)