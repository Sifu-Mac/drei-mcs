class PasswordChangesController < ApplicationController
  def edit
  end

  def update
    unless current_user.password_user? && current_user.authenticate(params.dig(:user, :current_password).to_s)
      flash.now[:alert] = "Das aktuelle Passwort ist nicht korrekt."
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(password_params)
      current_user.sessions.where.not(id: Current.session.id).destroy_all
      AuditEvent.record!(actor: current_user, action: "password_changed", target: current_user, target_label: current_user.email_address)
      redirect_to settings_path, notice: "Passwort wurde geändert. Andere Sitzungen wurden abgemeldet."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.expect(user: [ :password, :password_confirmation ])
  end
end
