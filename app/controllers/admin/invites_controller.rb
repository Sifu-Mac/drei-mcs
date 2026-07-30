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
      @new_invite.invited_by = current_user

      if User.exists?(email_address: email)
        @new_invite.errors.add(:email, "gehört bereits zu einem Konto")
      elsif Invite.pending.exists?(email: email)
        @new_invite.errors.add(:email, "hat bereits eine offene Einladung")
      elsif @new_invite.save
        InviteMailer.invitation(@new_invite).deliver_later
        redirect_to admin_invites_path, notice: "Einladung an #{@new_invite.email} wurde versendet." and return
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
      params.require(:invite).permit(:email, :role)
    end
  end
end
