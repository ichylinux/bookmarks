require 'test_helper'

class NoteGadgetJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/note_gadget.js').read
  end

  test 'desktop uses double click to enter edit mode' do
    assert_includes @source, ".on('dblclick.noteGadget', '.note-item-display'"
    assert_includes @source, "$item.addClass('note-item--editing');"
  end

  test 'mobile uses long press on display area to enter edit mode' do
    assert_includes @source, ".on('touchend.noteGadget', '.note-item-display'"
    assert_includes @source, 'const DOUBLE_TAP_MS = 350;'
    assert_includes @source, 'Date.now();'
    assert_includes @source, 'showEditControls($display.closest(\'.note-item\'));'
  end

  test 'save shortcut label switches to command on apple platforms' do
    assert_includes @source, ".find('.note-submit-shortcut')"
    assert_includes @source, 'shortcutMac'
    assert_includes @source, '/Mac|iPhone|iPad|iPod/.test(navigator.platform)'
  end

  test 'textarea ctrl or meta s submits the enclosing form' do
    assert_includes @source, ".on('keydown.noteGadget', 'textarea'"
    assert_includes @source, 'e.ctrlKey || e.metaKey'
    assert_includes @source, "e.key.toLowerCase() !== 's'"
    assert_includes @source, 'e.preventDefault();'
    assert_includes @source, 'submit.click();'
  end

end
