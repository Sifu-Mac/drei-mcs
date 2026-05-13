class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@mission.digitalbackup.cloud")
  layout "mailer"
end
