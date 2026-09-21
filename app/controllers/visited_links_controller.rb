class VisitedLinksController < ApplicationController
  def create
    if params[:source] == 'feed'
      VisitedLink.record!(current_user, params[:url], title: params[:title], source: 'feed')
    else
      VisitedLink.record!(current_user, params[:url])
    end
    head :no_content
  end
end
