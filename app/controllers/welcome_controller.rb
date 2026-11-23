class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    return unless user_signed_in?

    if params[:tab].to_s == 'notes' && current_user.preference.use_note?
      redirect_to notes_path
      return
    end

    @portal = current_user.portals.first
  end

  def save_state
    ActiveRecord::Base.transaction do
      current_user.portals.first.update_layout(params[:portal])
    end

    head :ok
  end
end
