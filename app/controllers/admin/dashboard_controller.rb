module Admin
  class DashboardController < ApplicationController
    layout "admin"
    require_admin

    def index
      @total_users = User.count
      @total_tasks = Task.count
      @recent_signups = User.where("created_at >= ?", 7.days.ago).count

      render layout: false if turbo_frame_request?
    end
  end
end
