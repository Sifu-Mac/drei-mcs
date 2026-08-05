class InviteMailer < ApplicationMailer
  def invitation(invite)
    @invite = invite
    mail subject: "Einladung zu DB × DREI", to: invite.email, content_type: "text/plain"
  end
end
