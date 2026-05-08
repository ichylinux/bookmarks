# frozen_string_literal: true

require 'test_helper'

class NoteGadgetJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/note_gadget.js').read
  end

  test 'desktop uses double click to enter edit mode' do
    assert_includes @source, ".on('dblclick.noteGadgetEdit'"
    assert_includes @source, "$item.addClass('note-item--editing');"
  end

  test 'mobile uses long press on display area to enter edit mode' do
    assert_includes @source, ".on('touchstart.noteGadgetLongpress'"
    assert_includes @source, 'const LONGPRESS_MS = 500;'
    assert_includes @source, 'setTimeout(function() {'
    assert_includes @source, 'showEditControls($item);'
  end

end
