require "test_helper"
require "open3"

class ProductionMailerConfigurationTest < ActiveSupport::TestCase
  test "production requires STARTTLS and does not allow opportunistic downgrade" do
    script = <<~RUBY
      settings = Rails.application.config.action_mailer.smtp_settings
      abort "unexpected SMTP port" unless settings[:port] == 587
      abort "STARTTLS is not required" unless settings[:enable_starttls] == :always
      abort "opportunistic STARTTLS is configured" if settings.key?(:enable_starttls_auto)
      abort "TLS peer verification is disabled" unless settings[:openssl_verify_mode] == "peer"
    RUBY

    env = {
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE_DUMMY" => "1",
      "APP_HOST" => "example.test",
      "SMTP_ADDRESS" => "smtp.example.test",
      "SMTP_PORT" => "587",
      "SMTP_DOMAIN" => "example.test",
      "SMTP_USERNAME" => "test-access-key",
      "SMTP_PASSWORD" => "test-secret-key",
      "MAILER_FROM" => "mailer@example.test"
    }

    _stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, "bin/rails", "runner", script)

    assert status.success?, stderr
  end
end
