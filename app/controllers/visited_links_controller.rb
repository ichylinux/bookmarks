class VisitedLinksController < ApplicationController
  def create
    VisitedLink.record!(current_user, params[:url])
    head :no_content
  end
end
