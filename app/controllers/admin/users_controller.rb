# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[confirm_purge destroy]

    def index
      scope = User.select(
        'users.*',
        '(SELECT COUNT(*) FROM bookmarks WHERE bookmarks.user_id = users.id) AS bookmarks_count',
        '(SELECT COUNT(*) FROM feeds WHERE feeds.user_id = users.id) AS feeds_count',
        '(SELECT COUNT(*) FROM notes WHERE notes.user_id = users.id) AS notes_count',
        '(SELECT COUNT(*) FROM todos WHERE todos.user_id = users.id) AS todos_count',
        '(SELECT COUNT(*) FROM portals WHERE portals.user_id = users.id AND portals.deleted = false) AS portals_count'
      ).order(:id)
      page = [params[:page].to_i, 1].max

      @users = scope.page(page)
    end

    def confirm_purge
      return redirect_to admin_users_path, alert: t('admin.users.purge.not_purgeable') unless @user.purgeable?
    end

    def destroy
      unless @user.purgeable?
        redirect_to admin_users_path, alert: t('admin.users.purge.not_purgeable')
        return
      end

      @user.purge!
      redirect_to admin_users_path, notice: t('admin.users.purge.success')
    rescue User::NotPurgeableError
      redirect_to admin_users_path, alert: t('admin.users.purge.not_purgeable')
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
