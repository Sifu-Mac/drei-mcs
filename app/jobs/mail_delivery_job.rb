class MailDeliveryJob < ActionMailer::MailDeliveryJob
  queue_as :mailers

  retry_on Net::OpenTimeout,
    Net::ReadTimeout,
    Net::SMTPServerBusy,
    IOError,
    SocketError,
    wait: :polynomially_longer,
    attempts: 5

  around_perform do |job, block|
    block.call
  rescue StandardError => error
    Rails.logger.error(
      "Transactional email delivery failed " \
      "job_id=#{job.job_id} error_class=#{error.class.name}"
    )
    raise
  end
end
