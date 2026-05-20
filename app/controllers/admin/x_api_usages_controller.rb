module Admin
  class XApiUsagesController < BaseController
    SORT_COLUMNS = %w[total_calls last_called_at].freeze

    def index
      @from_date = parse_date_param(params[:from])
      @to_date = parse_date_param(params[:to])
      @sort = SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : 'total_calls'
      @direction = params[:direction] == 'asc' ? 'asc' : 'desc'

      since_time = @from_date&.in_time_zone&.beginning_of_day
      until_time = @to_date&.in_time_zone&.end_of_day

      summaries = XApiCall.usage_summary(since: since_time, until_time: until_time).to_a
      users_by_id = User.where(id: summaries.map(&:user_id)).index_by(&:id)

      @rows = summaries.map do |summary|
        user = users_by_id[summary.user_id]
        {
          identity: identity_label(user),
          total_calls: summary.total_calls,
          last_called_at: summary.last_called_at,
          error_count: summary.error_count
        }
      end

      @rows.sort_by! { |row| row[@sort.to_sym] || 0 }
      @rows.reverse! if @direction == 'desc'
    end

    private

    def parse_date_param(value)
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def identity_label(user)
      return '—' unless user

      return user.email if user.has_valid_email?

      acct = user.x_accounts.not_deleted.order(:id).first
      return "@#{acct.username}" if acct

      user.name.presence || '—'
    end
  end
end
