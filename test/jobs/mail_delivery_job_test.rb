require "test_helper"

class MailDeliveryJobTest < ActiveJob::TestCase
  class TemporarilyFailingDelivery
    class_attribute :error_class, default: Net::OpenTimeout

    def deliver_now
      raise error_class, "test delivery failure"
    end
  end

  class TemporarilyFailingMailer
    def self.test_message
      TemporarilyFailingDelivery.new
    end

    def self.handle_exception(error)
      raise error
    end
  end

  test "uses the dedicated mailers queue" do
    assert_equal "mailers", MailDeliveryJob.new.queue_name
  end

  test "retries temporary SMTP connection failures" do
    retryable_errors = [ Net::OpenTimeout, Net::ReadTimeout, Net::SMTPServerBusy, IOError, SocketError ]

    retryable_errors.each do |error_class|
      self.class::TemporarilyFailingDelivery.error_class = error_class

      assert_enqueued_with(job: MailDeliveryJob, queue: "mailers") do
        perform_failing_delivery
      end
    end
  end

  test "limits retries to five attempts" do
    assert_equal 5, MailDeliveryJob::RETRY_ATTEMPTS
  end

  test "raises permanent failures without retrying" do
    self.class::TemporarilyFailingDelivery.error_class = ArgumentError

    assert_no_enqueued_jobs do
      assert_raises(ArgumentError) { perform_failing_delivery }
    end
  end

  private

  def perform_failing_delivery
    failing_delivery_job.perform_now
  end

  def failing_delivery_job
    MailDeliveryJob.new(
      self.class::TemporarilyFailingMailer.name,
      "test_message",
      "deliver_now",
      args: []
    )
  end
end
