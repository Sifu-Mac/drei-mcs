class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "hello@digitalbackup.at")
  layout "mailer"
end
