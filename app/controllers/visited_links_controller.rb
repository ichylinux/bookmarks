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

  def toggle_like
    source = params[:source]
    unless VisitedLink::HISTORY_SOURCES.include?(source)
      head :unprocessable_entity
      return
    end

    liked = VisitedLink.toggle_like!(current_user, params[:url], title: params[:title], source: source,
                                     gadget_id: params[:gadget_id])
    if liked.nil?
      head :unprocessable_entity
      return
    end

    response.set_header('X-Entry-Liked', liked ? '1' : '0')
    head :no_content
  end
end
