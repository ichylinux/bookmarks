# frozen_string_literal: true

require 'test_helper'

class NoteStylesContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/stylesheets/themes/_notes_shared.scss').read
  end

  test 'note edit controls are hidden in reference mode' do
    assert_includes @source, '.note-item .note-item-edit-form,'
    assert_includes @source, '.note-item .note-item-edit-form textarea,'
    assert_includes @source, '.note-item .note-item-edit-form input[type="submit"] {'
    assert_includes @source, 'display: none;'
  end

  test 'note edit controls are shown in editing mode' do
    assert_includes @source, '.note-item.note-item--editing .note-item-edit-form {'
    assert_includes @source, '.note-item.note-item--editing .note-item-edit-form textarea,'
    assert_includes @source, '.note-item.note-item--editing .note-item-edit-form input[type="submit"] {'
    assert_includes @source, 'display: inline-flex;'
  end
end
