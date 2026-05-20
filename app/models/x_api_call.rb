class XApiCall < ApplicationRecord
  belongs_to :user, optional: false

  # NOTE: Call record! OUTSIDE any surrounding transaction block.
  # If the caller's transaction rolls back, the log row would be lost.
  def self.record!(user_id:, endpoint:, success:, error_code: nil, rate_limit_remaining: nil)
    create!(
      user_id: user_id,
      endpoint: endpoint,
      success: success,
      error_code: error_code,
      rate_limit_remaining: rate_limit_remaining,
      called_at: Time.current
    )
  end

  def self.usage_summary(since: nil)
    scope = since ? where('called_at >= ?', since) : all
    scope.group(:user_id).select(
      :user_id,
      'COUNT(*) AS total_calls',
      'MAX(called_at) AS last_called_at',
      'SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS error_count'
    )
  end
end
