class ApplicationMailer < ActionMailer::Base
  sender_address = Mail::Address.new(ENV.fetch("MAILER_FROM", "noreply@digitalbackup.at"))
  sender_address.display_name = "DB × DREI"

  default from: sender_address.format
  layout "mailer"
end
