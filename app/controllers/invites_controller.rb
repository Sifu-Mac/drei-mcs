class InvitesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_invite

  def show
    redirect_to root_path, alert: "This invite link is invalid or has expired." unless @invite&.usable?
  end

  def update
    return redirect_to(root_path, alert: "This invite link is invalid or has expired.") unless @invite

    accepted = false

    ActiveRecord::Base.transaction do
      @invite.lock!
      raise ActiveRecord::Rollback unless @invite.usable?

      @user = User.new(
        email_address: @invite.email,
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
      @user.invited_role = @invite.client? ? :client : :member

      if @user.save
        @invite.update!(accepted_at: Time.current)
        accepted = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if accepted
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Account created. Welcome!"
    elsif @invite.reload.usable?
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    else
      redirect_to root_path, alert: "This invite link is invalid or has expired."
    end
  end

  private

  def set_invite
    @invite = Invite.find_by(token: params[:token])
  end
end
