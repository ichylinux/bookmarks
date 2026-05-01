require 'test_helper'

class TodoTest < ActiveSupport::TestCase
  def test_gadget_titles_follow_active_locale
    I18n.with_locale(:ja) do
      assert_equal 'ブックマーク', BookmarkGadget.new(user).title
      assert_equal 'タスク', TodoGadget.new([]).title
    end

    I18n.with_locale(:en) do
      assert_equal 'Bookmarks', BookmarkGadget.new(user).title
      assert_equal 'Tasks', TodoGadget.new([]).title
    end
  end

  def test_priority_options_follow_active_locale_and_keep_numeric_values
    I18n.with_locale(:ja) do
      assert_equal [['高', 1], ['中', 2], ['低', 3]], Todo.priority_options
    end

    I18n.with_locale(:en) do
      assert_equal [['High', 1], ['Normal', 2], ['Low', 3]], Todo.priority_options
    end

    assert_equal [1, 2, 3], Todo.priority_options.map(&:last)
  end

  def test_priority_name_follow_active_locale
    todo = Todo.new(priority: Todo::PRIORITY_HIGH)

    I18n.with_locale(:ja) do
      assert_equal '高', todo.priority_name
    end

    I18n.with_locale(:en) do
      assert_equal 'High', todo.priority_name
    end
  end
end
