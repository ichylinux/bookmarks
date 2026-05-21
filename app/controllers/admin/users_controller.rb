# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    def index
      @users = User.all.includes(:x_accounts).order(:id)
    end
  end
end
