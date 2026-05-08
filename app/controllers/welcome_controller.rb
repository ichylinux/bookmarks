class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  before_action :redirect_guest_to_landing, only: :index

  def index
    @portal = current_user.portals.first
    @note = Note.new
    @notes = current_user.notes.active.recent
  end

  def save_state
    ActiveRecord::Base.transaction do
      current_user.portals.first.update_layout(params[:portal])
    end

    head :ok
  end

  private

  def redirect_guest_to_landing
    return if user_signed_in?

    redirect_to landing_path
  end

end
