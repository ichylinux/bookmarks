require 'test_helper'

class XApiCallTest < ActiveSupport::TestCase
  def setup
    XApiCall.delete_all
  end

  def test_record_が行を作成する
    user = users(:one)
    assert_difference -> { XApiCall.count }, 1 do
      XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    end
  end

  def test_record_が正しい値を保存する
    user = users(:one)
    row = XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: false,
                           error_code: 'timeout', rate_limit_remaining: 42)
    assert_equal 'fetch_following', row.endpoint
    assert_equal false, row.success
    assert_equal 'timeout', row.error_code
    assert_equal 42, row.rate_limit_remaining
    assert_not_nil row.called_at
  end

  def test_usage_summaryが正しい集計を返す
    user = users(:one)
    XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    XApiCall.record!(user_id: user.id, endpoint: 'fetch_recent_tweets', success: false)
    result = XApiCall.usage_summary.find { |r| r.user_id == user.id }
    assert_not_nil result
    assert_equal 3, result.total_calls
    assert_equal 1, result.error_count
    assert_not_nil result.last_called_at
  end

  def test_usage_summaryのsinceフィルタが機能する
    user = users(:one)
    XApiCall.create!(user_id: user.id, endpoint: 'fetch_following', success: true,
                     called_at: 2.days.ago)
    XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    result = XApiCall.usage_summary(since: 1.day.ago).find { |r| r.user_id == user.id }
    assert_not_nil result
    assert_equal 1, result.total_calls
  end

  def test_usage_by_dayがユーザーと日付で集計する
    user = users(:one)
    day = Time.zone.local(2026, 5, 20, 10, 0, 0)
    travel_to day do
      2.times { XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true) }
      XApiCall.record!(user_id: user.id, endpoint: 'fetch_recent_tweets', success: false)
    end
    travel_to day + 1.day do
      XApiCall.record!(user_id: user.id, endpoint: 'fetch_following', success: true)
    end

    results = XApiCall.usage_by_day.to_a.select { |r| r.user_id == user.id }
    assert_equal 2, results.size
    may20 = results.find { |r| r.called_on.to_s == '2026-05-20' }
    assert_equal 3, may20.total_calls
    assert_equal 1, may20.error_count
    may21 = results.find { |r| r.called_on.to_s == '2026-05-21' }
    assert_equal 1, may21.total_calls
    assert_equal 0, may21.error_count
  end
end
