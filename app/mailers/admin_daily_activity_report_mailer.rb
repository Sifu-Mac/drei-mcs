class AdminDailyActivityReportMailer < ApplicationMailer
  def daily_summary(admin, period_start, period_end)
    @admin = admin
    @report = AdminDailyActivityReport.new(period_start: period_start, period_end: period_end)
    @period_start = period_start
    @period_end = period_end

    mail(
      subject: "DB × DREI – Tagesübersicht vom #{period_end.in_time_zone(DailyAdminActivityReportJob::REPORT_TIME_ZONE).strftime("%d.%m.%Y")}",
      to: admin.email_address
    )
  end
end
