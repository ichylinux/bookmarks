require 'test_helper'

# Mobile feed/X/Mastodon gadget: "設定" link is hidden by default and revealed when the
# user taps the header title/icon (gadget_header_settings.js toggles
# title--gadget-actions-visible), matching the bookmark/task gadget pattern.
class GadgetHeaderSettingsContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @gadget_header_settings_js = Rails.root.join('app/assets/javascripts/gadget_header_settings.js').read
  end

  %w[feed x mastodon].each do |kind|
    link_class = kind == 'feed' ? 'feed-gadget-settings-link' : "#{kind}-gadget-settings-link"

    test "welcome.css.scss hides #{link_class} on mobile by default" do
      assert_match(
        /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="#{kind}"\][\s\S]*?\.#{Regexp.escape(link_class)}[\s\S]*?opacity\s*:\s*0/,
        @welcome,
        "welcome.css.scss must set opacity: 0 on .#{link_class} scoped under " \
        ".title--gadget-with-icon[data-gadget-icon=\"#{kind}\"] inside @media (max-width: 767px)."
      )

      assert_match(
        /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="#{kind}"\][\s\S]*?\.#{Regexp.escape(link_class)}[\s\S]*?pointer-events\s*:\s*none/,
        @welcome,
        "welcome.css.scss must set pointer-events: none on .#{link_class} scoped under " \
        ".title--gadget-with-icon[data-gadget-icon=\"#{kind}\"] inside @media (max-width: 767px)."
      )
    end

    test "welcome.css.scss reveals #{link_class} when header has actions-visible class" do
      assert_match(
        /\.title--gadget-with-icon\[data-gadget-icon="#{kind}"\]\.title--gadget-actions-visible[\s\S]*?\.#{Regexp.escape(link_class)}[\s\S]*?opacity\s*:\s*1/,
        @welcome,
        "welcome.css.scss must set opacity: 1 on .#{link_class} when the #{kind} header " \
        'carries .title--gadget-actions-visible.'
      )

      assert_match(
        /\.title--gadget-with-icon\[data-gadget-icon="#{kind}"\]\.title--gadget-actions-visible[\s\S]*?\.#{Regexp.escape(link_class)}[\s\S]*?pointer-events\s*:\s*auto/,
        @welcome,
        "welcome.css.scss must set pointer-events: auto on .#{link_class} when the #{kind} header " \
        'carries .title--gadget-actions-visible.'
      )
    end
  end

  test 'gadget_header_settings.js binds header tap-to-reveal on headers with external profile links' do
    %w[feed x mastodon].each do |kind|
      assert_match(
        /data-gadget-icon="#{kind}"/,
        @gadget_header_settings_js,
        "gadget_header_settings.js HEADER_WITH_EXTERNAL_LINK must include data-gadget-icon=\"#{kind}\"."
      )
    end

    assert_match(
      /toggleClass\(\s*['"]title--gadget-actions-visible['"]\s*\)/,
      @gadget_header_settings_js,
      'gadget_header_settings.js must toggleClass("title--gadget-actions-visible") on header tap.'
    )
  end

  test 'gadget_header_settings.js stops propagation on mousedown/touchstart for settings links' do
    assert_match(
      /\.on\(\s*['"]mousedown touchstart['"],\s*SETTINGS_LINK_SELECTOR/,
      @gadget_header_settings_js,
      'gadget_header_settings.js must bind mousedown touchstart on settings links and stopPropagation, ' \
      'so jQuery UI sortable / touch-punch cannot swallow the tap on mobile.'
    )
  end

  test 'gadget_header_settings.js stops immediate propagation on gadget headers via .gadgets' do
    assert_match(
      /\.gadgets[\s\S]*?stopImmediatePropagation\(\)/,
      @gadget_header_settings_js,
      'gadget_header_settings.js must bind on .gadgets and stopImmediatePropagation on gadget headers ' \
      'so touch-punch cannot suppress the reveal click on mobile.'
    )
  end

  # ガードがヘッダ全体（セレクタはドラッグハンドルを含む）で stopImmediatePropagation すると
  # sortable にイベントが届かず、ガジェットをドラッグで並べ替えられなくなる（2026-09 のレグレッション）。
  # ハンドル上の押下は並べ替えに委ねること。
  test 'gadget_header_settings.js header guard excludes the drag handle so sortable can still start a drag' do
    guard_body_match = @gadget_header_settings_js.match(
      /\.on\(\s*['"]mousedown\.gadgetSettingsHeader touchstart\.gadgetSettingsHeader['"],\s*header,\s*function\(e\)\s*\{([\s\S]*?)\}\);/
    )
    assert_not_nil guard_body_match, 'gadget_header_settings.js must keep the .gadgets-bound header guard'
    assert_match(
      /\.gadget-title-drag-handle/,
      guard_body_match[1],
      'gadget_header_settings.js header guard must return early when the press starts on ' \
      '.gadget-title-drag-handle, otherwise gadgets cannot be dragged for reordering.'
    )
  end

  test 'gadget_header_settings.js prevents default navigation on first mobile header tap' do
    assert_match(
      /MOBILE_MQ\.matches[\s\S]*?preventDefault\(\)/,
      @gadget_header_settings_js,
      'gadget_header_settings.js must call preventDefault on the mobile header tap so the profile ' \
      'link does not navigate before revealing the settings link.'
    )
  end
end