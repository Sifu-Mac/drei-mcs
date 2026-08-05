require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:one)
    mail = PasswordsMailer.reset(user)

    assert_equal "Passwort zurücksetzen – DB × DREI", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_equal [ "noreply@digitalbackup.at" ], mail.from
    assert_equal [ "DB × DREI" ], mail[:from].display_names
    assert_match %r{\Ahttps://example\.com/passwords/}, extract_reset_url(mail)
    assert_includes mail.body.decoded, "Passworts für DB × DREI"
    assert_includes mail.body.decoded, "Digitalbackup MW GmbH"
  end

  private

  def extract_reset_url(mail)
    mail.body.decoded.lines.find { |line| line.start_with?("https://") }.to_s.strip
  end
end
