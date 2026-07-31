module Admin
  class InvitesController < ApplicationController
    layout "admin"
    require_admin

    def index
      @new_invite = Invite.new
      @invites = Invite.includes(:invited_by).order(created_at: :desc)

      render layout: false if turbo_frame_request?
    end

    def create
      email = params.dig(:invite, :email).to_s.strip.downcase
      @new_invite = Invite.new(invite_params)
      @new_invite.role = params.dig(:invite, :role) if params.dig(:invite, :role).present?
      @new_invite.invited_by = current_user

      if User.exists?(email_address: email)
        @new_invite.errors.add(:email, "gehört bereits zu einem Konto")
      elsif Invite.pending.exists?(email: email)
        @new_invite.errors.add(:email, "hat bereits eine offene Einladung")
      elsif @new_invite.save
        if enqueue_invitation
          redirect_to admin_invites_path, notice: "Einladung an #{@new_invite.email} wurde zum Versand eingereiht." and return
        end
      end

      @invites = Invite.includes(:invited_by).order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end

    def destroy
      invite = Invite.find(params[:id])
      invite.update!(revoked_at: Time.current) if invite.usable?
      redirect_to admin_invites_path, notice: "Einladung wurde widerrufen."
    end

    private

    def invite_params
      params.require(:invite).permit(:email)
    end

    def enqueue_invitation
      return true if InviteMailer.invitation(@new_invite).deliver_later

      cleanup_failed_invitation_enqueue(ActiveJob::EnqueueError.new("Mail delivery job was not enqueued"))
    rescue StandardError => error
      cleanup_failed_invitation_enqueue(error)
    end

    def cleanup_failed_invitation_enqueue(error)
      failed_attributes = @new_invite.attributes.slice("email", "role")
      @new_invite.delete
      @new_invite = Invite.new(failed_attributes)
      @new_invite.invited_by = current_user
      @new_invite.errors.add(:base, "Einladung konnte nicht zum Versand eingereiht werden. Bitte erneut versuchen.")
      Rails.logger.error("Invite email enqueue failed error_class=#{error.class.name}")
      false
    end
  end
end
