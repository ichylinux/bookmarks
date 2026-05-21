module Admin
  class XApiUsagesController < BaseController
    DEFAULT_RANGE_DAYS = 7
    SORT_COLUMNS_SUMMARY = %w[total_calls last_called_at].freeze
    SORT_COLUMNS_DETAIL = %w[called_at total_calls].freeze

    def index
      assign_date_range
      since_time = @from_date&.in_time_zone&.beginning_of_day
      until_time = @to_date&.in_time_zone&.end_of_day

      if @date_range_active
        load_detail_rows(since: since_time, until_time: until_time)
      else
        load_summary_rows(since: since_time, until_time: until_time)
      end
    end

    private

    def assign_date_range
      if params.key?(:from) || params.key?(:to)
        @from_date = parse_date_param(params[:from])
        @to_date = parse_date_param(params[:to])
      else
        @from_date = DEFAULT_RANGE_DAYS.days.ago.to_date
        @to_date = Date.current
      end
      @date_range_active = @from_date.present? || @to_date.present?
    end

    def load_summary_rows(since:, until_time:)
      @sort = SORT_COLUMNS_SUMMARY.include?(params[:sort]) ? params[:sort] : 'total_calls'
      @direction = params[:direction] == 'asc' ? 'asc' : 'desc'

      summaries = XApiCall.usage_summary(since: since, until_time: until_time).to_a
      users_by_id = User.includes(:x_accounts).where(id: summaries.map(&:user_id)).index_by(&:id)

      @rows = summaries.map do |summary|
        user = users_by_id[summary.user_id]
        {
          identity: identity_label(user),
          total_calls: summary.total_calls.to_i,
          last_called_at: summary.last_called_at ? Time.zone.parse(summary.last_called_at.to_s) : nil,
          error_count: summary.error_count.to_i
        }
      end

      sort_rows!(:last_called_at)
    end

    def load_detail_rows(since:, until_time:)
      @sort = SORT_COLUMNS_DETAIL.include?(params[:sort]) ? params[:sort] : 'called_at'
      @direction = params[:direction] == 'asc' ? 'asc' : 'desc'

      summaries = XApiCall.usage_by_day(since: since, until_time: until_time).to_a
      users_by_id = User.includes(:x_accounts).where(id: summaries.map(&:user_id)).index_by(&:id)

      @rows = summaries.map do |summary|
        user = users_by_id[summary.user_id]
        called_on = summary.called_on.is_a?(Date) ? summary.called_on : Date.parse(summary.called_on.to_s)
        {
          identity: identity_label(user),
          called_at: called_on.in_time_zone,
          total_calls: summary.total_calls.to_i,
          error_count: summary.error_count.to_i
        }
      end

      sort_rows!(:called_at)
    end

    def sort_rows!(nil_sort_key)
      @rows.sort_by! do |row|
        val = row[@sort.to_sym]
        if val.nil?
          @sort == nil_sort_key.to_s ? Time.at(0) : 0
        else
          val
        end
      end
      @rows.reverse! if @direction == 'desc'
    end

    def parse_date_param(value)
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def identity_label(user)
      return '—' unless user

      return user.email if user.has_valid_email?

      acct = user.x_accounts.reject(&:deleted?).sort_by(&:id).first
      return "@#{acct.username}" if acct

      user.x_user_name.presence || '—'
    end
  end
end
