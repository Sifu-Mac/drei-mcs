module Admin
  class AuditEventsController < ApplicationController
    layout "admin"
    require_admin

    def index
      @audit_events = AuditEvent.includes(:actor).recent.limit(200)
      render layout: false if turbo_frame_request?
    end
  end
end
