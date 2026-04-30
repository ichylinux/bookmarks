require 'test_helper'

class NoteTest < ActiveSupport::TestCase

  def test_他人のメモは参照できない
    user = User.find(2)
    note = Note.where('user_id <> ?', user.id).first
    assert note, 'fixture should provide a note owned by a different user'
    assert ! note.readable_by?(user)
    assert ! note.updatable_by?(user)
    assert ! note.deletable_by?(user)
  end

  def test_自分のメモは参照できる
    user = User.find(1)
    note = Note.where(user_id: user.id).first
    assert note
    assert note.readable_by?(user)
    assert note.updatable_by?(user)
    assert note.deletable_by?(user)
  end

  def test_body_is_required
    note = Note.new(user_id: 1, body: '')
    assert_not note.valid?
    assert note.errors[:body].any?
  end

  def test_whitespace_only_body_fails_presence
    note = Note.new(user_id: 1, body: '   ')
    assert_not note.valid?
    assert note.errors[:body].any?
  end

  def test_body_max_length_4000
    note = Note.new(user_id: 1, body: 'a' * 4001)
    assert_not note.valid?
    assert note.errors[:body].any?
  end

  def test_body_at_4000_chars_is_valid
    note = Note.new(user_id: 1, body: 'a' * 4000)
    assert note.valid?, note.errors.full_messages.inspect
  end

  def test_recent_scope_orders_by_created_at_desc
    sql = Note.recent.to_sql
    assert_match(/ORDER BY.*created_at.*DESC/i, sql)
  end

  def test_destroy_soft_deletes
    note = notes(:one)
    note.destroy
    reloaded = Note.find(note.id)
    assert reloaded.deleted, 'destroy should set deleted: true (soft-delete), not remove the row'
  end

end
