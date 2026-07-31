require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:one)
    mail = PasswordsMailer.reset(user)

    assert_equal "Reset your password", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_equal [ "hello@digitalbackup.at" ], mail.from
    assert_match %r{\Ahttps://example\.com/passwords/}, extract_reset_url(mail)
  end

  private

  def extract_reset_url(mail)
    mail.body.decoded.lines.find { |line| line.start_with?("https://") }.to_s.strip
  end
end
