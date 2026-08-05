class InviteAcceptanceMailer < ApplicationMailer
  def accepted(invite, accepted_user)
    @invite = invite
    @accepted_user = accepted_user

    mail(
      subject: "Einladung angenommen – DB × DREI",
      to: invite.invited_by.email_address,
      content_type: "text/plain"
    )
  end
end
