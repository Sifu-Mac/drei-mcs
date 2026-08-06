require "test_helper"

class DailyAdminActivityReportJobTest < ActiveJob::TestCase
  setup do
    @run_at = Time.utc(2026, 8, 5, 5, 30)
    TaskActivity.create!(task: tasks(:one), user: users(:client), action: "moved", field_name: "board_column", old_value: "Produktionsplan", new_value: "DREI-Review", created_at: @run_at - 1.hour, updated_at: @run_at - 1.hour)
  end

  test "queues one report for each admin and records the delivery window" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, queue: "mailers") do
      assert_difference("AdminActivityReportDelivery.count", 1) do
        DailyAdminActivityReportJob.perform_now(@run_at)
      end
    end

    delivery = AdminActivityReportDelivery.sole
    assert_equal users(:admin), delivery.user
    assert_equal Time.utc(2026, 8, 4, 5, 30), delivery.period_start_at
    assert_equal @run_at, delivery.period_end_at
  end

  test "does not queue a duplicate report for the same admin and period" do
    DailyAdminActivityReportJob.perform_now(@run_at)

    assert_no_enqueued_jobs do
      assert_no_difference("AdminActivityReportDelivery.count") do
        DailyAdminActivityReportJob.perform_now(@run_at)
      end
    end
  end

  test "does not queue a report without changes" do
    TaskActivity.delete_all

    assert_no_enqueued_jobs do
      assert_no_difference("AdminActivityReportDelivery.count") do
        DailyAdminActivityReportJob.perform_now(@run_at)
      end
    end
  end
end
