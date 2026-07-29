require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invitation" do
    invite = invites(:pending_internal)
    mail = InviteMailer.invitation(invite)

    assert_equal "You're invited to DREI Asset Review", mail.subject
    assert_equal [ invite.email ], mail.to
    assert_match invite.token, mail.body.encoded
  end
end
