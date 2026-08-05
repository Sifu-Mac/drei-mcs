class DailyAdminActivityReportJob < ApplicationJob
  REPORT_TIME_ZONE = "Europe/Vienna"
  REPORT_HOUR = 7
  REPORT_MINUTE = 30

  queue_as :mailers

  def perform(run_at = Time.current)
    period_start, period_end = report_window(run_at)
    report = AdminDailyActivityReport.new(period_start: period_start, period_end: period_end)
    return if report.empty?

    User.where(admin: true).find_each do |admin|
      enqueue_report_for(admin, period_start, period_end)
    end
  end

  private

  def report_window(run_at)
    end_time = run_at.in_time_zone(REPORT_TIME_ZONE).change(hour: REPORT_HOUR, min: REPORT_MINUTE, sec: 0)
    start_date = end_time.to_date - (end_time.monday? ? 3.days : 1.day)
    start_time = start_date.in_time_zone(REPORT_TIME_ZONE).change(hour: REPORT_HOUR, min: REPORT_MINUTE, sec: 0)

    [ start_time, end_time ]
  end

  def enqueue_report_for(admin, period_start, period_end)
    delivery = AdminActivityReportDelivery.create!(user: admin, period_start_at: period_start, period_end_at: period_end)
    return if AdminDailyActivityReportMailer.daily_summary(admin, period_start, period_end).deliver_later(queue: :mailers)

    delivery.destroy!
    raise ActiveJob::EnqueueError, "Daily admin activity report was not enqueued"
  rescue ActiveRecord::RecordNotUnique
    nil
  rescue StandardError => error
    delivery&.destroy! if delivery&.persisted?
    Rails.logger.error("Daily admin activity report enqueue failed error_class=#{error.class.name}")
    nil
  end
end
