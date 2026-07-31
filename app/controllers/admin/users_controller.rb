module Admin
  class UsersController < ApplicationController
    layout "admin"
    require_admin

    def index
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

    def promote
      user = User.find(params[:id])
      user.update!(admin: true)
      AuditEvent.record!(actor: current_user, action: "user_promoted_to_admin", target: user, target_label: user.email_address)
      redirect_to admin_users_path, notice: "#{user.display_label} ist jetzt Admin."
    end

    def demote
      user = User.find(params[:id])

      if user == current_user
        return redirect_to(admin_users_path, alert: "Die eigenen Adminrechte können nicht entzogen werden.")
      end
      if user.admin? && User.where(admin: true).count <= 1
        return redirect_to(admin_users_path, alert: "Der letzte Admin kann nicht herabgestuft werden.")
      end

      user.update!(admin: false)
      AuditEvent.record!(actor: current_user, action: "user_demoted_to_client", target: user, target_label: user.email_address)
      redirect_to admin_users_path, notice: "#{user.display_label} ist jetzt Client."
    end

    def destroy
      user = User.find(params[:id])

      if user == current_user
        redirect_to admin_users_path, alert: "Das eigene Konto kann nicht gelöscht werden."
      elsif user.admin? && User.where(admin: true).count <= 1
        redirect_to admin_users_path, alert: "Der letzte Admin kann nicht gelöscht werden."
      else
        AuditEvent.record!(actor: current_user, action: "user_deleted", target: user, target_label: user.email_address)
        user.destroy!
        redirect_to admin_users_path, notice: "Benutzer wurde gelöscht."
      end
    end
  end
end
