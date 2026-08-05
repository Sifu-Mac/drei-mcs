require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invitation" do
    invite = invites(:pending_internal)
    mail = InviteMailer.invitation(invite)

    assert_equal "Einladung zu DB × DREI", mail.subject
    assert_equal [ invite.email ], mail.to
    assert_equal [ "noreply@digitalbackup.at" ], mail.from
    assert_equal [ "DB × DREI" ], mail[:from].display_names
    assert_match "https://example.com/invites/#{invite.token}", mail.body.encoded
    assert_includes mail.body.decoded, "du wurdest zu DB × DREI eingeladen"
    assert_includes mail.body.decoded, "Digitalbackup MW GmbH"
  end
end
