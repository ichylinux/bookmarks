require 'test_helper'

class WelcomeHelperTest < ActionView::TestCase
  include WelcomeHelper

  test 'note_gadget_action_button disable_with keeps shortcut badge markup' do
    form_builder = ActionView::Helpers::FormBuilder.new(
      :note,
      Note.new,
      self,
      { url: '/notes', html: { class: 'note-gadget-form' } }
    )

    html = note_gadget_action_button(
      form_builder,
      label: 'メモを更新',
      css_class: 'note-item-update-submit',
      aria_label: 'メモを更新（Ctrl+S）'
    )

    assert_match(/data-disable-with="[^"]*note-submit-shortcut[^"]*Ctrl\+S[^"]*"/, html)
    assert_includes html, '<span class="note-submit-label">メモを更新</span>'
    assert_includes html, '<kbd class="note-submit-shortcut"'
  end
end
