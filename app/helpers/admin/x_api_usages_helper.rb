module Admin
  module XApiUsagesHelper
    def filter_params
      params = {}
      params[:from] = @from_date&.iso8601
      params[:to] = @to_date&.iso8601
      params
    end

    def toggle_direction(column)
      @sort == column && @direction == 'desc' ? 'asc' : 'desc'
    end
  end
end
