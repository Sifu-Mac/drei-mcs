class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Passwort zurücksetzen – DB × DREI", to: user.email_address, content_type: "text/plain"
  end
end
