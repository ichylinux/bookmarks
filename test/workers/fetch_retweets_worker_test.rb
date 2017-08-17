require 'test_helper'

class FetchRetweetsWorkerTest < MiniTest::Test

  def test_example
    w = FetchRetweetsWorker.new
    w.perform
  end

end
