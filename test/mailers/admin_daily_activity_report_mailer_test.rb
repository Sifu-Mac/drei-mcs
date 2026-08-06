require "test_helper"

class AdminDailyActivityReportMailerTest < ActionMailer::TestCase
  test "renders a readable multipart daily summary" do
    period_start = Time.utc(2026, 8, 4, 5, 30)
    period_end = Time.utc(2026, 8, 5, 5, 30)
    TaskActivity.create!(task: tasks(:one), user: users(:client), action: "moved", field_name: "board_column", old_value: "Produktionsplan", new_value: "DREI-Review", created_at: period_start + 1.hour, updated_at: period_start + 1.hour)

    mail = AdminDailyActivityReportMailer.daily_summary(users(:admin), period_start, period_end)

    assert_equal "DB × DREI – Tagesübersicht vom 05.08.2026", mail.subject
    assert_equal [ users(:admin).email_address ], mail.to
    assert_equal [ "noreply@digitalbackup.at" ], mail.from
    assert_predicate mail, :multipart?
    assert_includes mail.html_part.body.decoded, "Kartenbewegungen"
    assert_includes mail.html_part.body.decoded, "Karte öffnen"
    assert_includes mail.text_part.body.decoded, "TAGESÜBERSICHT"
    assert_includes mail.text_part.body.decoded, "Digitalbackup MW GmbH"
  end
end
