require 'test_helper'

class FetchRetweetsWorkerTest < Minitest::Test

  def test_example
    w = FetchRetweetsWorker.new
    w.perform
  end

end
