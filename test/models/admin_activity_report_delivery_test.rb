require "test_helper"

class AdminActivityReportDeliveryTest < ActiveSupport::TestCase
  test "deleting a user removes their activity report deliveries" do
    user = User.create!(email_address: "report-admin@example.com", password: "password123", password_confirmation: "password123", admin: true)
    AdminActivityReportDelivery.create!(user: user, period_start_at: 1.day.ago, period_end_at: Time.current)

    assert_difference("AdminActivityReportDelivery.count", -1) do
      user.destroy!
    end
  end
end
