require 'test_helper'

class WelcomeHelperTest < ActionView::TestCase
  include WelcomeHelper

  test 'no_icons_class returns empty string when not signed in' do
    define_singleton_method(:user_signed_in?) { false }
    assert_equal '', no_icons_class
  end

  test 'no_icons_class returns no-icons when show_icons is false' do
    user.preference.update!(show_icons: false)
    define_singleton_method(:user_signed_in?) { true }
    define_singleton_method(:current_user) { user }
    assert_equal 'no-icons', no_icons_class
  end

  test 'no_icons_class returns empty string when show_icons is true' do
    user.preference.update!(show_icons: true)
    define_singleton_method(:user_signed_in?) { true }
    define_singleton_method(:current_user) { user }
    assert_equal '', no_icons_class
  end

  test 'note_gadget_action_button disable_with keeps shortcut badge markup' do
    form_builder = ActionView::Helpers::FormBuilder.new(
      :note,
      Note.new,
      self,
      { url: '/notes', html: { class: 'note-gadget-form' } }
    )

    html = note_gadget_action_button(
      form_builder,
      label: '更新',
      css_class: 'note-item-update-submit',
      aria_label: '更新（Ctrl+S）'
    )

    assert_match(/data-disable-with="[^"]*note-submit-shortcut[^"]*Ctrl\+S[^"]*"/, html)
    assert_includes html, '<span class="note-submit-label">更新</span>'
    assert_includes html, '<kbd class="note-submit-shortcut"'
  end
end
