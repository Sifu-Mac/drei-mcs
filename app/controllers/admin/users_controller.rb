module Admin
  class UsersController < ApplicationController
    layout "admin"
    require_admin

    def index
      @new_user = User.new
      @users = User.includes(:sessions, :tasks)
                   .order(created_at: :desc)
                   .map do |user|
        {
          user: user,
          email: user.email_address,
          created_at: user.created_at,
          last_login: user.sessions.maximum(:updated_at),
          tasks_count: user.tasks.count
        }
      end

      render layout: false if turbo_frame_request?
    end

    def create
      @new_user = User.new(user_params)

      if @new_user.save
        redirect_to admin_users_path, notice: "Benutzer wurde erstellt."
      else
        index
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      user = User.find(params[:id])

      if user == current_user
        redirect_to admin_users_path, alert: "Das eigene Konto kann nicht gelöscht werden."
      elsif user.admin? && User.where(admin: true).count <= 1
        redirect_to admin_users_path, alert: "Der letzte Admin kann nicht gelöscht werden."
      else
        user.destroy!
        redirect_to admin_users_path, notice: "Benutzer wurde gelöscht."
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :admin)
    end
  end
end
