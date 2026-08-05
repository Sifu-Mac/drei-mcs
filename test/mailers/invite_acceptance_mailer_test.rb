require "test_helper"

class InviteAcceptanceMailerTest < ActionMailer::TestCase
  test "notifies the inviting admin when an invite is accepted" do
    invite = invites(:pending_client)
    accepted_user = users(:client)
    accepted_user.update!(display_name: "Kathi")

    mail = InviteAcceptanceMailer.accepted(invite, accepted_user)

    assert_equal "Einladung angenommen – DB × DREI", mail.subject
    assert_equal [ invite.invited_by.email_address ], mail.to
    assert_equal [ "noreply@digitalbackup.at" ], mail.from
    assert_equal [ "DB × DREI" ], mail[:from].display_names
    assert_includes mail.body.decoded, "Kathi hat deine Einladung zu DB × DREI angenommen"
    assert_includes mail.body.decoded, "Digitalbackup MW GmbH"
  end
end
