# Preview all emails at http://localhost:3000/rails/mailers/invite_mailer
class InviteMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/invite_mailer/invitation
  def invitation
    InviteMailer.invitation(Invite.first || Invite.new(email: "preview@example.com", invited_by: User.take, role: :internal))
  end
end
