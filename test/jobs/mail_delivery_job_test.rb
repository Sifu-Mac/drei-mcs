require "test_helper"

class MailDeliveryJobTest < ActiveJob::TestCase
  class TemporarilyFailingDelivery
    def deliver_now
      raise Net::OpenTimeout, "test timeout"
    end
  end

  class TemporarilyFailingMailer
    def self.test_message
      TemporarilyFailingDelivery.new
    end
  end

  test "uses the dedicated mailers queue" do
    assert_equal "mailers", MailDeliveryJob.new.queue_name
  end

  test "retries temporary SMTP connection failures" do
    assert_enqueued_with(job: MailDeliveryJob, queue: "mailers") do
      MailDeliveryJob.perform_now(
        self.class::TemporarilyFailingMailer.name,
        "test_message",
        "deliver_now",
        args: []
      )
    end
  end
end
