class VisitedLinksController < ApplicationController
  def create
    source = params[:source]
    if VisitedLink::HISTORY_SOURCES.include?(source)
      VisitedLink.record!(current_user, params[:url], title: params[:title], source: source,
                          gadget_id: params[:gadget_id])
    else
      VisitedLink.record!(current_user, params[:url])
    end
    head :no_content
  end
end
