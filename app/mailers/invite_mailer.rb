class InviteMailer < ApplicationMailer
  def invitation(invite)
    @invite = invite
    mail subject: "You're invited to DREI Asset Review", to: invite.email, content_type: "text/plain"
  end
end
